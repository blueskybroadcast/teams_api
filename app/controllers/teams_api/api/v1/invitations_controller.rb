# frozen_string_literal: true

module TeamsApi
  module Api
    module V1
      class InvitationsController < BaseController
        skip_before_action :authenticate_request, only: [:accept]

        def accept
          result = TeamsApi::Adapters::MembershipAdapter.accept_invitation(
            token: params[:token],
            user_id: params[:user_id]
          )

          if result
            render json: { success: true }
          else
            render json: { error: 'Invalid or expired invitation' }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
