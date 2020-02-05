defmodule BankingApi.Auth.User do
  @moduledoc """
  User Schema

  Fields:
  - id: binary_id | UUID
  - email: string, not nil
  - password_hash: string, hash from vitual field password (min-lenght 6)
  - name: string, not nil
  - permission: string, options: [ADMIN, DEFAULT]
  - is_active: boolean
  - account: %Account{}
  - inserted_at: timestamp,
  - updated_at: timestamp
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Argon2

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string, null: false
    field :is_active, :boolean, default: true
    field :name, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :permission, :string, default: "DEFAULT"
    has_one :account, BankingApi.Bank.Account
    timestamps()
  end

  @doc """
  Prepares changeset for user creation
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :is_active, :password, :permission])
    |> sanitize()
    |> validate_required([:name, :email, :password])
    |> validate_format(:email, ~r/^[A-Za-z0-9._-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> validate_length(:name, min: 3)
    |> validate_length(:password, min: 6)
    |> validate_inclusion(:permission, ["ADMIN", "DEFAULT"])
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  @doc """
  Prepares changeset for user updating
  """
  def changeset_update(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :is_active, :password, :permission])
    |> sanitize()
    |> validate_not_nil([:name, :email])
    |> validate_format(:email, ~r/^[A-Za-z0-9._-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> validate_length(:name, min: 3)
    |> validate_length(:password, min: 6)
    |> validate_inclusion(:permission, ["ADMIN", "DEFAULT"])
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  # Sanitaze data before validations
  defp sanitize(changeset) do
    permission = get_field(changeset, :permission) || ""

    put_change(changeset, :permission, String.upcase(permission))
  end

  # Hashes given password string
  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    change(changeset, Argon2.add_hash(password))
  end

  defp put_password_hash(changeset) do
    changeset
  end

  # Validate if given fields are not nil
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
