Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Auth
      post "auth/signup", to: "auth#signup"
      post "auth/login", to: "auth#login"

      # Profile
      get "profile", to: "profile#show"
      put "profile/loadout", to: "profile#update_loadout"
      get "players/:id/stats", to: "profile#stats"

      # Matches
      post "matches", to: "matches#create"

      # Leaderboard
      get "leaderboard", to: "leaderboard#index"

      # Admin
      get "admin/stats", to: "admin#stats"
    end
  end
end
