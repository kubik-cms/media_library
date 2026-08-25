# frozen_string_literal: true

KubikMediaLibrary.configure do |config|
  # Menu placement in ActiveAdmin
  # config.active_admin_menu = { label: 'Media', priority: 2, parent: 'Content' }

  # Add custom image derivatives
  # config.additional_derivatives = {
  #   custom: {
  #     hero_2000: { type: :limit, options: [2000, nil] }
  #   }
  # }

  # Override specific default derivatives
  # config.override_derivatives = {
  #   square: { square_800: { type: :fill, options: [900, 900, { crop: :attention }] } }
  # }

  # Exclude derivatives (thumb_* keys are always kept)
  # config.excluded_derivatives = [:panoramic_400]

  # Modern format outputs alongside JPEG/PNG derivatives
  # config.modern_formats = [:webp, :avif]
  # config.modern_format_quality = { webp: 80, avif: 65 }
  #
  # System packages (see README): libvips, libwebp-dev, libavif-dev, libheif-dev

  # Set false to register ActiveAdmin resource in app/admin/kubik_media_uploads.rb
  # config.auto_register_active_admin = false
end
