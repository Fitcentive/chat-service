defmodule ChatWeb.Plugs.VerifyServiceSecret do

  import Plug.Conn
  import ChatWeb.Authentication.VerifyBearerToken

  @doc false
  def init(opts), do: opts

  @doc """
  Fetches the `Authorization` header, and verifies the token if present. If a
  valid token is passed, the decoded `%Joken.Token{}` is added as `:token`
  to the `conn` assigns.
  """
  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _) do
    [token | _] = conn |> get_req_header("service-secret")
    case token do
      nil     -> send_401(conn)
      secret  -> case verify_service_secret(secret) do
                    :ok     -> conn
                    :error  -> send_401(conn)
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