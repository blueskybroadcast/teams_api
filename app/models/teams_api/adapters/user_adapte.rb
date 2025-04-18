# frozen_string_literal: true

module TeamsApi
  module Adapters
    class UserAdapter
      def self.find(id)
        ::User.find(id)
      end

      def self.find_by_email(email)
        ::User.find_by(email: email)
      end

      def self.in_team(team_id)
        ::User.joins(:team_members)
              .where(team_members: { team_id: team_id })
              .distinct
      end
    end
  end
end
