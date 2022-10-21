require 'rails/generators/active_record'

module Kubik
  module Generators
    module MediaLibrary
      class InstallGenerator < ActiveRecord::Generators::Base
        source_root File.expand_path("../templates", __FILE__)
        desc "Running Slickr generators"
        argument :name, type: :string, default: "application"

        def db_migrations
          migration_template "migrations/create_kubik_media_uploads.rb", "db/migrate/create_kubik_media_uploads.rb"
          migration_template "migrations/create_kubik_uploads.rb", "db/migrate/create_kubik_uploads.rb"
          puts "Database migrations added"
        end

        def copy_initializers
          copy_file 'config/initializers/shrine.rb', 'config/initializers/shrine.rb'
        end
      end
    end
  end
end
