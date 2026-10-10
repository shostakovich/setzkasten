defmodule Setzkasten.Dev.Data do
  @moduledoc false

  def holdings do
    [
      %{
        id: "kinder",
        label: "Kinderdepot",
        rows: [
          h(1, "Amundi Prime Global UCITS ETF", "LU2089238203", 70, 3374, 236_180, 238_740, 3.7),
          h(2, "SAP SE", "DE0007164600", 5, 24_181, 120_905, 85_885, 1.9),
          %{
            id: 3,
            name: "Verrechnungskonto",
            isin: nil,
            sub: "Referenzkonto · EUR",
            value: 324_374,
            weight: 5.1
          }
        ]
      },
      %{
        id: "lang",
        label: "Langfristig",
        rows: [
          h(
            4,
            "Vanguard FTSE All-World UCITS ETF",
            "IE00BK5BQT80",
            95,
            14_180,
            1_347_100,
            976_430,
            21.3
          ),
          h(
            5,
            "iShares Core MSCI World UCITS ETF",
            "IE00B4L5Y983",
            105,
            10_382,
            1_090_110,
            892_540,
            17.2
          ),
          h(6, "Xetra-Gold", "DE000A0S9GB0", 30, 11_979, 359_370, 178_300, 5.7)
        ]
      },
      %{
        id: "konten",
        label: "Konten",
        rows: [%{id: 7, name: "Tagesgeld", isin: nil, sub: "EUR", value: 1_287_140, weight: 20.3}]
      }
    ]
  end

  defp h(id, name, isin, shares, price, value, cost, weight) do
    gain = value - cost

    %{
      id: id,
      name: name,
      isin: isin,
      shares: shares,
      price: price,
      value: value,
      cost: cost,
      gain: gain,
      gain_pct: Float.round(gain / cost * 100, 1),
      weight: weight
    }
  end

  def entries do
    [
      %{id: 1, date: "07.10.2026", title: "Wocheneinkauf", amount: -8742},
      %{id: 2, date: "05.10.2026", title: "Abschlag Strom", amount: -11_200},
      %{id: 3, date: "01.10.2026", title: "Gehalt", amount: 312_450}
    ]
  end

  def costs do
    [
      %{name: "Vanguard FTSE All-World", ter: "0,22 %", year: "30 €"},
      %{name: "iShares Core MSCI World", ter: "0,20 %", year: "22 €"},
      %{name: "Xtrackers MSCI EM 1C", ter: "0,18 %", year: "7 €"},
      %{name: "Xetra-Gold", ter: "–", year: "–"}
    ]
  end

  def posts do
    [
      %{
        id: 12,
        title: "Herbst im Garten",
        meta: "Geändert am 07.10.2026 · 1.240 Wörter",
        status: :published
      },
      %{
        id: 11,
        title: "Notizen zum Apfelbaumschnitt im Spätwinter",
        meta: "Geändert am 02.10.2026 · 380 Wörter",
        status: :draft
      },
      %{
        id: 10,
        title: "Kürbissuppe mit Ingwer",
        meta: "Geplant für 14.10.2026 · 610 Wörter",
        status: :scheduled
      },
      %{
        id: 9,
        title: "Hochbeet aus Lärchenholz bauen",
        meta: "Geändert am 21.09.2026 · 2.015 Wörter",
        status: :published
      },
      %{
        id: 8,
        title: "Was im September blüht",
        meta: "Geändert am 03.09.2026 · 870 Wörter",
        status: :published
      }
    ]
  end
end
