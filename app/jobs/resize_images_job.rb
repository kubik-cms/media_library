# frozen_string_literal: true

class ResizeImagesJob < ApplicationJob
  after_perform do |job|
    Kubik::DerivativesCompletion.finalize_if_complete!(job.arguments.first)
  end

  def perform(record, thumb, options)
    return unless record.image_data.present?

    KubikMediaLibrary.processor.create_derivative(record, record.image_attacher, thumb, options)
  end
end
