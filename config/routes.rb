Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :accounts, only: [ :show ], param: :address
  post "lookup", to: "accounts#lookup", as: :lookup
  patch "network", to: "networks#update", as: :network

  root "pages#home"
end
