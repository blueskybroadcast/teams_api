# frozen_string_literal: true

module TeamsApi
  class UserSerializer < ActiveModel::Serializer
    attributes :id, :email, :first_name, :last_name, :username
  end
end
