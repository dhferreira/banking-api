defmodule BankingApi.Bank.Account do
  @moduledoc """
  Account Shema
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field :balance, :decimal, precision: 8, scale: 2
    belongs_to :user, BankingApi.Auth.User
    has_many :source_transaction, BankingApi.Bank.Transaction, foreign_key: :source_account_id

    has_many :destination_transaction, BankingApi.Bank.Transaction,
      foreign_key: :destination_account_id

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:balance, :user_id])
    |> validate_required([:balance, :user_id])
    |> validate_number(:balance, greater_than_or_equal_to: 0)
    |> unique_constraint(:user_id)
    |> balance_to_decimal()
  end

  @doc false
  def changeset_update(user, attrs) do
    user
    |> cast(attrs, [:balance, :user_id])
    |> validate_not_nil([:balance, :user_id])
    |> validate_number(:balance, greater_than_or_equal_to: 0)
    |> balance_to_decimal()
  end

  defp balance_to_decimal(%Ecto.Changeset{valid?: true, changes: %{balance: balance}} = changeset) do
    balance =
      balance
      |> Decimal.new()
      |> Decimal.round(2)

    change(changeset, %{balance: balance})
  end

  defp balance_to_decimal(changeset) do
    changeset
  end

  defp validate_not_nil(changeset, fields) do
    Enum.reduce(fields, changeset, fn field, changeset ->
      if get_field(changeset, field) == nil do
        add_error(changeset, field, "Can't be nil")
      else
        changeset
      end
    end)
  end
end
