defmodule BankingApi.Bank.Transaction do
  @moduledoc """
  Transaction Schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "transactions" do
    field :description, :string
    field :value, :decimal, precision: 8, scale: 2
    belongs_to :source_account, BankingApi.Bank.Account
    belongs_to :destination_account, BankingApi.Bank.Account
    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:description, :value, :source_account_id, :destination_account_id])
    |> validate_required([:description, :value, :source_account_id])
    |> validate_number(:value, message: "invalid value")
  end

  # defp value_to_decimal(
  #       %Ecto.Changeset{valid?: true, changes: %{value: value}} = changeset
  #     ) do
  #   value =
  #       value
  #       |> Decimal.new()
  #       |> Decimal.round(2)
  #   change(changeset, %{value: value})
  # end

  # defp value_to_decimal(changeset) do
  #   changeset
  # end
end
