# frozen_string_literal: true

module Kubik
  # Builds admin media gallery URLs for image/file picker modals (Formtastic inputs).
  module MediaPickerModalUrl
    private

    def image_picker_modal_src
      params = { modal: true }
      media_type = picker_media_type
      params[:media_type] = media_type if media_type.present?

      Rails.application.routes.url_helpers.admin_kubik_media_uploads_path(params)
    end

    def picker_media_type
      options[:media_type].presence || "image"
    end
  end
end
