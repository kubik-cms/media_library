# frozen_string_literal: true

require "test_helper"

class KubikMediaGalleryProcessingEnqueueTest < ActiveSupport::TestCase
  test "starts image pipeline only when stored and still uploaded" do
    upload = Kubik::MediaUpload.new(aasm_state: "uploaded")

    refute upload.should_start_gallery_image_processing?

    upload.image_data = { "id" => "mediaupload/1/image/test.jpg" }
    assert upload.should_start_gallery_image_processing?

    upload.aasm_state = "optimised"
    refute upload.should_start_gallery_image_processing?
  end

  test "does not start image pipeline for pdfs" do
    upload = Kubik::MediaUpload.new(
      aasm_state: "uploaded",
      file_data: { "id" => "mediaupload/1/file/test.pdf" }
    )

    refute upload.should_start_gallery_image_processing?
  end
end
