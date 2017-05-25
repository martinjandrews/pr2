Rails.application.routes.draw do
  devise_for :users
  resources :placings
  resources :players
  resources :editions
  resources :tournaments
  root to: 'home#index'
end
