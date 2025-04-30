# frozen_string_literal: true

module TeamsApi
  module Api
    module V1
      class BaseController < ActionController::API
        include TeamsApi::Concerns::JwtAware

        before_action :authenticate_request

        private

        def authenticate_request
          unless current_user
            render json: { error: 'Unauthorized' }, status: :unauthorized
          end
        end
      end
    end
  end
end
