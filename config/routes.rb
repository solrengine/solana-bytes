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

  # Learn hub (replaces /types — U15)
  get "learn", to: "learn#index", as: :learn
  get "learn/:slug", to: "learn#show", as: :learn_type, constraints: { slug: /[a-z][a-z0-9-]*/ }

  # Legacy /types route: 301 redirect to /learn for SEO continuity.
  get "types", to: redirect("/learn", status: 301), as: :types

  # About page (U19)
  get "about", to: "pages#about", as: :about

  root "pages#home"
end
