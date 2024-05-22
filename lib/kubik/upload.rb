# frozen_string_literal: true

module Kubik
  # Upload class
  class Upload < ApplicationRecord
    self.table_name = 'kubik_uploads'

    after_save :delete_if_no_kubik_media_upload_id

    acts_as_list scope: %i[uploadable_id uploadable_type]

    # optional true to allow the uploadable_type to be customised without
    # the class having to exist which will allow multiple associations
    # on the polymorphic model
    belongs_to :uploadable, polymorphic: true, optional: true
    belongs_to :kubik_media_upload,
               class_name: 'Kubik::MediaUpload',
               optional: true

    default_scope { order(position: :asc) }

    delegate :admin_image_thumbnail, :image, :image_url, :file, :file_url, :additional_info, to: :kubik_media_upload

    def self.ransackable_attributes(auth_object = nil)
      ["additional_info", "created_at", "kubik_media_upload_id", "updated_at", "uploadable_id", "uploadable_type"]
    end

    private

    def thumb
      kubik_media_upload.admin_image_thumbnail
    end

    def delete_if_no_kubik_media_upload_id
      destroy if kubik_media_upload_id.nil? ||
                 kubik_media_upload_id.zero? ||
                 kubik_media_upload_id.blank?
    end
  end
end
