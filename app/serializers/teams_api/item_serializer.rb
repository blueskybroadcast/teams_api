# frozen_string_literal: true

module TeamsApi
  class ItemSerializer < ::ActiveModel::Serializer
    attributes :id, :name, :description
    # Add additional attributes as needed
  end
end
