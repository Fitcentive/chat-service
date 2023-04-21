defmodule ChatWeb.RoomObserverChannel do
  use ChatWeb, :channel
  use WebSockex

  alias ChatWeb.Presence

  import Chat.Repo.Chats
  alias Chat.Repo.Chats
  alias ChatWeb.GcpPubSubClient
  alias ChatWeb.RoomObserverChannel

  @impl true
  def join("room_observer:" <> room_id, %{"user_id" => user_id} = payload, socket) do
    if authorized?(room_id, user_id, socket) do
      {:ok, assign(socket, :room_id, room_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def join("room_observer:" <> room_id, payload, socket) do
    {:ok, assign(socket, :room_id, room_id)}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  @impl true
  def handle_in("room_updated", %{"room_id" => roomId} = payload, socket) do
    broadcast(socket, "room_updated", payload)
    with room_users <- Chats.get_users_for_room(roomId) do
      Enum.map(
        room_users.user_ids,
        fn user_id ->
          send_user_room_updated_broadcast_socket_channel_message(UUID.binary_to_string!(user_id), roomId)
        end
      )
      {:noreply, socket}
    end
  end

  defp send_user_room_updated_broadcast_socket_channel_message(user_id, room_id) do
    {service_secret, _} = :service_secret
                          |> Application.get_env(__MODULE__, %{})
                          |> Keyword.split([:secret])

    {:ok, newSocket} =
        WebSockex.start("ws://127.0.0.1:4000/api/chat/socket/websocket?secret=#{service_secret[:secret]}", __MODULE__, :fake_state, [])

    WebSockex.send_frame(newSocket, {:text, Poison.encode!(%{
      topic: "user_room_observer:#{user_id}",
      event: "phx_join",
      payload: %{},
      ref: UUID.uuid4(),
      join_ref: UUID.uuid4()
    })})

    WebSockex.send_frame(newSocket, {:text, Poison.encode!(%{
      topic: "user_room_observer:#{user_id}",
      event: "user_room_updated",
      payload: %{
        room_id: room_id,
      },
      ref: UUID.uuid4(),
      join_ref: UUID.uuid4()
    })})

    WebSockex.send_frame(newSocket, {:close, 1000, "Closing message"})
  end


  defp authorized?(room_id, user_id, socket) do
    if (socket.assigns[:user_id] == user_id) do
      case Bodyguard.permit(Chats, :get_room_messages, user_id, room_id) do
        :ok -> true
        _   -> false
      end
    else
      # In this case, there is no socket.assigns[:user_id] as it might be an internal communication
      case Bodyguard.permit(Chats, :get_room_messages, user_id, room_id) do
        :ok -> true
        _   -> false
      end
    end
  end

end
