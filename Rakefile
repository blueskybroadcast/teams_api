begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rdoc/task'
require 'rspec/core/rake_task'

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'TeamsApi'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

APP_RAKEFILE = File.expand_path("test/dummy/Rakefile", __dir__)
load 'rails/tasks/engine.rake' if File.exist?(APP_RAKEFILE)
load 'rails/tasks/statistics.rake'

require 'bundler/gem_tasks'

RSpec::Core::RakeTask.new(:spec)

task default: :spec
