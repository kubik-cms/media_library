# frozen_string_literal: true
require "kubik_media_library/version"
require "kubik_media_library/configuration"
require "aasm"
require "activeadmin"
require "acts_as_list"
require "image_optim"
require "shrine"
require "kubik/uploadable"
require "kubik/media_library"
require "kubik/derivatives_resolver"
require "kubik/derivatives_completion"
require "kubik/processing/format_support"
require "kubik/processing/adapter"
require "kubik/processing/vips_adapter"
require "kubik_media_library/view_helper"
require "kubik_media_library/public_url"

# Optional dependencies
begin
  require "kubik_wysiwyg"
  KUBIK_WYSIWYG_AVAILABLE = true
rescue LoadError
  KUBIK_WYSIWYG_AVAILABLE = false
  # kubik_wysiwyg is not available, but that's okay
end

begin
  require "acts-as-taggable-on"
  ACTS_AS_TAGGABLE_ON_AVAILABLE = true
rescue LoadError
  ACTS_AS_TAGGABLE_ON_AVAILABLE = false
end

begin
  require "kubik_interface_elements"
  KUBIK_INTERFACE_ELEMENTS_AVAILABLE = true
rescue LoadError
  KUBIK_INTERFACE_ELEMENTS_AVAILABLE = false
end

module KubikMediaLibrary
  GALLERY_STREAM_NAME = "kubik_media_gallery"

  require "kubik_media_library/gallery_broadcaster"

  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
      @processor = config.processor if config.processor
    end

    def processor
      @processor ||= Kubik::Processing::VipsAdapter.new
    end

    def wysiwyg_available?
      KUBIK_WYSIWYG_AVAILABLE
    end

    def tagging_available?
      ACTS_AS_TAGGABLE_ON_AVAILABLE &&
        ActiveRecord::Base.connection.table_exists?("tags") &&
        ActiveRecord::Base.connection.table_exists?("taggings")
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
      false
    end

    def interface_elements_available?
      KUBIK_INTERFACE_ELEMENTS_AVAILABLE
    end

    # Normalizes tag params from gallery filter forms (array, legacy media_tag, blanks).
    def normalize_gallery_media_tags(params)
      source = params.to_h.with_indifferent_access
      tags = Array(source[:media_tags]).map { |tag| tag.to_s.strip }.reject(&:blank?)
      if tags.empty? && source[:media_tags].is_a?(String) && source[:media_tags].present?
        tags = source[:media_tags].split(",").map(&:strip).reject(&:blank?)
      end
      if tags.empty? && source[:media_tag].present?
        tags = [source[:media_tag].to_s.strip]
      end
      tags.uniq
    end
  end

  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace KubikMediaLibrary

      config.assets.precompile += %w( kubik_media_gallery.js )

      initializer :kubik_media_library_view_helper do
        require "kubik_media_library/gallery_filters_fallback_helper"

        ActiveSupport.on_load(:action_view) do
          include KubikMediaLibrary::ViewHelper
          include KubikMediaLibrary::GalleryFiltersFallbackHelper unless KubikMediaLibrary.interface_elements_available?
        end
      end

      initializer :kubik_media_library_active_admin do |app|
        lib_root = File.dirname(__FILE__)

        ActiveSupport.on_load(:active_admin) do
          ::ActiveAdmin.application.load_paths += Dir[File.join(lib_root, 'arbre')]
          ::ActiveAdmin.application.load_paths += Dir[File.join(lib_root, 'active_admin', 'views')]
        end

        app.config.to_prepare do
          require "kubik_media_library/gallery_broadcaster"
          load File.join(lib_root, "kubik_media_library", "gallery_filters.rb")

          require "kubik_media_library/active_admin/registration"

          Kubik.register_models!
          next unless KubikMediaLibrary.config.auto_register_active_admin

          begin
            ::ActiveAdmin.unregister Kubik::MediaUpload
          rescue NameError, NoMethodError
            # Resource not registered yet
          end

          KubikMediaLibrary::ActiveAdmin::Registration.register_media_upload!
        end
      end
    end
  end
end
