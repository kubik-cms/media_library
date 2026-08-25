# frozen_string_literal: true

require "test_helper"

class KubikMediaUploadHelperMethodsTest < ActiveSupport::TestCase
  setup do
    Kubik::Processing::FormatSupport.reset!
    KubikMediaLibrary.configure do |config|
      config.modern_formats = %i[webp avif]
    end
  end

  teardown do
    KubikMediaLibrary.instance_variable_set(:@config, KubikMediaLibrary::Configuration.new)
    KubikMediaLibrary.instance_variable_set(:@processor, nil)
    Kubik::Processing::FormatSupport.reset!
  end

  test "modern_derivative_key builds symbol" do
    upload = Kubik::MediaUpload.new
    assert_equal :content_800_webp, upload.modern_derivative_key(:content_800, :webp)
  end

  test "preferred_modern_formats prefers avif before webp" do
    Kubik::Processing::FormatSupport.stub(:available?, true) do
      assert_equal %i[avif webp], Kubik::MediaUpload.preferred_modern_formats
    end
  end

  test "image_derivative is false without image data" do
    upload = Kubik::MediaUpload.new
    assert_not upload.image_derivative?(:content_800)
  end
end

class KubikViewHelperTest < ActionView::TestCase
  include KubikMediaLibrary::ViewHelper

  setup do
    Kubik::Processing::FormatSupport.reset!
    KubikMediaLibrary.configure { |config| config.modern_formats = [:webp] }
  end

  teardown do
    KubikMediaLibrary.instance_variable_set(:@config, KubikMediaLibrary::Configuration.new)
    KubikMediaLibrary.instance_variable_set(:@processor, nil)
    Kubik::Processing::FormatSupport.reset!
  end

  test "kubik_image_url prefers webp when derivative exists" do
    upload = build_test_upload(
      derivatives: [:content_800_webp],
      urls: { content_800_webp: '/uploads/content_800_webp.webp' }
    )

    Kubik::Processing::FormatSupport.stub(:available?, true) do
      assert_equal '/uploads/content_800_webp.webp', kubik_image_url(upload, :content_800)
    end
  end

  test "kubik_srcset builds width descriptors" do
    upload = build_test_upload(
      derivatives: [:content_400, :content_800],
      urls: {
        content_400: '/uploads/content_400.jpg',
        content_800: '/uploads/content_800.jpg'
      }
    )

    srcset = kubik_srcset(upload, { content_400: 400, content_800: 800 }, prefer_modern: false)
    assert_includes srcset, '/uploads/content_400.jpg 400w'
    assert_includes srcset, '/uploads/content_800.jpg 800w'
  end

  test "kubik_picture_tag renders picture with img fallback" do
    upload = build_test_upload(
      derivatives: [:content_800],
      urls: { content_800: '/uploads/content_800.jpg' }
    )

    html = kubik_picture_tag(upload, default_key: :content_800, alt: 'Example')
    assert_includes html, '<picture>'
    assert_includes html, 'src="/uploads/content_800.jpg"'
    assert_includes html, 'alt="Example"'
  end

  private

  def build_test_upload(derivatives:, urls:)
    upload = Kubik::MediaUpload.new
    derivative_set = derivatives.map(&:to_sym).to_set

    upload.define_singleton_method(:image_data) { { 'metadata' => {} } }
    upload.define_singleton_method(:image_derivative?) { |key| derivative_set.include?(key.to_sym) }
    upload.define_singleton_method(:image_url) { |key| urls[key.to_sym] }
    upload.define_singleton_method(:modern_derivative_key) { |base, fmt| :"#{base}_#{fmt}" }
    upload.define_singleton_method(:modern_derivative_available?) do |base, fmt|
      derivative_set.include?(:"#{base}_#{fmt}")
    end
    upload
  end
end
