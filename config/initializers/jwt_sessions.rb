# frozen_string_literal: true

JWTSessions.algorithm = 'HS256'
JWTSessions.encryption_key = ENV['JWT_SECRET_KEY']

require_relative '../../app/lib/teams_api/jwt_stores/rails_cache_store'
cache_opts = {
  prefix: 'jwt_',
  expiration: ENV.fetch('JWT_CACHE_EXPIRATION', 3600 * 24).to_i  # 24 hours default
}

JWTSessions.token_store = TeamsApi::JwtStores::RailsCacheStore.new(cache_opts)
