defmodule BankingApiWeb.TransactionController do
  use BankingApiWeb, :controller

  import Guardian.Plug

  alias BankingApi.Bank
  # alias BankingApi.Bank.Transaction

  action_fallback BankingApiWeb.FallbackController

  def index(conn, _params) do
    transactions = Bank.list_transactions()
    render(conn, "index.json", transactions: transactions)
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
