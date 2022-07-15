# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :chat,
  ecto_repos: [Chat.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :chat, ChatWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: ChatWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Chat.PubSub,
  live_view: [signing_salt: "z9ztUCUE"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :chat, Chat.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :keycloak_basic, Keycloak.Plug.VerifyBasicAuthToken,
  public_key: """
  -----BEGIN PUBLIC KEY-----
  MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAixbkaPx/USZN27DumqgVXCrciZyt9zZGjRgpVwJ2uIKTGW/nyUlRIP+yYnHcaCVyArHDNVf+7DCKzCdBocYGWhcFA0ERG6aWBBVBxbnfcLGGVEyxaa3GJG58iXIBgeVTYExM/roBXE6SmVZWDBZTZ7lwHT3D6KbQZBe34minZEcCBDma4VXX7CLLDlTF/PiDd4BoKcH1XuzF/0PJkGQnjNj+Z9pezbC+lCPL28mHWVqYoE2BWW2m8Pt6yi3D1CibfHaF3cjqg+DMtgTZDy8oAbjEeAPycA/KiHMNa0TBFGugXyd3UdtREmltMlDx5AU1QgP7eUmJnQYQEP+HFISS9QIDAQAB
  -----END PUBLIC KEY-----
  """

config :keycloak_basic,  ChatWeb.Authentication.Native.VerifyToken,
  public_key: """
  -----BEGIN PUBLIC KEY-----
  MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAixbkaPx/USZN27DumqgVXCrciZyt9zZGjRgpVwJ2uIKTGW/nyUlRIP+yYnHcaCVyArHDNVf+7DCKzCdBocYGWhcFA0ERG6aWBBVBxbnfcLGGVEyxaa3GJG58iXIBgeVTYExM/roBXE6SmVZWDBZTZ7lwHT3D6KbQZBe34minZEcCBDma4VXX7CLLDlTF/PiDd4BoKcH1XuzF/0PJkGQnjNj+Z9pezbC+lCPL28mHWVqYoE2BWW2m8Pt6yi3D1CibfHaF3cjqg+DMtgTZDy8oAbjEeAPycA/KiHMNa0TBFGugXyd3UdtREmltMlDx5AU1QgP7eUmJnQYQEP+HFISS9QIDAQAB
  -----END PUBLIC KEY-----
  """

config :keycloak_google, Keycloak.Plug.VerifyGoogleAuthToken,
  public_key: """
  -----BEGIN PUBLIC KEY-----
  MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAhZrtxOu/AVm6H001Xlthefixpf79nUqgs/jKZQzp1RS8tm3deERalaphxvFrtxju35fcEJgaXzIa+hq6yP6EnAiXTOY+MeF16unxx4jUJr/ZW+S/0Cj+c7XDYSO/aYOuOcd6M4lTuPYWQNrwDfywU8FBzd1gH98vscQ4b74BisYCRx0tl6xDwpGrrpBdPrlSeTJau6MZaYbrVrplRZXxmJxwUitS0hXhzZw5gP0380T2nvcTL2eMexm5atUG83JU74dts+Fec8wGyqGxouVAJi3rmEVBquqh1HhryM4QhCeXigIr4Qw6weAQpXtQpMYq6USv6F3B2+us29T4JmG/fwIDAQAB
  -----END PUBLIC KEY-----
  """

config :keycloak_google, ChatWeb.Authentication.Google.VerifyToken,
  public_key: """
  -----BEGIN PUBLIC KEY-----
  MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAhZrtxOu/AVm6H001Xlthefixpf79nUqgs/jKZQzp1RS8tm3deERalaphxvFrtxju35fcEJgaXzIa+hq6yP6EnAiXTOY+MeF16unxx4jUJr/ZW+S/0Cj+c7XDYSO/aYOuOcd6M4lTuPYWQNrwDfywU8FBzd1gH98vscQ4b74BisYCRx0tl6xDwpGrrpBdPrlSeTJau6MZaYbrVrplRZXxmJxwUitS0hXhzZw5gP0380T2nvcTL2eMexm5atUG83JU74dts+Fec8wGyqGxouVAJi3rmEVBquqh1HhryM4QhCeXigIr4Qw6weAQpXtQpMYq6USv6F3B2+us29T4JmG/fwIDAQAB
  -----END PUBLIC KEY-----
  """

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
