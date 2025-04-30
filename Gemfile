source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

gem 'activesupport'
gem 'jwt_sessions'
gem 'pg'

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
