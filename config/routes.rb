Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  post "/signup", to: "users#signup"
  post "/login", to: "users#login"
  delete "/users/:id", to: "users#destroy"

  get "/oauth2-auth-server-uri", to: "users#send_auth_server"
  get "/#{ENV["OAUTH_REDIRECT_ROUTE"]}", to: "users#google_redirect_oauth2"

  root to: "main#index"
end
