# frozen_string_literal: true

module TeamsApi
  class TeamSerializer < ::ActiveModel::Serializer
    attributes :id, :name, :descriptor, :max_members, :expires_at,
               :enable_content_tab, :full_access, :include_inactive,
               :content_visibility, :created_at, :updated_at,
               :member_count, :expired

    has_many :members, serializer: TeamsApi::MemberSerializer
    has_many :items, serializer: TeamsApi::ItemSerializer

    def member_count
      object.memberships.count
    end

    def expired
      object.expired?
    end
  end
end
