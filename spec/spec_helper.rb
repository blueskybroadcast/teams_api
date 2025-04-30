# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

# Simplecov for test coverage (optional)
begin
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_filter '/spec/'
    add_filter '/config/'
  end
rescue LoadError
  # SimpleCov not available
end

require 'active_support/all'
require 'active_support/concern'
require 'rspec/rails'
require 'factory_bot'
require 'shoulda/matchers'
require 'jwt_sessions'
require 'database_cleaner'

# Configure JWT Sessions for testing
JWTSessions.encryption_key = 'test_secret_key_for_jwt_sessions'

# Set up support files
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |file| require file }

RSpec.configure do |config|
  # Basic RSpec configuration
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.order = :random

  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  # Clean the Rails cache before each test
  config.before(:each) do
    Rails.cache.clear
  end

  # Set up DatabaseCleaner
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Configure Shoulda Matchers
  Shoulda::Matchers.configure do |shoulda_config|
    shoulda_config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end

  # Add JWT helper methods
  config.include JwtTestHelper, type: :request
  config.include JwtTestHelper, type: :controller

  # Enable transactional fixtures
  config.use_transactional_fixtures = true

  # Infer spec type from file location
  config.infer_spec_type_from_file_location!
end
