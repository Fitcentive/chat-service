defmodule Chat.Schema.User do
  use Ecto.Schema
  alias Chat.Schema.User

  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "user" do
    field :first_name, :string
    field :last_name, :string
    field :is_active, :boolean

    timestamps(inserted_at: :created_at)
  end

  def changeset(user, params \\ %{}) do
    time = DateTime.utc_now()
           |> DateTime.truncate(:second)

    user
    |> cast(params, [:id, :first_name, :last_name, :is_active])
    |> validate_required([:id, :is_active])
    |> put_change(:created_at, time)
    |> put_change(:updated_at, time)
  end

end