# Started by `mix dev`: serves the component catalog on http://localhost:4110.
Application.put_env(:phoenix, :serve_endpoints, true, persistent: true)

{:ok, _} =
  Supervisor.start_link(
    [{Phoenix.PubSub, name: Setzkasten.Dev.PubSub}, Setzkasten.Dev.Endpoint],
    strategy: :one_for_one
  )

IO.puts("setzkasten catalog on http://localhost:#{Setzkasten.Dev.Endpoint.config(:http)[:port]}")
Process.sleep(:infinity)
