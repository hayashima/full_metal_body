# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
require "rails/test_help"
require 'minitest/stub_any_instance'
Dir["#{File.expand_path('support', __dir__)}/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("fixtures", __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + "/files"
  ActiveSupport::TestCase.fixtures :all
end

ActiveSupport::TestCase.send(:include, CustomValidatorHelper)

def upload_image
  ActionDispatch::Http::UploadedFile.new(
    filename: 'mandrill.png',
    type: 'image/png',
    tempfile: file_fixture('images/mandrill.png').read
  )
end

def upload_text(file_size:)
  ActionDispatch::Http::UploadedFile.new(
    filename: 'nyan.txt',
    type: 'text/plain',
    tempfile: StringIO.new('a' * file_size),
  )
end

class ActionDispatch::IntegrationTest
  def after_teardown
    super
    FileUtils.rm_rf(ActiveStorage::Blob.service.root)
  end
end
