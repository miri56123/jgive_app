Rails.application.routes.draw do
  root to: redirect("/campaigns/1")

  resources :campaigns, only: [ :show ] do
    resources :donations, only: [ :create ]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
