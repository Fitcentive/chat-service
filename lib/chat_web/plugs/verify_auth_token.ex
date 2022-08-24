defmodule ChatWeb.Plugs.VerifyAuthToken do
  @moduledoc """
  Plug for verifying authorization on a per request basis, verifies that a token is set in the
  `Authorization` header.
  ### Example Usage
      config :keycloak, Keycloak.Plug.VerifyToken, hmac: "foo"
      # In your plug pipeline
      plug Keycloak.Plug.VerifyToken
  """
  import ChatWeb.Plugs.PlugHelpers
  import ChatWeb.Authentication.VerifyBearerToken

  import Plug.Conn

  @regex ~r/^Bearer:?\s+(.+)/i

  @doc false
  def init(opts), do: opts

  @doc """
  Fetches the `Authorization` header, and verifies the token if present. If a
  valid token is passed, the decoded `%Joken.Token{}` is added as `:token`
  to the `conn` assigns.
  """
  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _) do
    token = conn
            |> get_req_header("authorization")
            |> fetch_token()

    case token do
      nil ->
        send_401(conn)
      _   ->
        [{:ok, rawHeader} | rest ] = token
                                     |> String.split(".")
                                     |> Enum.map(&(Base.decode64(&1, padding: false)))

        %{"kid" => key_id} = Poison.decode!(rawHeader)

        case verify_token(token, key_id) do
          {:ok, claims}     -> assign(conn, :claims, claims)
          {:error, message} -> send_401(conn)
        end
    end
  end

  defp send_401(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Poison.encode!(%{error: "Invalid token"}))
    |> halt()
  end


end