defmodule ChatWeb.UserSocket do
  use Phoenix.Socket

  import Chat.Repo.Chats
  alias Chat.Repo.Chats

  alias ChatWeb.Authentication.VerifyBearerToken

  # A Socket handler
  #
  # It's possible to control the websocket connection and
  # assign values that can be accessed by your channel topics.

  ## Channels
  # Uncomment the following line to define a "room:*" topic
  # pointing to the `ChatWeb.RoomChannel`:
  #
  # channel "room:*", ChatWeb.RoomChannel
  #
  # To create a channel file, use the mix task:
  #
  #     mix phx.gen.channel Room
  #
  # See the [`Channels guide`](https://hexdocs.pm/phoenix/channels.html)
  # for further details.

  channel "chat_room:lobby", ChatWeb.ChatRoomChannel
  channel "chat_room:*", ChatWeb.ChatRoomChannel


  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do

    [{:ok, rawHeader} | rest ] = token
                                 |> String.split(".")
                                 |> Enum.map(&(Base.decode64(&1, padding: false)))

    %{"kid" => key_id} = Poison.decode!(rawHeader)

    case VerifyBearerToken.verify_token(token, key_id) do
      {:ok, %{
        "user_id" => userId,
        "given_name" => first_name,
        "family_name" => last_name
      } = claims} ->
        Chats.upsert_user(%{id: userId, first_name: first_name, last_name: last_name, is_active: true})
        {:ok, assign(socket, :user_id, userId)}

      {:error, message}                      ->  :error
    end

  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Elixir.ChatWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(_socket), do: nil
end
