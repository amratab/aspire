Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  resources :users, param: :_username
  post '/auth/login', to: 'authentication#login'

  resources :loans, only: %i[index create] do
    member do
      put 'approve'
    end
    resources :installments, only: %i[index] do
      put 'pay'
    end
  end

  
end
