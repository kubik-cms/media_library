# frozen_string_literal: true

module KubikMediaLibrary
  class Configuration
    attr_accessor :image_derivatives,
                  :additional_derivatives,
                  :override_derivatives,
                  :excluded_derivatives,
                  :modern_formats,
                  :modern_format_quality,
                  :processor,
                  :active_admin_menu,
                  :active_admin_per_page,
                  :auto_register_active_admin

    attr_reader :active_admin_customize_block

    def initialize
      @additional_derivatives = {}
      @override_derivatives = {}
      @excluded_derivatives = []
      @modern_formats = %i[webp avif]
      @modern_format_quality = { webp: 80, avif: 65 }
      @active_admin_menu = { label: 'Media', priority: 2 }
      @active_admin_per_page = 25
      @auto_register_active_admin = true
    end

    def active_admin_customize(&block)
      @active_admin_customize_block = block
    end
  end
end
