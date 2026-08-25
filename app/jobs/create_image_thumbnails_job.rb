class CreateImageThumbnailsJob < ApplicationJob
  after_perform do |job|
    record = job.arguments.first
    record.resize!
    Kubik::DerivativesCompletion.finalize_if_complete!(record)
  end

  def perform(record)
    return unless record.image_data.present?

    attacher = record.image_attacher
    Kubik::MediaUpload::REQUIRED_THUMB_DERIVATIVES.each do |thumb_name, options|
      resolved_options = Kubik::MediaUpload.available_derivatives.dig(:thumb, thumb_name) || options
      KubikMediaLibrary.processor.create_derivative(record, attacher, thumb_name, resolved_options)
    end
    record.save
  end
end
