# frozen_string_literal: true

require "test_helper"

class KubikFormatSupportTest < ActiveSupport::TestCase
  teardown do
    Kubik::Processing::FormatSupport.reset!
  end

  test "available when dotted suffix is present and encoding probe passes" do
    Vips.stub(:get_suffixes, [".webp", ".jpg"]) do
      Kubik::Processing::FormatSupport.stub(:encoding_probe_passes?, true) do
        assert Kubik::Processing::FormatSupport.available?(:webp)
      end
    end
  end

  test "unavailable when suffix is missing" do
    Vips.stub(:get_suffixes, [".jpg"]) do
      assert_not Kubik::Processing::FormatSupport.available?(:webp)
    end
  end

  test "mark_unavailable excludes format from subsequent checks" do
    Vips.stub(:get_suffixes, [".webp"]) do
      Kubik::Processing::FormatSupport.stub(:encoding_probe_passes?, true) do
        assert Kubik::Processing::FormatSupport.available?(:webp)
      end

      Kubik::Processing::FormatSupport.mark_unavailable!(:webp, "encode failed")
      assert_not Kubik::Processing::FormatSupport.available?(:webp)
    end
  end
end

class KubikVipsAdapterModernFormatTest < ActiveSupport::TestCase
  setup do
    Kubik::Processing::FormatSupport.reset!
    KubikMediaLibrary.configure do |config|
      config.modern_formats = [:webp]
    end
  end

  teardown do
    KubikMediaLibrary.instance_variable_set(:@config, KubikMediaLibrary::Configuration.new)
    KubikMediaLibrary.instance_variable_set(:@processor, nil)
    Kubik::Processing::FormatSupport.reset!
  end

  test "creates webp derivative alongside base derivative" do
    skip "test_cover.jpg fixture missing" unless File.exist?("test/fixtures/files/test_cover.jpg")
    skip "WebP encoding unavailable" unless Kubik::Processing::FormatSupport.available?(:webp)

    upload = Kubik::MediaUpload.create!(image: File.open("test/fixtures/files/test_cover.jpg", "rb"))
    OptimiseImageJob.perform_now(upload)
    upload.reload

    adapter = Kubik::Processing::VipsAdapter.new
    spec = { type: :limit, options: [600, nil] }
    adapter.create_derivative(upload, upload.image_attacher, :content_600, spec)
    upload.reload

    assert upload.image_attacher.derivatives.key?(:content_600)
    assert upload.image_attacher.derivatives.key?(:content_600_webp)
  end
end
