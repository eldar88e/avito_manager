namespace :avito do
  get '/dashboard', to: 'dashboard#index'
  get '/reports', to: 'reports#index'
  get '/reports/:id', to: 'reports#show'
  get '/items', to: 'items#index'
  get '/autoload/edit', to: 'autoload#edit'
  patch '/autoload', to: 'autoload#update'
  get '/autoload', to: 'autoload#show'
  post '/autoload/update_ads', to: 'autoload#update_ads'

  post '/webhooks/receive', to: 'webhooks#receive'
  resources :chats, only: %i[index show create]
  resources :reviews, only: %i[index edit update destroy]
  resources :settings, only: %i[index update]
end
