Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :players, only: [:index, :show]
      resources :tournaments, only: [:index, :show]
      resources :editions, only: [:index, :show]
      get 'rankings', to: 'rankings#index'
    end
  end

  devise_for :users
  resources :placings
  resources :players do
    member do
      get  :merge
      post :merge
    end
  end
  resources :editions
  resources :tournaments
  get 'rankings', to: 'rankings#index'
  get 'export', to: 'home#export'
  root to: 'home#index'
end
