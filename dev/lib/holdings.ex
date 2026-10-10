defmodule Setzkasten.Dev.Holdings do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten

  attr :groups, :list, required: true
  attr :flush, :boolean, default: false

  def holdings_table(assigns) do
    ~H"""
    <.table id="holdings" groups={@groups} row_link={fn _ -> "/screens/holdings" end} flush={@flush}>
      <:col :let={h} label="Wertpapier">
        {h.name}
        <.cell_sub :if={h.isin} show_from={:lg}>{h.isin}</.cell_sub>
        <.cell_sub :if={h[:shares]} hide_from={:lg}>
          {h.shares} Stück · <.amount value={h.price} />
        </.cell_sub>
        <.cell_sub :if={h[:sub]}>{h.sub}</.cell_sub>
      </:col>
      <:col :let={h} label="Stück" align={:end} show_from={:lg}>{h[:shares]}</:col>
      <:col :let={h} label="Kurs" align={:end} show_from={:lg}>
        <.amount :if={h[:price]} value={h.price} />
      </:col>
      <:col :let={h} label="Wert" align={:end}>
        <.amount value={h.value} />
        <.cell_sub :if={h[:gain]} hide_from={:sm}><.amount value={h.gain} signed tone /></.cell_sub>
      </:col>
      <:col :let={h} label="Einstand" align={:end} show_from={:md}>
        <.amount :if={h[:cost]} value={h.cost} />
      </:col>
      <:col :let={h} label="Gewinn" align={:end} show_from={:sm}>
        <%= if h[:gain] do %>
          <.amount value={h.gain} signed tone />
          <div class={["text-sm", gain_class(h.gain)]}>
            {Setzkasten.Format.number(h.gain_pct, decimals: 1, signed: true)}&nbsp;%
          </div>
        <% end %>
      </:col>
      <:col :let={h} label="Anteil" align={:end} show_from={:md}>
        {Setzkasten.Format.number(h.weight, decimals: 1)}&nbsp;%
      </:col>
      <:foot>
        <th scope="row">Gesamt</th>
        <td class={show_from(:lg)}></td>
        <td class={show_from(:lg)}></td>
        <td class="text-end whitespace-nowrap">
          <.amount value={6_327_914} />
          <div class="text-sm sm:hidden"><.amount value={1_035_254} signed tone /></div>
        </td>
        <td class={["text-end whitespace-nowrap", show_from(:md)]}><.amount value={3_681_146} /></td>
        <td class={["text-end whitespace-nowrap", show_from(:sm)]}>
          <.amount value={1_035_254} signed tone />
        </td>
        <td class={["text-end whitespace-nowrap", show_from(:md)]}>100&nbsp;%</td>
      </:foot>
    </.table>
    """
  end

  defp gain_class(gain) when gain < 0, do: "text-error-ink"
  defp gain_class(_gain), do: "text-success-ink"
end
