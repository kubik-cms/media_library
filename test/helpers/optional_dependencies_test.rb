require 'test_helper'

class OptionalDependenciesTest < ActiveSupport::TestCase
  test "wysiwyg_available? returns false when kubik_wysiwyg is not loaded" do
    # This test assumes kubik_wysiwyg is not in the test environment
    assert_equal false, KubikMediaLibrary.wysiwyg_available?
  end

  test "gem loads successfully without kubik_wysiwyg" do
    # This test ensures the gem loads without errors even when kubik_wysiwyg is not available
    assert_nothing_raised do
      require 'kubik_media_library'
    end
  end

  test "KUBIK_WYSIWYG_AVAILABLE constant is defined" do
    assert defined?(KUBIK_WYSIWYG_AVAILABLE)
  end

  test "KUBIK_INTERFACE_ELEMENTS_AVAILABLE constant is defined" do
    assert defined?(KUBIK_INTERFACE_ELEMENTS_AVAILABLE)
  end

  test "normalize_gallery_media_tags accepts comma-separated media_tags string" do
    tags = KubikMediaLibrary.normalize_gallery_media_tags({ media_tags: "hero, brochure" })

    assert_equal %w[hero brochure], tags
  end
end
