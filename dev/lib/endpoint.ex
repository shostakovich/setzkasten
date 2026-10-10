defmodule Setzkasten.Dev.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :setzkasten

  @session_options [store: :cookie, key: "_setzkasten_catalog", signing_salt: "catalog"]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  plug Plug.Static, at: "/", from: Path.expand("../static", __DIR__), gzip: false

  plug Plug.Session, @session_options
  plug Setzkasten.Dev.Router
end
