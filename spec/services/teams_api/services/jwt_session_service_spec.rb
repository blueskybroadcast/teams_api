# frozen_string_literal: true

require 'jwt_sessions'
require 'ostruct'

class Hash
  def with_indifferent_access
    self
  end

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

  def blank?
    empty?
  end

  def present?
    !blank?
  end
end

class String
  def blank?
    empty?
  end

  def present?
    !blank?
  end
end

class NilClass
  def blank?
    true
  end

  def present?
    false
  end
end

class Object
  def presence
    self unless blank?
  end

  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  def present?
    !blank?
  end

  def try(method, *args)
    send(method, *args) if respond_to?(method)
  end
end

# Mock Rails
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

# Define ActiveSupport constants if needed
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

# Mock ENV
def ENV.fetch(key, default = nil)
  default
end

# Numeric time extensions
class Numeric
  def hours
    self * 3600
  end

  def days
    self * 24 * 3600
  end

  def to_i
    self.to_int rescue self
  end
end

# Mock models
class Account
  attr_accessor :id, :slug

  def initialize(id: 1, slug: 'test-account')
    @id = id
    @slug = slug
  end

  def jwt_enabled?
    true
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
end

# Configure JWT Sessions
JWTSessions.encryption_key = 'test_key_for_jwt_sessions'

# Load the actual service file - using relative path
service_path = File.expand_path('../../../../services/teams_api/services/jwt_session_service.rb', __dir__)
puts "Loading JWT service from: #{service_path}"
require service_path

# Define factory methods to replace FactoryBot
def create(factory_name, attributes = {})
  case factory_name
  when :account
    Account.new(attributes)
  when :user
    User.new(attributes)
  end
end

module TeamsApi
  module Services
    RSpec.describe JwtSessionService do
      let(:account) { create(:account) }
      let(:user) { create(:user, account: account) }
      let(:service) { described_class.new(account, user) }

      describe '#create_jwt_session' do
        it 'creates a JWT session' do
          token = service.create_jwt_session
          expect(token).not_to be_nil
        end

        it 'sets access token and returns it' do
          result = service.create_jwt_session
          expect(service.access_token).not_to be_nil
          expect(result).to eq service.access_token
        end
      end

      describe '#jwt_payload' do
        it 'returns payload with account and user info' do
          payload = service.jwt_payload
          expect(payload[:account_id]).to eq account.id
          expect(payload[:account_slug]).to eq account.slug
          expect(payload[:user_id]).to eq user.id
          expect(payload[:user_email]).to eq user.email
        end
      end
    end
  end
end
