defmodule ChatWeb.ChatView do
  use ChatWeb, :view

  alias ChatWeb.ChatView

  def render("show_room.json", %{room: room}) do
    %{
      id: room.id,
      name: room.name,
      type: room.type,
      created_at: room.created_at,
      updated_at: room.updated_at
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
      created_at: message.created_at,
      updated_at: message.updated_at
    }
  end

end
