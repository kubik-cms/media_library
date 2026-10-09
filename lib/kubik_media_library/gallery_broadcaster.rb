# frozen_string_literal: true

module KubikMediaLibrary
  module GalleryBroadcaster
    STREAM_NAME = "kubik_media_gallery"

    module_function

    def broadcast!(upload, event: :update, modal: false)
      return unless turbo_available?

      upload = upload.is_a?(Kubik::MediaUpload) ? upload.reload : Kubik::MediaUpload.find_by(id: upload)
      return unless upload
      return unless gallery_eligible?(upload)

      content = render_stream(upload, event: event, modal: modal)
      return if content.blank?

      Turbo::StreamsChannel.broadcast_stream_to(STREAM_NAME, content: content)

      if upload.aasm_state == "ready" && defined?(KubikAi::Media::MissedAnalysis)
        KubikAi::Media::MissedAnalysis.enqueue_if_eligible!(upload)
      end
    rescue StandardError => e
      ::Rails.logger.error("[KubikMediaLibrary] Gallery broadcast failed for MediaUpload #{upload&.id}: #{e.message}")
    end

    def render_stream(upload, event: :update, modal: false)
      gallery_turbo_renderer.render(
        template: "admin/kubik_media_uploads/gallery_item_sync",
        formats: [:turbo_stream],
        locals: { upload: upload, event: event.to_sym, modal: modal }
      )
    end

    def gallery_turbo_renderer
      @gallery_turbo_renderer ||= Class.new(::ApplicationController) do
        def self.controller_path
          "admin/kubik_media_uploads"
        end
      end
    end
    private_class_method :gallery_turbo_renderer

    def gallery_eligible?(upload)
      (upload.image_data.present? && upload.image_data["id"].present?) ||
        (upload.file_data.present? && upload.file_data["id"].present?)
    end

    def turbo_available?
      defined?(Turbo::StreamsChannel)
    end
  end
end
