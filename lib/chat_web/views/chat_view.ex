defmodule ChatWeb.ChatView do
  use ChatWeb, :view

  alias ChatWeb.ChatView

  def render("show_room_definitions.json", %{rooms: rooms}) do
    render_many(rooms, ChatView, "show_room.json", as: :room)
  end

  def render("show_rooms.json", %{rooms: rooms}) do
    render_many(rooms, ChatView, "show_room_with_users.json", as: :room_with_users)
  end

  def render("show_room_with_users.json", %{room_with_users: room_with_users}) do
    %{
      room_id: UUID.binary_to_string!(room_with_users.room_id),
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


  def render("show_most_recent_room_messages.json", %{most_recent_room_messages: most_recent_room_messages}) do
    render_many(most_recent_room_messages, ChatView, "show_most_recent_room_message.json", as: :most_recent_room_message)
  end

  def render("show_most_recent_room_message.json", %{most_recent_room_message: most_recent_room_message}) do
    %{
      room_id: most_recent_room_message.room_id,
      most_recent_message: most_recent_room_message.most_recent_message,
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
