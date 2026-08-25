## [Unreleased]

## [0.2.0] - 2026-08-25

### Added

- `KubikMediaLibrary.configure` for derivative customization, modern formats, and ActiveAdmin settings
- Social/meta-tag derivative group (`social_og`, `social_twitter_large`, `social_linkedin`, etc.)
- Pluggable processing adapter (`Kubik::Processing::VipsAdapter` by default)
- WebP and AVIF parallel derivatives with graceful fallback when encoding libraries are unavailable
- `regenerate_derivatives!` on `Kubik::MediaUpload` plus ActiveAdmin regenerate actions (index + edit)
- Configurable ActiveAdmin menu via `active_admin_menu`, `active_admin_customize`, and optional full host registration
- Install generator now adds `config/initializers/kubik_media_library.rb`
- Robust derivative completion check using expected derivative name sets

### Changed

- ActiveAdmin resource registration moved to `KubikMediaLibrary::ActiveAdmin::Registration` (loaded via `to_prepare`)
- Image processing jobs delegate to `KubikMediaLibrary.processor`
- Thumbnail generation reads from derivative config (required thumbs always preserved)
- Missing derivative URLs fall back to `:optimised`, then original; modern format URLs fall back to base derivative first
- Bumped minimum dependency versions in gemspec

### Removed

- Passive `lib/active_admin/media_uploads.rb` load-path registration (replaced by registration module)

## [0.1.36]

- Added optional dependency support for `kubik_wysiwyg`
- Added `KubikMediaLibrary.wysiwyg_available?` method to check if WYSIWYG functionality is available
- Updated media upload forms to conditionally use WYSIWYG editors when available

## [0.1.4] - 2021-06-04

- Changes to syntax for instantiation methods in model

## [0.1.0] - 2021-06-04

- Initial release
