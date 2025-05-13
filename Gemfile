source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

gem 'active_model_serializers', '~> 0.10.0'
gem 'activerecord-nulldb-adapter'
gem 'activesupport'
gem 'concurrent-ruby', '1.3.4'
gem 'jwt_sessions'
gem 'pg'
gem 'redis'

group :development, :test do
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'pry-byebug'
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'shoulda-matchers'

  gem 'rubocop', require: false
  gem 'rubocop-junit-formatter', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec'
end

# To use a debugger
# gem 'byebug', group: [:development, :test]
