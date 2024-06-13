# frozen_string_literal: true

require 'image_optim'
require 'image_processing/vips'

module Kubik
  # MediaImageUploader
  class MediaImageUploader < Shrine
    FALLBACK_PATH ='/image_fallback/fallback.svg'
    ALLOWED_TYPES = %w[image/gif image/jpg image/jpeg image/png image/svg+xml image/svg].freeze
    MAX_SIZE      = 10 * 1024 * 1024 # 10 MB

    plugin :store_dimensions
    plugin :derivatives
    plugin :activerecord
    plugin :pretty_location
    plugin :validation

    Attacher.validate do
      validate_max_size MAX_SIZE, message: 'is too large (max is 10 MB)'
      validate_mime_type_inclusion ALLOWED_TYPES
    end

    Attacher.default_url do |derivative: nil, **|
       FALLBACK_PATH if derivative
    end

    def generate_location(io, **context)
      path = super[%r{^(.*[\\\/])}]
      version = context[:derivative]
      is_original = version.nil? || version == :original

      # Save original image
      if is_original
        return path + context[:metadata]['filename'].tr(' ', '_')
      end

      # Handle derivatives
      orig_filename = context[:record].image_data['metadata']['filename']
      filename = "#{version}-#{orig_filename.tr(' ', '_')}"
      path + filename
    end
  end
end
