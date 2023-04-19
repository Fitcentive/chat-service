defmodule Chat.Schema.UserLastSeen do
  use Ecto.Schema
  alias Chat.Schema.UserLastSeen

  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]

  @primary_key false
  schema "user_last_seen" do
    field :user_id, Ecto.UUID, primary_key: true
    field :room_id, Ecto.UUID, primary_key: true
    field :last_seen, :utc_datetime

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

    room_user
    |> cast(params, [:room_id, :user_id])
    |> validate_required([:room_id, :user_id])
    |> put_change(:last_seen, time)
    |> put_change(:created_at, time)
    |> put_change(:updated_at, time)
  end

end