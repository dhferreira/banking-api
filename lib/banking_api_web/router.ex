defmodule BankingApiWeb.Router do
  use BankingApiWeb, :router
  require Logger

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BankingApiWeb do
    pipe_through :api
    resources "/users", UserController, except: [:new, :edit]
    post "/users/signin", UserController, :signin
  end
end
