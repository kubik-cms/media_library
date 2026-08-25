require 'image_processing/mini_magick'

module Kubik
  class MediaUpload < ::ApplicationRecord
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

    after_create :process!

    if defined?(acts_as_taggable_on)
      acts_as_taggable_on :media_tags
    end


    include Kubik::MediaImageUploader[:image] rescue NameError
    include Kubik::MediaFileUploader[:file] rescue NameError

    validates_presence_of :image, if: Proc.new { |u| u.file.blank? }
    validates_presence_of :file, if: Proc.new { |u| u.image.blank? }

    has_many :kubik_uploads, class_name: 'Kubik::Upload', foreign_key: 'kubik_media_upload_id', dependent: :destroy, inverse_of: :uploadable

    scope(:pdf_files, lambda do
      where('file_data @> ?', {
        metadata: { mime_type: 'application/pdf' }
      }.to_json)
    end)

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
      drop_area_text = DROP_AREA_TEXT
      {
        allowed_mime_types: allowed_mime_types.join(', '),
        file_mime_types: Kubik::MediaFileUploader::ALLOWED_TYPES.to_json,
        image_mime_types: Kubik::MediaImageUploader::ALLOWED_TYPES.to_json,
        drop_area_text: drop_area_text
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

        image_attacher.delete_derivative(key)
      end
      image_attacher.atomic_persist
      update_column(:aasm_state, 'uploaded')
      process!
    end

    def generate_thumbnails
      resize!
    end

    def admin_file_thumbnail
      path = file_url(:thumb_400x400)
      path = file_url(:optimised) if path.blank?
      path = file_url(:original) if path.blank?

      path
    end

    def admin_image_thumbnail
      path = image_url(:thumb_400x400)
      path = image_url(:optimised) if path.blank? || path.include?(Kubik::MediaImageUploader::FALLBACK_PATH)
      path = image_url if path.blank? || path.include?(Kubik::MediaImageUploader::FALLBACK_PATH)

      path
    end

    def return_object
      {
        display_name: image_data.deep_symbolize_keys.dig(:metadata, :filename),
        id: id,
        thumb: image_url(:thumb_200x200),
        status_info: { active: true },
        url: Rails.application.routes.url_helpers.admin_kubik_media_uploads_path(self, kubik_search: true, format: :json)
      }
    end

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
