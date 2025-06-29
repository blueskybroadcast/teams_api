# frozen_string_literal: true

module TeamsApi
  class Engine < (defined?(Rails) ? ::Rails::Engine : Object)
    isolate_namespace TeamsApi if defined?(Rails)

    if defined?(Rails)
      initializer "teams_api.load_dependencies" do
        begin
          require 'oauth_jwt'
          require 'active_model_serializers'
          Rails.logger.info "Dependencies loaded successfully for TeamsApi"
        rescue LoadError => e
          Rails.logger.warn "Failed to load dependency: #{e.message}"
        end
      end

      initializer "teams_api.assets.precompile" do |app|
        app.config.assets.precompile += %w( teams_api/application.js teams_api/application.css )
      end

      config.generators do |g|
        g.test_framework :rspec
        g.fixture_replacement :factory_bot
        g.factory_bot dir: 'spec/factories'
      end

      config.to_prepare do
        begin
          require 'active_model_serializers' if defined?(ActiveModel::Serializer).nil?
          require 'oauth_jwt' if defined?(OauthJwt).nil?
        rescue LoadError => e
          Rails.logger.warn "Failed to load dependency: #{e.message}"
        end

        Dir.glob(Engine.root.join("app", "**", "*.rb")).each do |file|
          require_dependency file
        end
      end
    end
  end
end
