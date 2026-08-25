# frozen_string_literal: true

require 'image_optim'
require 'image_processing/vips'

module Kubik
  module Processing
    class VipsAdapter < Adapter
      RESIZE_METHODS = {
        fill: :resize_to_fill,
        limit: :resize_to_limit,
        fit: :resize_to_fit,
        pad: :resize_and_pad
      }.freeze

      def optimize(record, attacher)
        return unless record.image_data.present?

        image_optim = ImageOptim.new(
          pngout: false,
          jpegoptim: { allow_lossy: true, max_quality: 85 }
        )

        tempfile = attacher.file.download

        File.open(tempfile.path) do |io|
          optimized_path = image_optim.optimize_image(io)

          if optimized_path.present?
            File.open(optimized_path.to_s) do |file|
              attacher.add_derivative(:optimised, file)
            end
          else
            attacher.add_derivative(:optimised, io)
          end
          attacher.atomic_persist
        end
      end

      def create_derivative(record, attacher, name, spec)
        return [] unless record.image_data.present?

        created = []
        svg = record.image.mime_type.include?('svg')

        if svg
          attacher.add_derivative(name, record.image(:optimised).download)
          created << name
        else
          resize_method = RESIZE_METHODS[spec[:type]]
          resize_options = spec[:options]

          record.image(:optimised).open do |io|
            pipeline = ImageProcessing::Vips.source(io)
            resized = pipeline.public_send(resize_method, *resize_options).call

            create_modern_variants(attacher, resized, name).each do |variant|
              created << variant
            end

            attacher.add_derivative(name, resized)
            created << name
          end
          attacher.atomic_persist
        end

        created
      end

      private

      def create_modern_variants(attacher, resized, name)
        created = []

        available_modern_formats.each do |format|
          variant_name = :"#{name}_#{format}"
          quality = KubikMediaLibrary.config.modern_format_quality.fetch(format, 80)

          variant_file = ImageProcessing::Vips
                         .source(resized)
                         .convert(format.to_s)
                         .saver(quality: quality)
                         .call

          attacher.add_derivative(variant_name, variant_file)
          created << variant_name
        rescue StandardError => e
          Kubik::Processing::FormatSupport.mark_unavailable!(format, e.message)
        end

        created
      end
    end
  end
end
