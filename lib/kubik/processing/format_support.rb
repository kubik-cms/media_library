# frozen_string_literal: true

require 'vips'

module Kubik
  module Processing
    module FormatSupport
      module_function

      @availability_cache = {}
      @warned_formats = []

      def available?(format)
        format = format.to_s
        return @availability_cache[format] if @availability_cache.key?(format)

        @availability_cache[format] = detect(format)
      end

      def available_formats(formats)
        Array(formats).select { |format| available?(format) }
      end

      def reset!
        @availability_cache = {}
        @warned_formats = []
      end

      def detect(format)
        suffixes = Vips.get_suffixes
        return true if suffixes.include?(format)

        warn_once(format, "Vips suffix #{format.inspect} is not available")
        false
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
