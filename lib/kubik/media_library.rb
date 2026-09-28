# frozen_string_literal: true

module Kubik
  module_function

  def register_models!
    media_upload_path = File.expand_path("media_upload.rb", __dir__)

    # Always require (idempotent). Skipping when the constant exists leaves a stub
    # class without gallery helpers if something referenced Kubik::MediaUpload first.
    require "kubik/media_upload"

    # `require` does not re-run after gem files change on disk; reload when gallery
    # helpers are missing (common in development after pulling or editing the gem).
    if Kubik.const_defined?(:MediaUpload, false) &&
       !Kubik::MediaUpload.respond_to?(:filter_gallery)
      load media_upload_path
    end

    require "kubik/upload"
  end
end
