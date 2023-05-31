defmodule ChatWeb.ChatView do
  use ChatWeb, :view

  alias ChatWeb.ChatView

  def render("show_room_definitions.json", %{rooms: rooms}) do
    render_many(rooms, ChatView, "show_room.json", as: :room)
  end

  def render("show_rooms.json", %{rooms: rooms}) do
    render_many(rooms, ChatView, "show_room_with_users.json", as: :room_with_users)
  end

  def render("show_detailed_rooms.json", %{rooms: rooms}) do
    render_many(rooms, ChatView, "show_detailed_room_with_users.json", as: :room_with_users)
  end

  def render("show_user_room_last_seens.json", %{user_room_last_seens: user_room_last_seens}) do
    render_many(user_room_last_seens, ChatView, "show_user_last_seen.json", as: :user_last_seen)
  end

  def render("show_room_with_users.json", %{room_with_users: room_with_users}) do
    %{
      room_id: UUID.binary_to_string!(room_with_users.room_id),
      user_ids: Enum.map(room_with_users.user_ids, &(UUID.binary_to_string!(&1))),
    }
  end

  def render("show_detailed_room_with_users.json", %{room_with_users: room_with_users}) do
    %{
      most_recent_message: room_with_users.most_recent_message,
      most_recent_message_timestamp: room_with_users.most_recent_message_timestamp,
      room_id: room_with_users.room.id,
      room_name: room_with_users.room.name,
      room_type: room_with_users.room.type,
      enabled: room_with_users.room.enabled,
      created_at: room_with_users.room.created_at,
      updated_at: room_with_users.room.updated_at,
      user_ids: Enum.map(room_with_users.users, &(UUID.binary_to_string!(&1))),
    }
  end

  def render("show_one_room_with_users.json", %{room_with_users: room_with_users}) do
    %{
      room_id: room_with_users.room_id,
      user_ids: Enum.map(room_with_users.user_ids, &(UUID.binary_to_string!(&1))),
    }
  end

  def render("show_room.json", %{room: room}) do
    %{
      id: room.id,
      name: room.name,
      type: room.type,
      created_at: room.created_at,
      updated_at: room.updated_at
    }
  end

  def render("show_user_last_seen.json", %{user_last_seen: user_last_seen}) do
    if user_last_seen != nil do
      %{
        room_id: user_last_seen.room_id,
        user_id: user_last_seen.user_id,
        last_seen: user_last_seen.last_seen,
        created_at: user_last_seen.created_at,
        updated_at: user_last_seen.updated_at
      }
    end
  end


  def render("show_most_recent_room_messages.json", %{most_recent_room_messages: most_recent_room_messages}) do
    render_many(most_recent_room_messages, ChatView, "show_most_recent_room_message.json", as: :most_recent_room_message)
  end

  def render("show_most_recent_room_message.json", %{most_recent_room_message: most_recent_room_message}) do
    %{
      room_id: most_recent_room_message.room_id,
      most_recent_message: most_recent_room_message.most_recent_message,
      most_recent_message_time: most_recent_room_message.most_recent_message_time,
    }
  end



  def render("show_messages.json", %{messages: messages}) do
    render_many(messages, ChatView, "show_message.json", as: :message)
  end

  def render("show_message.json", %{message: message}) do
    %{
      id: message.id,
      sender_id: message.sender_id,
      room_id: message.room_id,
      text: message.text,
      image_url: message.image_url,
      created_at: message.created_at,
      updated_at: message.updated_at
    }
  end

end
