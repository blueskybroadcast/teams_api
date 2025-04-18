# frozen_string_literal: true

require 'rails_helper'

module TeamsApi
  module Services
    RSpec.describe TeamService do
      describe '.create_team' do
        it 'creates a team and assigns the creator as admin' do
          user = FactoryBot.create(:user)

          allow_any_instance_of(::User).to receive(:can_create_team?).and_return(true)

          result = TeamService.create_team(
            name: 'New Team',
            description: 'Test team',
            owner_id: user.id
          )

          expect(result[:success]).to be true
          expect(result[:team].name).to eq('New Team')

          team_member = ::TeamMember.find_by(team_id: result[:team].id, user_id: user.id)
          expect(team_member).to be_present
          expect(team_member.role).to eq('admin')
        end
      end
    end
  end
end
