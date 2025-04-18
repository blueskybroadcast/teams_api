# frozen_string_literal: true

module TeamsApi
  module Api
    module V1
      class TeamsController < BaseController
        before_action :set_account_id

        def index
          teams = Adapters::TeamAdapter.all(account_id: @account_id)
          render json: teams, each_serializer: TeamSerializer
        end

        def show
          team = Adapters::TeamAdapter.find(id: params[:id], account_id: @account_id)
          render json: team, serializer: TeamSerializer, include: ['members', 'items']
        end

        def create
          team = Adapters::TeamAdapter.create(
            attributes: team_params,
            account_id: @account_id
          )

          if team.persisted?
            render json: team, serializer: TeamSerializer, status: :created
          else
            render json: { errors: team.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          team = Adapters::TeamAdapter.update(
            id: params[:id],
            attributes: team_params,
            account_id: @account_id
          )

          if team&.errors&.empty?
            render json: team, serializer: TeamSerializer
          else
            render json: { errors: team&.errors&.full_messages || ['Team not found'] },
                   status: team ? :unprocessable_entity : :not_found
          end
        end

        def destroy
          result = Adapters::TeamAdapter.delete(id: params[:id], account_id: @account_id)

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

        def set_account_id
          # This would come from authentication/authorization
          # For now, we'll use a param or header
          @account_id = request.headers['X-Account-ID'] || params[:account_id]
          render json: { error: 'Account ID required' }, status: :bad_request unless @account_id
        end
      end
    end
  end
end
