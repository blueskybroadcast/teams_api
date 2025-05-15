# frozen_string_literal: true

module TeamsApi
  module Api
    module V1
      class BaseController < ActionController::API
        before_action :authenticate_request

        private

        def authenticate_request
          if defined?(::OauthJwt)
            authenticate_with_oauth_jwt
          else
            token = request.headers['Authorization']&.split(' ')&.last
            @current_user = ::User.find_by_auth_token(token)

            unless @current_user
              render json: { error: 'Unauthorized' }, status: :unauthorized
            end
          end
        end

        def authenticate_with_oauth_jwt
          token = request.headers['Authorization']&.split(' ')&.last

          if token.blank?
            render json: { error: 'Unauthorized', message: 'Missing authentication token' },
                   status: :unauthorized
            return
          end

          begin
            @current_token_payload = ::OauthJwt::Service.verify_token(token, issuer: 'path_lms')
            @current_account = ::Account.find(@current_token_payload['account_id'])
            @current_user = ::User.find_by(account_id: @current_account.id)

            unless @current_user
              render json: { error: 'Unauthorized', message: 'User not found' },
                     status: :unauthorized
            end
          rescue ::OauthJwt::TokenVerificationError => e
            render json: { error: 'Unauthorized', message: e.message }, status: :unauthorized
          rescue ActiveRecord::RecordNotFound
            render json: { error: 'Unauthorized', message: 'Invalid account' },
                   status: :unauthorized
          end
        end

        def verify_scope(required_scope)
          return true unless defined?(::OauthJwt)

          token_scopes = @current_token_payload&.dig('scopes') || []
          token_scopes.include?(required_scope)
        end

        def verify_scope!(required_scope)
          unless verify_scope(required_scope)
            render json: {
              error: 'Forbidden',
              message: "Insufficient permissions. Required scope: #{required_scope}"
            }, status: :forbidden
            return false
          end
          true
        end

        def require_scope(required_scope)
          unless verify_scope(required_scope)
            render json: {
              error: 'Forbidden',
              message: "Insufficient permissions. Required scope: #{required_scope}"
            }, status: :forbidden
            return false
          end
          true
        end
      end
    end
  end
end
