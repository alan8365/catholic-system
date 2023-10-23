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
    resources :regular_donations, param: :_id
    resources :events, param: :_id
    resources :special_donations, param: :_id

    get 'parishioners/:_id/picture', to: 'parishioners#picture', param: :_id
    get 'parishioners/:_id/card', to: 'parishioners#id_card', param: :_id
    get 'parishioners/:_id/card_back', to: 'parishioners#id_card_back', param: :_id
    get 'parishioners/:_id/certificate', to: 'parishioners#certificate', param: :_id

    post 'id-cards', to: 'parishioners#id_card_pdf'

    get 'report/all_donations/year', to: 'reports#ad_yearly_report'
    get 'report/regular_donations/month', to: 'reports#rd_monthly_report'
    get 'report/regular_donations/year', to: 'reports#rd_yearly_report'
    get 'report/regular_donations/receipt', to: 'reports#receipt_register'
    get 'report/special_donations/event', to: 'reports#sd_event_report'
    get 'report/special_donations/year', to: 'reports#sd_yearly_report'
    post 'report/parishioner', to: 'reports#parishioner_report'
    post 'report/regular_donations', to: 'reports#rd_report'
    post 'report/special_donations', to: 'reports#sd_report'
  end

  get '/*a', to: 'application#not_found'
end
