defmodule BankingApiWeb.TransactionController do
  use BankingApiWeb, :controller
  use PhoenixSwagger

  import Guardian.Plug

  alias BankingApi.Bank
  # alias BankingApi.Bank.Transaction

  action_fallback BankingApiWeb.FallbackController

  def swagger_definitions do
    %{
      Transaction:
        swagger_schema do
          title("Transaction")
          description("An bank transaction")

          properties do
            id(:binary_id, "Unique identifier of transaction", required: true)
            description(:string, "Description of Transaction", required: true)
            destination_account_id(:binary_id, "Destination Account's ID")
            source_account_id(:binary_id, "Source Account's ID")
            value(:number, "Transaction's value")
            created_at(:timestamp, "Date of transaction")
          end

          example(%{
            created_at: "2020-01-30T13:36:53",
            description: "TRANSFERENCIA ENTRE CONTAS",
            destination_account_id: "2d19c9dd-048e-44f7-89f7-2908f4f40344",
            id: "97f5b396-84b0-487d-8501-1030aaf5eaa3",
            source_account_id: "e304961d-75db-48d5-a3bf-8930a2c1f1ec",
            value: "10.00"
          })
        end,
      Transactions:
        swagger_schema do
          title("Transactions")
          description("All Bank Transactions")
          type(:array)
          items(Schema.ref(:Transaction))
        end
    }
  end

  swagger_path :index do
    get("/backoffice/transactions")
    summary("List all transactions")
    description("Returns a list of all bank transactions. Permission needed: ADMIN")
    operation_id("list_transactions")
    response(200, "Ok", Schema.ref(:Transactions))
    tag("Backoffice")
    security([%{Bearer: []}])
  end

  def index(conn, _params) do
    transactions = Bank.list_transactions()
    render(conn, "index.json", transactions: transactions)
  end

  swagger_path :show_current_account_transaction do
    get("/account/transactions")
    summary("Get Transactions of current Account")
    description("Returns a list of transactions given the account id of the logged in user")
    operation_id("get_current_account_transactions")
    response(200, "Ok", Schema.ref(:Transactions))

    response(400, "Bad Request", Schema.ref(:Error),
      examples: %{errors: %{details: "Bad Request"}}
    )

    tag("Accounts")
    security([%{Bearer: []}])
  end

  def show_current_account_transaction(conn, _params) do
    current_user = current_resource(conn)

    transactions = Bank.list_transactions_by_account(current_user.account.id)
    render(conn, "index.json", transactions: transactions)
  end

  def relatorio(conn, _params) do
    result = %{
      total: List.first(Bank.total_transactions()),
      year: Bank.total_transactions(:year),
      month: Bank.total_transactions(:month),
      day: Bank.total_transactions(:day)
    }

    send_resp(conn, :ok, Jason.encode!(result))
  end

  # def create(conn, %{"transaction" => transaction_params}) do
  #   with {:ok, %Transaction{} = transaction} <- Bank.create_transaction(transaction_params) do
  #     conn
  #     |> put_status(:created)
  #     |> put_resp_header("location", Routes.transaction_path(conn, :show, transaction))
  #     |> render("show.json", transaction: transaction)
  #   end
  # end

  # def show(conn, %{"id" => id}) do
  #   transaction = Bank.get_transaction!(id)
  #   render(conn, "show.json", transaction: transaction)
  # end

  # def update(conn, %{"id" => id, "transaction" => transaction_params}) do
  #   transaction = Bank.get_transaction!(id)

  #   with {:ok, %Transaction{} = transaction} <-
  #          Bank.update_transaction(transaction, transaction_params) do
  #     render(conn, "show.json", transaction: transaction)
  #   end
  # end

  # def delete(conn, %{"id" => id}) do
  #   transaction = Bank.get_transaction!(id)

  #   with {:ok, %Transaction{}} <- Bank.delete_transaction(transaction) do
  #     send_resp(conn, :no_content, "")
  #   end
  # end
end
