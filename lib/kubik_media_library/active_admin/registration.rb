# frozen_string_literal: true

module KubikMediaLibrary
  module ActiveAdmin
    module Registration
      module_function

      def register_media_upload!(&block)
        Kubik.register_models!

        ::ActiveAdmin.register Kubik::MediaUpload do
          menu(**KubikMediaLibrary.config.active_admin_menu)
          actions :all, except: %i[new show]

          config.filters = false
          config.per_page = KubikMediaLibrary.config.active_admin_per_page

          permit_params :image, :file, :media_tag_list, additional_info: {}

          breadcrumb do
            if params[:action] == 'index'
              [link_to('Admin', admin_root_path)]
            else
              [
                link_to('Admin', admin_root_path),
                link_to('Media', admin_kubik_media_uploads_path)
              ]
            end
          end

          controller do
            def permitted_params
              params.permit(
                :authenticity_token, :commit,
                kubik_media_upload: [:image, :file, :media_tag_list, { additional_info: {} }],
                media_upload: [:image, :file, :media_tag_list, { additional_info: {} }]
              )
            end

            def gallery_filter_params
              # Read from query string (GET filter form). Do not compact_blank media_type so
              # explicit empty values are not the issue; only pass present filter keys.
              permitted = params.permit(
                :media_type, :uploaded_from, :uploaded_to, :media_tag, :media_tags_match, :modal,
                :q, :gallery_sort, :media_untagged,
                media_tags: []
              )
              uploaded_from, uploaded_to = Kubik::MediaUpload.normalize_gallery_filter_dates(
                permitted[:uploaded_from],
                permitted[:uploaded_to]
              )
              tags = KubikMediaLibrary.normalize_gallery_media_tags(permitted)
              result = {
                media_type: permitted[:media_type],
                uploaded_from: uploaded_from,
                uploaded_to: uploaded_to,
                q: permitted[:q].to_s.strip.presence,
                gallery_sort: permitted[:gallery_sort].presence,
                modal: permitted[:modal]
              }
              if KubikMediaLibrary.gallery_untagged_requested?(permitted)
                result[:media_untagged] = "1"
              end
              if tags.any?
                result[:media_tags] = tags
                match = permitted[:media_tags_match].to_s.downcase
                result[:media_tags_match] = match == "and" ? "and" : "or"
              end
              result.compact_blank
            end

            def filtered_collection
              Kubik::MediaUpload.filter_gallery(scoped_collection, gallery_filter_params)
            end

            def gallery_sorted_collection
              Kubik::MediaUpload.gallery_order(filtered_collection, gallery_filter_params[:gallery_sort])
            end

            def index
              @page_title = "Media gallery"
              @collection = gallery_sorted_collection.page(params[:page])
                                             .per(KubikMediaLibrary.config.active_admin_per_page)
              turbo_action = params["modal"].present? ? "advance" : false
              @gallery_filter_params = gallery_filter_params
              modal = params["modal"].present?
              index_locals = {
                modal: modal,
                turbo_action: turbo_action,
                gallery_filter_params: @gallery_filter_params
              }

              if turbo_frame_request?
                frame_id = request.headers["Turbo-Frame"].to_s
                if KubikMediaLibrary::MODAL_GALLERY_TURBO_FRAME_IDS.include?(frame_id)
                  render partial: "modal_gallery_frame",
                         locals: index_locals.merge(collection: @collection),
                         layout: false
                else
                  render partial: "gallery_results",
                         locals: index_locals.merge(collection: @collection),
                         layout: false
                end
              else
                render "index", locals: index_locals, layout: "active_admin"
              end
            end

            def create
              if Kubik::MediaFileUploader::ALLOWED_TYPES.include?(params[:kubik_media_upload][:image].content_type)
                params[:kubik_media_upload][:file] = params[:kubik_media_upload].delete(:image)
              end
              create! do |success, _failure|
                @collection = gallery_sorted_collection.page(params[:page])
                                                 .per(KubikMediaLibrary.config.active_admin_per_page)
                @gallery_filter_params = gallery_filter_params
                @modal = params[:kubik_media_upload][:modal].present?
                @turbo_action = (params[:kubik_media_upload][:modal].present? || params['modal'].present?) ? 'advance' : false
                success.html { redirect_to admin_kubik_media_uploads_path, allow_other_host: false }
                success.json
                success.turbo_stream
              end
            end

            def update
              update! do |success, _failure|
                success.html { redirect_to admin_kubik_media_uploads_path, allow_other_host: false }
              end
            end
          end

          collection_action :tag_suggestions, format: :json do
            query = params[:q].to_s.downcase.strip
            return render(json: []) if query.blank?

            tags = Kubik::MediaUpload.gallery_media_tag_options
            tags = tags.select { |name| name.downcase.include?(query) }
            render json: tags
          end

          collection_action :regenerate_all, method: :post do
            RegenerateAllDerivativesJob.perform_later
            redirect_to collection_path, notice: 'Regeneration queued for all images'
          end

          member_action :regenerate, method: :post do
            if resource.pdf_upload?
              resource.regenerate_file_preview!
              notice = "PDF preview regeneration queued"
            else
              resource.regenerate_derivatives!
              notice = "Regeneration queued"
            end
            redirect_to edit_admin_kubik_media_upload_path(resource), notice: notice
          end

          action_item :regenerate_all, only: :index do
            link_to 'Regenerate all',
                    regenerate_all_admin_kubik_media_uploads_path,
                    method: :post,
                    data: { confirm: 'Regenerate all image versions?' }
          end

          action_item :regenerate, only: :edit, if: proc {
            resource.pdf_upload? || (resource.image_data.present? && resource.ready?)
          } do
            label = resource.pdf_upload? ? "Regenerate PDF preview" : "Regenerate versions"
            confirm = resource.pdf_upload? ? "Regenerate the PDF preview thumbnails?" : "Regenerate all versions for this image?"
            link_to label,
                    regenerate_admin_kubik_media_upload_path(resource),
                    method: :post,
                    data: { confirm: confirm }
          end

          form do |image|
            if image.object.new_record?
              image.input :image, as: :file
            elsif image.object.image_data.present?
              tabs do
                tab 'Details' do
                  legend_header = helpers.render(
                    partial: "admin/kubik_media_uploads/media_details_legend_header",
                    locals: {
                      title: "Image details - #{image.object.gallery_display_name}",
                      url: image.object.public_media_url,
                      upload: image.object
                    }
                  )
                  inputs name: legend_header do
                    columns do
                      column do
                        text_node image_tag image.object.image_url, class: 'media_image'
                      end
                      column do
                        image.fields_for :additional_info do |f|
                          if KubikMediaLibrary.wysiwyg_available?
                            f.input :img_title, as: :kubik_wysiwyg, required: false, input_html: { value: image.object.additional_info['img_title'] }
                          else
                            f.input :img_title, required: false, input_html: { value: image.object.additional_info['img_title'] }
                          end
                        end
                        image.fields_for :additional_info do |f|
                          if KubikMediaLibrary.wysiwyg_available?
                            f.input :alt_text, as: :kubik_wysiwyg, required: false, input_html: { value: image.object.additional_info['alt_text'] }
                          else
                            f.input :alt_text, required: false, input_html: { value: image.object.additional_info['alt_text'] }
                          end
                        end
                        image.fields_for :additional_info do |f|
                          if KubikMediaLibrary.wysiwyg_available?
                            f.input :img_credit, as: :kubik_wysiwyg, required: false, input_html: { value: image.object.additional_info['img_credit'] }
                          else
                            f.input :img_credit, required: false, input_html: { value: image.object.additional_info['img_credit'] }
                          end
                        end
                        if KubikMediaLibrary.tagging_available?
                          tag_options = {
                            label: "Tags",
                            hint: "Comma-separated labels (e.g. hero, brochure, 2024)",
                            min_length: 1,
                            required: false
                          }
                          if helpers.kubik_tags_field_available?
                            tag_options[:as] = :"kubik/tags"
                            tag_options[:suggestions_url] = lambda {
                              tag_suggestions_admin_kubik_media_uploads_path
                            }
                          end
                          image.input :media_tag_list, **tag_options
                        end
                      end
                    end
                  end
                end
                tab 'Available versions', class: 'version_details' do
                  render 'image_available_versions_tab', image: image
                end
              end
            elsif image.object.file_data.present?
              tabs do
                tab 'Details' do
                  render 'file_details_tab', image: image
                end
              end
            end
            actions
          end

          instance_eval(&block) if block
          customize_block = KubikMediaLibrary.config.active_admin_customize_block
          instance_eval(&customize_block) if customize_block
        end
      end
    end
  end
end
