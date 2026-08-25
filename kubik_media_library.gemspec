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

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "aasm", ">= 4.12"
  spec.add_dependency "activeadmin", ">= 2.13"
  spec.add_dependency "acts_as_list"
  spec.add_dependency "image_processing", "~> 1.12"
  spec.add_dependency "image_optim"
  spec.add_dependency "image_optim_pack"
  spec.add_dependency "shrine", ">= 3.0"
  spec.add_dependency "fastimage"
  spec.add_dependency "rails", ">= 6.0"
  spec.add_dependency "ruby-vips", ">= 2.0"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "warning"

  # Optional dependencies (not declared in gemspec - see README.md for details)
  # - kubik_wysiwyg: Provides WYSIWYG editor integration
end
