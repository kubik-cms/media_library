# KubikMediaLibrary

Media library for Kubik CMS — ActiveAdmin gallery, Shrine uploads, configurable image derivatives, and optional modern format outputs.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kubik_media_library', github: 'primate-inc/kubik_media_library'
```

Then:

```bash
bundle install
rails g kubik:media_library:install
```

The install generator adds database migrations, Shrine initializer, and `config/initializers/kubik_media_library.rb`.

## Usage

```ruby
class Blog < ApplicationRecord
  include Kubik::Uploadable

  has_one_kubik_upload(self, :header_image)
  has_many_kubik_uploads(self, :gallery)
end
```

Validate presence of attachments:

```ruby
has_one_kubik_upload(self, :header_image, { validate_presence: true })
```

Reference derivatives in views:

```ruby
blog.header_image.image_url(:thumb_200x200)
blog.header_image.image_url(:social_og)
blog.header_image.image_url(:square_800_webp)
```

If a derivative does not exist yet (e.g. legacy uploads before a new size was added), Shrine falls back to `:optimised`, then the original file.

## Image derivatives

### Default groups

| Group | Purpose |
|-------|---------|
| `square` | Square crops at multiple sizes |
| `landscape` | Landscape crops |
| `portrait` | Portrait crops |
| `panoramic` | Panoramic crops |
| `content` | Width-limited images |
| `social` | Meta tag sizes (`social_og`, `social_twitter_large`, etc.) |
| `thumb` | Admin UI thumbnails (required, always generated) |

Social sizes included by default:

| Derivative | Size | Use case |
|------------|------|----------|
| `social_og` | 1200×630 | Open Graph / Facebook / LinkedIn |
| `social_twitter_large` | 1200×675 | X large card |
| `social_twitter_small` | 800×418 | X summary card |
| `social_linkedin` | 1200×627 | LinkedIn |
| `social_pinterest` | 1000×1500 | Pinterest |
| `social_square` | 1080×1080 | Square previews |

### Configuration

```ruby
# config/initializers/kubik_media_library.rb
KubikMediaLibrary.configure do |config|
  # Add derivatives
  config.additional_derivatives = {
    custom: { hero_2000: { type: :limit, options: [2000, nil] } }
  }

  # Override specific defaults
  config.override_derivatives = {
    square: { square_800: { type: :fill, options: [900, 900, { crop: :attention }] } }
  }

  # Remove derivatives (thumb_* keys are always kept)
  config.excluded_derivatives = [:panoramic_400]

  # Replace entire derivative set
  # config.image_derivatives = { ... }

  # Modern formats (WebP / AVIF) alongside JPEG/PNG
  config.modern_formats = [:webp, :avif]
  config.modern_format_quality = { webp: 80, avif: 65 }

  # Processing adapter (default: Kubik::Processing::VipsAdapter)
  # config.processor = Kubik::Processing::VipsAdapter.new
end
```

**Required thumbnails:** `thumb_200x200`, `thumb_400x400`, and `thumb_800x800` are always generated for the admin UI. They cannot be excluded.

Legacy class-reopen still works:

```ruby
class Kubik::MediaUpload
  def self.additional_derivatives
    { custom: { my_size: { type: :limit, options: [1600, nil] } } }
  end
