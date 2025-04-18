# frozen_string_literal: true

module TeamsApi
  class Engine < ::Rails::Engine
    isolate_namespace TeamsApi

    initializer "teams_api.assets.precompile" do |app|
      app.config.assets.precompile += %w( teams_api/application.js teams_api/application.css )
    end

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end

    config.to_prepare do
      Dir.glob(Engine.root.join("app", "**", "*.rb")).each do |file|
        require_dependency file
      end
    end
  end
end
