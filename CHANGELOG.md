## [Unreleased]

## [0.2.7] - 2026-08-25

### Added

- `Kubik::MediaUpload` helpers: `image_derivative?`, `modern_derivative_key`, `modern_derivative_available?`, `preferred_image_derivative`
- `KubikMediaLibrary::ViewHelper` with `kubik_image_url`, `kubik_srcset`, and `kubik_picture_tag`
- Helpers use `KubikMediaLibrary.processor.available_modern_formats` (AVIF preferred over WebP in `<picture>`)
- README section documenting the `<picture>` serving pattern

### Fixed

- `Attacher.default_url` uses expression values instead of `return`/`next` inside the block

## [0.2.6] - 2026-08-25

### Fixed

- `FormatSupport` now recognises dotted Vips suffixes (`.webp`, `.avif`) and runs an encoding smoke test before enabling a format
- `VipsAdapter` generates WebP/AVIF variants before persisting the base derivative (temp file was deleted too early)
- Runtime encode failures call `FormatSupport.mark_unavailable!` so `derivatives_complete?` does not wait for formats that cannot be created

### Added

- Admin "Available versions" tab lists WebP/AVIF variants alongside base derivatives
- Tests for suffix detection and WebP derivative generation
- README and generator docs for runtime dependencies (`libvips`, `libwebp`, `libavif`, `libheif`)
- `libwebp-dev` added to gem Dockerfile

## [0.2.5] - 2026-08-25

### Fixed

- Use Shrine `remove_derivative(key, delete: true)` instead of non-existent `delete_derivative` in `regenerate_derivatives!`

## [0.2.4] - 2026-08-25

### Fixed

- Remove `ActiveSupport.on_load(:active_record)` from `lib/kubik/media_library.rb` so models load only in engine `to_prepare` (after uploaders are available)
- Remove `rescue NameError` from Shrine uploader includes on `Kubik::MediaUpload` so missing uploaders fail loudly at boot

### Added

- Boot test asserting `Kubik::MediaUpload` has Shrine image/file attachments after application load

## [0.2.3] - 2026-08-25

### Fixed

- Remove `config.batch_actions = false` from ActiveAdmin registration (not supported on all ActiveAdmin versions; custom gallery index does not use batch actions anyway)
- Defer ActiveAdmin load path setup to `ActiveSupport.on_load(:active_admin)` so extensions are available before registration

## [0.2.2] - 2026-08-25

### Fixed

- Use `::ActiveAdmin` in engine initializer (avoids lookup under `KubikMediaLibrary::ActiveAdmin` with `isolate_namespace`)
- Defer loading `Kubik::Upload` and `Kubik::MediaUpload` until `to_prepare` / registration (not during `Bundler.require`)
- Inherit models from `ActiveRecord::Base` instead of `ApplicationRecord` (host `ApplicationRecord` is not available at gem load time)

## [0.2.1] - 2026-08-25

### Fixed

- Correct `require_relative` path in ActiveAdmin registration (`../../kubik/media_library`)
- Use `::ApplicationRecord` for `Kubik::MediaUpload` and `Kubik::Upload` so host apps do not need `Kubik::ApplicationRecord`

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
