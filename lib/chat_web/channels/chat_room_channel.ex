defmodule ChatWeb.ChatRoomChannel do
  use ChatWeb, :channel
  alias ChatWeb.Presence

  import Chat.Repo.Chats
  alias Chat.Repo.Chats
  alias ChatWeb.GcpPubSubClient
  alias ChatWeb.ChatRoomChannel

  @impl true
  def join("chat_room:" <> room_id, %{"user_id" => user_id} = payload, socket) do
    if authorized?(room_id, user_id, socket) do
      send(self(), :after_join)
      {:ok, assign(socket, :room_id, room_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
      online_at: inspect(System.system_time(:second))
    })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  # Heartbeat
  @impl true
  def handle_in("heartbeat", _payload, socket) do
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  @impl true
  def handle_in("typing_started", _payload, socket) do
    room_id = socket.assigns[:room_id]
    user_id = socket.assigns[:user_id]
    broadcast(socket, "typing_started", %{"user_id" => user_id})
    {:noreply, socket}
  end

  @impl true
  def handle_in("typing_stopped", _payload, socket) do
    room_id = socket.assigns[:room_id]
    user_id = socket.assigns[:user_id]
    broadcast(socket, "typing_stopped", %{"user_id" => user_id})
    {:noreply, socket}
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
      send_push_notifications_to_offline_users(socket, room_id, user_id, text)
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
      send_push_notifications_to_offline_users(socket, room_id, user_id, text)
      {:noreply, socket}
    end
  end

  defp send_push_notifications_to_offline_users(socket, room_id, user_id, text) do
    # Send notification to other users if they are not already online
    room_users = Chats.get_users_for_room(room_id)
    room_user_ids = Enum.map(room_users.user_ids, &(UUID.binary_to_string!(&1)))
    online_users = Presence.list(socket) |> Map.keys
    offline_users = ((room_user_ids -- online_users) -- [user_id])

    offline_users
    |> Enum.map(&(GcpPubSubClient.publish_chat_room_message_sent(user_id, &1, room_id, text)))
    #####
  end

  defp authorized?(room_id, user_id, socket) do
    if (socket.assigns[:user_id] == user_id) do
      case Bodyguard.permit(Chats, :get_room_messages, user_id, room_id) do
        :ok -> true
        _   -> false
      end
    else
      false
    end
  end

end
