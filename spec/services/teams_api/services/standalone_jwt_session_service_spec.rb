# frozen_string_literal: true

# Basic requirements
require 'jwt_sessions'
require 'ostruct'

# Mock ActiveSupport methods
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

# Use absolute path to the service file
# = File.expand_path('../../../', __FILE__)
service_path = File.expand_path('../../../../services/teams_api/services/jwt_session_service.rb', __dir__)
puts "Loading JWT service from: #{service_path}"
require service_path

RSpec.describe TeamsApi::Services::JwtSessionService do
  let(:account) { Account.new }
  let(:user) { User.new(account: account) }
  let(:service) { described_class.new(account, user) }

  it "can be initialized" do
    expect(service).to be_a(TeamsApi::Services::JwtSessionService)
  end

  it "creates a JWT token" do
    result = service.create_jwt_session
    expect(result).not_to be_nil
  end

  it "has access to the created token" do
    service.create_jwt_session
    expect(service.access_token).not_to be_nil
  end

  it "returns correct payload" do
    payload = service.jwt_payload
    expect(payload[:account_id]).to eq account.id
    expect(payload[:account_slug]).to eq account.slug
    expect(payload[:user_id]).to eq user.id
    expect(payload[:user_email]).to eq user.email
  end
end
