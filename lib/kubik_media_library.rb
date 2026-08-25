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

# Optional dependencies
begin
  require "kubik_wysiwyg"
  KUBIK_WYSIWYG_AVAILABLE = true
rescue LoadError
  KUBIK_WYSIWYG_AVAILABLE = false
  # kubik_wysiwyg is not available, but that's okay
end

module KubikMediaLibrary
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
  end

  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace KubikMediaLibrary

      config.assets.precompile += %w( kubik_media_gallery.js )

      initializer :kubik_media_library_active_admin do |app|
        lib_root = File.dirname(__FILE__)
        ::ActiveAdmin.application.load_paths += Dir[File.join(lib_root, 'arbre')]
        ::ActiveAdmin.application.load_paths += Dir[File.join(lib_root, 'active_admin', 'views')]

        app.config.to_prepare do
          require "kubik_media_library/active_admin/registration"

          Kubik.register_models! unless defined?(Kubik::MediaUpload)
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
