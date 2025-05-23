source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in teams_api.gemspec.
gemspec

group :development do
  gem 'sqlite3'
end

group :development, :test do
  gem 'rubocop', require: false
  gem 'rubocop-junit-formatter', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec'
  gem 'rspec_junit_formatter', '~> 0.6'
end

# To use a debugger
# gem 'byebug', group: [:development, :test]
