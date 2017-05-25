Rails.application.routes.draw do
  devise_for :users
  resources :placings
  resources :players
  resources :editions
  resources :tournaments
  get 'rankings', to: 'rankings#index'
  root to: 'home#index'
end
