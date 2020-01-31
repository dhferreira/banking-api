defmodule BankingApiWeb.AccountController do
  @moduledoc """
  Account Controller
  """
  use BankingApiWeb, :controller
  use PhoenixSwagger

  import Guardian.Plug

  alias BankingApi.Bank
  alias BankingApi.Bank.Account

  require Logger

  action_fallback BankingApiWeb.FallbackController

  def swagger_definitions do
    %{
      Account:
        swagger_schema do
          title("Account")
          description("An bank account of users")

          properties do
            id(:binary_id, "Unique identifier of account", required: true)
            balance(:decimal, "Account's balance", required: true)
            user_id(:binary_id, "Owner User ID", required: true)
          end

          example(%{
            id: "aa992124-d1a5-4ddc-b4e8-395902f50d77",
            balance: "1253.00",
            user_id: "01992124-d1a5-4ddc-b4e9-395905f50d77"
          })
        end,
      AccountUser:
        swagger_schema do
          title("Account with User")
          description("An bank account of users")

          properties do
            id(:binary_id, "Unique identifier of account", required: true)
            balance(:decimal, "Account's balance", required: true)
            user(Schema.ref(:User))
          end

          example(%{
            id: "aa992124-d1a5-4ddc-b4e8-395902f50d77",
            balance: "1253.00",
            user: %{
              name: "José da Silva",
              email: "jose.silva@gmail.com",
              id: "01992124-d1a5-4ddc-b4e9-395905f50d77"
            }
          })
        end,
      Accounts:
        swagger_schema do
          title("Accounts")
          description("All Accounts of the application")
          type(:array)
          items(Schema.ref(:AccountUser))
        end
    }
  end

  swagger_path :index do
    get("/backoffice/accounts")
    summary("List all accounts")
    description("Returns a list of all bank accounts. Permission needed: ADMIN")
    operation_id("list_accounts")
    response(200, "Ok", Schema.ref(:Accounts))
    tag("Backoffice")
    security([%{Bearer: []}])
  end

  def index(conn, _params) do
    accounts = Bank.list_accounts()
    render(conn, "index.json", accounts: accounts)
  end

  # def create(conn, %{"account" => account_params}) do
  #   with {:ok, %Account{} = account} <- Bank.create_account(account_params) do
  #     conn
  #     |> put_status(:created)
  #     |> put_resp_header("location", Routes.account_path(conn, :show, account))
  #     |> render("show.json", account: account)
  #   end
  # end

  swagger_path :show do
    get("/backoffice/accounts/{id}")
    summary("Get Account by ID")
    description("Returns a single account given an ID. Permission Needed: ADMIN")
    operation_id("get_account_by_id")
    response(200, "Ok", Schema.ref(:AccountUser))

    response(400, "Bad Request", Schema.ref(:Error),
      examples: %{errors: %{details: "Bad Request"}}
    )

    response(404, "Not Found", Schema.ref(:Error), examples: %{errors: %{details: "Not Found"}})
    tag("Backoffice")
    security([%{Bearer: []}])

    parameters do
      id(:path, :binary_id, "Account's ID", required: true)
    end
  end

  def show(conn, %{"id" => id}) do
    account = Bank.get_account!(id)
    render(conn, "show.json", account: account)
  end

  swagger_path :show_current_account do
    get("/account")
    summary("Get current Account")
    description("Returns the account of the logged in user")
    operation_id("get_current_account")
    response(200, "Ok", Schema.ref(:AccountUser))

    response(400, "Bad Request", Schema.ref(:Error),
      examples: %{errors: %{details: "Bad Request"}}
    )

    tag("Accounts")
    security([%{Bearer: []}])
  end

  def show_current_account(conn, _params) do
    current_user = current_resource(conn)

    account = Bank.get_account!(current_user.account.id)
    render(conn, "show.json", account: account)
  end

  swagger_path :update do
    put("/backoffice/accounts/{id}")
    summary("Update an existing Account")
    description("Updates an existing Account. Permission Needed: ADMIN")
    operation_id("update_account")
    response(200, "Ok", Schema.ref(:AccountUser))

    response(400, "Bad Request", Schema.ref(:Error),
      examples: %{errors: %{details: "Bad Request"}}
    )

    response(404, "Not Found", Schema.ref(:Error), examples: %{errors: %{details: "Not Found"}})

    response(422, "Unprocessable Entity", Schema.ref(:Error),
      examples: %{errors: %{balance: "must be greater than or equal to 0"}}
    )

    tag("Backoffice")
    security([%{Bearer: []}])

    parameters do
      id(:path, :binary_id, "Account's ID", required: true)
    end

    parameters do
      account(
        :body,
        %PhoenixSwagger.Schema{
          type: :object,
          properties: %{
            balance: %PhoenixSwagger.Schema{
              type: :number,
              description: "account's balance grater than 0"
            }
          },
          example: %{
            balance: 1253.00
          }
        },
        "Account Object",
        required: true
      )
    end
  end

  def update(conn, %{"id" => id, "account" => account_params}) do
    account = Bank.get_account!(id)

    with {:ok, %Account{} = account} <- Bank.update_account(account, account_params) do
      render(conn, "show.json", account: account)
    end
  end

  def withdraw(conn, %{"amount" => amount}) do
    try do
      current_user = current_resource(conn)

      with {:ok, %{account: account, transaction: transaction}} <-
             Bank.withdraw(current_user.account.id, amount) do
        Logger.info("Account Withdraw - Sending email to client...")
        render(conn, "show.json", %{account: account, transaction: transaction})
      end
    rescue
      err ->
        if err.message do
          Logger.error(err.message)
        else
          err |> IO.inspect() |> Logger.error()
        end

        {:error, :bad_request}
    end
  end

  def transfer(conn, %{"destination_account_id" => destination_account_id, "amount" => amount}) do
    try do
      current_user = current_resource(conn)
      source_account_id = current_user.account.id

      with {:ok, %{account: account, transaction: transaction}} <-
             Bank.transfer(source_account_id, destination_account_id, amount) do
        Logger.info("Transfer Money Between Accounts - Sending email to clients...")
        render(conn, "show.json", %{account: account, transaction: transaction})
      end
    rescue
      err ->
        if err.message do
          Logger.error(err.message)
        else
          err |> IO.inspect() |> Logger.error()
        end

        {:error, :bad_request}
    end
  end
end
