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

end
