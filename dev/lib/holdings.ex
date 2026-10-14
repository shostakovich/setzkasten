defmodule Setzkasten.Dev.Holdings do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  alias Setzkasten.Format

  @doc "The depot with `id`, nil for all."
  def depot(_holdings, nil), do: nil
  def depot(holdings, id), do: Enum.find(holdings.depots, &(&1.id == id))

  @doc "Every account, the reference accounts first, each with its depot's id."
  def accounts(holdings) do
    for(depot <- holdings.depots, do: Map.put(depot.account, :depot, depot.id)) ++
      Enum.map(holdings.accounts, &Map.put(&1, :depot, nil))
  end

  def securities_value(depot), do: sum(depot.holdings, :value)

  def subtitle(holdings, nil) do
    securities = Enum.flat_map(holdings.depots, & &1.holdings)

    join_meta([
      count(length(holdings.depots), "Depot", "Depots"),
      count(length(securities), "Wertpapier", "Wertpapiere"),
      count(length(accounts(holdings)), "Konto", "Konten")
    ])
  end

  def subtitle(_holdings, depot),
    do:
      join_meta([count(length(depot.holdings), "Wertpapier", "Wertpapiere"), depot.account.name])

  defp count(1, one, _many), do: "1 #{one}"
  defp count(count, _one, many), do: "#{count} #{many}"

  attr :holdings, :map, required: true, doc: "see `Data.holdings/0`"
  attr :depot, :map, default: nil, doc: "the one shown, nil for all"
  attr :marked, :string, default: nil, doc: "the id of the account the page was opened for"
  attr :flush, :boolean, default: false

  def holdings_table(assigns) do
    {depots, accounts} =
      if assigns.depot,
        do: {[assigns.depot], []},
        else: {assigns.holdings.depots, assigns.holdings.accounts}

    assigns =
      assign(assigns,
        groups: groups(depots, accounts, assigns.marked),
        total: total(depots, accounts),
        net_worth: total(assigns.holdings.depots, assigns.holdings.accounts).value
      )

    ~H"""
    <.table
      id="holdings"
      groups={@groups}
      row_id={& &1.id}
      row_link={&row_link/1}
      row_attrs={&row_attrs/1}
      flush={@flush}
    >
      <:col :let={item} label="Wertpapier" class="min-w-52"><.position_name item={item} /></:col>
      <:col :let={item} label="Stück" align={:end} show_from={:xl}>
        <span :if={item.type == :holding}>{shares(item.entry.shares)}</span>
      </:col>
      <:col :let={item} label="Kurs" align={:end} show_from={:xl}>
        <.amount :if={item.type == :holding} value={item.entry.price} />
      </:col>
      <:col :let={item} label="Wert" align={:end}>
        <.amount value={item.entry.value} class="font-semibold" />
        <.cell_sub :if={item.type == :holding} hide_from={:sm}>
          <.gain gain={item.entry.gain} cost={item.entry.cost} />
        </.cell_sub>
      </:col>
      <:col :let={item} label="Einstand" align={:end} show_from={:md}>
        <.amount :if={item.type == :holding} value={item.entry.cost} />
      </:col>
      <:col :let={item} label="Gewinn" align={:end} show_from={:sm}>
        <.gain :if={item.type == :holding} gain={item.entry.gain} cost={item.entry.cost} />
      </:col>
      <:col :let={item} label="Anteil" align={:end} show_from={:md}>
        {percent(item.entry.value, @net_worth)}
      </:col>
      <:col :let={item} label="Div.-Rendite" align={:end} show_from={:xl}>
        <span :if={item.type == :holding} class={item.entry.dividends == 0 && "text-base-content/70"}>
          {dividend_yield(item.entry.dividends, item.entry.value)}
        </span>
      </:col>
      <:foot>
        <th scope="row">{if @depot, do: @depot.name, else: "Gesamt"}</th>
        <td class={show_from(:xl)}></td>
        <td class={show_from(:xl)}></td>
        <td class="text-end whitespace-nowrap">
          <.amount value={@total.value} />
          <.cell_sub hide_from={:sm}><.amount value={@total.gain} signed tone /></.cell_sub>
        </td>
        <td class={["text-end whitespace-nowrap", show_from(:md)]}>
          <.amount value={@total.cost} />
        </td>
        <td class={["text-end whitespace-nowrap", show_from(:sm)]}>
          <.amount value={@total.gain} signed tone />
        </td>
        <td class={["text-end whitespace-nowrap", show_from(:md)]}>
          {@depot && percent(@total.value, @net_worth)}
        </td>
        <td class={["text-end whitespace-nowrap", show_from(:xl)]}>
          {dividend_yield(@total.dividends, @total.securities_value)}
        </td>
      </:foot>
    </.table>
    """
  end

  defp position_name(%{item: %{type: :holding}} = assigns) do
    ~H"""
    {@item.entry.name}
    <.cell_sub show_from={:xl}>{@item.entry.isin}</.cell_sub>
    <.cell_sub hide_from={:xl} class="tabular-nums">
      <span class="whitespace-nowrap">{shares(@item.entry.shares)} Stück</span><.meta_sep /><.amount value={
        @item.entry.price
      } />
    </.cell_sub>
    """
  end

  defp position_name(%{item: %{type: :account}} = assigns) do
    ~H"""
    <span class="inline-flex items-center gap-2 font-medium">
      <.icon name="wallet" class="text-base-content/70" />{@item.entry.name}
    </span>
    <.cell_sub class="whitespace-nowrap">{@item.note}</.cell_sub>
    """
  end

  attr :gain, :integer, required: true
  attr :cost, :integer, required: true

  defp gain(assigns) do
    ~H"""
    <.amount value={@gain} signed tone />
    <div class={["text-sm", if(@gain < 0, do: "text-error-ink", else: "text-success-ink")]}>
      {Format.number(@gain / @cost * 100, decimals: 1, signed: true)}&nbsp;%
    </div>
    """
  end

  # A security opens its page; accounts have none. The account the page was opened for is marked.
  defp row_link(%{type: :holding}), do: "/screens/holdings"
  defp row_link(_item), do: nil

  defp row_attrs(%{type: :account, marked: true}),
    do: %{"aria-current": "true"}

  defp row_attrs(_item), do: %{}

  # A group per depot, its securities and its reference account; last the accounts of no depot.
  defp groups(depots, accounts, marked) do
    depot_groups =
      for depot <- depots do
        securities =
          for entry <- depot.holdings,
              do: %{type: :holding, id: "holding-#{entry.id}", entry: entry}

        reference = account_row(depot.account, join_meta(["Referenzkonto", "EUR"]), marked)
        %{id: depot.id, label: depot.name, rows: securities ++ [reference]}
      end

    case Enum.map(accounts, &account_row(&1, "EUR", marked)) do
      [] -> depot_groups
      rows -> depot_groups ++ [%{id: "konten", label: "Konten", rows: rows}]
    end
  end

  defp account_row(account, note, marked) do
    %{
      type: :account,
      id: "account-#{account.id}",
      entry: account,
      note: note,
      marked: account.id == marked
    }
  end

  defp total(depots, accounts) do
    securities = Enum.flat_map(depots, & &1.holdings)
    securities_value = sum(securities, :value)

    %{
      value: securities_value + sum(Enum.map(depots, & &1.account) ++ accounts, :value),
      securities_value: securities_value,
      cost: sum(securities, :cost),
      gain: sum(securities, :gain),
      dividends: sum(securities, :dividends)
    }
  end

  attr :allocation, :map, required: true, doc: "see `Data.allocation/0`"
  attr :tab, :atom, required: true, doc: "`:regions`, `:sectors` or `:classes`"
  attr :tabs, :list, required: true, doc: "each with its `label`, `path` and whether `active`"

  def allocation(assigns) do
    ~H"""
    <section id="allocation" aria-labelledby="allocation-title">
      <.section_heading id="allocation-title">Aufteilung</.section_heading>
      <.tabs label="Aufteilung nach" class="mb-4">
        <:tab :for={tab <- @tabs} patch={tab.path} active={tab.active}>{tab.label}</:tab>
      </.tabs>
      <.classes :if={@tab == :classes} rows={@allocation.classes} />
      <.composition :if={@tab != :classes} rows={Map.fetch!(@allocation, @tab)} />
    </section>
    """
  end

  # Regions or sectors seen through the funds, the largest at full width, „Ohne Angabe“ neutral.
  defp composition(assigns) do
    assigns = assign(assigns, :scale, assigns.rows |> Enum.map(&elem(&1, 1)) |> Enum.max())

    ~H"""
    <ul id="allocation-rows" class="flex flex-col gap-3">
      <li :for={{label, share} <- @rows}>
        <.bar
          label={label || "Ohne Angabe"}
          value={share / @scale * 100}
          show_value
          value_label={in_percent(share)}
          tone={if label, do: :primary, else: :neutral}
        />
      </li>
    </ul>
    <p class="mt-4 max-w-prose text-sm text-base-content/70">
      Durchsicht durch die Fonds mit den Länder- und Sektordaten des Kursanbieters, Stand
      30.09.2026. Konten zählen nicht mit. „Ohne Angabe“: Wertpapiere ohne Länder- oder
      Sektordaten.
    </p>
    """
  end

  # The asset classes against their targets.
  defp classes(assigns) do
    assigns =
      assign(assigns, :scale, assigns.rows |> Enum.flat_map(&[&1.share, &1.target]) |> Enum.max())

    ~H"""
    <ul id="allocation-rows" class="flex flex-col gap-3">
      <li :for={class <- @rows}>
        <.bar
          label={class.name}
          value={class.share / @scale * 100}
          target={class.target / @scale * 100}
          show_value
          value_label={in_percent(class.share)}
        >
          Ziel {in_percent(class.target)}
          <.badge :if={class[:deviation] == :below} tone={:error} class="ms-1">unter Ziel</.badge>
        </.bar>
      </li>
    </ul>
    <p class="mt-4 max-w-prose text-sm text-base-content/70">
      {join_meta(["Balken: Ist", "Strich: dein Ziel", "Ziele aus den Einstellungen"])}
    </p>
    """
  end

  attr :depots, :list, required: true

  # Running costs per security, the most expensive first.
  def costs(assigns) do
    funds =
      for(depot <- assigns.depots, entry <- depot.holdings, do: entry)
      |> Enum.map(&Map.put(&1, :per_year, &1.ter && round(&1.value * &1.ter / 100)))
      |> Enum.sort_by(&(&1.per_year || -1), :desc)

    with_ter = Enum.filter(funds, & &1.ter)
    per_year = sum(with_ter, :per_year)
    ter = if with_ter != [], do: per_year / sum(with_ter, :value) * 100

    assigns = assign(assigns, funds: funds, per_year: per_year, ter: ter)

    ~H"""
    <section id="costs" aria-labelledby="costs-title">
      <.section_heading id="costs-title">
        Kosten
        <:actions :if={@ter}>
          <span class="text-sm text-base-content/70">gewichtet {ter(@ter)}</span>
        </:actions>
      </.section_heading>
      <.table id="cost-rows" rows={@funds} row_id={&"cost-#{&1.id}"} size={:sm}>
        <:col :let={fund} label="Wertpapier">
          <.link navigate="/screens/holdings" class="hover:underline">{fund.name}</.link>
          <.cell_sub :if={fund.fund_size} hide_from={:sm} class="tabular-nums whitespace-nowrap">
            Fondsgröße {fund.fund_size}
          </.cell_sub>
        </:col>
        <:col :let={fund} label="TER" align={:end}>{ter(fund.ter)}</:col>
        <:col :let={fund} label="Größe" align={:end} show_from={:sm}>{fund.fund_size || "–"}</:col>
        <:col :let={fund} label="pro Jahr" align={:end}><.per_year cents={fund.per_year} /></:col>
        <:foot>
          <th scope="row">Gesamt</th>
          <td class="text-end">{ter(@ter)}</td>
          <td class={show_from(:sm)}></td>
          <td class="text-end whitespace-nowrap"><.per_year cents={@per_year} /></td>
        </:foot>
      </.table>
      <p class="mt-2 max-w-prose text-sm text-base-content/70">
        Laufende Kosten, die im Kurs stecken. Ordergebühren kommen aus den Buchungen.
        <span :if={Enum.any?(@funds, &is_nil(&1.ter))}>Wertpapiere ohne TER zählen nicht mit.</span>
      </p>
    </section>
    """
  end

  attr :cents, :integer, required: true, doc: "nil without a TER"

  defp per_year(assigns) do
    ~H"""
    <span :if={!@cents}>–</span><.amount :if={@cents} value={@cents} decimals={0} />
    """
  end

  defp shares(shares) when is_float(shares), do: Format.number(shares, decimals: 4)
  defp shares(shares), do: Format.number(shares)

  defp percent(value, total), do: in_percent(value / total * 100)

  defp in_percent(percent), do: Format.number(percent, decimals: 1) <> " %"

  defp ter(nil), do: "–"
  defp ter(ter), do: Format.number(ter, decimals: 2) <> " %"

  defp dividend_yield(0, _value), do: "–"
  defp dividend_yield(cents, value), do: percent(cents, value)

  defp sum(entries, key), do: entries |> Enum.map(&Map.fetch!(&1, key)) |> Enum.sum()
end
