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
end
