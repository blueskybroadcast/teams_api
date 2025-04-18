# frozen_string_literal: true

module TeamsApi
  module Api
    module V1
      class BaseController < ActionController::API
        before_action :authenticate_request

        private

        def authenticate_request

          token = request.headers['Authorization']&.split(' ')&.last
          @current_user = ::User.find_by_auth_token(token)

          unless @current_user
            render json: { error: 'Unauthorized' }, status: :unauthorized
          end
        end
      end
    end
  end
end
