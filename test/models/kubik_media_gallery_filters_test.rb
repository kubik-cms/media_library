# frozen_string_literal: true

require "test_helper"

class KubikMediaGalleryFiltersTest < ActiveSupport::TestCase
  setup do
    @image = Kubik::MediaUpload.create!(image: File.open(file_fixture("test_cover.jpg"), "rb"))
    @pdf = Kubik::MediaUpload.create!(file: File.open(file_fixture("test_document.pdf"), "rb"))
  end

  test "filter_gallery limits to images" do
    ids = Kubik::MediaUpload.filter_gallery(Kubik::MediaUpload.all, { media_type: "image" }).pluck(:id)

    assert_includes ids, @image.id
    refute_includes ids, @pdf.id
  end

  test "filter_gallery limits to files" do
    ids = Kubik::MediaUpload.filter_gallery(Kubik::MediaUpload.all, { media_type: "file" }).pluck(:id)

    assert_includes ids, @pdf.id
    refute_includes ids, @image.id
  end

  test "filter_gallery limits by single media tag" do
    skip "tagging tables not installed" unless Kubik::MediaUpload.tagging_available?

    @image.media_tag_list = "brochure, hero"
    @image.save!
    @pdf.media_tag_list = "brochure"
    @pdf.save!

    ids = Kubik::MediaUpload.filter_gallery(Kubik::MediaUpload.all, { media_tags: ["hero"] }).pluck(:id)
    assert_includes ids, @image.id
    refute_includes ids, @pdf.id
  end

  test "filter_gallery matches any tag with OR logic" do
    skip "tagging tables not installed" unless Kubik::MediaUpload.tagging_available?

    @image.media_tag_list = "hero"
    @image.save!
    @pdf.media_tag_list = "brochure"
    @pdf.save!

    ids = Kubik::MediaUpload.filter_gallery(
      Kubik::MediaUpload.all,
      { media_tags: %w[hero brochure], media_tags_match: "or" }
    ).pluck(:id)

    assert_includes ids, @image.id
    assert_includes ids, @pdf.id
  end

  test "filter_gallery matches all tags with AND logic" do
    skip "tagging tables not installed" unless Kubik::MediaUpload.tagging_available?

    @image.media_tag_list = "brochure, hero"
    @image.save!
    @pdf.media_tag_list = "brochure"
    @pdf.save!

    ids = Kubik::MediaUpload.filter_gallery(
      Kubik::MediaUpload.all,
      { media_tags: %w[brochure hero], media_tags_match: "and" }
    ).pluck(:id)

    assert_includes ids, @image.id
    refute_includes ids, @pdf.id
  end

  test "filter_gallery limits by upload date range" do
    @image.update_column(:created_at, Time.zone.parse("2024-06-15 12:00:00"))

    in_range = Kubik::MediaUpload.filter_gallery(
      Kubik::MediaUpload.all,
      { uploaded_from: "2024-06-01", uploaded_to: "2024-06-30" }
    )

    assert_includes in_range.pluck(:id), @image.id
    refute_includes in_range.pluck(:id), @pdf.id
  end

  test "normalize_gallery_filter_dates swaps reversed range" do
    from, to = Kubik::MediaUpload.normalize_gallery_filter_dates("2024-06-30", "2024-06-01")

    assert_equal "2024-06-01", from
    assert_equal "2024-06-30", to
  end

  test "filter_gallery searches by filename" do
    ids = Kubik::MediaUpload.filter_gallery(Kubik::MediaUpload.all, { q: "test_cover" }).pluck(:id)

    assert_includes ids, @image.id
    refute_includes ids, @pdf.id
  end

  test "filter_gallery searches by image title" do
    @image.update!(additional_info: @image.additional_info.merge("img_title" => "Harbour sunset"))

    ids = Kubik::MediaUpload.filter_gallery(Kubik::MediaUpload.all, { q: "Harbour sunset" }).pluck(:id)

    assert_includes ids, @image.id
    refute_includes ids, @pdf.id
  end

  test "gallery_order name prefers title over filename" do
    @image.update!(additional_info: @image.additional_info.merge("img_title" => "Alpha asset"))
    @pdf.update!(additional_info: @pdf.additional_info.merge("document_title" => "Beta brochure"))
    scope = Kubik::MediaUpload.where(id: [@image.id, @pdf.id])

    name_ids = Kubik::MediaUpload.gallery_order(scope, "name").pluck(:id)

    assert_equal [@image.id, @pdf.id], name_ids
  end

  test "filter_gallery limits to untagged uploads" do
    skip "tagging tables not installed" unless Kubik::MediaUpload.tagging_available?

    @image.media_tag_list = "tagged"
    @image.save!

    ids = Kubik::MediaUpload.filter_gallery(Kubik::MediaUpload.all, { media_untagged: "1" }).pluck(:id)

    refute_includes ids, @image.id
    assert_includes ids, @pdf.id
  end

  test "gallery_order sorts oldest and newest" do
    @image.update_column(:created_at, Time.zone.parse("2024-01-01 12:00:00"))
    @pdf.update_column(:created_at, Time.zone.parse("2024-02-01 12:00:00"))
    scope = Kubik::MediaUpload.where(id: [@image.id, @pdf.id])

    oldest_ids = Kubik::MediaUpload.gallery_order(scope, "oldest").pluck(:id)
    newest_ids = Kubik::MediaUpload.gallery_order(scope, "newest").pluck(:id)

    assert_equal [@image.id, @pdf.id], oldest_ids
    assert_equal [@pdf.id, @image.id], newest_ids
  end
end
