# frozen_string_literal: true

module TeamsApi
  module Concerns
    module JwtAware
      extend ActiveSupport::Concern

      included do
        helper_method :current_user, :current_account if respond_to?(:helper_method)
      end

      def current_user
        @current_user ||= jwt_auth.current_user
      end

      def current_account
        @current_account ||= jwt_auth.current_account
      end

      private

      def jwt_auth
        @jwt_auth ||= TeamsApi::Auth::JwtAuthenticator.new(self)
      end

      def authenticate_with_jwt
        jwt_auth.authenticate
      end
    end
  end
end
