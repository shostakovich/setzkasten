import Config

# Configuration for the catalog dev app in dev/ (not part of the package).
if config_env() in [:dev, :test] do
  config :setzkasten,
    icons: Setzkasten.Dev.Icons,
    plush: Setzkasten.Dev.Plush

  config :setzkasten, Setzkasten.Dev.Endpoint,
    url: [host: "localhost"],
    adapter: Bandit.PhoenixAdapter,
    secret_key_base: String.duplicate("setzkasten catalog ", 4),
    live_view: [signing_salt: "setzkasten"],
    pubsub_server: Setzkasten.Dev.PubSub,
    render_errors: [formats: [html: Setzkasten.Dev.ErrorHTML], layout: false],
    check_origin: false

  config :phoenix, :json_library, Jason
  config :phoenix, :plug_init_mode, :runtime
  config :logger, level: :warning
end

if config_env() == :dev do
  node_path = %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}

  config :tailwind,
    version: "4.3.3",
    catalog: [
      args: ~w(--input=dev/assets/app.css --output=dev/static/assets/app.css),
      cd: Path.expand("..", __DIR__),
      env: node_path
    ]

  config :esbuild,
    version: "0.25.4",
    catalog: [
      args: ~w(dev/assets/app.js --bundle --target=es2022 --outdir=dev/static/assets),
      cd: Path.expand("..", __DIR__),
      env: node_path
    ]

  # As in a generated Phoenix app: the comments between list rows change how morphdom moves them.
  config :phoenix_live_view, debug_heex_annotations: true

  config :setzkasten, Setzkasten.Dev.Endpoint,
    http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "4110"))],
    server: true,
    watchers: [
      tailwind: {Tailwind, :install_and_run, [:catalog, ~w(--watch)]},
      esbuild: {Esbuild, :install_and_run, [:catalog, ~w(--watch)]}
    ]
end

if config_env() == :test do
  config :setzkasten, Setzkasten.Dev.Endpoint, server: false
end
