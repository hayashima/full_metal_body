# frozen_string_literal: true

module FullMetalBody
  class InstallGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    source_root File.expand_path('templates', __dir__)

    def self.next_migration_number(_path)
      Time.now.utc.strftime('%Y%m%d%H%M%S')
    end

    def create_migration_file
      template = 'create_blocked_actions'
      migration_dir = File.expand_path('db/migrate')
      migration_template(
        "#{template}.rb.erb",
        "db/migrate/#{template}.rb",
        migration_version: migration_version,
      )
    end

    def create_whitelist_dir
      empty_directory('config/full_metal_body')
    end

    private

    def migration_version
      "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]" if over_rails5?
    end

    def over_rails5?
      Rails::VERSION::MAJOR >= 5
    end
  end
end