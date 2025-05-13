# frozen_string_literal: true

module TeamsApi
  module Api
    module V1
      class AuthController < ActionController::API
        include TeamsApi::Concerns::JwtAware

        # Define all required callbacks before skipping them
        before_action :authenticate_request
        before_action :authorize_with_jwt, if: -> { jwt_enabled? && jwt.present? }
        before_action :set_jwt_auth_header, if: -> { jwt_enabled? && jwt.present? }
        before_action :create_jwt_session, if: :create_jwt_session?

        # Now skip them for specific actions
        skip_before_action :authenticate_request, only: [:login, :refresh]
        skip_before_action :authorize_with_jwt, only: [:login, :refresh]
        skip_before_action :set_jwt_auth_header, only: [:login, :refresh]
        skip_before_action :create_jwt_session, only: [:login, :refresh]

        # Define authenticate_request method
        def authenticate_request
          unless current_user
            render json: { error: 'Unauthorized' }, status: :unauthorized
          end
        end

        # Define authorize_with_jwt method (which was expected from JWTSessions::RailsAuthorization)
        def authorize_with_jwt
          authorize_access_request!
        rescue JWTSessions::Errors::Error
          if create_session_from_existing_jwt?
            create_session_from_existing_jwt
          else
            render json: { error: 'Invalid token' }, status: :unauthorized
          end
        end

        # Define set_jwt_auth_header
        def set_jwt_auth_header
          request.headers[JWTSessions.access_header] ||= "Bearer #{jwt}"
        end

        # Original action methods below
        def login
          user = User.find_by(email: params[:email])

          if user&.authenticated?(params[:password])
            account = user.account
            jwt_service = TeamsApi::Services::JwtSessionService.new(account, user)

            tokens = {
              access: jwt_service.create_jwt_session,
              refresh: jwt_service.refresh_token,
              access_expires_at: Time.current + jwt_service.jwt_access_exp_seconds,
              refresh_expires_at: Time.current + jwt_service.jwt_refresh_exp_seconds
            }

            render json: tokens, status: :created
          else
            render json: { error: 'Invalid credentials' }, status: :unauthorized
          end
        end

        def refresh
          refresh_token = params[:refresh_token]

          if refresh_token.blank?
            render json: { error: 'Refresh token required' }, status: :bad_request
            return
          end

          begin
            session = JWTSessions::Session.new(payload: {}, refresh_by_access_allowed: true)

            tokens = session.refresh(refresh_token)

            payload = JWTSessions::Token.decode(tokens[:access]).first
            user_id = payload['user_id']
            account_id = payload['account_id']

            user = User.find_by(id: user_id)
            account = Account.find_by(id: account_id)

            jwt_service = TeamsApi::Services::JwtSessionService.new(account, user)

            response_tokens = {
              access: tokens[:access],
              refresh: tokens[:refresh],
              access_expires_at: Time.current + jwt_service.jwt_access_exp_seconds,
              refresh_expires_at: Time.current + jwt_service.jwt_refresh_exp_seconds
            }

            render json: response_tokens, status: :ok
          rescue JWTSessions::Errors::Unauthorized
            render json: { error: 'Invalid refresh token' }, status: :unauthorized
          rescue JWTSessions::Errors::Error => e
            render json: { error: e.message }, status: :unprocessable_entity
          end
        end

        def logout
          token = request.headers[JWTSessions.access_header]&.split(' ')&.last
          if token
            JWTSessions::Token.decode(token).first

            jwt_service = TeamsApi::Services::JwtSessionService.new(
              current_account,
              current_user
            )

            jwt_service.destroy_jwt_session!(token: token)

            render json: { status: 'logged out' }, status: :ok
          else
            render json: { error: 'No token provided' }, status: :bad_request
          end
        rescue JWTSessions::Errors::Error
          render json: { error: 'Invalid token' }, status: :unprocessable_entity
        end
      end
    end
  end
end
