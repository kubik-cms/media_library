module KubikInterfaceElementsLayoutOverride
  def build_active_admin_head
    within super do
      render "admin/kubik/interface_elements/additional_headers"
    end
  end

  def build(*args)
    ## Disable turbo drive globally
    set_attribute :'data-turbo', "false"
    super
  end
end

ActiveAdmin::Views::Pages::Base.prepend KubikInterfaceElementsLayoutOverride
