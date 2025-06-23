# Example: How to use the optional kubik_wysiwyg dependency
#
# This example shows how to conditionally use WYSIWYG functionality
# when the kubik_wysiwyg gem is available.

# In your ActiveAdmin resource or form:
class MediaUploadForm
  def build_form(form)
    form.inputs "Media Details" do
      # Regular input (always available)
      form.input :title

      # Conditional WYSIWYG input
      if KubikMediaLibrary.wysiwyg_available?
        form.input :description, as: :kubik_wysiwyg
        form.input :caption, as: :kubik_wysiwyg
      else
        form.input :description, as: :text
        form.input :caption, as: :text
      end
    end
  end
end

# In your model or helper:
class MediaHelper
  def self.render_description(media_upload)
    if KubikMediaLibrary.wysiwyg_available?
      # Use WYSIWYG-specific rendering
      KubikWysiwyg.render(media_upload.description)
    else
      # Fallback to simple text rendering
      simple_format(media_upload.description)
    end
  end
end

# In your view:
# <% if KubikMediaLibrary.wysiwyg_available? %>
#   <%= render 'wysiwyg_editor', field: :description %>
# <% else %>
#   <%= text_area_tag :description %>
# <% end %>
