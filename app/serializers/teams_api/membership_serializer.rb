# frozen_string_literal: true

module TeamsApi
  class MembershipSerializer < ::ActiveModel::Serializer
    attributes :id, :user_id, :team_id, :manager,
               :invitation_email, :invited_at, :accepted_at,
               :sso_synced, :auto_reg_skipped_by,
               :created_at, :updated_at

    belongs_to :member, if: -> { object.user_id.present? }
    belongs_to :access_code, if: -> { object.access_code_id.present? }

    def invitation_status
      if object.accepted_at.present?
        'accepted'
      elsif object.invited_at.present?
        'invited'
      elsif object.user_id.present?
        'added'
      else
        'pending'
      end
    end
  end
end
