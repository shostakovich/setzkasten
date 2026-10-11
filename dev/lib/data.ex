defmodule Setzkasten.Dev.Data do
  @moduledoc false

  # Two depots, each with its reference account, and an account of no depot. Values in cents.
  def holdings do
    %{
      depots: [
        %{
          id: "kinder",
          name: "Kinderdepot",
          holdings: [
            h(1, "Amundi Prime Global UCITS ETF", "LU2089238203", 70.4183, 3374, 215_000,
              ter: 0.05,
              fund_size: "4,1 Mrd. €"
            ),
            h(2, "SAP SE", "DE0007164600", 5, 24_181, 128_400, dividends: 1175)
          ],
          account: %{id: "verrechnung", name: "Verrechnungskonto", value: 32_437}
        },
        %{
          id: "lang",
          name: "Langfristig",
          holdings: [
            h(3, "Vanguard FTSE All-World UCITS ETF (Dist)", "IE00B3RBWM25", 95, 13_180, 976_430,
              ter: 0.22,
              fund_size: "15,8 Mrd. €",
              dividends: 22_800
            ),
            h(4, "iShares Core MSCI World UCITS ETF", "IE00B4L5Y983", 105, 10_382, 892_540,
              ter: 0.20,
              fund_size: "104,3 Mrd. €"
            ),
            h(5, "Xetra-Gold", "DE000A0S9GB0", 30, 11_979, 178_300)
          ],
          account: %{id: "depotkonto", name: "Depotkonto", value: 18_420}
        }
      ],
      accounts: [%{id: "tagesgeld", name: "Tagesgeld", value: 1_287_140}]
    }
  end

  defp h(id, name, isin, shares, price, cost, opts \\ []) do
    value = round(shares * price)

    %{
      id: id,
      name: name,
      isin: isin,
      shares: shares,
      price: price,
      value: value,
      cost: cost,
      gain: value - cost,
      dividends: Keyword.get(opts, :dividends, 0),
      ter: opts[:ter],
      fund_size: opts[:fund_size]
    }
  end

  # Shares in percent: regions and sectors seen through the funds (gold has neither), the asset
  # classes against their targets.
  def allocation do
    %{
      regions: [
        {"USA", 52.4},
        {"Europa", 17.8},
        {"Schwellenländer", 9.6},
        {"Japan", 4.2},
        {"Pazifik ohne Japan", 2.6},
        {"Kanada", 1.7},
        {nil, 11.7}
      ],
      sectors: [
        {"Technologie", 25.1},
        {"Finanzen", 14.3},
        {"Industrie", 9.8},
        {"Konsum zyklisch", 8.9},
        {"Gesundheit", 8.6},
        {"Kommunikation", 6.4},
        {"Basiskonsum", 4.9},
        {"Energie", 3.2},
        {"Grundstoffe", 3.0},
        {"Versorger", 2.3},
        {"Immobilien", 1.8},
        {nil, 11.7}
      ],
      classes: [
        %{name: "Aktien", share: 61.4, target: 60},
        %{name: "Gold", share: 8.2, target: 10, deviation: :below},
        %{name: "Liquidität", share: 30.4, target: 30}
      ]
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
