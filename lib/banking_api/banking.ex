defmodule BankingApi.Banking do
  @moduledoc """
  The Banking context.
  """

  import Ecto.Query, warn: false
  alias BankingApi.Banking.Account
  alias BankingApi.Banking.Transaction
  alias BankingApi.Repo
  alias Ecto.Multi

  require Logger

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts()
      [%Account{}, ...]

  """
  def list_accounts do
    Repo.all(Account)
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
  def get_account!(id), do: Repo.get!(Account, id)

  @doc """
  Creates an account.

  ## Examples

      iex> create_account(%User{}, %{field: value})
      {:ok, %Account{}}

      iex> create_account(%User{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(user, attrs \\ %{}) do
    %Account{balance: attrs.balance, user_id: user.id}
    #|> Account.changeset(attrs)
    #|> Account.changeset(%{user_id: user.id})
    #|> Ecto.Changeset.put_assoc(:user, user)
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
      {:ok, %Account{}}

      #Insufficient Balance
      iex> withdraw(account)
      {:error, %Ecto.Changeset{}}

      iex> withdraw(account, -100.00)
      {:error, :invalid_value}

  """
  def withdraw(%Account{} = account, value) do
    #check if value is valid (> 0.00)
    if Decimal.cmp(value, Decimal.cast(0.00)) === :gt do
      value = value |> Decimal.round(2) |> Decimal.minus() #round for 2 decimal places and negative (debit)

      #prepare account balance update
      balance_updated = Decimal.add(account.balance, value)
      account_changeset = Account.changeset(account, %{balance: balance_updated})

      #prepare account transaction details
      transaction = %{
        value: value,
        description:  "SAQUE",
        account_id: account.id
      }
      transaction_changeset = Transaction.changeset(%Transaction{}, transaction)

      #persists in DB
      Multi.new()
      |> Multi.insert(:transaction, transaction_changeset)
      |> Multi.update(:account, account_changeset)
      |> Repo.transaction()
    else
      {:error, :invalid_value}
    end
  end

  def transfer(%Account{} = source, %Account{} = destination, value) do
    if Decimal.cmp(value, Decimal.cast(0.00)) === :gt do
      value = value |> Decimal.round(2) #round for 2 decimal places

      #Debit value from source account
      source_balance_updated = Decimal.add(source.balance, Decimal.minus(value))
      source_changeset = Account.changeset(source, %{balance: source_balance_updated}) #validate if new balance is >= 0.00

      #Credit value to destination account
      destination_balance_updated = Decimal.add(destination.balance, value)
      destination_changeset = Ecto.Changeset.change(destination, balance: destination_balance_updated) #doesn't validate balance because value alway be >= 0.00

       #prepare account transaction details
       transaction = %{
        value: Decimal.minus(value),
        description:  "TRANSFERENCIA ENTRE CONTAS",
        account_id: source.id
      }
      transaction_changeset = Transaction.changeset(%Transaction{}, transaction)

      #persists in DB
      Multi.new()
      |> Multi.insert(:transaction, transaction_changeset)
      |> Multi.update(:source_account, source_changeset)
      |> Multi.update(:destination_account, destination_changeset)
      |> Repo.transaction()
    else
      {:error, :invalid_value}
    end
  end

  alias BankingApi.Banking.Transaction

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
