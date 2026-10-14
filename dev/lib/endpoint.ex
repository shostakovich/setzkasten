defmodule Setzkasten.Dev.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :setzkasten

  @session_options [store: :cookie, key: "_setzkasten_catalog", signing_salt: "catalog"]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  plug Plug.Static, at: "/setzkasten", from: {:setzkasten, "priv/static"}, only: ~w(fonts)
  plug Plug.Static, at: "/", from: Path.expand("../static", __DIR__), gzip: false

  plug :strict_styles
  plug Plug.Session, @session_options
  plug Setzkasten.Dev.Router

  # The components must work without inline styles; the browser reports any as a violation.
  defp strict_styles(conn, _opts),
    do: Plug.Conn.put_resp_header(conn, "content-security-policy", "style-src 'self'")
end
