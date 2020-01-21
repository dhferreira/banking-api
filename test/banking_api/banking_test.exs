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
end
