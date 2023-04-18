defmodule Chat.Schema.Room do
  use Ecto.Schema
  alias Chat.Schema.Room

  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "room" do
    field :name, :string
    field :type, :string
    field :enabled, :boolean

    timestamps(inserted_at: :created_at)
  end

  def changeset(room, params \\ %{}) do
    time = DateTime.utc_now()
           |> DateTime.truncate(:second)

    room
    |> cast(params, [:id, :name, :type, :enabled])
    |> validate_required([:id, :type])
    |> put_change(:created_at, time)
    |> put_change(:updated_at, time)
  end

end