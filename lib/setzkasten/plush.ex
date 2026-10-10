defmodule Setzkasten.Plush do
  @moduledoc """
  Where `<.plush name="…">` finds its images. The app owns the WebP files and tells the package
  how to reach them:

      defmodule MyAppWeb.Plush do
        @behaviour Setzkasten.Plush
        use MyAppWeb, :verified_routes

        @impl true
        def src("home", :light), do: ~p"/images/plush/home-light.webp"
        def src("home", :dark), do: ~p"/images/plush/home-dark.webp"
        def src(_name, _variant), do: nil
      end

      # config/config.exs
      config :setzkasten, plush: MyAppWeb.Plush

  Returning `nil` for `:dark` renders a single image for both themes. A name without a light
  source renders nothing (plush names often come from data, e.g. categories). Pages that do not
  need a module can pass `src` and `dark_src` to `<.plush>` directly.
  """

  @callback src(name :: String.t(), variant :: :light | :dark) :: String.t() | nil

  @doc false
  def sources(name) do
    case Application.get_env(:setzkasten, :plush) do
      nil -> {nil, nil}
      module -> {module.src(name, :light), module.src(name, :dark)}
    end
  end
end
