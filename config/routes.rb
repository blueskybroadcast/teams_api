# frozen_string_literal: true

TeamsApi::Engine.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :teams do
        resources :memberships, controller: 'team_memberships'
      end

      post 'accept_invitation', to: 'invitations#accept'
    end
  end
end
