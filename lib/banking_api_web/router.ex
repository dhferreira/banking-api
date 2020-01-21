defmodule BankingApiWeb.Router do
  use BankingApiWeb, :router

  pipeline :auth do
    plug BankingApiWeb.Auth.Pipeline
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
    resources "/users", UserController, except: [:new, :edit, :create]
  end
end
