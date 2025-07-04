# frozen_string_literal: true

module TeamsApi
  module Api
    module V1
      class TeamMembershipsController < BaseController
        before_action -> { require_scope('teams:read') }, only: [:index, :show]
        before_action -> { require_scope('teams:write') }, only: [:create, :update, :destroy]

        def index
          filters = params.permit(:invite_sent, :manager, :member)
                         .to_h.symbolize_keys

          memberships = TeamsApi::Adapters::MembershipAdapter.all(
            team_id: params[:team_id],
            account_id: @current_account.id,
            filters: filters
          )

          render json: memberships, each_serializer: MembershipSerializer
        end

        def show
          membership = Adapters::MembershipAdapter.find(
            id: params[:id],
            team_id: params[:team_id],
            account_id: @current_account.id
          )

          if membership
            render json: membership, serializer: MembershipSerializer
          else
            render json: { error: 'Membership not found' }, status: :not_found
          end
        end

        def create
          if membership_params[:user_id].present?
            membership = Adapters::MembershipAdapter.create(
              team_id: params[:team_id],
              account_id: @current_account.id,
              attributes: membership_params
            )

            if membership.persisted?
              render json: membership, serializer: MembershipSerializer, status: :created
            else
              render json: { errors: membership.errors.full_messages },
                     status: :unprocessable_entity
            end
          elsif membership_params[:invitation_email].present?
            membership = Adapters::MembershipAdapter.invite(
              team_id: params[:team_id],
              account_id: @current_account.id,
              email: membership_params[:invitation_email],
              as_manager: membership_params[:manager] || false
            )

            if membership.persisted?
              render json: membership, serializer: MembershipSerializer, status: :created
            else
              render json: { errors: membership.errors.full_messages },
                     status: :unprocessable_entity
            end
          else
            render json: { error: 'Either user_id or invitation_email is required' },
                   status: :bad_request
          end
        end

        def update
          membership = Adapters::MembershipAdapter.update(
            id: params[:id],
            team_id: params[:team_id],
            account_id: @current_account.id,
            attributes: membership_params
          )

          if membership&.errors&.empty?
            render json: membership, serializer: MembershipSerializer
          else
            render json: { errors: membership&.errors&.full_messages || ['Membership not found'] },
                   status: membership ? :unprocessable_entity : :not_found
          end
        end

        def destroy
          result = Adapters::MembershipAdapter.delete(
            id: params[:id],
            team_id: params[:team_id],
            account_id: @current_account.id
          )

          if result
            head :no_content
          else
            render json: { error: 'Membership not found' }, status: :not_found
          end
        end

        private

        def require_read_scope
          verify_scope!('teams:read')
        end

        def require_write_scope
          verify_scope!('teams:write')
        end

        def membership_params
          params.require(:membership).permit(
            :user_id,
            :invitation_email,
            :manager,
            :access_code_id,
            :auto_reg_skipped_by
          )
        end
      end
    end
  end
end
