require 'sidekiq/web'
Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/add-requests-in-queue', to: 'pages#add_requests_in_queue'
  mount Sidekiq::Web => '/sidekiq'    

end


