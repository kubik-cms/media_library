# frozen_string_literal: true

require "image_processing/vips"
require "open3"
require "tempfile"
require "fileutils"

module Kubik
  # Renders the first page of a PDF into JPEG Shrine derivatives on the file attacher.
  class PdfPreviewGenerator
    PREVIEW_DPI = 150
    OPTIMISED_MAX = 1800
    THUMBNAIL_SIZES = {
      thumb_200x200: 200,
      thumb_400x400: 400,
      thumb_800x800: 800
    }.freeze

    def self.call(attacher)
      new(attacher).call
    end

    def initialize(attacher)
      @attacher = attacher
    end

    def call
      preview_jpeg = nil

      @attacher.file.open do |io|
        preview_jpeg = render_first_page(io)
        add_derivatives(preview_jpeg.path)
      end

      @attacher.atomic_persist
    ensure
      preview_jpeg&.close!
    end

    private

    def render_first_page(io)
      render_with_pdftoppm(io.path) || render_with_vips(io.path)
    end

    def render_with_pdftoppm(pdf_path)
      return unless pdftoppm_available?

      dir = Dir.mktmpdir("kubik-pdf-preview")
      output_prefix = File.join(dir, "page")
      _stdout, _stderr, status = Open3.capture3(
        "pdftoppm", "-f", "1", "-l", "1", "-jpeg", "-r", PREVIEW_DPI.to_s, pdf_path, output_prefix
      )
      return unless status.success?

      jpeg_path = Dir.glob(File.join(dir, "page*.jpg")).max_by { |path| File.mtime(path) }
      return if jpeg_path.nil? || jpeg_path.empty?

      tempfile = Tempfile.new(["pdf-preview", ".jpg"])
      FileUtils.cp(jpeg_path, tempfile.path)
      tempfile
    ensure
      FileUtils.remove_entry(dir) if defined?(dir) && dir && Dir.exist?(dir)
    end

    def render_with_vips(pdf_path)
      page = Vips::Image.pdfload(pdf_path, page: 0, dpi: PREVIEW_DPI)
      tempfile = Tempfile.new(["pdf-preview", ".jpg"])
      page.jpegsave(tempfile.path, Q: 85)
      tempfile
    rescue Vips::Error
      nil
    end

    def pdftoppm_available?
      system("which", "pdftoppm", out: File::NULL, err: File::NULL)
    end

    def add_derivatives(preview_path)
      optimised = ImageProcessing::Vips
                  .source(preview_path)
                  .resize_to_limit(OPTIMISED_MAX, OPTIMISED_MAX)
                  .call
      @attacher.add_derivative(:optimised, optimised)

      THUMBNAIL_SIZES.each do |name, size|
        thumb = ImageProcessing::Vips
                .source(preview_path)
                .resize_and_pad(size, size, extend: :white, background: [255, 255, 255])
                .call
        @attacher.add_derivative(name, thumb)
      end
    end
  end
end
