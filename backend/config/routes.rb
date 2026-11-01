Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'health', to: 'sessions#health'
      get 'auth/csrf', to: 'sessions#csrf'
      post 'auth/login', to: 'sessions#login'
      delete 'auth/logout', to: 'sessions#logout'
      get 'me', to: 'sessions#me'
      get 'organizations', to: 'sessions#organizations'
      resources :tickets, only: [:index, :show, :create, :update] do
        resources :comments, only: [:index, :create]
        get 'events', to: 'ticket_events#index'
      end
      get 'dashboard/summary', to: 'dashboard#summary'
      resources :notifications, only: [:index] do
        patch 'read', on: :member
      end
      resources :memberships, only: [:index, :create, :update]
      resources :categories, only: [:index, :create, :update]
      resources :sla_policies, only: [:index, :update], param: :priority
    end
  end
end
