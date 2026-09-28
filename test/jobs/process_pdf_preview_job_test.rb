# frozen_string_literal: true

require "test_helper"
require "active_job/test_helper"

class ProcessPdfPreviewJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @pdf_path = file_fixture("test_document.pdf")
  end

  test "enqueues when a PDF media upload is created" do
    assert_enqueued_with(job: ProcessPdfPreviewJob) do
      Kubik::MediaUpload.create!(file: File.open(@pdf_path, "rb"))
    end
  end

  test "generates preview derivatives and marks upload ready" do
    upload = Kubik::MediaUpload.create!(file: File.open(@pdf_path, "rb"))

    perform_enqueued_jobs

    upload.reload
    assert upload.ready?, "expected aasm_state ready, got #{upload.aasm_state}"
    assert upload.file_preview_derivative?(:thumb_400x400)
    assert upload.file_preview_derivative?(:optimised)
    assert upload.file_preview_available?
    assert_includes upload.admin_file_thumbnail, "/uploads/"
  end
end
