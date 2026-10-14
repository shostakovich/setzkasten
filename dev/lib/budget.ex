defmodule Setzkasten.Dev.Budget do
  @moduledoc false
  # Demo data of a household budget: account groups for the sidebar, the transactions of one account.

  def groups do
    [
      %{
        label: "Budgetkonten",
        accounts: [
          %{id: "giro", glyph: "🏦", name: "Girokonto", balance: 234_512, open: 3},
          %{id: "karte", glyph: "💳", name: "Kreditkarte", balance: -48_230, open: 0},
          %{
            id: "ruecklage",
            glyph: "🐷",
            name: "Rücklage für Reparaturen am Haus und im Garten",
            balance: 1_250_000,
            open: 0
          }
        ]
      },
      %{
        label: "Außerhalb des Budgets",
        accounts: [
          %{id: "depot", glyph: "📈", name: "Depot", balance: 2_458_000, open: 0},
          %{id: "kredit", glyph: nil, name: "Autokredit", balance: -812_400, open: 0}
        ]
      }
    ]
  end

  def nav_accounts do
    for group <- groups(),
        {account, index} <- Enum.with_index(group.accounts),
        do: {group, account, index == 0}
  end

  def total(group), do: group.accounts |> Enum.map(& &1.balance) |> Enum.sum()

  def account(id),
    do:
      groups() |> Enum.flat_map(& &1.accounts) |> Enum.find(&(&1.id == id)) ||
        hd(hd(groups()).accounts)

  def categories do
    [
      {"Fixkosten", [{"Miete", "rent"}, {"Strom", "power"}, {"Internet", "internet"}]},
      {"Alltag", [{"Lebensmittel", "groceries"}, {"Drogerie", "drugstore"}, {"Tanken", "fuel"}]},
      {"Rücklagen", [{"Urlaub", "holiday"}, {"Geschenke", "gifts"}]}
    ]
  end

  def category_label(nil), do: nil

  def category_label(value) do
    Enum.find_value(categories(), fn {_group, options} ->
      Enum.find_value(options, fn {label, v} -> v == value && label end)
    end)
  end

  def payees,
    do: [
      "Bäckerei Krume",
      "Drogerie am Markt",
      "Stadtwerke",
      "Supermarkt Frisch",
      "Tankstelle Nord"
    ]

  def transactions do
    [
      %{
        id: "t1",
        date: "12.10.",
        payee: "Supermarkt Frisch",
        category: "groceries",
        amount: -8_742,
        approved: false
      },
      %{
        id: "t2",
        date: "11.10.",
        payee: "Tankstelle Nord",
        category: nil,
        amount: -6_430,
        approved: false
      },
      %{
        id: "t3",
        date: "10.10.",
        payee: "Bäckerei Krume",
        category: "groceries",
        amount: -1_260,
        approved: false
      },
      %{
        id: "t4",
        date: "01.10.",
        payee: "Hausverwaltung Ost",
        category: "rent",
        amount: -118_000,
        approved: true
      },
      %{
        id: "t5",
        date: "30.09.",
        payee: "Arbeitgeber",
        category: nil,
        amount: 312_450,
        approved: true
      }
    ]
  end
end
