defmodule ChatWeb.Authentication.VerifyBearerToken do

  use Joken.Config
  alias JOSE.JWK

  def verify_token_config(key_id) do
    {config, _} =
      :auth_tokens
      |> Application.get_env(__MODULE__, %{})
      |> Keyword.split([:keyIdPublicKeys])

    case config do
      [keyIdPublicKeys: config_map] ->
        default_claims(
          aud: "account",
          iss: config_map[key_id][:iss]
        )

      _ ->
        raise "No signer configuration present for #{__MODULE__}"
    end

  end

  def verify_token(nil), do: {:error, :not_authenticated}

  def verify_token(token, key_id) do
    Joken.verify_and_validate(verify_token_config(key_id), token, signer_key(key_id))
  end


  def signer_key(key_id) do
    {config, _} =
      :auth_tokens
      |> Application.get_env(__MODULE__, %{})
      |> Keyword.split([:keyIdPublicKeys])

    case config do
      [keyIdPublicKeys: config_map] ->
        %Joken.Signer{
          alg: "RS256",
          jwk: JWK.from_pem(config_map[key_id][:public_key]),
        }

      _ ->
        raise "No signer configuration present for #{__MODULE__}"
    end
  end
end