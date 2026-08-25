# frozen_string_literal: true

module Kubik
  module DerivativesResolver
    module_function

    def resolve(defaults:, image_derivatives:, override_derivatives:, additional_derivatives:,
                legacy_additional_derivatives:, excluded_derivatives:, required_thumbs:)
      base = deep_dup_hash(image_derivatives || defaults)
      merged = deep_merge(base, override_derivatives)
      merged = deep_merge(merged, additional_derivatives)
      merged = deep_merge(merged, legacy_additional_derivatives)

      excluded = Array(excluded_derivatives).map(&:to_sym).reject { |key| key.to_s.start_with?('thumb_') }
      merged.each_value do |derivatives|
        excluded.each { |key| derivatives.delete(key) }
      end

      merged[:thumb] = deep_merge(merged[:thumb] || {}, required_thumbs)
      merged
    end

    def deep_merge(original, other)
      return original if other.nil? || other.empty?

      original.merge(other) do |_key, old_val, new_val|
        if old_val.is_a?(Hash) && new_val.is_a?(Hash)
          deep_merge(old_val, new_val)
        else
          new_val
        end
      end
    end

    def deep_dup_hash(value)
      value.transform_values(&:dup).transform_keys(&:to_sym)
    end
  end
end
