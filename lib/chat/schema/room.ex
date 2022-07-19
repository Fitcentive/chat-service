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

    timestamps(inserted_at: :created_at)
  end

  def changeset(room, params \\ %{}) do
    time = DateTime.utc_now()
           |> DateTime.truncate(:second)

    #  Not validating the column 'value' to allow empty strings to be stored as Attribute Values
    #  Ecto validate_required/3 throw errors and remove the column when an empty string
    #  Also setting the list of empty_values in cast/4 to not consider "" as empty. By default it is [""]
    room
    |> cast(params, [:id, :name, :type])
    |> validate_required([:id, :type])
    |> put_change(:created_at, time)
    |> put_change(:updated_at, time)
  end

end