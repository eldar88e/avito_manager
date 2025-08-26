Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'registrations' }
  get 'up' => 'rails/health#show', as: :rails_health_check

  get 'manifest' => 'rails/pwa#manifest', as: :pwa_manifest
  get 'service-worker' => 'rails/pwa#service_worker', as: :pwa_service_worker if Rails.env.production?

  root 'feeds#index'

  resources :stores
  resources :ad_imports, only: %i[index show destroy]
  resources :settings, only: %i[index create update]
  resources :avitos, only: [:index]

  resources :stores do
    draw :avito

    get '/avito', to: 'avito/dashboard#index'
  end
end
