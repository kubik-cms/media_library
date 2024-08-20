require_relative '../kubik/media_library'
ActiveAdmin.register Kubik::MediaUpload do
  MEDIA_PER_PAGE ||= 25
  menu priority: 2, label: 'Media'
  actions :all, except: %i[new show]

  config.filters = false
  config.per_page = MEDIA_PER_PAGE
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
      params.permit(:authenticity_token, :commit, kubik_media_upload: [:image, :file, :media_tag_list, additional_info: {}])
    end

    def index
      @page_title = 'Media gallery'
      @collection = scoped_collection
      @collection = @collection.order(created_at: :desc).page(params[:page]).per(MEDIA_PER_PAGE)
      modal = params[:modal].present? ? true : false
      turbo_action = modal ? false : 'advance'
      render 'index', locals: { modal: modal, turbo_action: turbo_action }, layout: 'active_admin'
    end

    def create
      #turbo_enabled = Mime::Type.lookup_by_extension(:turbo_stream).present?
      params[:kubik_media_upload][:file] = params[:kubik_media_upload].delete(:image) if Kubik::MediaFileUploader::ALLOWED_TYPES.include?(params[:kubik_media_upload][:image].content_type)
      create! do |success, failure|
        @collection = scoped_collection
        @collection = @collection.order(created_at: :desc).page(params[:page]).per(MEDIA_PER_PAGE)
        @modal = params[:kubik_media_upload][:modal].present? ? true : false
        success.html { redirect_to admin_kubik_media_uploads_path }
        success.json
        success.turbo_stream
      end
    end
  end

  form do |image|
    if image.object.new_record?
      image.input :image, as: :file
    else
      if image.object.image_data.present?
        tabs do
          tab 'Details' do
            inputs "Image details - #{image.object.image_attacher.file.metadata['filename']}" do
              columns do
                column do
                  text_node image_tag image.object.image_url, class: 'media_image'
                end
                column do
                  image.fields_for :additional_info do |f|
                    f.input :img_title, input_html: { value: image.object.additional_info['img_title'] }
                  end
                  image.fields_for :additional_info do |f|
                    f.input :alt_text, input_html: { value: image.object.additional_info['alt_text'] }
                  end
                  image.fields_for :additional_info do |f|
                    f.input :img_credit, input_html: { value: image.object.additional_info['img_credit'] }
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
    end
    actions
  end
end
