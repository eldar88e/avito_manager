Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'registrations' }
  get 'up' => 'rails/health#show', as: :rails_health_check

  authenticate :user do
    mount SolidQueueDashboard::Engine, at: '/solid-queue'
    mount PgHero::Engine, at: '/pghero'
  end

  get 'manifest' => 'rails/pwa#manifest', as: :pwa_manifest
  get 'service-worker' => 'rails/pwa#service_worker', as: :pwa_service_worker # if Rails.env.production?

  root 'feeds#index'

  resources :ad_imports, only: %i[index show destroy]
  resources :settings, only: %i[index create update]
  resources :avitos, only: [:index]
  resources :image_layers, only: %i[new create show update destroy]
  post '/update_img', to: 'jobs#update_img'
  get '/feeds', to: 'feeds#index'

  draw :stores

  match '*unmatched', to: 'pwa#not_found', via: :all,
                      constraints: ->(req) { !req.path.start_with?('/rails/active_storage') }
end
