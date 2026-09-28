# frozen_string_literal: true

require "test_helper"

class KubikRegisterModelsReloadTest < ActiveSupport::TestCase
  test "register_models! reloads media_upload when gallery helpers are missing" do
    Kubik::MediaUpload.singleton_class.send(:remove_method, :filter_gallery) if Kubik::MediaUpload.respond_to?(:filter_gallery)

    refute Kubik::MediaUpload.respond_to?(:filter_gallery)
    refute Kubik::MediaUpload.respond_to?(:gallery_untagged_requested?)

    Kubik.register_models!

    assert Kubik::MediaUpload.respond_to?(:filter_gallery)
    assert Kubik::MediaUpload.respond_to?(:gallery_untagged_requested?)
  end
end
