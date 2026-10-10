defmodule Setzkasten.Dev.Icons do
  @moduledoc false
  use Setzkasten.Icons, path: "dev/icons"
end

defmodule Setzkasten.Dev.Plush do
  @moduledoc false
  @behaviour Setzkasten.Plush

  @dir Path.expand("../static/images/plush", __DIR__)
  @files @dir |> File.ls!() |> MapSet.new()

  # Placeholder images (`<name>-light.webp`/`<name>-dark.webp`, or one `<name>.webp` for both
  # themes). The file list is read at compile time; recompile when a file is added or removed.
  def __mix_recompile__?, do: @dir |> File.ls!() |> MapSet.new() != @files

  @impl true
  def src(name, variant) do
    file =
      cond do
        "#{name}-light.webp" in @files -> "#{name}-#{variant}.webp"
        variant == :light and "#{name}.webp" in @files -> "#{name}.webp"
        true -> nil
      end

    file && "/images/plush/" <> file
  end
end
