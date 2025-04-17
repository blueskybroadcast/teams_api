TeamsApi::Engine.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :teams, only: [:index, :show, :create, :update, :destroy]
    end
  end
end