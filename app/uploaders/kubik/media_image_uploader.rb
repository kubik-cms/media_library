# frozen_string_literal: true

require 'image_optim'
require 'image_processing/vips'

module Kubik
  # MediaImageUploader
  class MediaImageUploader < Shrine
    FALLBACK_PATH ='/image_fallback/fallback.svg'
    ALLOWED_TYPES = %w[image/gif image/jpg image/jpeg image/png image/svg+xml image/svg].freeze
    MAX_SIZE      = 10 * 1024 * 1024 # 10 MB
    MODERN_FORMAT_SUFFIXES = %w[webp avif].freeze

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
      if derivative
        sym = derivative.to_sym
        base_fallback =
          if (match = sym.to_s.match(/\A(.+)_(webp|avif)\z/))
            derivatives[match[1].to_sym]&.url
          end

        derivatives[sym]&.url ||
          base_fallback ||
          derivatives[:optimised]&.url ||
          file&.url
      end
    end

    def generate_location(io, **context)
      path = super[%r{^(.*[\\\/])}]
      version = context[:derivative]
      is_original = version.nil? || version == :original

      if is_original
        return path + context[:metadata]['filename'].tr(' ', '_')
      end

      orig_filename = context[:record].image_data['metadata']['filename']
      base_name = File.basename(orig_filename, '.*')

      if (match = version.to_s.match(/\A(.+)_(webp|avif)\z/))
        filename = "#{version}-#{base_name}.#{match[2]}"
        return path + filename
      end

      filename = "#{version}-#{orig_filename.tr(' ', '_')}"
      path + filename
    end
  end
end
