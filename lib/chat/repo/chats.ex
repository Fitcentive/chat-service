defmodule Chat.Repo.Chats do
  import Ecto.Query, warn: false

  alias Chat.Repo

  alias Chat.Schema.Message
  alias Chat.Schema.MessageMetadata
  alias Chat.Schema.Room
  alias Chat.Schema.RoomUser
  alias Chat.Schema.User

  defp room_changeset(room_params) do
    Room.changeset(
      %Room{},
      Map.merge(room_params, %{})
    )
  end

  defp user_changeset(user_params) do
    User.changeset(
      %User{},
      Map.merge(user_params, %{})
    )
  end

  defp message_changeset(message_params) do
    Message.changeset(
      %Message{},
      Map.merge(message_params, %{})
    )
  end

  defp message_metadata_changeset(message_metadata_params) do
    MessageMetadata.changeset(
      %MessageMetadata{},
      Map.merge(message_metadata_params, %{})
    )
  end

  defp room_user_changeset(room_user_params) do
    RoomUser.changeset(
      %RoomUser{},
      Map.merge(room_user_params, %{})
    )
  end

  def upsert_user(user_params) do
    Repo.insert!(
      user_changeset(user_params),
      on_conflict: {:replace, [:updated_at, :is_active, :first_name, :last_name]},
      conflict_target: :id,
      returning: true,
    )
  end

  def upsert_room(room_params) do
    Repo.insert!(
      room_changeset(room_params),
      on_conflict: {:replace, [:updated_at, :name]},
      conflict_target: :id,
      returning: true,
    )
  end

  def create_message_metadata(message_metadata_params) do
    Repo.insert!(
      message_metadata_changeset(message_metadata_params),
      on_conflict: {:replace, [:updated_at, :image_url]},
      conflict_target: :message_id,
      returning: true,
    )
  end

  def upsert_room_user(room_user_params) do
    Repo.insert!(
      room_user_changeset(room_user_params),
      on_conflict: :nothing,
      returning: true,
    )
  end

  def create_message(message_params) do
    Repo.insert!(
      message_changeset(message_params),
      returning: true,
    )
  end

  def get_messages(room_id) do
    query = from message in Message,
                 select: message,
                 where: message.room_id == ^room_id,
                 distinct: true

    query
    |> Repo.all
  end


end