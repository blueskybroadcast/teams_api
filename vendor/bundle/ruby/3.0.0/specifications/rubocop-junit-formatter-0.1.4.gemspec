# -*- encoding: utf-8 -*-
# stub: rubocop-junit-formatter 0.1.4 ruby lib

Gem::Specification.new do |s|
  s.name = "rubocop-junit-formatter".freeze
  s.version = "0.1.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mikko Kokkonen".freeze]
  s.date = "2018-01-13"
  s.description = "Allows neat integration with Atlassian Bamboo by listing all offences as failed JUnit testcase".freeze
  s.email = ["mikko@mikian.com".freeze]
  s.homepage = "https://github.com/mikian/rubocop-junit-formatter".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.2.33".freeze
  s.summary = "Outputs RuboCop Offences as JUnit report".freeze

  s.installed_by_version = "3.2.33" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, ["~> 1.7"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.7"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
  end
end
