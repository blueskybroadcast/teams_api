Rails.application.routes.draw do
  mount TeamsApi::Engine => "/teams_api"
end
