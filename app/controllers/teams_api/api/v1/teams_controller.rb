# frozen_string_literal: true

module TeamsApi
  module Api
    module V1
      class TeamsController < BaseController
        before_action -> { require_scope('teams:read') }, only: [:index, :show]
        before_action -> { require_scope('teams:write') }, only: [:create, :update, :destroy]

        def index
          teams = TeamsApi::Adapters::TeamAdapter.all(account_id: @current_account.id)
          render json: teams, each_serializer: TeamSerializer
        end

        def show
          team = TeamsApi::Adapters::TeamAdapter.find(id: params[:id], account_id: @current_account.id)
          render json: team, serializer: TeamSerializer, include: ['members', 'items']
        end

        def create
          team = TeamsApi::Adapters::TeamAdapter.create(
            attributes: team_params,
            account_id: @current_account.id
          )

          if team.persisted?
            render json: team, serializer: TeamSerializer, status: :created
          else
            render json: { errors: team.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          team = TeamsApi::Adapters::TeamAdapter.update(
            id: params[:id],
            attributes: team_params,
            account_id: @current_account.id
          )

          if team&.errors&.empty?
            render json: team, serializer: TeamSerializer
          else
            render json: { errors: team&.errors&.full_messages || ['Team not found'] },
                   status: team ? :unprocessable_entity : :not_found
          end
        end

        def destroy
          result = TeamsApi::Adapters::TeamAdapter.delete(id: params[:id], account_id: @current_account.id)

          if result
            head :no_content
          else
            render json: { error: 'Team not found' }, status: :not_found
          end
        end

        private

        def team_params
          params.require(:team).permit(
            :name,
            :descriptor,
            :custom_page_id,
            :max_members,
            :enable_content_tab,
            :full_access,
            :include_inactive,
            :content_visibility,
            :expires_at
          )
        end
      end
    end
  end
end
