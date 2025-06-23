# KubikMediaLibrary

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kubik_media_library', github: 'kubik-inc/media_library'
```

And then execute:

```bash
bundle install
rails g kubik:media_library:install
```

## Optional Dependencies

This gem supports optional dependencies that can be added to your application for enhanced functionality. These are not declared in the gemspec to avoid forcing them on all users.

### kubik_wysiwyg

The `kubik_wysiwyg` gem is an optional dependency that provides WYSIWYG editor integration. To use it, add it to your Gemfile:

```ruby
# Add this to your application's Gemfile
gem 'kubik_wysiwyg'
```

The gem will automatically detect if `kubik_wysiwyg` is available and enable WYSIWYG features accordingly. You can check if the WYSIWYG functionality is available in your code:

```ruby
if KubikMediaLibrary.wysiwyg_available?
  # WYSIWYG features are available
else
  # WYSIWYG features are not available
end
```

## Usage

You can quickly add the ability to add media library attachments and attach them to instances of models in your application

```ruby
class Blog < ApplicationRecord
  include include Kubik::Uploadable
  has_one_kubik_upload(self, :header_image)
  has_many_kubik_uploads(self, :gallery)
  ...
end
```

By default uplodable doesn't validate presence of attachments.

```ruby
  has_one_kubik_upload(self, :header_image, { validate_presence: true })
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/kubik_previewable. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/primate-inc/kubik_previewable/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the KubikPreviewable project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/primate-inc/kubik_previewable/blob/master/CODE_OF_CONDUCT.md).
