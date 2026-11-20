Rails.application.routes.draw do
  # Public auth
  get  "signup", to: "registrations#new"
  post "signup", to: "registrations#create"
  resource :session, only: %i[new create destroy]

  # Authenticated area
  root "dashboard#index"

  resources :products do
    patch :adjust_stock, on: :member
  end
  resources :categories
  resources :customers
  resources :suppliers
  resources :purchases
  resources :expenses, except: %i[ show ]
  resources :payables, only: %i[ index new create ], controller: "supplier_payments"
  resources :imports, only: %i[new create] do
    collection do
      get :template
    end
  end
  resources :payments, only: %i[index new create]
  resource :settings, only: %i[edit update]
  resources :employees, controller: "users", only: %i[index new create]
  resources :sales do
    patch :cancel, on: :member
    get :ticket, on: :member
    resources :returns, only: %i[new create]
  end
  resources :stock_movements, only: %i[index new create]
  resources :cash_counts, only: %i[ index create ]
  resources :reports, only: [] do
    collection do
      get :daily_cash
      get :sales_report
      get :profit
      get :stock
    end
  end
  resources :dashboard, only: :index

  # Reveal health status on /up
  get "up" => "rails/health#show", as: :rails_health_check
end