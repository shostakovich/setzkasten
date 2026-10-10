{:ok, _} =
  Supervisor.start_link(
    [{Phoenix.PubSub, name: Setzkasten.Dev.PubSub}, Setzkasten.Dev.Endpoint],
    strategy: :one_for_one
  )

ExUnit.start()
