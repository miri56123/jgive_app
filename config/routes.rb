Rails.application.routes.draw do
  root to: "campaigns#index"

  resources :campaigns, only: [ :index, :show ] do
    resources :donations, only: [ :create ]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
