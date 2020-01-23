defmodule BankingApi.Banking.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "transactions" do
    field :description, :string
    field :value, :decimal, precision: 8, scale: 2
    belongs_to :account, BankingApi.Banking.Account
    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:description, :value, :account_id])
    |> validate_required([:description, :value, :account_id])
    |> validate_number(:value, message: "invalid value")
  end
end
