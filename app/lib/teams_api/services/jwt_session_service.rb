# frozen_string_literal: true

module TeamsApi
  module Services
    class JwtSessionService
      DEFAULT_JWT_ACCESS_EXPIRATION = 12.hours
      DEFAULT_JWT_REFRESH_EXPIRATION = 14.days

      attr_reader :account, :user
      attr_accessor :access_token, :refresh_token

      def initialize(account, user = nil)
        @account = account || user&.account
        @user = user
      end

      def create_jwt_session(override_opts = {})
        override_opts.deep_symbolize_keys!
        payload = jwt_payload(true).merge(override_opts[:payload] || {})
        raise JWTSessions::Errors::Error.new('Could not find account and user') if payload.blank?

        sessions_opts = {
          payload: payload,
          refresh_by_access_allowed: true,
          namespace: jwt_namespace(payload),
          access_exp: jwt_access_exp_seconds,
          refresh_exp: jwt_refresh_exp_seconds,
          **override_opts.except(:payload)
        }
        jwt_session = jwt_session(sessions_opts)
        tokens = jwt_session.login

        @refresh_token = tokens[:refresh]
        @access_token = tokens[:access]
      rescue JWTSessions::Errors::Error => e
        Rails.logger.error "Create JWT session error - #{e.message}"
        Rails.logger.error e.backtrace
        nil # Return nil explicitly on error
      end
      alias_method :create_jwt, :create_jwt_session

      def destroy_jwt_session!(token: access_token, by_namespace: false, namespace: nil)
        if by_namespace
          destroy_session_by_namespace(namespace)
        else
          destroy_session_by_token(token)
        end

        @access_token = nil
        @refresh_token = nil
      rescue JWTSessions::Errors::Error => e
        Rails.logger.error "Destroy JWT session error - #{e.message}"
        Rails.logger.error e.backtrace
      end
      alias_method :destroy_jwt!, :destroy_jwt_session!

      def jwt_session(opts = {})
        JWTSessions::Session.new(opts)
      end

      def jwt_payload(new_session = false)
        if access_token.present? && !new_session
          JWTSessions::Token.decode(access_token).first.with_indifferent_access
        else
          return if account.blank? && user.blank?

          { account_id: account.id, account_slug: account.slug, **user_payload }
        end
      end

      def jwt_namespace(payload = nil)
        user_id, account_id = if payload.present?
                                payload.try(:symbolize_keys!)
                                [payload[:user_id], payload[:account_id]]
                              else
                                [user&.id, account&.id]
                              end

        if user_id.present?
          "user_#{user_id}"
        elsif account_id.present?
          "account_#{account_id}"
        else
          raise JWTSessions::Errors::Error.new('Could not destroy session without namespace')
        end
      end

      def jwt_access_exp_seconds
        ENV.fetch('JWT_ACCESS_EXPIRATION_SECONDS', DEFAULT_JWT_ACCESS_EXPIRATION).to_i
      end

      def jwt_refresh_exp_seconds
        ENV.fetch('JWT_REFRESH_EXPIRATION_SECONDS', DEFAULT_JWT_REFRESH_EXPIRATION).to_i
      end

      private

      def destroy_session_by_token(token)
        payload = JWTSessions::Token.decode!(token).first.with_indifferent_access
        jwt_session(
          payload: payload,
          namespace: jwt_namespace(payload),
          refresh_by_access_allowed: true
        ).flush_by_access_payload
      end

      def destroy_session_by_namespace(namespace = nil)
        jwt_session(namespace: namespace.presence || jwt_namespace).flush_namespaced
      end

      def user_payload
        return {} if user.blank?

        { user_id: user.id, user_email: user.email, admin: user.admin? }
      end
    end
  end
end
