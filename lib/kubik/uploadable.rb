# frozen_string_literal: true
require 'kubik/kubik_image_present_validator'

module Kubik
  # Uploadable module
  module Uploadable
    include ActiveSupport::Concern

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def has_one_kubik_upload(model, method_symbol, options={})
        model_param_key = ActiveModel::Naming.param_key(model)
        method_name = "#{model_param_key}_#{method_symbol.to_s}"
        has_one method_symbol,
          -> { where(uploadable_type: method_name) },
                foreign_key: 'uploadable_id',
                class_name: 'Kubik::Upload',
                dependent: :destroy
        accepts_nested_attributes_for method_symbol, allow_destroy: true
        if options[:validate_presence].present? && options[:validate_presence] == true
          validates_with KubikImagePresentValidator, method_symbol: method_symbol, required: true
        end
      end

      def has_many_kubik_uploads(model, method_symbol, options={})
        model_param_key = ActiveModel::Naming.param_key(model)
        method_name = "#{model_param_key}_#{method_symbol.to_s}"
        has_many method_symbol,
                 -> { where(uploadable_type: method_name) },
                 foreign_key: 'uploadable_id',
                 class_name: 'Kubik::Upload',
                 dependent: :destroy
        accepts_nested_attributes_for method_symbol, allow_destroy: true
        validate do |object|
          object.present_if_required(method_symbol) if options[:validate_presence].present? && options[:validate_presence] == true
        end
      end
    end

    def present_if_required(method_symbol)
      unless send(method_symbol).nil?
        return unless send(method_symbol).kubik_media_upload_id.nil? ||
                      send(method_symbol).kubik_media_upload_id.zero? ||
                      send(method_symbol).kubik_media_upload_id.blank?
      end
      errors.add(method_symbol, "can't be blank")
    end
  end
end
