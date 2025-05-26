# frozen_string_literal: true

module TeamsApi
  class MemberSerializer < ::ActiveModel::Serializer
    attributes :id, :email, :first_name, :last_name, :username

  end
end
