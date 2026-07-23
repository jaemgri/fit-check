Rails.application.routes.draw do
  resource :session, only: [:new, :create, :destroy]
  resource :registration, only: [:new, :create]
  resource :profile, only: [:show, :update]

  resources :tryons, only: [:index, :new, :create, :show, :destroy] do
    member do
      post :regenerate
      patch :toggle_favorite
    end
  end

  root "tryons#new"
end
