defmodule BankingApi.Bank.Batches do
  import Ecto.Query

  alias BankingApi.Bank.Account
  alias BankingApi.Bank.Transaction
  alias BankingApi.Repo
  alias Ecto.Multi

  # PREPARE DB TRANSACTION FOR WITHDRAW MONEY
  def withdraw_money(account_id, amount) do
    amount = amount |> Decimal.round(2)

    Multi.new()
    |> Multi.run(:get_account, get_account(account_id))
    |> Multi.run(:verify_balance, verify_balance(amount))
    |> Multi.run(:subtract_from_account, &subtract_from_account/2)
    |> Multi.run(:save_bank_transaction, save_bank_transaction("SAQUE"))
  end

  # PREPARE DB TRANSACTION FOR TRANSFER MONEY
  def transfer_money(source_acc_id, destination_acc_id, amount) do
    amount = amount |> Decimal.round(2)

    Multi.new()
    |> Multi.run(:get_accounts, get_account(source_acc_id, destination_acc_id))
    |> Multi.run(:verify_balance, verify_balance_source(amount))
    |> Multi.run(:subtract_from_account, &subtract_from_account/2)
    |> Multi.run(:add_to_account, &add_to_account/2)
    |> Multi.run(:save_bank_transaction, save_bank_transaction("TRANSFERENCIA ENTRE CONTAS"))
  end

  defp get_account(account_id) do
    fn repo, _ ->
      case repo.get(Account, account_id) do
        account -> {:ok, {account}}
        _ -> {:error, :account_not_found}
      end
    end
  end

  defp get_account(source_id, destination_id) do
    fn repo, _ ->
      case from(acc in Account, where: acc.id in [^source_id, ^destination_id]) |> repo.all() do
        [source, destination] -> {:ok, {source, destination}}
        _ -> {:error, :account_not_found}
      end
    end
  end

  defp verify_balance(amount) do
    fn _repo,
      %{get_account: {account}} ->
        if account.balance < amount,
          do: {:error, :insufficient_balance},
          else: {:ok,  {account, amount}}
    end
  end

  defp verify_balance_source(amount) do
    fn _repo,
      %{get_accounts: {source, destination}} ->
        if source.balance < amount,
          do: {:error, :insufficient_balance},
          else: {:ok,  {source, destination, amount}}
    end
  end

  defp subtract_from_account(repo, %{verify_balance: {account, verified_amount}}) do
    minus_verified_amout = Decimal.minus(verified_amount)

    account
    |> Account.changeset(%{balance: Decimal.add(account.balance, minus_verified_amout)})
    |> repo.update()
  end

  defp subtract_from_account(repo, %{verify_balance: {source, destination, verified_amount}}) do
    minus_verified_amout = Decimal.minus(verified_amount)

    source
    |> Account.changeset(%{balance: Decimal.add(source.balance, minus_verified_amout)})
    |> repo.update()
    |> case do
      {:ok, updated_source} -> {:ok, {updated_source, destination, verified_amount}}
      {:error, changeset} -> {:error, :subtract_from_account, changeset }
    end
  end

  defp add_to_account(repo, %{verify_balance: {source, destination, verified_amount}}) do
    destination
    |> Account.changeset(%{balance: Decimal.add(destination.balance, verified_amount)})
    |> repo.update()
    |> case do
      {:ok, updated_destination} -> {:ok, {source, updated_destination, verified_amount}}
      {:error, changeset} -> {:error, :add_to_account, changeset }
    end
  end

  defp save_bank_transaction(description) do
    fn repo,
      %{subtract_from_account: {source, destination, amount}} ->
        transaction = %{
          value: amount,
          description:  description,
          account_id: source.id
        }

        %Transaction{}
          |> Transaction.changeset(transaction)
          |> repo.insert()
          |> case do
            {:ok, transaction} -> {:ok, {source, amount, transaction}}
            {:error, changeset} -> {:error, :save_bank_transaction, changeset}
          end
    end
  end

  # defp save_withdraw_transaction(repo, %{subtract_from_account: {account, withdrew_amount}}) do
  #   #prepare account transaction details
  #   transaction = %{
  #     value: withdrew_amount,
  #     description:  "SAQUE",
  #     account_id: account.id
  #   }

  #   %Transaction{}
  #   |> Transaction.changeset(transaction)
  #   |> repo.insert()
  #   |> case do
  #     {:ok, transaction} -> {:ok, {account, withdrew_amount, transaction}}
  #     {:error, changeset} -> {:error, :save_withdraw_transaction, changeset}
  #   end
  # end
end