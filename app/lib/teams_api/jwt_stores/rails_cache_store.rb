# frozen_string_literal: true

module TeamsApi
  module JwtStores
    class RailsCacheStore < JWTSessions::StoreAdapter
      attr_reader :prefix, :expiration

      # Initialize with options
      # @param [Hash] options - store options
      # @option options [Integer] :expiration - token expiration time in seconds
      # @option options [String] :prefix - prefix for the cache keys
      def initialize(options = {})
        @expiration = options[:expiration] || 3600
        @prefix = options[:prefix] || "jwt_"
      end

      # Create or update a record in the store
      # @param [String] key - record key
      # @param [String] value - record value
      # @param [Hash] options - additional options to save with the key-value pair
      # @option options [Integer] :expiration - record expiration time in seconds
      def persist(key, value, options = {})
        Rails.cache.write(prefixed(key), value, expires_in: options[:expiration] || expiration)
      end

      # Retrieve a payload by key
      # @param [String] key - key to look up
      def fetch(key)
        Rails.cache.read(prefixed(key))
      end

      # Check if key exists in the store
      # @param [String] key - key to check
      def exist?(key)
        Rails.cache.exist?(prefixed(key))
      end

      # Remove a record from the store
      # @param [String] key - key to remove
      def delete(key)
        Rails.cache.delete(prefixed(key))
      end

      # Remove all records which match the given pattern
      # @param [String] pattern - pattern to match keys against
      def destroy_by_prefix(prefix)
        # This requires custom implementation based on how Rails.cache is configured
        # For Redis-backed cache, we could use Redis SCAN and delete
        # For memory stores, we might need to iterate through all keys
        #
        # A simple implementation might be:
        Rails.logger.warn "RailsCacheStore#destroy_by_prefix: This method may not work efficiently depending on your cache store"
        if Rails.cache.respond_to?(:delete_matched)
          Rails.cache.delete_matched("#{@prefix}#{prefix}*")
        else
          Rails.logger.warn "Your cache store doesn't support delete_matched, JWT namespace flush may not work correctly"
        end
      end

      # Retrieve all tokens for a given namespace
      # @param [String] namespace - namespace to retrieve tokens for
      def all_by_namespace(namespace)
        Rails.logger.warn "RailsCacheStore#all_by_namespace: Not efficiently supported with Rails.cache"
        []
      end

      # Remove all records from the store
      def flush_all
        if Rails.cache.respond_to?(:clear)
          Rails.cache.clear
        else
          Rails.logger.warn "Your cache store doesn't support clear, JWT flush_all may not work correctly"
        end
      end

      private

      # Add prefix to key
      # @param [String] key - key to add prefix to
      def prefixed(key)
        "#{@prefix}#{key}"
      end
    end
  end
end
