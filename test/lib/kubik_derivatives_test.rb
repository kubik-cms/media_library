# frozen_string_literal: true

require "test_helper"

class KubikDerivativesResolverTest < ActiveSupport::TestCase
  setup do
    @defaults = {
      thumb: {
        thumb_200x200: { type: :pad, options: [200, 200, { extend: :white }] }
      },
      square: {
        square_800: { type: :fill, options: [800, 800, { crop: :attention }] }
      }
    }
    @required = @defaults[:thumb]
  end

  test "merges additional derivatives" do
    result = Kubik::DerivativesResolver.resolve(
      defaults: @defaults,
      image_derivatives: nil,
      override_derivatives: {},
      additional_derivatives: { custom: { hero: { type: :limit, options: [1200, nil] } } },
      legacy_additional_derivatives: {},
      excluded_derivatives: [],
      required_thumbs: @required
    )

    assert result.key?(:custom)
    assert result[:thumb].key?(:thumb_200x200)
  end

  test "excludes derivatives except thumbs" do
    result = Kubik::DerivativesResolver.resolve(
      defaults: @defaults,
      image_derivatives: nil,
      override_derivatives: {},
      additional_derivatives: {},
      legacy_additional_derivatives: {},
      excluded_derivatives: [:square_800, :thumb_200x200],
      required_thumbs: @required
    )

    assert_not result[:square].key?(:square_800)
    assert result[:thumb].key?(:thumb_200x200)
  end

  test "applies overrides" do
    result = Kubik::DerivativesResolver.resolve(
      defaults: @defaults,
      image_derivatives: nil,
      override_derivatives: {
        square: { square_800: { type: :fill, options: [900, 900, { crop: :attention }] } }
      },
      additional_derivatives: {},
      legacy_additional_derivatives: {},
      excluded_derivatives: [],
      required_thumbs: @required
    )

    assert_equal [900, 900, { crop: :attention }], result[:square][:square_800][:options]
  end
end

class KubikMediaUploadDerivativesTest < ActiveSupport::TestCase
  setup do
    KubikMediaLibrary.configure do |config|
      config.image_derivatives = nil
      config.additional_derivatives = {}
      config.override_derivatives = {}
      config.excluded_derivatives = []
      config.modern_formats = []
    end
  end

  teardown do
    KubikMediaLibrary.instance_variable_set(:@config, KubikMediaLibrary::Configuration.new)
    KubikMediaLibrary.instance_variable_set(:@processor, nil)
    Kubik::Processing::FormatSupport.reset!
  end

  test "includes social derivatives by default" do
    assert Kubik::MediaUpload.available_derivatives[:social].key?(:social_og)
  end

  test "expected derivative names include optimised and social" do
    names = Kubik::MediaUpload.expected_derivative_names

    assert_includes names, :optimised
    assert_includes names, :social_og
    assert_includes names, :thumb_200x200
  end

  test "expected derivative names include modern formats when enabled" do
    KubikMediaLibrary.configure do |config|
      config.modern_formats = [:webp]
    end

    Kubik::Processing::FormatSupport.stub(:available?, true) do
      names = Kubik::MediaUpload.expected_derivative_names
      assert_includes names, :social_og_webp
    end
  end
end
