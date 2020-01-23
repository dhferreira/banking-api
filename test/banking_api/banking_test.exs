defmodule BankingApi.BankingTest do
  use BankingApi.DataCase

  alias BankingApi.Banking

  describe "accounts" do
    alias BankingApi.Banking.Account

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def account_fixture(attrs \\ %{}) do
      {:ok, account} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Banking.create_account()

      account
    end

    test "list_accounts/0 returns all accounts" do
      account = account_fixture()
      assert Banking.list_accounts() == [account]
    end

    test "get_account!/1 returns the account with given id" do
      account = account_fixture()
      assert Banking.get_account!(account.id) == account
    end

    test "create_account/1 with valid data creates a account" do
      assert {:ok, %Account{} = account} = Banking.create_account(@valid_attrs)
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Banking.create_account(@invalid_attrs)
    end

    test "update_account/2 with valid data updates the account" do
      account = account_fixture()
      assert {:ok, %Account{} = account} = Banking.update_account(account, @update_attrs)
    end

    test "update_account/2 with invalid data returns error changeset" do
      account = account_fixture()
      assert {:error, %Ecto.Changeset{}} = Banking.update_account(account, @invalid_attrs)
      assert account == Banking.get_account!(account.id)
    end

    test "delete_account/1 deletes the account" do
      account = account_fixture()
      assert {:ok, %Account{}} = Banking.delete_account(account)
      assert_raise Ecto.NoResultsError, fn -> Banking.get_account!(account.id) end
    end

    test "change_account/1 returns a account changeset" do
      account = account_fixture()
      assert %Ecto.Changeset{} = Banking.change_account(account)
    end
  end

  describe "transactions" do
    alias BankingApi.Banking.Transaction

    @valid_attrs %{description: "some description", value: "120.5"}
    @update_attrs %{description: "some updated description", value: "456.7"}
    @invalid_attrs %{description: nil, value: nil}

    def transaction_fixture(attrs \\ %{}) do
      {:ok, transaction} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Banking.create_transaction()

      transaction
    end

    test "list_transactions/0 returns all transactions" do
      transaction = transaction_fixture()
      assert Banking.list_transactions() == [transaction]
    end

    test "get_transaction!/1 returns the transaction with given id" do
      transaction = transaction_fixture()
      assert Banking.get_transaction!(transaction.id) == transaction
    end

    test "create_transaction/1 with valid data creates a transaction" do
      assert {:ok, %Transaction{} = transaction} = Banking.create_transaction(@valid_attrs)
      assert transaction.description == "some description"
      assert transaction.value == Decimal.new("120.5")
    end

    test "create_transaction/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Banking.create_transaction(@invalid_attrs)
    end

    test "update_transaction/2 with valid data updates the transaction" do
      transaction = transaction_fixture()
      assert {:ok, %Transaction{} = transaction} = Banking.update_transaction(transaction, @update_attrs)
      assert transaction.description == "some updated description"
      assert transaction.value == Decimal.new("456.7")
    end

    test "update_transaction/2 with invalid data returns error changeset" do
      transaction = transaction_fixture()
      assert {:error, %Ecto.Changeset{}} = Banking.update_transaction(transaction, @invalid_attrs)
      assert transaction == Banking.get_transaction!(transaction.id)
    end

    test "delete_transaction/1 deletes the transaction" do
      transaction = transaction_fixture()
      assert {:ok, %Transaction{}} = Banking.delete_transaction(transaction)
      assert_raise Ecto.NoResultsError, fn -> Banking.get_transaction!(transaction.id) end
    end

    test "change_transaction/1 returns a transaction changeset" do
      transaction = transaction_fixture()
      assert %Ecto.Changeset{} = Banking.change_transaction(transaction)
    end
  end
end
