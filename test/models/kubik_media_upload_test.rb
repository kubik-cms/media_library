# frozen_string_literal: true

require "test_helper"

class KubikMediaUploadTest < ActiveSupport::TestCase
  # Test for model attachments
  class MixinsDefitions < ActiveSupport::TestCase
    setup do
      @default_example = Example.new
    end

    test "instance defines the single upload method" do
      assert @default_example.respond_to? :example_upload
    end

    test "instance returns nil when single upload empty" do
      assert @default_example.example_upload.nil?
    end

    test "instance defines the multiple upload method" do
      assert @default_example.respond_to? :example_gallery
    end

    test "instance defines the multiple upload method as association" do
      assert @default_example.example_gallery.is_a?(ActiveRecord::Associations::CollectionProxy)
    end

    test "instance returns nil when multiple upload empty" do
      assert @default_example.example_gallery.empty?
    end
  end

  class UploadClasses < ActiveSupport::TestCase
    setup do
      @image_example = Kubik::MediaUpload.create(image: File.open("test/fixtures/files/test_cover.jpg", "rb"))
      @document_example = Kubik::MediaUpload.create(file: File.open("test/fixtures/files/test_document.pdf", "rb"))
    end

    test "correctly extracts mime_type from image" do
      assert_equal "image/jpeg", @image_example.image.mime_type
    end

    test "correctly extracts mime_type from document" do
      assert_equal "application/pdf", @document_example.file.mime_type
    end

    test "leaves document data empty" do
      assert @image_example.file.nil?
    end

    test "return_object includes file url for PDF uploads" do
      object = @document_example.return_object
      assert_equal @document_example.gallery_display_name, object[:display_name]
      assert_equal @document_example.file.metadata["filename"], object[:display_name]
      assert object[:file_url].present?
    end

    test "gallery_display_name prefers title over filename" do
      @image_example.update!(additional_info: { "alt_text" => "", "img_title" => "Summer hero" })

      assert_equal "Summer hero", @image_example.gallery_display_name
      assert_equal "Summer hero", @image_example.return_object[:display_name]
    end

    test "gallery_display_name falls back to filename" do
      assert_equal @image_example.upload_filename, @image_example.gallery_display_name
    end

    test "public_media_url returns file url for documents and image url for images" do
      assert_equal @document_example.file_url, @document_example.public_media_url
      assert_equal @image_example.image_url, @image_example.public_media_url
    end

    test "Correctly extracts other metadata" do
      assert_instance_of Integer, @image_example.image.size
      assert_instance_of Integer, @image_example.image.width
      assert_instance_of Integer, @image_example.image.height
    end
  end
end
