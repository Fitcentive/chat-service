defmodule ChatWeb.ChatRoomChannel do
  use ChatWeb, :channel

  import Chat.Repo.Chats
  alias Chat.Repo.Chats

  # todo - Use Phoenix.presence to track user active status
  @impl true
  def join("chat_room:" <> room_id, %{"user_id" => user_id} = payload, socket) do
    if authorized?(payload, socket) do
      with room_user <- Chats.upsert_room_user(%{"room_id" => room_id, "user_id" => user_id}) do
        {:ok, assign(socket, :room_id, room_id)}
      end
    else
      {:error, %{reason: "unauthorized"}}
    end
  end



  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end


  @impl true
  def handle_in("shout", %{"body" => text, "image_url" => image_url} = payload, socket) do
    room_id = socket.assigns[:room_id]
    user_id = socket.assigns[:user_id]
    with message <- Chats.create_message_with_metadata(%{
      "sender_id" => user_id,
      "room_id" => room_id,
      "text" => text,
      "image_url" => image_url,
    }) do
      broadcast(socket, "shout", payload)
      {:noreply, socket}
    end
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (chat_room:lobby).
  @impl true
  def handle_in("shout", %{"body" => text} = payload, socket) do
    room_id = socket.assigns[:room_id]
    user_id = socket.assigns[:user_id]
    with message <- Chats.create_message(%{
      "sender_id" => user_id,
      "room_id" => room_id,
      "text" => text,
    }) do
      broadcast(socket, "shout", payload)
      {:noreply, socket}
    end
  end

  # Add authorization logic here as required.
  defp authorized?(%{"user_id" => user_id, "body" => content} = payload, socket) do
    if socket.assigns[:user_id] == user_id do
      true
    else
      false
    end
  end

end
