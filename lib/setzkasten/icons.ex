defmodule Setzkasten.Icons do
  @moduledoc """
  Compiles a directory of Lucide SVG files into an icon module.

  The package ships only the icons its own components draw (`Setzkasten.Lucide`). An app adds
  the icons it uses by copying their files from [lucide-static](https://www.npmjs.com/package/lucide-static)
  (`icons/<name>.svg`) into a directory of its own and compiling them:

      defmodule MyAppWeb.Icons do
        use Setzkasten.Icons, path: "assets/vendor/lucide"
      end

      # config/config.exs
      config :setzkasten, icons: MyAppWeb.Icons

  `path` is relative to the project root (or absolute). Adding a file recompiles the module.
  `<.icon name="…">` looks the name up in the app module first, then in `Setzkasten.Lucide`.
  Unknown names raise, so a typo fails in the test suite rather than rendering nothing.
  """

  @callback svg(name :: String.t()) :: Phoenix.HTML.safe() | nil
  @callback names() :: [String.t()]

  defmacro __using__(opts) do
    {path, _} = opts |> Keyword.fetch!(:path) |> Code.eval_quoted([], __CALLER__)
    dir = Path.expand(path, File.cwd!())
    files = dir |> Path.join("*.svg") |> Path.wildcard() |> Enum.sort()

    if files == [] do
      raise ArgumentError, "no Lucide SVG files in #{dir} (path: #{inspect(path)})"
    end

    icons =
      for file <- files do
        {Path.basename(file, ".svg"), file |> File.read!() |> Setzkasten.Icons.inner_markup()}
      end

    names = Enum.map(icons, &elem(&1, 0))
    hash = :erlang.md5(Enum.join(files, "\n"))

    clauses =
      for {name, body} <- icons do
        quote do
          def svg(unquote(name)), do: {:safe, unquote(body)}
        end
      end

    quote do
      @behaviour Setzkasten.Icons
      unquote(for file <- files, do: quote(do: @external_resource(unquote(file))))

      unquote_splicing(clauses)
      def svg(_name), do: nil

      def names, do: unquote(names)

      @doc false
      def __mix_recompile__? do
        files = unquote(dir) |> Path.join("*.svg") |> Path.wildcard() |> Enum.sort()
        :erlang.md5(Enum.join(files, "\n")) != unquote(hash)
      end
    end
  end

  @doc false
  def inner_markup(svg) do
    case Regex.run(~r{<svg[^>]*>(.*)</svg>}s, svg, capture: :all_but_first) do
      [inner] -> inner |> String.split("\n") |> Enum.map_join(&String.trim/1)
      nil -> raise ArgumentError, "not an SVG file"
    end
  end

  @doc """
  Returns the inner SVG markup for `name`, checking the app's icon module first.
  """
  def fetch!(name) do
    app = Application.get_env(:setzkasten, :icons)

    (app && app.svg(name)) || Setzkasten.Lucide.svg(name) ||
      raise ArgumentError,
            "unknown icon #{inspect(name)}; add its Lucide SVG to the module set in config :setzkasten, :icons"
  end
end

defmodule Setzkasten.Lucide do
  @moduledoc """
  The Lucide icons the components draw themselves (lucide-static 1.48.0, ISC licence,
  `priv/lucide/LICENSE`).
  """
  use Setzkasten.Icons, path: Path.expand("../../priv/lucide", __DIR__)
end
