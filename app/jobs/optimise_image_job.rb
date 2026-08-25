class OptimiseImageJob < ApplicationJob
  after_perform do |job|
    job.arguments.first.create_thumbnails!
  end

  def perform(record)
    return unless record.image_data.present?

    KubikMediaLibrary.processor.optimize(record, record.image_attacher)
    record.save
  end
end
