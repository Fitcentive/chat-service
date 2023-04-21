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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

config :deleted_user_id, ChatWeb.ChatController,
  user_id: "aaaaaaaa-aaaa-8bbb-8bbb-aaaaaaaaaaaa"

config :service_secret, ChatWeb.Authentication.VerifyBearerToken,
  secret: "ymmtuBE62NJRIro6eCBxl5wcIZvmKg3nSTgP2YSyjOB5fq3S0ZNFXdY1DLUBo8ji"

config :service_secret, ChatWeb.ChatRoomChannel,
       secret: "ymmtuBE62NJRIro6eCBxl5wcIZvmKg3nSTgP2YSyjOB5fq3S0ZNFXdY1DLUBo8ji"

config :service_secret, ChatWeb.RoomObserverChannel,
       secret: "ymmtuBE62NJRIro6eCBxl5wcIZvmKg3nSTgP2YSyjOB5fq3S0ZNFXdY1DLUBo8ji"

config :auth_tokens, ChatWeb.Authentication.VerifyBearerToken,
  keyIdPublicKeys: %{
   "ZK_xufw1gGfVqJ-3a4aJM9EzZRfxp1Z6_AH2fCpYvtk" => %{
     public_key: """
     -----BEGIN PUBLIC KEY-----
     MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAhZrtxOu/AVm6H001Xlthefixpf79nUqgs/jKZQzp1RS8tm3deERalaphxvFrtxju35fcEJgaXzIa+hq6yP6EnAiXTOY+MeF16unxx4jUJr/ZW+S/0Cj+c7XDYSO/aYOuOcd6M4lTuPYWQNrwDfywU8FBzd1gH98vscQ4b74BisYCRx0tl6xDwpGrrpBdPrlSeTJau6MZaYbrVrplRZXxmJxwUitS0hXhzZw5gP0380T2nvcTL2eMexm5atUG83JU74dts+Fec8wGyqGxouVAJi3rmEVBquqh1HhryM4QhCeXigIr4Qw6weAQpXtQpMYq6USv6F3B2+us29T4JmG/fwIDAQAB
     -----END PUBLIC KEY-----
     """,
     iss: "https://api.vid.app/auth/realms/GoogleAuth"
   },

   "FvVQglTSr4F98GxVSO930wTDSdkTTCntPpjA6gICv9k" => %{
     public_key: """
     -----BEGIN PUBLIC KEY-----
     MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnwxrlR45xYuj77wJu3sIZqYmv7tcb0/p68E8mhz8VyAfEzdSTLko9dtruyUbmy6yhEDlzp5wJDnJmrSv/8R23zucJ/SjcdhJuwHSIF2se2eMKHTM2KP9B/KDcAk0hcHduzqC3JKDkj0aHgBgduBH+3Jpnye13j2FqbnBtoFIny1AlmHlCey7igr8UjZK+vikdufz7KeHgMjQJbrho3QhQo7zzunr90szwC+1CH95ZQl5Y6qzn74mg19tDoZJMMAgtimU6Rer8P5DcuTPG/hCV2VPw9Qx9aw0VkvzXomanzCC90e5rWjvWTQQlIzqC0l/sIogph9kkNqKD1Y6U4x42QIDAQAB
     -----END PUBLIC KEY-----
     """,
     iss: "https://auth.fitcentive.xyz/auth/realms/NativeAuth"
   },

    "qdczNS1H48MCBJ7QD0dhnv_o_BikgoN4U79--nQmxT0" => %{
      public_key: """
      -----BEGIN PUBLIC KEY-----
      MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmVDJ4ZXPO09a6eHHWmke2TbBzvsLZIy7dITsJIxu3eYK5oNPF4hVZzP75AMbtSiMuHKIiEji7CulZmd7pu25nUidKNVYB4Kh66kaWsiJ6z7iqTz6Xajc25AdOiQTCk6aE8HqVKSXNULhC53ZF7uMKApEdlvEDPubpUmj/FR8oIBPwmoyovW3JUhydqcMxyplBemrwxPw9SCJhbOaBJtShiyJ+q5xQL23gltweUiVHT6UT2EkNNQpS1uBCeLNguVSEUGFDw4YYTFkKiMBEjhjfHYdeAx5dmq5hVCf2ECphIxeKrb6z3+xz5iRW4yvr7s2ix+dvnybaf11186qLHARSwIDAQAB
      -----END PUBLIC KEY-----
      """,
      iss: "https://api.vid.app/auth/realms/AppleAuth"
    },

    "e28-PLM8vJ6rBS8TDTNH5UOCgi5mql2MBIl88Fk_F6o" => %{
      public_key: """
      -----BEGIN PUBLIC KEY-----
      MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA28RGo7/MXNpJTNhOybAM85vXFwb6imoHrnbEr9t0egzJhR4GSLMCQUozQ+K1FruZ+LHnHzMMkZFUnz1veaXaAV9Vxum3iuoD1hGHjRtADzNuLqoclj3XgCH9EkbXzI9MvFK83M6pAa6Udt3kpHrIxL4nt5Tk6H12PkpV9x4vPcGOfdT2UTiDdpnT2RW0+IiuG52/hkBSTg4Kew/FU/5mNcGI8fKh2wnHIWdVZY+PfXMPIZ+eKw4QLprk+fKXZ7cKcKK+zHZJNbxNkR1E+pjduPY5+kyagjEW/oO/NU5CEOdW8jabjzRILBDaZRvNjvDiK1Rf3SfhFn9lXJxDZHZ4OQIDAQAB
      -----END PUBLIC KEY-----
      """,
      iss: "https://api.vid.app/auth/realms/FacebookAuth"
    },
  }

config :gcp_pubsub_client, ChatWeb.GcpPubSubClient,
  topics: %{
    chat_room_message_sent: "chat-room-message-sent"
  }
