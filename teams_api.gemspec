require_relative "lib/teams_api/version"

Gem::Specification.new do |spec|
  spec.name        = "teams_api"
  spec.version     = TeamsApi::VERSION
  spec.authors     = ["Manuel Crosthwaite"]
  spec.email       = ["manuel.crosthwaite@momentivesoftware.com"]
  spec.homepage    = "https://github.com/blueskybroadcast/teams_api.git"
  spec.summary     = "Teams API engine for Path LMS."
  spec.description = "A Rails engine that provides Teams API functionality for Path LMS"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.1.7", ">= 6.1.7.10"
  spec.add_dependency "pg"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "shoulda-matchers"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "rails-controller-testing"
  spec.add_development_dependency "pry-byebug"
end
