defmodule Chat.Schema.RoomUser do
  use Ecto.Schema
  alias Chat.Schema.RoomUser

  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]

  @primary_key false
  schema "room_user" do
    field :room_id, Ecto.UUID, primary_key: true
    field :user_id, Ecto.UUID, primary_key: true

    belongs_to :room,
               Chat.Schema.Room,
               foreign_key: :room_id, define_field: false
    belongs_to :user,
               Chat.Schema.User,
               foreign_key: :user_id, define_field: false

    timestamps(inserted_at: :created_at)
  end

  def changeset(room_user, params \\ %{}) do
    time = DateTime.utc_now()
           |> DateTime.truncate(:second)

    #  Not validating the column 'value' to allow empty strings to be stored as Attribute Values
    #  Ecto validate_required/3 throw errors and remove the column when an empty string
    #  Also setting the list of empty_values in cast/4 to not consider "" as empty. By default it is [""]
    room_user
    |> cast(params, [:room_id, :user_id])
    |> validate_required([:room_id, :user_id])
    |> put_change(:created_at, time)
    |> put_change(:updated_at, time)
  end

end