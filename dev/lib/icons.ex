defmodule Setzkasten.Dev.Icons do
  @moduledoc false
  use Setzkasten.Icons, path: "dev/icons"
end

defmodule Setzkasten.Dev.Plush do
  @moduledoc false
  @behaviour Setzkasten.Plush

  @dir Path.expand("../static/images/plush", __DIR__)
  @files @dir |> File.ls!() |> MapSet.new()

  # The file list is read at compile time; recompile when a file is added or removed.
  def __mix_recompile__?, do: @dir |> File.ls!() |> MapSet.new() != @files

  @impl true
  def src(name, :light), do: if("#{name}.webp" in @files, do: "/images/plush/#{name}.webp")
  def src(_name, :dark), do: nil
end
