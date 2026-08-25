# frozen_string_literal: true

module KubikMediaLibrary
  module ViewHelper
    MODERN_FORMAT_MIME_TYPES = {
      webp: 'image/webp',
      avif: 'image/avif'
    }.freeze

    def kubik_image_url(upload, derivative_key, prefer_modern: true, format: :auto)
      upload = resolve_kubik_upload(upload)
      return nil unless upload&.image_data.present?

      key = derivative_key.to_sym
      fmt = format.to_sym

      if fmt != :auto
        modern_key = upload.modern_derivative_key(key, fmt)
        return upload.image_url(modern_key) if upload.modern_derivative_available?(key, fmt)
      elsif prefer_modern
        modern_formats_for(:auto).each do |modern_fmt|
          modern_key = upload.modern_derivative_key(key, modern_fmt)
          return upload.image_url(modern_key) if upload.modern_derivative_available?(key, modern_fmt)
        end
      end

      upload.image_url(key)
    end

    def kubik_srcset(upload, widths_by_key, prefer_modern: true, format: :auto)
      upload = resolve_kubik_upload(upload)
      return nil unless upload&.image_data.present?

      widths_by_key.filter_map do |derivative_key, width|
        url = kubik_image_url(upload, derivative_key, prefer_modern: prefer_modern, format: format)
        "#{url} #{width}w" if url.present?
      end.join(', ')
    end

    def kubik_picture_tag(upload, default_key:, srcset: nil, sizes: nil, prefer_modern: true, format: :auto, **img_options)
      upload = resolve_kubik_upload(upload)
      return ''.html_safe unless upload&.image_data.present?

      base_key = default_key.to_sym
      fallback_url = kubik_image_url(upload, base_key, prefer_modern: false)
      return ''.html_safe if fallback_url.blank?

      img_options = img_options.dup
      img_options[:src] = fallback_url
      img_options[:sizes] = sizes if sizes.present? && srcset.present?

      content_tag(:picture) do
        sources = modern_picture_sources(
          upload,
          base_key,
          srcset: srcset,
          sizes: sizes,
          prefer_modern: prefer_modern,
          format: format
        )

        safe_join(sources + [tag.img(**img_options)])
      end
    end

    private

    def resolve_kubik_upload(upload)
      return nil if upload.nil?
      return upload if upload.is_a?(Kubik::MediaUpload)
      return upload.kubik_media_upload if defined?(Kubik::Upload) && upload.is_a?(Kubik::Upload)

      upload
    end

    def modern_formats_for(format)
      return Kubik::MediaUpload.preferred_modern_formats if format.to_sym == :auto

      fmt = format.to_sym
      Kubik::MediaUpload.preferred_modern_formats.include?(fmt) ? [fmt] : []
    end

    def modern_picture_sources(upload, base_key, srcset:, sizes:, prefer_modern:, format:)
      return [] unless prefer_modern

      Kubik::MediaUpload.preferred_modern_formats.filter_map do |fmt|
        next unless KubikMediaLibrary.processor.available_modern_formats.include?(fmt)

        mime = MODERN_FORMAT_MIME_TYPES[fmt]
        next unless mime

        source_srcset =
          if srcset.present?
            kubik_srcset(upload, srcset, prefer_modern: false, format: fmt)
          elsif upload.modern_derivative_available?(base_key, fmt)
            upload.image_url(upload.modern_derivative_key(base_key, fmt))
          end

        next if source_srcset.blank?

        tag.source(type: mime, srcset: source_srcset, sizes: sizes)
      end
    end
  end
end
