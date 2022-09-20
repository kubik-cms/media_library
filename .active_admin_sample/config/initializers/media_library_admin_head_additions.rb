module KubikMediaLibrararyPageLayoutOverride
  def build_active_admin_head
    within super do
      text_node javascript_pack_tag 'admin'
    end
  end

  def build(*args)
    ## Disable turbo drive globally
    set_attribute :'data-turbo', "false"
    super
  end
end

ActiveAdmin::Views::Pages::Base.prepend KubikMediaLibrararyPageLayoutOverride
