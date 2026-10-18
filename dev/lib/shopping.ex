defmodule Setzkasten.Dev.Shopping do
  @moduledoc false

  @open [
    {"Bananen", "6 Stück, nicht zu reif", "cart"},
    {"Haferdrink", "2 Packungen", "cart"},
    {"Brot", nil, "utensils"},
    {"Tomaten", "500 g", "cart"},
    {"Spülmittel", nil, "home"},
    {"Kaffee", "ganze Bohnen", "utensils"},
    {"Katzenfutter", "12 Dosen · Nassfutter", "paw"},
    {"Windeln", "Größe 4", "baby"},
    {"Joghurt", "griechisch", "cart"},
    {"Äpfel", "1 kg", "cart"},
    {"Nudeln", nil, "utensils"},
    {"Geschenkpapier", nil, "gift"}
  ]

  @recent [
    {"Butter", nil, "utensils"},
    {"Käse", "Bergkäse am Stück", "utensils"},
    {"Teelichter", nil, "home"},
    {"Haferflocken", "500 g", "cart"},
    {"Basilikum", "Topf", "cart"},
    {"Hundeleckerli", nil, "paw"}
  ]

  def open, do: index(@open, 1)
  def recent, do: index(@recent, length(@open) + 1)

  def item(name),
    do: %{id: "new-#{System.unique_integer([:positive])}", name: name, note: nil, plush: "cart"}

  @doc "The open ids with `id` back at its place in the fixture order; new items go last."
  def put_back(open_ids, id) do
    rank = fn id ->
      case Integer.parse(id) do
        {n, ""} -> n
        _ -> :infinity
      end
    end

    Enum.sort_by([id | open_ids], rank)
  end

  defp index(items, from) do
    for {{name, note, plush}, i} <- Enum.with_index(items, from),
        do: %{id: "#{i}", name: name, note: note, plush: plush}
  end
end
