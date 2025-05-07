# frozen_string_literal: true

module TeamsApi
  module Services
    class TeamService
      def self.create_team(name:, description:, owner_id:)
        unless ::User.find(owner_id).can_create_team?
          return { success: false, error: "User not authorized to create teams" }
        end
        
        team = Adapters::TeamAdapter.create(
          name: name,
          description: description,
          owner_id: owner_id,
          created_at: Time.current
        )
        
        if team.persisted?
          ::TeamMember.create(team_id: team.id, user_id: owner_id, role: 'admin')
          { success: true, team: team }
        else
          { success: false, error: team.errors.full_messages.join(", ") }
        end
      end
      
      def self.update_team(id:, attributes:, current_user_id:)
        team = Adapters::TeamAdapter.find(id)

        unless ::TeamMember.where(team_id: id, user_id: current_user_id, role: 'admin').exists?
          return { success: false, error: "Not authorized to update this team" }
        end
        
        if Adapters::TeamAdapter.update(id, attributes)
          { success: true, team: team.reload }
        else
          { success: false, error: team.errors.full_messages.join(", ") }
        end
      end

    end
  end
end
