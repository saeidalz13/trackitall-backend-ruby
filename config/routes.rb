Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Auth and users
  post '/signup', to: 'users#signup'
  post '/login', to: 'users#login'
  delete '/signout', to: 'users#signout'
  delete '/users/:id', to: 'users#destroy'
  get '/oauth2-auth-server-uri', to: 'users#send_auth_server'
  get "/#{ENV['OAUTH_REDIRECT_ROUTE']}", to: 'users#google_redirect_oauth2'
  get 'is-session-valid', to: 'users#is_session_valid'

  # Jobs
  get '/jobs', to: 'job#index'
  get '/jobs/:id', to: 'job#show'
  post '/jobs', to: 'job#new'
  delete '/jobs/:id', to: 'job#destroy'
  patch '/jobs/:id', to: 'job#update'

  # Interview
  get '/interview-questions', to: 'interview_question#show'
  patch '/interview-questions/:id', to: 'interview_question#update'

  # AI
  get '/ai/job-insight', to: 'ai#get_ai_insight'

  # Root
  root to: 'main#index'
end
