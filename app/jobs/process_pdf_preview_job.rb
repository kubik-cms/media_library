# frozen_string_literal: true

require "kubik/pdf_preview_generator"

class ProcessPdfPreviewJob < ApplicationJob
  def perform(record)
    return unless record.pdf_upload?
    return if record.file_preview_available?

    Kubik::PdfPreviewGenerator.call(record.file_attacher)
    record.update!(aasm_state: :ready)
  rescue StandardError => e
    Rails.logger.error("[ProcessPdfPreviewJob] Failed for MediaUpload #{record.id}: #{e.class}: #{e.message}")
    raise
  end
end
