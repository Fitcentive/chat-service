defmodule Chat.Repo.Chats do
  import Ecto.Query, warn: false

  alias Chat.Repo
  alias Ecto.Multi

  alias Chat.Schema.Message
  alias Chat.Schema.MessageMetadata
  alias Chat.Schema.Room
  alias Chat.Schema.RoomUser
  alias Chat.Schema.User

  alias Chat.Repo.Chats

  @behaviour Bodyguard.Policy

  def authorize(:get_room_messages, user_id, room_id) do
    case Chats.get_room_user_if_exists(room_id, user_id) do
      nil -> :error
      _   -> :ok
    end

  end

  # Otherwise, denied
  def authorize(:update_post, _user, _post), do: :error


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

  #------------------------------------------------------------------------------------------------------------

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

  def upsert_room_user(room_user_params) do
    Repo.insert!(
      room_user_changeset(room_user_params),
      on_conflict: {:replace, [:updated_at]},
      conflict_target: [:room_id, :user_id],
      returning: true,
    )
  end

  def create_message(message_params) do
    Repo.insert!(
      message_changeset(message_params),
      returning: true,
    )
  end

  def create_message_metadata(message_metadata_params) do
    Repo.insert!(
      message_metadata_changeset(message_metadata_params),
      on_conflict: {:replace, [:updated_at, :image_url]},
      conflict_target: :id,
      returning: true,
    )
  end

  # Todo - replace with with Ecto.Multi
  def create_message_with_metadata(%{
    "sender_id" => user_id,
    "room_id" => room_id,
    "text" => text,
    "image_url" => image_url,
  }) do
    with new_message <- create_message(%{
      "sender_id" => user_id,
      "room_id" => room_id,
      "text" => text,
    }) do
      create_message_metadata(%{
        "message_id" => new_message.id,
        "image_url" => image_url
      })
    end
  end

  def get_messages(room_id) do
    query =
      from message in Message,
        left_join: message_metadata in MessageMetadata,
        on: message.id == message_metadata.message_id,
        select: %{
          id: message.id,
          sender_id: message.sender_id,
          room_id: message.sender_id,
          text: message.text,
          created_at: message.created_at,
          updated_at: message.updated_at,
          image_url: message_metadata.image_url,
        },
        where: message.room_id == ^room_id,
        distinct: true

    query
    |> Repo.all
  end

  def get_room_user_if_exists(room_id, user_id) do
    query =
      from room_user in RoomUser,
      select: room_user,
      where: room_user.room_id == ^room_id and room_user.user_id == ^user_id

  query
    |> Repo.one

  end

end