# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in kubik_previewable.gemspec
gemspec

gem "rake", "~> 13.0"
gem "minitest", "~> 5.0"
gem "rubocop", "~> 1.7"

gem 'kubik_styles_base', github: 'primate-inc/kubik_styles_base', branch: 'main'
gem 'active_admin_kubik', git: 'https://github.com/primate-inc/active_admin_kubik_theme.git', branch: 'master'
gem 'kubik_interface_elements', git: 'https://github.com/kubik-cms/kubik_interface_elements.git', branch: 'master'

group :development do
  gem "devise"
  gem "pry"
  gem "rails"
end

gem "minitest-rails"
gem "minitest-rails-capybara"
gem "puma"
gem "sassc-rails"
gem "selenium-webdriver"
