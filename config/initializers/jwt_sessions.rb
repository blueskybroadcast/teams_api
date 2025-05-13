# frozen_string_literal: true

JWTSessions.algorithm = 'HS256'
JWTSessions.encryption_key = ENV['JWT_SECRET_KEY']

# Configure Redis store
redis_opts = { token_prefix: 'jwt_' }

if ENV['REDIS_URL'].present?
  redis_opts[:url] = ENV['REDIS_URL']
  redis_opts[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
else
  redis_opts[:redis_host] = ENV.fetch('REDIS_HOST', '127.0.0.1')
  redis_opts[:redis_port] = ENV.fetch('REDIS_PORT', '6379')
  redis_opts[:redis_db_name] = ENV.fetch('REDIS_DB', '0')
end

JWTSessions.token_store = :redis, redis_opts
