Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'registrations' }
  get 'up' => 'rails/health#show', as: :rails_health_check

  authenticate :user do
    mount SolidQueueDashboard::Engine, at: '/solid-queue'
    # mount PgHero::Engine, at: 'pghero'
  end

  get 'manifest' => 'rails/pwa#manifest', as: :pwa_manifest
  get 'service-worker' => 'rails/pwa#service_worker', as: :pwa_service_worker if Rails.env.production?

  root 'feeds#index'

  resources :stores
  resources :ad_imports, only: %i[index show destroy]
  resources :settings, only: %i[index create update]
  resources :avitos, only: [:index]
  resources :image_layers, only: %i[new create show update destroy]
  post '/update_img', to: 'jobs#update_img'
  get '/feeds', to: 'feeds#index'

  resources :stores do
    draw :avito
    get '/avito', to: 'avito/dashboard#index'

    post '/update_feed', to: 'jobs#update_feed', as: 'update_feed'
    post '/update_ban_list', to: 'jobs#update_ban_list'
    post '/update_store_test_img', to: 'jobs#update_store_test_img'
    patch '/update_all', to: 'ads#update_all'

    resources :streets, only: %i[index create update destroy]
    resources :maps, only: [:show]
    resources :addresses, only: %i[new create show update destroy]
    resources :ads, only: %i[edit update]
  end
end
