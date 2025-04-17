# frozen_string_literal: true

module TeamsApi
  module Api
    module V1
      class BaseController < ApplicationController
        protect_from_forgery with: :null_session
        # Add authentication/authorization as needed
      end
    end
  end
end