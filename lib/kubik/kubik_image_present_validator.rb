# frozen_string_literal: true

# Image presence validator
class KubikImagePresentValidator < ActiveModel::Validator
  def validate(record)
    return unless record.send(options[:method_symbol]).blank? ||
                  record.send(options[:method_symbol]).marked_for_destruction? ||
                  record.send(options[:method_symbol]).kubik_media_upload_id.nil? ||
                  record.send(options[:method_symbol]).kubik_media_upload_id.zero? ||
                  record.send(options[:method_symbol]).kubik_media_upload_id.blank?

    record.errors.add(options[:method_symbol], "can't be blank")
  end
end
