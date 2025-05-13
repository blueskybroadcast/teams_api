# frozen_string_literal: true

module TeamsApi
  class AccessCodeSerializer < ::ActiveModel::Serializer
    attributes :id, :code
    # Add additional attributes as needed
  end
end
