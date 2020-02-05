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

    # |> Repo.preload([:source_transaction])
    # |> Repo.preload([:destination_transaction])
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

    # |> Repo.preload([:source_transaction])
    # |> Repo.preload([:destination_transaction])
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
    |> Account.changeset_update(attrs)
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
      {:error, :invalid_amount}

  """
  def withdraw(source_account_id, amount) do
    amount = Decimal.cast(amount)

    # check if amount is valid (> 0.00)
    if Decimal.cmp(amount, Decimal.cast(0.00)) === :gt do
      Batches.withdraw_money(source_account_id, amount)
      |> Repo.transaction()
      |> case do
        {:ok, %{save_bank_transaction: {updated_account, _amount, transaction}}} ->
          {:ok, %{account: updated_account, transaction: transaction}}

        {:error, _, _changeset} ->
          {:error, :bad_request}

        {:error, _, err, _} ->
          {:error, err}
      end
    else
      {:error, :invalid_amount}
    end
  catch
    err ->
      if err.message do
        Logger.error(err.message)
      else
        Logger.error("#{inspect(err)}")
      end

      {:error, :bad_request}
  end

  @doc """
  Make a money transfer between two accounts.

  ## Examples

      iex> transfer(source_account_id, destination_account_id, amount)
      {:ok, %{account: %Account{}, transaction: %Transaction{}}}

      iex> transfer(source_account_id, destination_account_id, amount)
      {:error, :insufficient_balance}

      iex> transfer(not_valid_source_account_id, destination_account_id, amount)
      {:error, :source_account_not_found}

      iex> transfer(source_account_id, not_valid_destination_account_id, amount)
      {:error, :destination_account_not_found}

      iex> transfer(source_account_id, destination_account_id, bad_amount)
      {:error, :invalid_amount}

      iex> transfer(source_account_id, source_account_id, bad_amount)
      {:error, :same_account}

      iex> transfer(source_account_id, not_valid_destination_account_id, amount)
      {:error, :bad_request}

  """
  def transfer(source_account_id, destination_account_id, amount) do
    amount = Decimal.cast(amount)

    # check if amount is valid (> 0.00)
    if Decimal.cmp(amount, Decimal.cast(0.00)) === :gt do
      Batches.transfer_money(source_account_id, destination_account_id, amount)
      |> Repo.transaction()
      |> case do
        {:ok, %{save_bank_transaction: {updated_account, _amount, transaction}}} ->
          {:ok, %{account: updated_account, transaction: transaction}}

        {:error, _, _changeset} ->
          {:error, :bad_request}

        {:error, _, err, _} ->
          {:error, err}
      end
    else
      {:error, :invalid_amount}
    end
  catch
    err ->
      if err.message do
        Logger.error(err.message)
      else
        Logger.error("#{inspect(err)}")
      end

      {:error, :bad_request}
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
    |> Repo.preload(:source_account)
    |> Repo.preload(:destination_account)
  end

  @doc """
  Returns the list of transactions given Account ID.

  ## Examples

      iex> list_transactions_by_account(account_id)
      [%Transaction{}, ...]

  """
  def list_transactions_by_account(account_id) do
    query =
      from(transaction in Transaction,
        where: [source_account_id: ^account_id],
        or_where: [destination_account_id: ^account_id]
      )

    Repo.all(query)
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

  @doc """
  Returns Sum of Transactions value field.

  If no transactions, return nil

  ## Examples

      iex> total_transactions()
      [1150.0]

      iex> total_transactions()
      nil

  """
  def total_transactions do
    query = from t in Transaction, select: sum(t.value)

    Repo.all(query)
  end

  @doc """
  Returns Array of Sums of Transactions value grouped by given period in [day, month, year].

  If no transactions, return []

  ## Examples

      iex> total_transactions(:day)
      [{date: "2020-02-02", total: 125.20}, ...]

      iex> total_transactions(:day)
      []

  """
  def total_transactions(period) do
    query =
      Transaction
      |> order_by([a, p], desc: fragment("rounded_date"))
      |> group_by([a, p], [fragment("rounded_date"), fragment("date")])
      |> (fn q ->
            case period do
              :year ->
                q
                |> select([a, p], %{
                  date: fragment("to_char(?, 'YYYY') as date", a.inserted_at),
                  inserted_at: fragment("date_trunc('year', ?) as rounded_date", a.inserted_at),
                  total: sum(a.value)
                })

              :month ->
                q
                |> select([a, p], %{
                  date: fragment("to_char(?, 'YYYY-MM') as date", a.inserted_at),
                  inserted_at: fragment("date_trunc('month', ?) as rounded_date", a.inserted_at),
                  value: sum(a.value)
                })

              :day ->
                q
                |> select([a, p], %{
                  date: fragment("to_char(?, 'YYYY-MM-DD') as date", a.inserted_at),
                  inserted_at: fragment("date_trunc('day', ?) as rounded_date", a.inserted_at),
                  value: sum(a.value)
                })
            end
          end).()

    query
    |> Repo.all()
    |> Enum.map(fn monthly_result -> Map.delete(monthly_result, :inserted_at) end)
  end
end
