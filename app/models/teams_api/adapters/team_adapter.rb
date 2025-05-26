# frozen_string_literal: true

module TeamsApi
  module Adapters
    class TeamAdapter
      def self.all(account_id:)
        ::Team.where(account_id: account_id)
      end

      def self.find(id:, account_id:)
        ::Team.where(id: id, account_id: account_id).first
      end

      def self.create(attributes:, account_id:)
        ::Team.create(attributes.merge(account_id: account_id))
      end

      def self.update(id:, attributes:, account_id:)
        team = find(id: id, account_id: account_id)
        team&.update(attributes)
        team
      end

      def self.delete(id:, account_id:)
        team = find(id: id, account_id: account_id)
        team&.destroy
      end
    end
  end
end
