# frozen_string_literal: true

module TeamsApi
  module Concerns
    module JwtAware
      extend ActiveSupport::Concern

      # Instead of including JWTSessions::RailsAuthorization directly,
      # we'll include its methods manually

      included do
        helper_method :current_user, :current_account if respond_to?(:helper_method)

        # Add these before_actions for comprehensive JWT handling
        prepend_before_action :authorize_with_jwt, if: -> { jwt_enabled? && jwt.present? }
        prepend_before_action :set_jwt_auth_header, if: -> { jwt_enabled? && jwt.present? }
        prepend_before_action :create_jwt_session, if: :create_jwt_session?
        prepend_before_action :delete_jwt, if: -> { current_account&.persisted? && jwt_enabled? && jwt.present? }
      end

      # Public methods
      def current_user
        @current_user ||= jwt_auth.current_user
      end

      def current_account
        @current_account ||= jwt_auth.current_account
      end

      # Methods from JWTSessions::RailsAuthorization that we need
      def authorize_access_request!
        begin
          authorize_request(JWTSessions.access_header)
        rescue JWTSessions::Errors::Unauthorized
          raise JWTSessions::Errors::Unauthorized
        end
      end

      def authorize_refresh_request!
        begin
          authorize_request(JWTSessions.refresh_header)
        rescue JWTSessions::Errors::Unauthorized
          raise JWTSessions::Errors::Unauthorized
        end
      end

      def authorize_refresh_by_access_request!
        begin
          authorize_refresh_by_access_request
        rescue JWTSessions::Errors::Unauthorized
          raise JWTSessions::Errors::Unauthorized
        end
      end

      def session_exists?(token = request.cookies[JWTSessions.access_cookie], token_type = :access)
        JWTSessions::Session.new.session_exists?(token, token_type)
      end

      def payload
        claims = token_claims
        return claims if claims

        {}
      end

      private

      def jwt_auth
        @jwt_auth ||= TeamsApi::Auth::JwtAuthenticator.new(self)
      end

      def authenticate_with_jwt
        jwt_auth.authenticate
      end

      def create_jwt_session?
        current_user.present? && jwt_enabled? && !jwt_session_exists?
      end

      def jwt_enabled?
        return @jwt_enabled if defined?(@jwt_enabled)

        @jwt_enabled = if current_account
                         current_account.respond_to?(:jwt_enabled?) ? current_account.jwt_enabled? : true
                       elsif jwt_payload['account_id']
                         account = ::Account.find_by(id: jwt_payload['account_id'])
                         account && (account.respond_to?(:jwt_enabled?) ? account.jwt_enabled? : true)
                       else
                         false
                       end
      end

      def set_jwt_auth_header
        request.headers[JWTSessions.access_header] ||= "Bearer #{jwt}"
      end

      def authorize_with_jwt
        authorize_access_request!
      rescue JWTSessions::Errors::Error
        if create_session_from_existing_jwt?
          create_session_from_existing_jwt
        else
          destroy_jwt_session!
        end
      end

      def jwt(token_type = :access)
        begin
          cookieless_auth(token_type)
        rescue JWTSessions::Errors::Unauthorized
          begin
            cookie_based_auth(token_type)
          rescue JWTSessions::Errors::Error
            nil
          end
        end
      end

      def cookieless_auth(token_type = :access)
        token = request.headers[JWTSessions.access_header]&.split(' ')&.last
        token && token_type == :access ? decode_token(token) : nil
      rescue StandardError
        nil
      end

      def cookie_based_auth(token_type = :access)
        token = request.cookies[JWTSessions.access_cookie]
        token && token_type == :access ? decode_token(token) : nil
      rescue StandardError
        nil
      end

      def decode_token(token)
        JWTSessions::Token.decode(token).first
      rescue StandardError
        nil
      end

      def jwt_session_exists?(type = :access)
        token = jwt
        token.present? && session_exists?(token, type)
      rescue JWTSessions::Errors::Error
        false
      end

      def jwt_payload
        payload
      rescue JWTSessions::Errors::Error
        {}
      end

      # Methods from JWTSessions::RailsAuthorization
      def authorize_request(header_name)
        token = request.headers[header_name]&.split(' ')&.last
        if token
          @_csrf = JWTSessions::CSRFToken.new(token_claims(token)&.[]('csrf')).encoded
        else
          @_csrf = request.headers[JWTSessions.csrf_header]
        end

        raise JWTSessions::Errors::Unauthorized, "CSRF token is not found" if token && @_csrf.nil? && JWTSessions.csrf_claim

        check_csrf
      end

      def authorize_refresh_by_access_request
        cookieless_auth_refresh_by_access_token ||
          cookie_based_auth_refresh_by_access_token

        raise JWTSessions::Errors::Unauthorized, "Refresh token not found" unless found?
        valid_csrf? ? check_csrf : check_csrf_header
      end

      def token_claims(original_token = nil)
        token = original_token || token_from_headers || token_from_cookies
        if token.nil?
          nil
        else
          JWTSessions::Token.decode(token).first
        end
      end

      def token_from_headers
        request.headers[JWTSessions.access_header]&.split(' ')&.last ||
          request.headers[JWTSessions.refresh_header]&.split(' ')&.last
      end

      def token_from_cookies
        request.cookies[JWTSessions.access_cookie] ||
          request.cookies[JWTSessions.refresh_cookie]
      end

      def check_csrf
        return unless JWTSessions.csrf_claim
        raise JWTSessions::Errors::Unauthorized, "CSRF token is not found" if @_csrf.nil?
      end

      def create_session_from_existing_jwt?
        jwt_from_headers = cookieless_auth(:access)
        jwt_from_headers && jwt_from_headers != jwt &&
          jwt_payload.present? && jwt_payload['exp'].present? &&
          (jwt_payload['user_id'].present? || jwt_payload['account_id'].present?)
      end

      def create_session_from_existing_jwt
        token = request.headers[JWTSessions.access_header]&.split(' ')&.last
        payload = JWTSessions::Token.decode(token).first

        service = TeamsApi::Services::JwtSessionService.new(
          current_account,
          current_user
        )

        session = service.jwt_session(
          refresh_by_access_allowed: true,
          namespace: service.jwt_namespace(payload),
          refresh_exp: service.jwt_refresh_exp_seconds
        )

        csrf = JWTSessions::CSRFToken.new
        access = JWTSessions::AccessToken.new(
          csrf.encoded,
          payload,
          session.store,
          payload['uid'] || SecureRandom.uuid,
          payload['exp']
        )

        session.store.persist_access(access.uid, access.csrf, access.expiration)
        session.instance_variable_set(:@_csrf, csrf)
        session.instance_variable_set(:@_access, access)
        session.instance_variable_set(:@access_token, access.token)
        session.send(:create_refresh_token)
      rescue JWTSessions::Errors::Error => e
        Rails.logger.error "Create JWT session from header JWT error - #{e.message}"
        Rails.logger.error e.backtrace
      end

      def create_jwt_session
        jwt_service.create_jwt_session
        set_jwt_cookie(jwt_service.access_token)
      end

      def destroy_jwt_session!
        jwt_service.destroy_jwt_session!(token: jwt)
      ensure
        delete_jwt
      end

      def set_jwt_cookie(value)
        request.cookie_jar[JWTSessions.access_cookie] = { value: value }
      end

      def jwt_service
        @jwt_service ||= TeamsApi::Services::JwtSessionService.new(current_account, current_user)
      end

      def delete_jwt
        request.headers[JWTSessions.access_header] = nil
        cookies.delete(JWTSessions.access_cookie) if cookies.respond_to?(:delete)
      end
    end
  end
end
