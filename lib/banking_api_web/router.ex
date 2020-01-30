defmodule BankingApiWeb.Router do
  use BankingApiWeb, :router

  pipeline :auth do
    plug BankingApiWeb.Auth.PipelineAuth
  end

  pipeline :admin do
    plug BankingApiWeb.Auth.PipelineAdmin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BankingApiWeb do
    pipe_through :api
    post "/user/signin", UserController, :signin
    post "/user/signup", UserController, :signup
  end

  scope "/api", BankingApiWeb do
    pipe_through [:api, :auth]
    get "/user", UserController, :show_current_user
    put "/user", UserController, :update_current_user
    patch "/user", UserController, :update_current_user
    get "/account", AccountController, :show_current_account
    get "/account/transactions", TransactionController, :show_current_account_transaction
    post "/account/withdraw", AccountController, :withdraw
    post "/account/transfer", AccountController, :transfer
  end

  scope "/api/backoffice", BankingApiWeb do
    pipe_through [:api, :auth, :admin]
    resources "/users", UserController, except: [:new, :edit]
    resources "/accounts", AccountController, only: [:index, :show, :update]
    resources "/transactions", TransactionController, only: [:index]
    get "/report", TransactionController, :relatorio
  end
end
