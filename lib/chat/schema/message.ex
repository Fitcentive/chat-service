defmodule Chat.Schema.Message do
  use Ecto.Schema
  alias Chat.Schema.Message

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "message" do
    field :sender_id, Ecto.UUID
    field :room_id, Ecto.UUID
    field :text, :string

    has_one :metadata, Chat.Schema.MessageMetadata

    belongs_to :room,
               Chat.Schema.Room,
               foreign_key: :room_id, define_field: false
    belongs_to :user,
               Chat.Schema.User,
               foreign_key: :sender_id, define_field: false

    timestamps(inserted_at: :created_at)
  end

  def changeset(message, params \\ %{}) do
    time =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)

    #  Not validating the column 'value' to allow empty strings to be stored as Attribute Values
    #  Ecto validate_required/3 throw errors and remove the column when an empty string
    #  Also setting the list of empty_values in cast/4 to not consider "" as empty. By default it is [""]
    message
    |> cast(params, [:sender_id, :room_id, :text])
    |> validate_required([:sender_id, :room_id, :text])
    |> put_change(:created_at, time)
    |> put_change(:updated_at, time)
  end

end