end
```

### Regenerating derivatives

Config changes are not retroactive. Regenerate from ActiveAdmin:

- **Index** — "Regenerate all" (collection action)
- **Edit** — "Regenerate versions" (member action)

Or in code:

```ruby
upload.regenerate_derivatives!
```

### Modern formats

When enabled, each base derivative also generates `:_webp` and/or `:_avif` variants (e.g. `:square_800_webp`).

If system libraries are missing or encoding fails, the gem logs a warning and skips that format — processing continues without errors. Formats that fail at runtime are excluded from `expected_derivative_names` so processing can still complete.

Use JPEG/PNG derivatives (`:social_og`) for meta tags; use WebP/AVIF in `<picture>` elements on the front end.

### Runtime dependencies

| Package | Required for |
|---------|----------------|
| `libvips` (+ dev headers) | All image processing |
| `libwebp` | WebP output (often bundled with libvips) |
| `libavif`, `libheif` | AVIF output |

**Debian/Ubuntu example:**

```bash
apt-get install -y libvips libvips-dev libwebp-dev libavif-dev libheif-dev
```

**Docker example:**

```dockerfile
RUN apt-get install -y libvips libvips-dev libwebp-dev libavif-dev libheif-dev
```

If AVIF encoding is unavailable, set `config.modern_formats = [:webp]` until AVIF libraries are installed.

## Serving images in views

Modern format derivatives are stored as separate files (e.g. `content_800_webp`, `content_800_avif`). The intended consumption pattern is **`<picture>` with explicit sources**, not `Accept` header negotiation.

Helpers are included automatically in ActionView (`KubikMediaLibrary::ViewHelper`).

### Model helpers

```ruby
upload = blog.header_image # Kubik::Upload or Kubik::MediaUpload

upload.image_derivative?(:content_800_webp)           # => true/false
upload.modern_derivative_key(:content_800, :webp)   # => :content_800_webp
upload.modern_derivative_available?(:content_800, :webp)
upload.preferred_image_derivative(:content_800)     # best available key (AVIF → WebP → base)
```

### `kubik_image_url`

Picks the best available modern format when `prefer_modern: true` (default), using `KubikMediaLibrary.processor.available_modern_formats`:

```erb
<%= kubik_image_url(blog.header_image, :content_800) %>
<%= kubik_image_url(blog.header_image, :social_og, prefer_modern: false) %>
```

### `kubik_srcset`

Build a responsive `srcset` from derivative keys and widths:

```erb
<%= kubik_srcset(blog.header_image, { content_400: 400, content_800: 800, content_1200: 1200 }) %>
```

Pass `prefer_modern: false` or `format: :webp` to control format selection per srcset.

### `kubik_picture_tag`

Encapsulates `<picture>` + `<source>` + `<img>`:

```erb
<%= kubik_picture_tag(
      blog.header_image,
      default_key: :content_800,
      srcset: { content_400: 400, content_800: 800, content_1200: 1200 },
      sizes: '(max-width: 800px) 100vw, 800px',
      alt: blog.title,
      class: 'hero-image'
    ) %>
```

- Modern `<source>` tags are emitted for each available format (AVIF first, then WebP)
- The `<img>` fallback uses the base JPEG/PNG derivative
- Without `srcset`, sources point at a single modern URL per format for `default_key`

Use base derivatives (`:social_og`, etc.) for Open Graph / Twitter meta tags — crawlers expect JPEG/PNG.

## ActiveAdmin menu customization

### Menu placement via initializer (recommended)

```ruby
KubikMediaLibrary.configure do |config|
  config.active_admin_menu = {
    label: 'Media Library',
    priority: 5,
    parent: 'Content'
  }
  config.active_admin_per_page = 25
end
```

All standard ActiveAdmin `menu` options are supported (`:label`, `:priority`, `:parent`, `:if`, `:id`).

### Extending the resource

```ruby
KubikMediaLibrary.configure do |config|
  config.active_admin_customize do |dsl|
    dsl.action_item :my_action, only: :index do
      link_to 'My Action', '#'
    end
  end
end
```

### Full host-app control

```ruby
KubikMediaLibrary.configure do |config|
  config.auto_register_active_admin = false
end
```

```ruby
# app/admin/kubik_media_uploads.rb
KubikMediaLibrary::ActiveAdmin::Registration.register_media_upload! do
  menu parent: 'Site', priority: 3, label: 'Assets'
end
```

Views can be overridden in `app/views/admin/kubik_media_uploads/`.

## Optional Dependencies

### kubik_wysiwyg

```ruby
gem 'kubik_wysiwyg'
```

```ruby
if KubikMediaLibrary.wysiwyg_available?
  # WYSIWYG features are available
end
```

## Development

```bash
bin/setup
rake test
```

## License

MIT
