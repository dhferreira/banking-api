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
    resources "/users", UserController, except: [:new, :edit, :delete]
    # Fix incompatibility with PhoenixSwagger
    delete "/users/:id", UserController, :delete_user
    resources "/accounts", AccountController, only: [:index, :show, :update]
    resources "/transactions", TransactionController, only: [:index]
    get "/report", TransactionController, :transactions_report
  end

  scope "/doc" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI,
      otp_app: :banking_api,
      swagger_file: "swagger.json",
      disable_validator: true
  end

  def swagger_info do
    schemes = if System.get_env("MIX_ENV") === "prod", do: ["https"], else: ["http"]

    %{
      info: %{
        version: "1.0",
        title: "Banking API",
        description: "Banking API built in Elixir",
        contact: %{
          email: "dhferreira.ibm@gmail.com"
        }
      },
      basePath: "/api",
      schemes: schemes,
      securityDefinitions: %{
        Bearer: %{
          type: :apiKey,
          name: "Authorization",
          in: :header
        }
      }
    }
  end
end
