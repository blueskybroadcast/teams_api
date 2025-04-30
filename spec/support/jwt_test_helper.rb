# frozen_string_literal: true

require 'ostruct'
require 'jwt_sessions'

# Define Rails mock outside of methods
unless defined?(Rails) && Rails.respond_to?(:cache)
  module Rails
    def self.cache
      @cache ||= Object.new.tap do |o|
        def o.write(key, value, options = {}); @store ||= {}; @store[key] = value; end
        def o.read(key); @store ||= {}; @store[key]; end
        def o.exist?(key); @store ||= {}; @store.key?(key); end
        def o.delete(key); @store ||= {}; @store.delete(key); end
        def o.clear; @store = {}; end
      end
    end

    def self.logger
      @logger ||= Object.new.tap do |o|
        def o.error(*args); end
        def o.warn(*args); end
        def o.info(*args); end
      end
    end

    def self.env
      OpenStruct.new(test?: true)
    end
  end
end

# Define ActiveSupport mock outside of methods
unless defined?(ActiveSupport)
  module ActiveSupport
    class HashWithIndifferentAccess < Hash
      def [](key)
        super(key.to_s)
      end
    end

    module Concern
    end
  end
end

module JwtTestingHelper
  def self.configure
    JWTSessions.encryption_key = 'test_key_for_jwt_sessions'
  end

  module JwtHelpers
    def generate_jwt_token(account, user = nil, custom_payload = {})
      jwt_service = TeamsApi::Services::JwtSessionService.new(account, user)
      payload = {
        account_id: account.id,
        account_slug: account.slug
      }

      if user
        payload.merge!({
          user_id: user.id,
          user_email: user.email,
          admin: user.admin?
        })
      end

      payload.merge!(custom_payload)

      jwt_service.create_jwt_session(payload: payload)
    end

    def set_jwt_auth_header(token)
      request.headers[JWTSessions.access_header] = "Bearer #{token}"
    end

    def sign_in_with_jwt(account, user)
      token = generate_jwt_token(account, user)
      set_jwt_auth_header(token)
    end

    def clean_jwt_tokens
      Rails.cache.clear
    end

    def setup_jwt_test_env
      JWTSessions.encryption_key = 'test_secret_key'
      Rails.cache.clear
    end
  end

  module Mocks
    module Extensions
      def self.apply
        apply_hash_extensions
        apply_string_extensions
        apply_nil_extensions
        apply_object_extensions
        apply_numeric_extensions
        mock_env
      end

      def self.apply_hash_extensions
        unless Hash.method_defined?(:with_indifferent_access)
          Hash.class_eval do
            def with_indifferent_access; self; end

            def deep_symbolize_keys!
              keys.each do |key|
                value = delete(key)
                self[(key.to_sym rescue key) || key] = value.is_a?(Hash) ? value.deep_symbolize_keys! : value
              end
              self
            end

            def symbolize_keys!
              keys.each do |key|
                self[(key.to_sym rescue key) || key] = delete(key)
              end
              self
            end

            def except(*keys)
              dup.tap { |hash| keys.each { |key| hash.delete(key) } }
            end

            def blank?; empty?; end
            def present?; !blank?; end
          end
        end
      end

      def self.apply_string_extensions
        unless String.method_defined?(:blank?)
          String.class_eval do
            def blank?; empty?; end
            def present?; !blank?; end
          end
        end
      end

      def self.apply_nil_extensions
        unless NilClass.method_defined?(:blank?)
          NilClass.class_eval do
            def blank?; true; end
            def present?; false; end
          end
        end
      end

      def self.apply_object_extensions
        unless Object.method_defined?(:presence)
          Object.class_eval do
            def presence; self unless blank?; end
            def blank?; respond_to?(:empty?) ? empty? : !self; end
            def present?; !blank?; end
            def try(method, *args); send(method, *args) if respond_to?(method); end
          end
        end
      end

      def self.apply_numeric_extensions
        unless Numeric.method_defined?(:hours)
          Numeric.class_eval do
            def hours; self * 3600; end
            def days; self * 24 * 3600; end
            def to_i; self.to_int rescue self; end
          end
        end
      end

      def self.mock_env
        unless ENV.respond_to?(:fetch)
          def ENV.fetch(key, default = nil)
            default
          end
        end
      end
    end

    class Account
      attr_accessor :id, :slug

      def initialize(id: 1, slug: 'test-account')
        @id = id
        @slug = slug
      end

      def jwt_enabled?
        true
      end

      def self.find_by(criteria)
        if criteria[:id] == 1
          new
        else
          nil
        end
      end
    end

    class User
      attr_accessor :id, :email, :account

      def initialize(id: 1, email: 'test@example.com', account: nil, admin: false)
        @id = id
        @email = email
        @account = account || Account.new
        @admin = admin
      end

      def admin?
        @admin
      end

      def authenticated?(password)
        password == 'password'
      end

      def self.find_by(criteria)
        if criteria[:id] == 1 || criteria[:email] == 'test@example.com'
          new
        else
          nil
        end
      end

      def self.find_by_auth_token(token)
        token == 'valid_token' ? new : nil
      end
    end

    def create(factory_name, attributes = {})
      case factory_name
      when :account
        Account.new(**attributes)
      when :user
        User.new(**attributes)
      else
        raise ArgumentError, "Unknown factory: #{factory_name}"
      end
    end
  end

  def self.setup_rspec(config)
    config.include JwtHelpers
    config.include Mocks

    config.before(:each) do
      setup_jwt_test_env if respond_to?(:setup_jwt_test_env)
    end
  end

  Mocks::Extensions.apply

  configure
end

if defined?(RSpec)
  RSpec.configure do |config|
    JwtTestingHelper.setup_rspec(config)
  end
end
