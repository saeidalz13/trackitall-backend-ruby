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
  get 'is-session-valid', to: 'users#session_valid?'

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
  get '/ai/job-insight', to: 'ai#new_ai_insight'
  get '/ai/iq-response-suggestion', to: 'ai#new_interview_question_response_suggestion'
  get '/ai/tech-questions', to: 'ai#new_technical_questions'
  get '/ai/get-hint-tc', to: 'ai#new_tech_challenge_hint'

  # FileSystem
  get '/fs/resume', to: 'fs#show'
  post '/fs/resume', to: 'fs#new'
  delete '/fs/resume', to: 'fs#destroy'

  # Technical Challenges
  get '/technical-challenges', to: 'technical_challenge#index'

  # Root
  root to: 'main#index'
end
