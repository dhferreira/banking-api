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
        end,
      Report:
        swagger_schema do
          title("Report")
          description("An transactions report")

          properties do
            day(:array, "Transactional total by day",
              required: true,
              items: Schema.ref(:ReportItem)
            )

            month(:array, "Transactional total by month",
              required: true,
              items: Schema.ref(:ReportItem)
            )

            year(:array, "Transactional total by year",
              required: true,
              items: Schema.ref(:ReportItem)
            )

            total(:number, "Transactional total over time", required: true)
          end

          example(%{
            day: [
              %{
                date: "2020-01-30",
                value: "200.00"
              },
              %{
                date: "2020-01-16",
                value: "150.00"
              }
            ],
            month: [
              %{
                date: "2020-01",
                value: "350.00"
              }
            ],
            total: "350.00",
            year: [
              %{
                date: "2020",
                total: "350.00"
              }
            ]
          })
        end,
      ReportItem:
        swagger_schema do
          title("ReportItem")
          description("An transactions report item")

          properties do
            date(:string, "String representation of the date", required: true)
            value(:number, "Trasactional total for the given date", required: true)
          end
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

    tag("Account")
    security([%{Bearer: []}])
  end

  def show_current_account_transaction(conn, _params) do
    current_user = current_resource(conn)

    transactions = Bank.list_transactions_by_account(current_user.account.id)
    render(conn, "index.json", transactions: transactions)
  end

  swagger_path :transactions_report do
    get("/backoffice/report")
    summary("Get Transactional Report")

    description(
      "Returns a report of Total of Transactions by year, month, day, and over all time. Permission needed: ADMIN"
    )

    operation_id("get_transactions_report")

    response(200, "Ok", Schema.ref(:Report),
      example: %{
        day: [
          %{
            date: "2020-01-30",
            value: "200.00"
          },
          %{
            date: "2020-01-16",
            value: "150.00"
          }
        ],
        month: [
          %{
            date: "2020-01",
            value: "350.00"
          }
        ],
        total: "350.00",
        year: [
          %{
            date: "2020",
            total: "350.00"
          }
        ]
      }
    )

    response(400, "Bad Request", Schema.ref(:Error),
      examples: %{errors: %{details: "Bad Request"}}
    )

    tag("Backoffice")
    security([%{Bearer: []}])
  end

  def transactions_report(conn, _params) do
    result = %{
      total: List.first(Bank.total_transactions()) || "0.00",
      year: Bank.total_transactions(:year),
      month: Bank.total_transactions(:month),
      day: Bank.total_transactions(:day)
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: result}))
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
