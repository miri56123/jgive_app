Rails.application.routes.draw do
  scope "(:locale)", locale: /en|he/ do
    scope "(:currency)", currency: /usd|eur|gbp|cad/ do
      root to: "campaigns#index"

      resources :campaigns, only: [ :index, :show ] do
        resources :donations, only: [ :create ]
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
