defmodule BankingApi.Bank.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field :balance, :decimal, precision: 8, scale: 2
    belongs_to :user, BankingApi.Auth.User
    has_many :transaction, BankingApi.Bank.Transaction
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
end
