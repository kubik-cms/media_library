# frozen_string_literal: true

class ResizeImagesJob < ApplicationJob
  after_perform do |job|
    image = job.arguments.first
    number_of_derivatives = image.image_attacher.derivatives.length
    image.finalize! if Kubik::MediaUpload.derivatives_number == number_of_derivatives
  end

  def perform(record, thumb, options)
    if record.image_data.present?
      attacher = record.image_attacher
      svg = record.image.mime_type.include?('svg')
      if svg
        attacher.add_derivative(thumb, record.image(:optimised).download)
      else
        resize_methods = {
          fill: :resize_to_fill,
          limit: :resize_to_limit,
          fit: :resize_to_fit,
          pad: :resize_and_pad
        }
        resize_method = resize_methods[options[:type]]
        resize_options = options[:options]
        record.image(:optimised).open do |io|
          pipeline = ImageProcessing::Vips.source(io)
          attacher.add_derivative(thumb, pipeline.send(resize_method, *resize_options).call)
        end
        attacher.atomic_persist
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
end
