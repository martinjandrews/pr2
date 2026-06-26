Rails.application.routes.draw do
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
