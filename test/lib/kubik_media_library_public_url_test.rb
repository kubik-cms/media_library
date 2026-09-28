# frozen_string_literal: true

require "test_helper"

class KubikMediaLibraryPublicUrlTest < ActiveSupport::TestCase
  test "absolute returns url unchanged when already http" do
    url = "https://cdn.example.com/uploads/foo.jpg"
    assert_equal url, KubikMediaLibrary::PublicUrl.absolute(url, host: "http://ignored.test")
  end

  test "absolute prefixes host for relative paths" do
    result = KubikMediaLibrary::PublicUrl.absolute(
      "/uploads/store/photo.jpg",
      host: "http://cln.localhost:3000"
    )
    assert_equal "http://cln.localhost:3000/uploads/store/photo.jpg", result
  end

  test "default_host uses route default url options" do
    previous = Rails.application.routes.default_url_options.dup
    Rails.application.routes.default_url_options.merge!(
      host: "example.test",
      port: 3000,
      protocol: "http"
    )

    assert_equal "http://example.test:3000", KubikMediaLibrary::PublicUrl.default_host
  ensure
    Rails.application.routes.default_url_options.replace(previous)
  end
end
