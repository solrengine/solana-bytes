Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :accounts, only: [ :show ], param: :address
  post "lookup", to: "accounts#lookup", as: :lookup
  patch "network", to: "networks#update", as: :network

  # Byte Challenge game
  get "challenge", to: "challenges#show", as: :challenge
  get "challenges", to: "challenges#index", as: :challenges

  root "pages#home"
end
