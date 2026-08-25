# frozen_string_literal: true

require_relative '../../kubik/media_library'

module KubikMediaLibrary
  module ActiveAdmin
    module Registration
      module_function

      def register_media_upload!(&block)
        ::ActiveAdmin.register Kubik::MediaUpload do
          menu(**KubikMediaLibrary.config.active_admin_menu)
          actions :all, except: %i[new show]

          config.filters = false
          config.per_page = KubikMediaLibrary.config.active_admin_per_page
          config.batch_actions = false

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

            def index
              @page_title = 'Media gallery'
              @collection = scoped_collection
              @collection = @collection.order(created_at: :desc).page(params[:page]).per(KubikMediaLibrary.config.active_admin_per_page)
              turbo_action = params['modal'].present? ? 'advance' : false
              render 'index', locals: { modal: params['modal'].present?, turbo_action: turbo_action }, layout: 'active_admin'
            end

            def create
              if Kubik::MediaFileUploader::ALLOWED_TYPES.include?(params[:kubik_media_upload][:image].content_type)
                params[:kubik_media_upload][:file] = params[:kubik_media_upload].delete(:image)
              end
              create! do |success, _failure|
                @collection = scoped_collection
                @collection = @collection.order(created_at: :desc).page(params[:page]).per(KubikMediaLibrary.config.active_admin_per_page)
                @modal = params[:kubik_media_upload][:modal].present?
                @turbo_action = (params[:kubik_media_upload][:modal].present? || params['modal'].present?) ? 'advance' : false
                success.html { redirect_to admin_kubik_media_uploads_path }
                success.json
                success.turbo_stream
              end
            end
          end

          collection_action :regenerate_all, method: :post do
            RegenerateAllDerivativesJob.perform_later
            redirect_to collection_path, notice: 'Regeneration queued for all images'
          end

          member_action :regenerate, method: :post do
            resource.regenerate_derivatives!
            redirect_to edit_admin_kubik_media_upload_path(resource), notice: 'Regeneration queued'
          end

          action_item :regenerate_all, only: :index do
            link_to 'Regenerate all',
                    regenerate_all_admin_kubik_media_uploads_path,
                    method: :post,
                    data: { confirm: 'Regenerate all image versions?' }
          end

          action_item :regenerate, only: :edit, if: proc {
            resource.image_data.present? && resource.ready?
          } do
            link_to 'Regenerate versions',
                    regenerate_admin_kubik_media_upload_path(resource),
                    method: :post,
                    data: { confirm: 'Regenerate all versions for this image?' }
          end

          form do |image|
            if image.object.new_record?
              image.input :image, as: :file
            elsif image.object.image_data.present?
              tabs do
                tab 'Details' do
                  inputs "Image details - #{image.object.image_attacher.file.metadata['filename']}" do
                    columns do
                      column do
                        text_node image_tag image.object.image_url, class: 'media_image'
                      end
                      column do
                        image.fields_for :additional_info do |f|
                          if KubikMediaLibrary.wysiwyg_available?
                            f.input :img_title, as: :kubik_wysiwyg, input_html: { value: image.object.additional_info['img_title'] }
                          else
                            f.input :img_title, input_html: { value: image.object.additional_info['img_title'] }
                          end
                        end
                        image.fields_for :additional_info do |f|
                          if KubikMediaLibrary.wysiwyg_available?
                            f.input :alt_text, as: :kubik_wysiwyg, input_html: { value: image.object.additional_info['alt_text'] }
                          else
                            f.input :alt_text, input_html: { value: image.object.additional_info['alt_text'] }
                          end
                        end
                        image.fields_for :additional_info do |f|
                          if KubikMediaLibrary.wysiwyg_available?
                            f.input :img_credit, as: :kubik_wysiwyg, input_html: { value: image.object.additional_info['img_credit'] }
                          else
                            f.input :img_credit, input_html: { value: image.object.additional_info['img_credit'] }
                          end
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
