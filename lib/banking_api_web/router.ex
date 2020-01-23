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
    post "/users/signin", UserController, :signin
    post "/users/", UserController, :create
  end

  scope "/api", BankingApiWeb do
    pipe_through [:api, :auth]
    get "/users", UserController, :show_signedin_user
    get "/user", UserController, :show_signedin_user
    post "/account/withdraw", AccountController, :withdraw
    post "/account/transfer", AccountController, :transfer
  end

  scope "/api/backoffice", BankingApiWeb do
    pipe_through [:api, :auth, :admin]
    resources "/users", UserController, except: [:new, :edit]
    resources "/account", UserController, except: [:new, :edit]
  end

end
