source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in teams_api.gemspec.
gemspec

group :development do
  gem 'sqlite3'
end

group :development, :test do
  # Use secure version (>= 1.16.5) to avoid CVE-2024-34459
  gem 'nokogiri', '~> 1.16.7'
  gem 'rspec_junit_formatter', '~> 0.6'
  gem 'rubocop', require: false
  gem 'rubocop-junit-formatter', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec'
end

# To use a debugger
# gem 'byebug', group: [:development, :test]
