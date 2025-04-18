# frozen_string_literal: true

module TeamsApi
  module Adapters
    class MembershipAdapter

      def self.all(team_id:, account_id:, filters: {})
        memberships = ::Teams::Membership.where(team_id: team_id, account_id: account_id)
        memberships = memberships.filter_by_status(filters) if filters.present?
        memberships
      end

      def self.find(id:, team_id:, account_id:)
        ::Teams::Membership.where(
          id: id,
          team_id: team_id,
          account_id: account_id
        ).first
      end

      def self.search(query:, team_id:, account_id:)
        ::Teams::Membership.where(team_id: team_id, account_id: account_id)
                          .search(query)
      end

      def self.create(team_id:, account_id:, attributes:)
        normalized_attrs = attributes.dup

        if normalized_attrs[:user_id].present?
          normalized_attrs[:member_id] = normalized_attrs.delete(:user_id)
        end

        ::Teams::Membership.create(
          normalized_attrs.merge(
            team_id: team_id,
            account_id: account_id
          )
        )
      end

      def self.invite(team_id:, account_id:, email:, as_manager: false)
        user = ::User.find_by(email: email, account_id: account_id)

        if user
          create(
            team_id: team_id,
            account_id: account_id,
            attributes: {
              user_id: user.id,
              manager: as_manager,
              invited_at: Time.current
            }
          )
        else
          create(
            team_id: team_id,
            account_id: account_id,
            attributes: {
              invitation_email: email,
              manager: as_manager,
              invited_at: Time.current
            }
          )
        end
      end

      def self.update(id:, team_id:, account_id:, attributes:)
        membership = find(id: id, team_id: team_id, account_id: account_id)
        membership&.update(attributes)
        membership
      end

      def self.accept_invitation(token:, user_id:)
        membership = ::Teams::Membership.find_by_token(token)

        return false unless membership&.valid_invite_token?

        user = ::User.find(user_id)
        return false if membership.invitation_email.present? &&
                        !membership.invitation_email.casecmp(user.email).zero?

        membership.update(
          user_id: user_id,
          accepted_at: Time.current
        )
      end

      def self.delete(id:, team_id:, account_id:)
        membership = find(id: id, team_id: team_id, account_id: account_id)
        membership&.destroy
      end
    end
  end
end
