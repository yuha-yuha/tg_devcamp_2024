Rails.application.routes.draw do

  root 'users#new'
  get '/after_login', to: 'static_pages#after_login'

  resource :user, only: %i[new create]
  resources :posts
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  post 'callback' => 'line_bot#callback'

  # Defines the root path route ("/")
  # root "posts#index"
end
