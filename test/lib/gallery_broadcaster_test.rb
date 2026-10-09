# frozen_string_literal: true

require "test_helper"

class GalleryBroadcasterTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  test "broadcasts turbo stream to kubik_media_gallery" do
    upload = kubik_media_uploads(:image_example)

    assert_broadcast_on("kubik_media_gallery") do
      KubikMediaLibrary::GalleryBroadcaster.broadcast!(upload)
    end
  end
end
