defmodule ChatWeb.Authentication.Native.VerifyToken do

  use Joken.Config
  alias JOSE.JWK

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