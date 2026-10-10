defmodule Setzkasten do
  @moduledoc """
  HEEx components and design system for Phoenix admin backends.

  `use Setzkasten` imports every component module:

      defmodule MyAppWeb do
        defp html_helpers do
          quote do
            use Setzkasten
            # ...
          end
        end
      end

  Component modules can also be imported one by one, e.g. `import Setzkasten.Components.Data`.
  See the README for installation and `guides/design-system.md` for the design rules.

  ## Configuration (all optional, read at runtime)

      config :setzkasten,
        icons: MyAppWeb.Icons,                       # extra Lucide icons, see Setzkasten.Icons
        plush: MyAppWeb.Plush,                       # plush image sources, see Setzkasten.Plush
        translate_error: {MyAppWeb.CoreComponents, :translate_error}
  """

  @component_modules [
    Setzkasten.Components.Icons,
    Setzkasten.Components.Actions,
    Setzkasten.Components.Forms,
    Setzkasten.Components.Feedback,
    Setzkasten.Components.Layout,
    Setzkasten.Components.Data,
    Setzkasten.Components.Navigation,
    Setzkasten.Components.Overlays,
    Setzkasten.Components.Shell
  ]

  @doc false
  def component_modules, do: @component_modules

  # Not imported by `use Setzkasten`: an app's CoreComponents keeps its own
  # Gettext `translate_error/1` (configured as `:translate_error`), which would clash.
  @except %{Setzkasten.Components.Forms => [translate_error: 1]}

  defmacro __using__(_opts) do
    for module <- @component_modules do
      except = Map.get(@except, module, [])

      quote do
        import unquote(module), except: unquote(except)
      end
    end
  end
end
