# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  namespace :api do
    resources :users, param: :_username

    post '/auth/login', to: 'authentication#login', param: :_username

    resources :households, param: :_home_number
    resources :parishioners, param: :_id
    resources :baptisms, param: :_parishioner_id
    resources :confirmations, param: :_parishioner_id
    resources :eucharists, param: :_parishioner_id
    resources :marriages, param: :_id

    get 'parishioners/:_id/picture', to: 'parishioners#picture', param: :_id
  end

  get '/*a', to: 'application#not_found'

  # Defines the root path route ("/")
  # root "articles#index"
end
