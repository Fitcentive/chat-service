defmodule ChatWeb.Plugs.PlugHelpers do

  import Joken

  import Plug.Conn
  alias JOSE.JWK

  def params_to_snake_case(params) do
    for {key, value} <- params, into: %{} do
      {Macro.underscore(key), value}
    end
  end

  @regex ~r/^Bearer:?\s+(.+)/i


  @doc """
  Fetches the token from the `Authorization` headers array, attempting
  to match the token in the format `Bearer <token>`.
  ### Example
      iex> fetch_token([])
      nil
      iex> fetch_token(["abc123"])
      nil
      iex> fetch_token(["Bearer abc123"])
      "abc123"
  """
  @spec fetch_token([String.t()] | []) :: String.t() | nil
  def fetch_token([]), do: nil

  def fetch_token([token | tail]) do
    case Regex.run(@regex, token) do
      [_, token] -> String.trim(token)
      nil -> fetch_token(tail)
    end
  end


end