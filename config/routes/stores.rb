resources :stores do
  draw :avito
  get '/avito', to: 'avito/dashboard#index'

  post '/update_feed', to: 'jobs#update_feed', as: 'update_feed'
  post '/update_ban_list', to: 'jobs#update_ban_list'
  patch '/update_promotion', to: 'jobs#update_promotion'
  delete '/stop_promotion', to: 'jobs#stop_promotion'
  post '/update_store_test_img', to: 'jobs#update_store_test_img'
  patch '/update_all', to: 'ads#update_all'

  resources :streets, only: %i[index create update destroy]
  resources :maps, only: [:show]
  resources :addresses, only: %i[new create show update destroy]
  resources :ads, only: %i[edit update]
end
