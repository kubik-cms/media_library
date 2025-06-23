# frozen_string_literal: true
require "kubik_media_library/version"
require "aasm"
require "activeadmin"
require "acts_as_list"
require "image_optim"
require "shrine"
require "kubik/uploadable"

# Optional dependencies
begin
  require "kubik_wysiwyg"
  KUBIK_WYSIWYG_AVAILABLE = true
rescue LoadError
  KUBIK_WYSIWYG_AVAILABLE = false
  # kubik_wysiwyg is not available, but that's okay
end

module KubikMediaLibrary
  # Check if kubik_wysiwyg is available
  def self.wysiwyg_available?
    KUBIK_WYSIWYG_AVAILABLE
  end

  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace KubikMediaLibrary

      config.assets.precompile += %w( kubik_media_gallery.js )
      initializer :kubik_media_library do
        ActiveAdmin.application.load_paths += Dir[File.dirname(__FILE__) + '/arbre']
        ActiveAdmin.application.load_paths += Dir[File.dirname(__FILE__) + '/active_admin']
        ActiveAdmin.application.load_paths += Dir[File.dirname(__FILE__) + '/active_admin/views']
      end
    end
  end
end
