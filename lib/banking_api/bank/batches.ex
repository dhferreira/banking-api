defmodule BankingApi.Bank.Batches do
  alias BankingApi.Bank.Account
  alias BankingApi.Bank.Transaction
  alias Ecto.Multi

  # PREPARE DB TRANSACTION FOR WITHDRAW MONEY
  @spec withdraw_money(Ecto.UUID, Decimal.t()) :: Ecto.Multi.t()
  def withdraw_money(source_account_id, amount) do
    amount = amount |> Decimal.round(2)

    Multi.new()
    |> Multi.run(:get_accounts, get_account(source_account_id))
    |> Multi.run(:verify_balance, verify_balance_source(amount))
    |> Multi.run(:subtract_from_account, &subtract_from_account/2)
    |> Multi.run(:save_bank_transaction, save_bank_transaction("SAQUE"))
  end

  # PREPARE DB TRANSACTION FOR TRANSFER MONEY
  @spec transfer_money(Ecto.UUID, Ecto.UUID, Decimal.t()) :: Ecto.Multi.t()
  def transfer_money(source_acc_id, destination_acc_id, amount) do
    amount = amount |> Decimal.round(2)

    Multi.new()
    |> Multi.run(:get_accounts, get_account(source_acc_id, destination_acc_id))
    |> Multi.run(:verify_balance, verify_balance_source(amount))
    |> Multi.run(:subtract_from_account, &subtract_from_account/2)
    |> Multi.run(:add_to_account, &add_to_account/2)
    |> Multi.run(:save_bank_transaction, save_bank_transaction("TRANSFERENCIA ENTRE CONTAS"))
  end

  defp get_account(source_id) do
    fn repo, _ ->
      case repo.get(Account, source_id) do
        %Account{} = account -> {:ok, {account}}
        nil -> {:error, :account_not_found}
      end
    end
  end

  defp get_account(source_id, destination_id) do
    fn repo, _ ->
      if source_id !== destination_id do
        source = repo.get(Account, source_id)
        destination = repo.get(Account, destination_id)

        cond do
          source && destination !== nil -> {:ok, {source, destination}}
          source === nil -> {:error, :source_account_not_found}
          destination === nil -> {:error, :destination_account_not_found}
        end
      else
        {:error, :same_account}
      end
    end
  end

  defp verify_balance_source(amount) do
    fn _repo, %{get_accounts: accounts} ->
      source = elem(accounts, 0)

      if source.balance < amount do
        {:error, :insufficient_balance}
      else
        {:ok, Tuple.append(accounts, amount)}
      end
    end
  end

  defp subtract_from_account(repo, %{verify_balance: {source, destination, verified_amount}}) do
    case subtract(repo, source, verified_amount) do
      {:ok, updated_source} ->
        {:ok, {updated_source, destination, verified_amount}}

      {:error, changeset} ->
        {:error, :subtract_from_account, changeset}
    end
  end

  defp subtract_from_account(repo, %{verify_balance: {source, verified_amount}}) do
    case subtract(repo, source, verified_amount) do
      {:ok, updated_source} ->
        {:ok, {updated_source, verified_amount}}

      {:error, changeset} ->
        {:error, :subtract_from_account, changeset}
    end
  end

  defp subtract(repo, account, amount) do
    minus_amount = Decimal.minus(amount)

    account
    |> Account.changeset(%{balance: Decimal.add(account.balance, minus_amount)})
    |> repo.update()
  end

  defp add_to_account(repo, %{verify_balance: {source, destination, verified_amount}}) do
    case add(repo, destination, verified_amount) do
      {:ok, updated_destination} ->
        {:ok, {source, updated_destination, verified_amount}}

      {:error, changeset} ->
        {:error, :add_to_account, changeset}
    end
  end

  defp save_bank_transaction(description) do
    fn repo, %{subtract_from_account: subtract_from_account} ->
      case subtract_from_account do
        {source, amount} ->
          transaction = %{
            value: amount,
            description: description,
            source_account_id: source.id
          }

          case bank_transaction(repo, transaction) do
            {:ok, transaction} -> {:ok, {source, amount, transaction}}
            {:error, changeset} -> {:error, :save_bank_transaction, changeset}
          end

        {source, destination, amount} ->
          transaction = %{
            value: amount,
            description: description,
            source_account_id: source.id,
            destination_account_id: destination.id
          }

          case bank_transaction(repo, transaction) do
            {:ok, transaction} ->
              {:ok, {source, amount, transaction}}

            {:error, changeset} ->
              {:error, :save_bank_transaction, changeset}
          end
      end
    end
  end

  defp add(repo, account, amount) do
    account
    |> Account.changeset(%{balance: Decimal.add(account.balance, amount)})
    |> repo.update()
  end

  defp bank_transaction(repo, params) do
    %Transaction{}
    |> Transaction.changeset(params)
    |> repo.insert()
  end
end
