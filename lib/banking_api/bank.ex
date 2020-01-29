defmodule BankingApi.Bank do
  @moduledoc """
  The Banking context.
  """

  import Ecto.Query, warn: false
  alias BankingApi.Bank.Account
  alias BankingApi.Bank.Batches
  alias BankingApi.Bank.Transaction
  alias BankingApi.Repo

  require Logger

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts()
      [%Account{}, ...]

  """
  def list_accounts do
    Repo.all(Account)
    |> Repo.preload([:user])
    |> Repo.preload([:transaction])
  end

  @doc """
  Gets a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account!(id) do
    Repo.get!(Account, id)
    |> Repo.preload([:user])
    |> Repo.preload([:transaction])
  end

  @doc """
  Creates an account.

  ## Examples

      iex> create_account(%User{}, %{field: value})
      {:ok, %Account{}}

      iex> create_account(%User{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a account.

  ## Examples

      iex> update_account(account, %{field: new_value})
      {:ok, %Account{}}

      iex> update_account(account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account(account)
      %Ecto.Changeset{source: %Account{}}

  """
  def change_account(%Account{} = account) do
    Account.changeset(account, %{})
  end

 @doc """
  Make a witdraw from account.

  ## Examples

      iex> withdraw(account, 100.00)
      {:ok, %{account: %Account{}, transaction: %Transaction{}}}

      #Insufficient_Balance
      iex> withdraw(account, value)
      {:error, :insufficient_balance}

      iex> withdraw(not_valid_account, value)
      {:error, :account_not_found}

      iex> withdraw(account, value)
      {:error, %Changeset{}}

      iex> withdraw(account, -100.00)
      {:error, :invalid_value_withdraw}

  """
  def withdraw(account_id, amount) do
    try do
      amount = Decimal.cast(amount)

      #check if amount is valid (> 0.00)
      if Decimal.cmp(amount, Decimal.cast(0.00)) === :gt do
        Batches.withdraw_money(account_id, amount)
        |> Repo.transaction()
        |> case do
          {:ok, %{save_withdraw_transaction: {updated_account, _amount, transaction}}} ->
            {:ok, %{account: updated_account, transaction: transaction}}
          {:error, _, :account_not_found, _} -> {:error, :account_not_found}
          {:error, _, :insufficient_balance, _} -> {:error, :insufficient_balance}
          {:error, _, changeset} -> {:error, :bad_request}
        end
      else
        {:error, :invalid_value_withdraw}
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

  def transfer(source_account_id, destination_account_id, amount) do
    try do
      amount = Decimal.cast(amount)

      #check if amount is valid (> 0.00)
      if Decimal.cmp(amount, Decimal.cast(0.00)) === :gt do
        Batches.transfer_money(source_account_id, destination_account_id, amount)
        |> Repo.transaction()
        |> case do
          {:ok, %{save_bank_transaction: {updated_account, _amount, transaction}}} ->
            {:ok, %{account: updated_account, transaction: transaction}}
          {:error, _, :account_not_found, _} -> {:error, :account_not_found}
          {:error, _, :insufficient_balance, _} -> {:error, :insufficient_balance}
          {:error, _, changeset} -> {:error, :bad_request}
        end
      else
        {:error, :invalid_value}
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

  alias BankingApi.Bank.Transaction

  @doc """
  Returns the list of transactions.

  ## Examples

      iex> list_transactions()
      [%Transaction{}, ...]

  """
  def list_transactions do
    Repo.all(Transaction)
  end

  @doc """
  Gets a single transaction.

  Raises `Ecto.NoResultsError` if the Transaction does not exist.

  ## Examples

      iex> get_transaction!(123)
      %Transaction{}

      iex> get_transaction!(456)
      ** (Ecto.NoResultsError)

  """
  def get_transaction!(id), do: Repo.get!(Transaction, id)

  @doc """
  Creates a transaction.

  ## Examples

      iex> create_transaction(%{field: value})
      {:ok, %Transaction{}}

      iex> create_transaction(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_transaction(attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a transaction.

  ## Examples

      iex> update_transaction(transaction, %{field: new_value})
      {:ok, %Transaction{}}

      iex> update_transaction(transaction, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_transaction(%Transaction{} = transaction, attrs) do
    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Transaction.

  ## Examples

      iex> delete_transaction(transaction)
      {:ok, %Transaction{}}

      iex> delete_transaction(transaction)
      {:error, %Ecto.Changeset{}}

  """
  def delete_transaction(%Transaction{} = transaction) do
    Repo.delete(transaction)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking transaction changes.

  ## Examples

      iex> change_transaction(transaction)
      %Ecto.Changeset{source: %Transaction{}}

  """
  def change_transaction(%Transaction{} = transaction) do
    Transaction.changeset(transaction, %{})
  end
end