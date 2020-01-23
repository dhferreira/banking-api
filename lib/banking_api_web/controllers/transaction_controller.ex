defmodule BankingApiWeb.TransactionController do
  use BankingApiWeb, :controller

  alias BankingApi.Banking
  alias BankingApi.Banking.Transaction

  action_fallback BankingApiWeb.FallbackController

  def index(conn, _params) do
    transactions = Banking.list_transactions()
    render(conn, "index.json", transactions: transactions)
  end

  def create(conn, %{"transaction" => transaction_params}) do
    with {:ok, %Transaction{} = transaction} <- Banking.create_transaction(transaction_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.transaction_path(conn, :show, transaction))
      |> render("show.json", transaction: transaction)
    end
  end

  def show(conn, %{"id" => id}) do
    transaction = Banking.get_transaction!(id)
    render(conn, "show.json", transaction: transaction)
  end

  def update(conn, %{"id" => id, "transaction" => transaction_params}) do
    transaction = Banking.get_transaction!(id)

    with {:ok, %Transaction{} = transaction} <- Banking.update_transaction(transaction, transaction_params) do
      render(conn, "show.json", transaction: transaction)
    end
  end

  def delete(conn, %{"id" => id}) do
    transaction = Banking.get_transaction!(id)

    with {:ok, %Transaction{}} <- Banking.delete_transaction(transaction) do
      send_resp(conn, :no_content, "")
    end
  end
end