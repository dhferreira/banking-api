defmodule BankingApi.Auth.User do
  @moduledoc """
  User Schema
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Argon2

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string, null: false
    field :is_active, :boolean, default: true
    field :name, :string
    field :password, :string, virtual: true
    field :password_hash, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :is_active, :password])
    |> validate_required([:name, :email, :password])
    |> validate_format(:email, ~r/^[A-Za-z0-9._-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> validate_length(:password, min: 6)
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    change(changeset, add_hash(password))
  end

  defp put_password_hash(changeset) do
    changeset
  end
end
