# frozen_string_literal: true

module TeamsApi
  class Engine < ::Rails::Engine
    isolate_namespace TeamsApi

    initializer "teams_api.load_dependencies" do
      begin
        require 'oauth_jwt'
        require 'active_model_serializers'
        Rails.logger.info "Dependencies loaded successfully for TeamsApi"
      rescue LoadError => e
        Rails.logger.warn "Failed to load dependency: #{e.message}"
      end
    end

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end

    config.to_prepare do
      begin
        require 'active_model_serializers' unless defined?(ActiveModel::Serializer)
        require 'oauth_jwt' unless defined?(OauthJwt)
      rescue LoadError => e
        Rails.logger.warn "Failed to load dependency: #{e.message}"
      end
    end
  end
end
