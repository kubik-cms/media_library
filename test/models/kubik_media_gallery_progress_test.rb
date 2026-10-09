# frozen_string_literal: true

require "test_helper"

class KubikMediaGalleryProgressTest < ActiveSupport::TestCase
  setup do
    @upload = kubik_media_uploads(:image_example)
  end

  test "gallery progress reflects upload, crops, and alt text" do
    @upload.update_columns(aasm_state: "uploaded", additional_info: { "alt_text" => "" })

    assert @upload.gallery_progress_uploaded?
    refute @upload.gallery_progress_crops_processed?
    assert @upload.gallery_progress_crops_processing?
    refute @upload.gallery_progress_alt_text_present?

    @upload.update_columns(aasm_state: "ready")
    @upload.reload

    assert @upload.gallery_progress_crops_processed?
    refute @upload.gallery_progress_crops_processing?

    @upload.update!(additional_info: @upload.additional_info.merge("alt_text" => "Harbour at dusk"))
    assert @upload.gallery_progress_alt_text_present?
  end

  test "gallery broadcast slice includes alt text and AI status" do
    slice = @upload.gallery_broadcast_additional_info_slice(
      {
        "alt_text" => "Sunset",
        "kubik_ai" => { "status" => "processing", "status_message" => "Working…" }
      }
    )

    assert_equal "Sunset", slice[:alt_text]
    assert_equal "processing", slice[:kubik_ai]["status"]
  end
end
