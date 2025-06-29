# frozen_string_literal: true
require_relative "lib/kubik_media_library/version"

Gem::Specification.new do |spec|
  spec.name          = "kubik_media_library"
  spec.version       = KubikMediaLibrary::VERSION
  spec.authors       = ["Bart Oleszczyk"]
  spec.email         = ["bart@primate.co.uk"]

  spec.summary       = "Media Library for Kubik CMS"
  spec.description   = "Active admin media library extension"
  spec.homepage      = "https://github.com/primate-inc/kubik_media_library"
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency "aasm"
  spec.add_dependency "activeadmin"
  spec.add_dependency "acts_as_list"
  spec.add_dependency "image_processing", "~> 1.0"
  spec.add_dependency "image_optim"
  spec.add_dependency 'image_optim_pack'
  spec.add_dependency 'shrine'
  spec.add_dependency 'fastimage'
  spec.add_development_dependency "pg"
  spec.add_dependency "rails"
  spec.add_dependency "ruby-vips"
  spec.add_development_dependency "warning"

  # Optional dependencies (not declared in gemspec - see README.md for details)
  # - kubik_wysiwyg: Provides WYSIWYG editor integration

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
