# frozen_string_literal: true

require 'image_optim'
require 'image_processing/vips'

module Kubik
  # MediaFileUploader
  class MediaFileUploader < Shrine
    ALLOWED_TYPES = %w[application/pdf].freeze
    MAX_SIZE      = 10 * 1024 * 1024 # 10 MB

    plugin :derivatives
    plugin :activerecord
    plugin :store_dimensions
    plugin :validation

    Attacher.validate do
      validate_max_size MAX_SIZE, message: 'is too large (max is 10 MB)'
      validate_mime_type_inclusion ALLOWED_TYPES
    end

    def generate_location(io, **context)
      path = super[%r{^(.*[\\/])}]
      derivative = context[:derivative]
      is_original = derivative.nil? || derivative == :original

      if is_original
        return path + context[:metadata]["filename"].tr(" ", "_")
      end

      orig_filename = context[:record].file_data["metadata"]["filename"]
      base_name = File.basename(orig_filename, ".*")
      extension = File.extname(context[:metadata]["filename"]).delete_prefix(".")
      filename = "#{derivative}-#{base_name}.#{extension}"
      path + filename
    end
  end
end

