defmodule Chat.Schema.MessageMetadata do
  use Ecto.Schema
  alias Chat.Schema.MessageMetadata

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "message_metadata" do
    field :message_id, Ecto.UUID
    field :image_url, :string

    belongs_to :message,
               Chat.Schema.Message,
               foreign_key: :message_id, define_field: false
    timestamps(inserted_at: :created_at)
  end

  def changeset(message_metadata, params \\ %{}) do
    time =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)

    message_metadata
    |> cast(params, [:message_id, :image_url])
    |> validate_required([:message_id])
    |> put_change(:created_at, time)
    |> put_change(:updated_at, time)
  end

end