Rails.application.routes.draw do
  get 'welcome/docs'
  get 'welcome/index'
  devise_for :users
  
  root to: 'welcome#index'

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  devise_scope :user do
    get 'login', to: 'devise/sessions#new'
  end

  devise_scope :user do
    delete 'logout', to: 'devise/sessions#destroy'
  end

  get 'command/enter'
  post 'command/show_data'
end
