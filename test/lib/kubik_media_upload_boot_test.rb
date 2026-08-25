# frozen_string_literal: true

require "test_helper"

class KubikMediaUploadBootTest < ActiveSupport::TestCase
  test "MediaUpload has shrine attachments after boot" do
    upload = Kubik::MediaUpload.new

    assert upload.respond_to?(:image)
    assert upload.respond_to?(:file)
    assert upload.respond_to?(:image_attacher)
    assert upload.respond_to?(:file_attacher)
  end
end
