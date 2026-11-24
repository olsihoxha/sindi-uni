Rails.application.routes.draw do
  root "welcome#index"
  get "welcome", to: "welcome#index"
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "dashboard", to: "dashboard#index"
  resource :profile, only: %i[edit update]
  resources :students
  resources :courses do
    get :statistics, on: :member
    resources :assessments, except: %i[index show]
    resources :enrollments, only: %i[index create destroy] do
      resources :grades, except: :show
    end
  end
  namespace :api do
    namespace :v1 do
      resources :students
      get "transcripts", to: "transcripts#show"
      get "transcripts/:student_id", to: "transcripts#show"
      post "grades", to: "grades#create"
    end
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
