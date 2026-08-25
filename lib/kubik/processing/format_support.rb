# frozen_string_literal: true

require 'vips'
require 'image_processing/vips'

module Kubik
  module Processing
    module FormatSupport
      module_function

      @availability_cache = {}
      @unavailable_formats = []
      @warned_formats = []

      def available?(format)
        format = format.to_s
        return false if @unavailable_formats.include?(format)
        return @availability_cache[format] if @availability_cache.key?(format)

        @availability_cache[format] = detect(format)
      end

      def available_formats(formats)
        Array(formats).select { |format| available?(format) }
      end

      def mark_unavailable!(format, message = nil)
        format = format.to_s
        @unavailable_formats << format unless @unavailable_formats.include?(format)
        @availability_cache[format] = false
        warn_once(format, message || "encoding probe failed")
      end

      def reset!
        @availability_cache = {}
        @unavailable_formats = []
        @warned_formats = []
      end

      def detect(format)
        suffixes = Vips.get_suffixes
        suffix_present = suffixes.include?(format) || suffixes.include?(".#{format}")

        unless suffix_present
          warn_once(format, "Vips suffix #{format.inspect} is not available")
          return false
        end

        encoding_probe_passes?(format)
      rescue StandardError => e
        warn_once(format, e.message)
        false
      end

      def encoding_probe_passes?(format)
        image = Vips::Image.black(1, 1)

        case format.to_s
        when 'webp'
          image.webpsave_buffer(Q: 80)
        when 'avif'
          image.heifsave_buffer(Q: 65)
        else
          return false
        end

        true
      rescue StandardError => e
        warn_once(format, e.message)
        false
      end

      def warn_once(format, message)
        return if @warned_formats.include?(format)

        @warned_formats << format
        Rails.logger.warn(
          "[KubikMediaLibrary] #{format.upcase} encoding unavailable (#{message}); skipping #{format.upcase} derivatives"
        )
      rescue StandardError
        nil
      end
    end
  end
end
