# frozen_string_literal: true

module TeamsApi
  class ItemSerializer < ::ActiveModel::Serializer
    attributes :id, :name, :description, :created_at, :updated_at

  end
end
