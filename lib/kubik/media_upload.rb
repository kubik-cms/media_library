require 'image_processing/mini_magick'

module Kubik
  class MediaUpload < ActiveRecord::Base
    self.table_name = 'kubik_media_uploads'
    DROP_AREA_TEXT = 'Maximum size 10Mb | .jpeg, .jpg, .png and .pdf files only'

    DEFAULT_IMAGE_DERIVATIVES = {
      square: {
        square_2400: {
          type: :fill, options: [2400, 2400, { crop: :attention }]
        },
        square_1800: {
          type: :fill, options: [1800, 1800, { crop: :attention }]
        },
        square_1200: {
          type: :fill, options: [1200, 1200, { crop: :attention }]
        },
        square_800: {
          type: :fill, options: [800, 800, { crop: :attention }]
        },
        square_600: {
          type: :fill, options: [600, 600, { crop: :attention }]
        },
        square_400: {
          type: :fill, options: [400, 400, { crop: :attention }]
        }
      },
      landscape: {
        landscape_2400: {
          type: :fill, options: [2400, 1600, { crop: :attention }]
        },
        landscape_1800: {
          type: :fill, options: [1800, 1200, { crop: :attention }]
        },
        landscape_1200: {
          type: :fill, options: [1200, 800, { crop: :attention }]
        },
        landscape_800: {
          type: :fill, options: [800, 534, { crop: :attention }]
        },
        landscape_600: {
          type: :fill, options: [600, 400, { crop: :attention }]
        },
        landscape_400: {
          type: :fill, options: [400, 267, { crop: :attention }]
        }
      },
      portrait: {
        portrait_2400: {
          type: :fill, options: [1600, 2400, { crop: :attention }]
        },
        portrait_1800: {
          type: :fill, options: [1200, 1800, { crop: :attention }]
        },
        portrait_1200: {
          type: :fill, options: [800, 1200, { crop: :attention }]
        },
        portrait_800: {
          type: :fill, options: [534, 800, { crop: :attention }]
        },
        portrait_600: {
          type: :fill, options: [400, 600, { crop: :attention }]
        },
        portrait_400: {
          type: :fill, options: [267, 400, { crop: :attention }]
        }
      },
      panoramic: {
        panoramic_2400: {
          type: :fill, options: [2400, 1350, { crop: :attention }]
        },
        panoramic_1800: {
          type: :fill, options: [1800, 1012, { crop: :attention }]
        },
        panoramic_1200: {
          type: :fill, options: [1200, 675, { crop: :attention }]
        },
        panoramic_800: {
          type: :fill, options: [800, 450, { crop: :attention }]
        },
        panoramic_600: {
          type: :fill, options: [600, 337, { crop: :attention }]
        },
        panoramic_400: {
          type: :fill, options: [400, 225, { crop: :attention }]
        }
      },
      content: {
        content_1200: {
          type: :limit, options: [1200, nil]
        },
        content_800: {
          type: :limit, options: [800, nil]
        },
        content_600: {
          type: :limit, options: [600, nil]
        },
        content_400: {
          type: :limit, options: [400, nil]
        }
      },
      social: {
        social_og: {
          type: :fill, options: [1200, 630, { crop: :attention }]
        },
        social_twitter_large: {
          type: :fill, options: [1200, 675, { crop: :attention }]
        },
        social_twitter_small: {
          type: :fill, options: [800, 418, { crop: :attention }]
        },
        social_linkedin: {
          type: :fill, options: [1200, 627, { crop: :attention }]
        },
        social_pinterest: {
          type: :fill, options: [1000, 1500, { crop: :attention }]
        },
        social_square: {
          type: :fill, options: [1080, 1080, { crop: :attention }]
        }
      },
      thumb: {
        thumb_800x800: {
          type: :pad, options: [800, 800, { extend: :white }]
        },
        thumb_400x400: {
          type: :pad, options: [400, 400, { extend: :white }]
        },
        thumb_200x200: {
          type: :pad, options: [200, 200, { extend: :white }]
        }
      }
    }.freeze

    REQUIRED_THUMB_DERIVATIVES = DEFAULT_IMAGE_DERIVATIVES[:thumb].freeze

    include AASM
    aasm do
      state :uploaded, initial: true
      state :processed
      state :optimised
      state :thumbnails
      state :resizing
      state :ready

      event :process, after: :optimise_image do
        transitions from: [:uploaded], to: :processed
      end

      event :optimise do
        transitions from: [:processed], to: :optimised
      end

      event :create_thumbnails, after: :process_thumbnails do
        transitions from: [:optimised], to: :thumbnails
      end

      event :resize, after: :send_for_resizing do
        transitions from: [:thumbnails], to: :resizing
      end

      event :finalize do
        transitions from: :resizing, to: :ready
      end
    end

    # Start derivative jobs only after the row (and Shrine attachment) is committed.
    # `after_create` can enqueue before promote/store finishes; PDF previews use the same pattern below.
    after_commit :start_gallery_image_processing!, if: :should_start_gallery_image_processing?
    # Shrine may promote file cache → store in the same transaction as create; plain
    # `on: :create` after_commit often never runs the enqueue. Enqueue on any commit
    # where the PDF is stored and previews are still missing.
    after_commit :enqueue_pdf_preview, if: :should_enqueue_pdf_preview_job?
    after_commit :broadcast_gallery_live_update!, on: :update, if: :gallery_broadcast_state_changed?

    if defined?(ActsAsTaggableOn)
      acts_as_taggable_on :media_tags
    end


    include Kubik::MediaImageUploader[:image]
    include Kubik::MediaFileUploader[:file]

    validates_presence_of :image, if: Proc.new { |u| u.file.blank? }
    validates_presence_of :file, if: Proc.new { |u| u.image.blank? }

    has_many :kubik_uploads, class_name: 'Kubik::Upload', foreign_key: 'kubik_media_upload_id', dependent: :destroy, inverse_of: :uploadable

    scope(:pdf_files, lambda do
      where('file_data @> ?', {
        metadata: { mime_type: 'application/pdf' }
      }.to_json)
    end)

    # Shrine JSONB attachments expose an "id" key when present.
    scope :gallery_images, -> { where("image_data ? 'id'") }
    scope :gallery_files, -> { where("file_data ? 'id'") }

    scope :uploaded_on_or_after, lambda { |date|
      day = parse_gallery_filter_date(date)
      day ? where(created_at: day.in_time_zone.beginning_of_day..) : all
    }

    scope :uploaded_on_or_before, lambda { |date|
      day = parse_gallery_filter_date(date)
      day ? where(created_at: ..day.in_time_zone.end_of_day) : all
    }

    scope :gallery_untagged, lambda {
      return all unless tagging_available?

      sql = <<~SQL.squish
        NOT EXISTS (
          SELECT 1 FROM taggings
          WHERE taggings.taggable_id = #{quoted_table_name}.id
            AND taggings.taggable_type = ?
            AND taggings.context = 'media_tags'
        )
      SQL
      where(sql, name)
    }

    def self.filter_gallery(scope = all, filter_params = {})
      params = filter_params.to_h.with_indifferent_access
      relation = scope

      case params[:media_type].to_s
      when "image"
        relation = relation.gallery_images
      when "file"
        relation = relation.gallery_files
      end

      uploaded_from, uploaded_to = normalize_gallery_filter_dates(params[:uploaded_from], params[:uploaded_to])
      relation = relation.uploaded_on_or_after(uploaded_from) if uploaded_from.present?
      relation = relation.uploaded_on_or_before(uploaded_to) if uploaded_to.present?

      relation = gallery_search(relation, params[:q]) if params[:q].present?

      if gallery_untagged_requested?(params)
        relation = relation.gallery_untagged if tagging_available?
      else
        tags = KubikMediaLibrary.normalize_gallery_media_tags(params)
        if tags.any? && tagging_available?
          match_all = params[:media_tags_match].to_s.downcase == "and"
          tag_options = { on: :media_tags }
          tag_options[:all] = true if match_all
          tag_options[:any] = true unless match_all
          relation = relation.tagged_with(tags, **tag_options)
        end
      end

      relation
    end

    def self.gallery_order(relation, sort_param)
      case sort_param.to_s
      when "oldest"
        relation.order(created_at: :asc)
      when "name"
        relation.order(
          Arel.sql(
            "LOWER(COALESCE(
              NULLIF(TRIM(additional_info->>'img_title'), ''),
              NULLIF(TRIM(additional_info->>'document_title'), ''),
              image_data->'metadata'->>'filename',
              file_data->'metadata'->>'filename',
              ''
            )) ASC"
          )
        )
      else
        relation.order(created_at: :desc)
      end
    end

    def self.gallery_search(relation, query)
      term = query.to_s.strip
      return relation if term.blank?

      pattern = "%#{sanitize_sql_like(term)}%"
      sql = <<~SQL.squish
        image_data->'metadata'->>'filename' ILIKE :pattern
        OR file_data->'metadata'->>'filename' ILIKE :pattern
        OR additional_info->>'img_title' ILIKE :pattern
        OR additional_info->>'document_title' ILIKE :pattern
      SQL
      relation.where(sql, pattern: pattern)
    end

    def self.normalize_gallery_filter_dates(uploaded_from, uploaded_to)
      from = parse_gallery_filter_date(uploaded_from)
      to = parse_gallery_filter_date(uploaded_to)
      from, to = to, from if from && to && from > to

      [
        from ? from.iso8601 : uploaded_from.presence,
        to ? to.iso8601 : uploaded_to.presence
      ]
    end

    def self.gallery_untagged_requested?(params)
      KubikMediaLibrary.gallery_untagged_requested?(params)
    end

    def self.normalize_gallery_media_tags(params)
      KubikMediaLibrary.normalize_gallery_media_tags(params)
    end

    def self.tagging_available?
      KubikMediaLibrary.tagging_available? && respond_to?(:tagged_with)
    end

    def self.gallery_media_tag_options
      return [] unless tagging_available?

      tag_counts_on(:media_tags).sort_by(&:name).map(&:name)
    end

    def self.parse_gallery_filter_date(value)
      return nil if value.blank?

      return value.to_date if value.is_a?(Date)
      return value.in_time_zone.to_date if value.respond_to?(:in_time_zone)

      Date.iso8601(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def self.available_derivatives
      Kubik::DerivativesResolver.resolve(
        defaults: DEFAULT_IMAGE_DERIVATIVES,
        image_derivatives: KubikMediaLibrary.config.image_derivatives,
        override_derivatives: KubikMediaLibrary.config.override_derivatives,
        additional_derivatives: KubikMediaLibrary.config.additional_derivatives,
        legacy_additional_derivatives: legacy_additional_derivatives,
        excluded_derivatives: KubikMediaLibrary.config.excluded_derivatives,
        required_thumbs: REQUIRED_THUMB_DERIVATIVES
      )
    end

    def self.base_derivative_names
      available_derivatives.each_with_object([]) do |(_group, derivatives), names|
        derivatives.each_key { |name| names << name }
      end
    end

    def self.expected_derivative_names
      names = [:optimised] + base_derivative_names

      KubikMediaLibrary.processor.available_modern_formats.each do |format|
        base_derivative_names.each do |base_name|
          names << :"#{base_name}_#{format}"
        end
      end

      names.uniq
    end

    def self.derivatives_number
      expected_derivative_names.size
    end

    def derivatives_complete?
      return false unless image_data.present?

      expected = self.class.expected_derivative_names.map(&:to_sym)
      present = image_attacher.derivatives.keys.map(&:to_sym)
      (expected - present).empty?
    end

    def process_thumbnails
      send(:send_to_generate_thumbnails)
    end

    def optimise_image
      optimise!
      send(:send_to_optimising)
    end

    def self.allowed_upload_info
      allowed_mime_types = Kubik::MediaFileUploader::ALLOWED_TYPES +
                           Kubik::MediaImageUploader::ALLOWED_TYPES
      max_filesize_mb = [
        Kubik::MediaFileUploader::MAX_SIZE,
        Kubik::MediaImageUploader::MAX_SIZE
      ].max / (1024 * 1024)
      {
        allowed_mime_types: allowed_mime_types.join(', '),
        file_mime_types: Kubik::MediaFileUploader::ALLOWED_TYPES.to_json,
        image_mime_types: Kubik::MediaImageUploader::ALLOWED_TYPES.to_json,
        drop_area_text: DROP_AREA_TEXT,
        max_filesize_mb: max_filesize_mb
      }
    end

    def self.additional_info
      {
        create_path: Rails.application.routes.url_helpers
                          .admin_kubik_media_uploads_path
      }
    end

    def self.additional_derivatives
      {}
    end

    def self.legacy_additional_derivatives
      additional_derivatives
    end


    def crop(x, y, w, h)
      return if (x || y || w || h).nil?
      storage = Shrine::Storage::FileSystem.new('public').directory.to_s
      full_path = storage + image_url(:original)

      ImageProcessing::MiniMagick.source(full_path)
                                 .crop("#{w}x#{h}+#{x}+#{y}")
                                 .call(destination: full_path)
      update(image: self.image[:original])
      regenerate_derivatives!
    end

    def regenerate_derivatives!
      return unless image_data.present?

      image_attacher.derivatives.each_key do |key|
        next if key == :original

        image_attacher.remove_derivative(key, delete: true)
      end
      image_attacher.atomic_persist
      update_column(:aasm_state, 'uploaded')
      process!
    end

    def generate_thumbnails
      resize!
    end

    def pdf_upload?
      file_data.present? && file&.mime_type == "application/pdf"
    end

    def public_media_url
      image_data.present? ? image_url : file_url
    end

    def file_preview_derivative?(key)
      file_data.present? && file_attacher.derivatives.key?(key.to_sym)
    end

    def file_preview_available?
      pdf_upload? && file_preview_derivative?(:thumb_400x400)
    end

    def admin_file_thumbnail
      path = file_url(:thumb_400x400) if file_preview_derivative?(:thumb_400x400)
      path = file_url(:optimised) if path.blank? && file_preview_derivative?(:optimised)
      path = file_url if path.blank?

      path
    end

    def admin_image_thumbnail
      path = image_url(:thumb_400x400)
      path = image_url(:optimised) if path.blank? || path.include?(Kubik::MediaImageUploader::FALLBACK_PATH)
      path = image_url if path.blank? || path.include?(Kubik::MediaImageUploader::FALLBACK_PATH)

      path
    end

    def upload_filename
      if image_data.present?
        image_data.dig("metadata", "filename").presence ||
          image_data.deep_symbolize_keys.dig(:metadata, :filename).presence
      elsif file_data.present?
        file&.metadata&.dig("filename").presence
      end
    end

    def gallery_title
      info = (additional_info || {}).with_indifferent_access
      if image_data.present?
        info[:img_title].to_s.strip.presence
      elsif file_data.present?
        info[:document_title].to_s.strip.presence
      end
    end

    def gallery_display_name
      gallery_title.presence || upload_filename.to_s
    end

    def return_object
      if image_data.present?
        {
          display_name: gallery_display_name,
          id: id,
          thumb: image_url(:thumb_200x200),
          file_url: nil,
          url: Rails.application.routes.url_helpers.admin_kubik_media_uploads_path(self, kubik_search: true, format: :json)
        }
      else
        {
          display_name: gallery_display_name,
          id: id,
          thumb: admin_file_thumbnail,
          file_url: file_url,
          url: Rails.application.routes.url_helpers.admin_kubik_media_uploads_path(self, kubik_search: true, format: :json)
        }
      end
    end

    def regenerate_file_preview!
      return unless pdf_upload?

      file_attacher.derivatives.each_key do |key|
        next if key == :original

        file_attacher.remove_derivative(key, delete: true)
      end
      file_attacher.atomic_persist
      update_column(:aasm_state, "uploaded")
      ProcessPdfPreviewJob.perform_later(self)
    end

    def image_derivative?(key)
      image_data.present? && image_attacher.derivatives.key?(key.to_sym)
    end

    def modern_derivative_key(base_key, format = :webp)
      :"#{base_key}_#{format}"
    end

    def modern_derivative_available?(base_key, format = :webp)
      fmt = format.to_sym
      return false unless KubikMediaLibrary.processor.available_modern_formats.include?(fmt)

      image_derivative?(modern_derivative_key(base_key, fmt))
    end

    def preferred_image_derivative(base_key, format: :auto)
      key = base_key.to_sym

      formats = format.to_sym == :auto ? self.class.preferred_modern_formats : [format.to_sym]
      formats.each do |fmt|
        modern_key = modern_derivative_key(key, fmt)
        return modern_key if image_derivative?(modern_key)
      end

      key
    end

    def self.preferred_modern_formats
      KubikMediaLibrary.processor.available_modern_formats.reverse
    end

    def should_enqueue_pdf_preview_job?
      return false unless pdf_upload? && !file_preview_available?
      return false unless file&.storage_key == :store
      return false unless previous_changes.key?("file_data")

      true
    end

    def enqueue_pdf_preview
      ProcessPdfPreviewJob.perform_later(self)
    end

    def should_start_gallery_image_processing?
      return false if pdf_upload?
      return false unless aasm_state == "uploaded"
      return false unless gallery_progress_uploaded?

      true
    end

    def start_gallery_image_processing!
      process!
    end

    def gallery_progress_uploaded?
      (image_data.present? && image_data["id"].present?) ||
        (file_data.present? && file_data["id"].present?)
    end

    def gallery_progress_crops_processed?
      aasm_state == "ready"
    end

    def gallery_progress_crops_processing?
      gallery_progress_uploaded? && !gallery_progress_crops_processed?
    end

    def gallery_progress_alt_text_present?
      return true unless image_data.present?

      additional_info.to_h.with_indifferent_access[:alt_text].to_s.strip.present?
    end

    def gallery_broadcast_state_changed?
      return true if saved_change_to_aasm_state? || saved_change_to_image_data? || saved_change_to_file_data?
      return true if saved_change_to_additional_info? && gallery_relevant_additional_info_changed?

      false
    end

    def gallery_relevant_additional_info_changed?
      previous, current = saved_change_to_additional_info
      gallery_broadcast_additional_info_slice(previous) != gallery_broadcast_additional_info_slice(current)
    end

    def gallery_broadcast_additional_info_slice(info)
      data = (info || {}).deep_dup.with_indifferent_access
      ai = data[:kubik_ai].is_a?(Hash) ? data[:kubik_ai].slice("status", "status_message") : {}
      data.slice(:alt_text, :img_title, :document_title).merge(kubik_ai: ai)
    end

    def broadcast_gallery_live_update!
      KubikMediaLibrary::GalleryBroadcaster.broadcast!(self, event: :update)
    end

    ActiveSupport.run_load_hooks(:kubik_media_upload, self)

    private

    def send_to_optimising
      OptimiseImageJob.perform_later(self) if image_data.present?
    end

    def send_to_generate_thumbnails
      CreateImageThumbnailsJob.perform_later(self)
    end

    def send_for_resizing
      Kubik::MediaUpload.available_derivatives.except(:thumb).each do |_size, thumbs|
        thumbs.each do |thumb_name, options|
          ResizeImagesJob.perform_later(self, thumb_name, options)
        end
      end
    end
  end
end
