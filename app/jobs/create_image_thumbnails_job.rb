class CreateImageThumbnailsJob < ApplicationJob
  after_perform do |job|
    record = job.arguments.first
    record.reload
    record.resize! if record.may_resize?
    Kubik::DerivativesCompletion.finalize_if_complete!(record)
  end

  def perform(record)
    record.reload
    return unless record.image_data.present?
    return unless record.aasm_state == "thumbnails"

    attacher = record.image_attacher
    Kubik::MediaUpload::REQUIRED_THUMB_DERIVATIVES.each do |thumb_name, options|
      resolved_options = Kubik::MediaUpload.available_derivatives.dig(:thumb, thumb_name) || options
      KubikMediaLibrary.processor.create_derivative(record, attacher, thumb_name, resolved_options)
    end
    record.save
  end
end
