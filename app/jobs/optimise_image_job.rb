class OptimiseImageJob < ApplicationJob
  after_perform do |job|
    record = job.arguments.first
    record.reload
    record.create_thumbnails! if record.may_create_thumbnails?
  end

  def perform(record)
    record.reload
    return unless record.image_data.present?
    return if record.aasm_state != "optimised"

    KubikMediaLibrary.processor.optimize(record, record.image_attacher)
    record.save
  end
end
