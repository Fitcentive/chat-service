defmodule ChatWeb.ChatRoomChannel do
  use ChatWeb, :channel

  use Joken.Config
  alias JOSE.JWK

  @impl true
  def join("chat_room:lobby", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def join("chat_room:" <> _private_room_id, payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
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

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (chat_room:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(%{"token" => auth_token, "body" => content} = payload) do
    case verify_token(auth_token) do
      {:ok, claims} -> true
      {:error, message} -> false
    end

  end


  def token_config() do
    default_claims(
      aud: "account",
      iss: "http://api.vid.app/auth/realms/NativeAuth"
    )
  end

  @spec verify_token(String.t() | nil) :: {atom(), Joken.Token.t() | atom()}
  def verify_token(nil), do: {:error, :not_authenticated}

  def verify_token(token) do
    verify_and_validate(token, signer_key())
  end

  @spec signer_key() :: Joken.Signer.t()
  def signer_key() do
    {config, _} =
      :keycloak_basic
      |> Application.get_env(__MODULE__, [])
      |> Keyword.split([:hmac, :public_key])

    case config do
      [public_key: public_key] ->
        %Joken.Signer{
          alg: "RS256",
          jwk: JWK.from_pem(public_key),
        }

      _ ->
        raise "No signer configuration present for #{__MODULE__}"
    end
  end


end
