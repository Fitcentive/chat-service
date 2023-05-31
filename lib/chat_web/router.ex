defmodule ChatWeb.Router do
  use ChatWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ChatWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug CORSPlug, origin: ["http://localhost:5555", "https://app.fitcentive.xyz"]
    plug :accepts, ["json"]

  end

  pipeline :authentication do
    plug ChatWeb.Plugs.VerifyAuthToken
  end

  pipeline :internal_authentication do
    plug ChatWeb.Plugs.VerifyServiceSecret
  end

  get "/api/chat/health", ChatWeb.ChatController, :server_health

  scope "/", ChatWeb do
    pipe_through :browser

    get "/", ChatController, :index
  end

  # Other scopes may use custom stacks.
   scope "/api/chat", ChatWeb do
    pipe_through :authentication
    pipe_through :api

    post "/",                               ChatController, :upsert_user
    post "/get-chat-rooms",                 ChatController, :get_chat_room_definitions
    post "/get-chat-room",                  ChatController, :get_chat_room

    get    "/room/:room_id/messages",       ChatController, :get_room_messages

    put    "/room/:room_id",                ChatController, :update_room_name
    get    "/room/:room_id/users",          ChatController, :get_room_users
    post   "/room/:room_id/users/:user_id", ChatController, :add_user_to_room
    delete "/room/:room_id/users/:user_id", ChatController, :remove_user_from_room

    put    "/room/:room_id/last-seen",      ChatController, :upsert_user_last_seen

    post   "/room/get-last-seen",           ChatController, :get_user_last_seen


    post "/room/most-recent-message",       ChatController, :get_most_recent_room_messages


    get "/user/rooms",                      ChatController, :get_user_rooms
    get "/user/detailed-rooms",             ChatController, :get_detailed_user_rooms

   end

   scope "/api/internal/chat", ChatWeb do
    pipe_through :internal_authentication
    pipe_through :api

    delete "/user/:user_id",                ChatController, :delete_user_data

    delete "/room/:room_id",                ChatController, :delete_chat_room_internal

    post   "/room/:room_id/enable",         ChatController, :enable_room
    post   "/room/:room_id/disable",        ChatController, :disable_room

    post   "/room/:room_id/users/:user_id", ChatController, :add_user_to_room_internal
    delete "/room/:room_id/users/:user_id", ChatController, :remove_user_from_room_internal
   end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ChatWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
