module Kubik
  class SingleMediaInput
    include Formtastic::Inputs::Base

    def wrapper_html_options
      upload_data = kubik_upload.present? ? kubik_upload.as_json(only: [:id, :kubik_media_upload_id, :position], methods: [:thumb]) : {id: nil, thumb: nil, kubik_media_upload_id: nil}
      super.merge(
        'data-controller': 'image_selector',
        'data-image_selector-id-value': kubik_upload.try(:id),
        'data-image_selector-related-media-value': upload_data.to_json,
      )
    end

    def to_html
      input_wrapping do
        empty_template_html <<
        image_template_html <<
        new_fields_template_html <<
        existing_fields_template_html <<
        existing_fields_delete_template_html <<
        label_html <<
        info_box_html
      end
    end

    private

    def modal_header
      "Select #{method.to_s.humanize.downcase}"
    end

    def method_prefix
      "#{method}_attributes"
    end

    def field_attribute_factory(field_name)
      attributes_prefix = options[:name].present? ? options[:name] : ActiveModel::Naming.param_key(object)
      association_name = options[:association].present? ? options[:association] : nil
      form_string_head, *form_string_tail = [association_name, attributes_prefix, method].delete_if(&:blank?)
      form_string_tail_string = form_string_tail.map{|a| "[#{a}_attributes]"}.join('')
      "#{[form_string_head, form_string_tail_string].join('')}[#{field_name}]"
    end

    def field_delete_attribute
      field_attribute_factory('_destroy')
    end

    def field_name_attribute
      field_attribute_factory('kubik_media_upload_id')
    end

    def field_id_attribute
      field_attribute_factory('id')
    end

    def new_fields_template_html
      template.content_tag(:template, 'data-image_selector-target': 'newFieldsTemplate') do
        (
          template.hidden_field_tag(
            field_name_attribute,
            "${kubik_media_upload_id}",
            'data-image_selector-target': 'mediaUploadId',
          )
        )
      end
    end

    def existing_fields_delete_template_html
      template.content_tag(:template, 'data-image_selector-target': 'existingFieldsDeleteTemplate') do
        (
          template.hidden_field_tag(
            field_delete_attribute,
            1,
            'data-image_selector-target': 'mediaUploadDelete',
          ) +
          template.hidden_field_tag(
            field_id_attribute,
            "${id}"
          )

        )
      end
    end

    def existing_fields_template_html
      template.content_tag(:template, 'data-image_selector-target': 'existingFieldsTemplate') do
        (
          template.hidden_field_tag(
            field_name_attribute,
            "${kubik_media_upload_id}",
            'data-image_selector-target': 'mediaUploadId',
          )        )
      end
    end

    def empty_template_html
      template.content_tag(:template, 'data-image_selector-target': 'emptyTemplate') do
        template.content_tag(:div,
                             'src': Rails.application.routes.url_helpers.admin_kubik_media_uploads_path(modal: true),
                             'data-kubik-modal-header-text': modal_header,
                             'data-kubik-modal-action': 'return',
                             'data-kubik-modal-return-controller': "image_selector##{wrapper_html_options[:id]}",
                             'data-action': 'click->kubik-modal#openModal',
                             class: 'kubik-media-gallery--file_select_container kubik-media-gallery--file_select_container__small') do
          template.content_tag(:div, class: 'kubik-select-placeholder') do
            (template.content_tag(:div, class: 'material-symbols-outlined material-icon') do
              "add"
            end +
            template.content_tag(:div, class: 'kubik-media-gallery--file_select_header') do
              "#{modal_header}"
            end)
          end
        end
      end
    end

    def image_template_html
      template.content_tag(:template, 'data-image_selector-target': 'imageTemplate') do
        template.content_tag(:div, class: 'kubik-image-placeholder') do
          template.content_tag(:div, class: 'kubik-media-gallery--media_item_container') do
            (
              swap_action +
              template.content_tag(:div, class: 'kubik-media-gallery--media_item_container--image') do
                template.content_tag(:img, src: '${thumb}') do; end
              end +
              remove_action
            )
          end
        end
      end
    end

    def swap_action
      template.content_tag(:div,
                           'src': Rails.application.routes.url_helpers.admin_kubik_media_uploads_path(modal: true),
                           'data-kubik-modal-header-text': modal_header,
                           'data-kubik-modal-action': 'return',
                           'data-kubik-modal-return-controller': "image_selector##{wrapper_html_options[:id]}",
                           'data-action': 'click->kubik-modal#openModal',
                           class: 'kubik-media-gallery--media_item_action kubik-media-gallery--media_item_action__brand') do
        (
          template.content_tag(:span, class: 'material-symbols-outlined kubik-media-gallery--media_item_container--icon') do
            'autorenew'
          end +
          template.content_tag(:span, 'Swap image', class: 'kubik-media-gallery--media_item_action--text')
        )
      end
    end

    def remove_action
      template.content_tag(:div,
                           'data-action': 'click->image_selector#removeImage',
                           class: 'kubik-media-gallery--media_item_action kubik-media-gallery--media_item_action__alert') do
        (
          template.content_tag(:span, class: 'material-symbols-outlined kubik-media-gallery--media_item_container--icon') do
            'cancel'
          end +
          template.content_tag(:span, 'Remove image', class: 'kubik-media-gallery--media_item_action--text')
        )
      end
    end

    def trigger_html
      template.content_tag :div do
        kubik_upload.present? ? "Change image" : "Select image"
      end
    end

    def info_box_html
      template.content_tag(:div, 'class': 'kubik-image-placeholder','data-image_selector-target': 'imageContainer' ) do
        info_box_content
      end
    end

    def info_box_content
      if kubik_upload.nil?
        "No #{method.to_s.humanize} selected yet"
      else
      end
    end

    private

    def kubik_upload
      object.send(method)
    end

  end
end
