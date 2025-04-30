# frozen_string_literal: true

# Mock JWTSessions module for testing
module JWTSessions
  def self.access_header
    'Authorization'
  end

  def self.access_cookie
    'jwt_access'
  end

  class Token
    def self.decode(token)
      if token == "test_token_123"
        [{ 'user_id' => 1, 'account_id' => 1 }]
      else
        raise StandardError, "Invalid token"
      end
    end
  end
end

# JwtAuthenticator implementation
module TeamsApi
  module Auth
    class JwtAuthenticator
      attr_reader :request, :controller

      def initialize(controller)
        @controller = controller
        @request = controller.request
      end

      def authenticate
        if jwt_payload && jwt_payload['user_id']
          current_user
        else
          nil
        end
      end

      def current_user
        return @current_user if defined?(@current_user)

        user_id = jwt_payload['user_id']
        @current_user = user_id ? ::User.find_by(id: user_id) : nil
      end

      def current_account
        return @current_account if defined?(@current_account)

        account_id = jwt_payload['account_id']
        @current_account = account_id ? ::Account.find_by(id: account_id) : nil
      end

      private

      def cookieless_auth
        token = request.headers[JWTSessions.access_header]&.split(' ')&.last
        token && decode_token(token)
      rescue StandardError
        nil
      end

      def cookie_based_auth
        token = request.cookies[JWTSessions.access_cookie]
        token && decode_token(token)
      rescue StandardError
        nil
      end

      def decode_token(token)
        JWTSessions::Token.decode(token).first
      rescue StandardError
        nil
      end

      def jwt_payload
        @jwt_payload ||= cookieless_auth || cookie_based_auth || {}
      end
    end
  end
end
