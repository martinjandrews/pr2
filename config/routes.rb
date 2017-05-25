Rails.application.routes.draw do
  resources :placings
  resources :players
  resources :editions
  resources :tournaments
  root to: 'home#index'
end
