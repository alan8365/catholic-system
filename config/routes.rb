Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  namespace :api do
    resources :users, param: :_username

    post '/auth/login', to: 'authentication#login', param: :_username
  end

  get '/*a', to: 'application#not_found'

  # Defines the root path route ("/")
  # root "articles#index"
end
