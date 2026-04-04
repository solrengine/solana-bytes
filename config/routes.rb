Rails.application.routes.draw do
  mount Solrengine::Auth::Engine, at: "/auth"

  get "up" => "rails/health#show", as: :rails_health_check

  resources :accounts, only: [ :show ], param: :address
  post "lookup", to: "accounts#lookup", as: :lookup
  patch "network", to: "networks#update", as: :network

  # Byte Challenge game
  get "challenges", to: "challenges#index", as: :challenges
  get "challenge", to: "challenges#show", as: :challenge
  post "challenge/result", to: "challenges#save_result", as: :save_challenge_result

  # Leaderboard
  get "leaderboard", to: "leaderboard#index", as: :leaderboard

  # Public stats
  get "stats", to: "stats#show"

  root "pages#home"
end
