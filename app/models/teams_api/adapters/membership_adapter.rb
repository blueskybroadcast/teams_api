# frozen_string_literal: true

require 'securerandom'

module TeamsApi
  module Adapters
    class MembershipAdapter
      def self.all(team_id:, account_id:, filters: {})
        memberships = ::Teams::Membership.where(team_id: team_id, account_id: account_id)
        memberships = filter_by_status(memberships, filters) if filters.present?
        memberships
      end

      def self.find(id:, team_id:, account_id:)
        ::Teams::Membership.where(
          id: id,
          team_id: team_id,
          account_id: account_id
        ).first
      end

      def self.create(team_id:, account_id:, attributes:)
        ::Teams::Membership.create(
          attributes.merge(
            team_id: team_id,
            account_id: account_id
          )
        )
      end

      def self.invite(team_id:, account_id:, email:, as_manager: false)
        user = ::User.find_by(email: email, account_id: account_id)

        # Generate a secure invitation token
        invitation_token = generate_token

        if user
          create(
            team_id: team_id,
            account_id: account_id,
            attributes: {
              user_id: user.id,
              manager: as_manager,
              invited_at: Time.current,
              invite_token: invitation_token
            }
          )
        else
          create(
            team_id: team_id,
            account_id: account_id,
            attributes: {
              invitation_email: email,
              manager: as_manager,
              invited_at: Time.current,
              invite_token: invitation_token
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
        membership = ::Teams::Membership.find_by(invite_token: token)

        return false unless membership && valid_invite?(membership)

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

      def self.valid_invite?(membership)
        membership.invited_at.present? &&
        membership.accepted_at.nil? &&
        membership.invite_token.present?
      end

      def self.generate_token
        # Generate a secure random token
        SecureRandom.urlsafe_base64(32)
      end

      def self.filter_by_status(memberships, filters)
        result = memberships

        if filters[:invite_sent]
          result = result.where.not(invited_at: nil)
        end

        if filters[:manager]
          result = result.where(manager: true)
        end

        if filters[:member]
          result = result.where.not(user_id: nil)
        end

        result
      end
    end
  end
end
