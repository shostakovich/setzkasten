defmodule Setzkasten.Dev.Pages.TablesPage do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  import Setzkasten.Dev.Demo
  alias Phoenix.LiveView.JS
  alias Setzkasten.Dev.Data

  def title, do: "Tabellen und Listen"
  def summary, do: "table, cell_sub, list, list_row, list_heading, Zahlentabelle"

  def render(assigns) do
    assigns =
      assign(assigns,
        entries: Data.entries(),
        costs: Data.costs(),
        posts: Enum.take(Data.posts(), 2),
        groups: Data.holdings()
      )

    ~H"""
    <.showcase
      id="table"
      name="<.table>"
      title="Tabelle"
      apps="Depot, Budget, Ausgaben"
      code={code(0)}
    >
      <:intro>
        Zahlenlastige Daten mit Spaltenprioritäten, Gruppenzeilen und Summen; flach auf der Seite
        zwischen Haarlinien, auf dem Handy randlos. Breite Tabellen scrollen in ihrem Container.
      </:intro>
      <.demo title=":md (Standard) mit Zeilen-Link">
        <.table id="entries" rows={@entries} row_link={fn _ -> "/tables" end}>
          <:col :let={e} label="Datum" class="whitespace-nowrap">{e.date}</:col>
          <:col :let={e} label="Titel">{e.title}</:col>
          <:col :let={e} label="Betrag" align={:end}><.amount value={e.amount} signed tone /></:col>
        </.table>
      </.demo>
      <.demo title=":sm, zebra, Summe im tfoot (nur Lesetabellen)">
        <.table id="costs" rows={@costs} size={:sm} zebra>
          <:col :let={c} label="Wertpapier">{c.name}</:col>
          <:col :let={c} label="TER" align={:end}>{c.ter}</:col>
          <:col :let={c} label="pro Jahr" align={:end}>{c.year}</:col>
          <:foot>
            <th scope="row">Gesamt</th>
            <td class="text-end whitespace-nowrap">0,20&nbsp;%</td>
            <td class="text-end whitespace-nowrap">76&nbsp;€</td>
          </:foot>
        </.table>
      </.demo>
      <.demo title="Leer (:empty-Slot)">
        <.table id="empty-entries" rows={[]}>
          <:col :let={e} label="Datum">{e.date}</:col>
          <:col :let={e} label="Titel">{e.title}</:col>
          <:col :let={e} label="Betrag" align={:end}><.amount value={e.amount} /></:col>
          <:empty>
            <.empty_state icon="inbox" title="Keine Buchungen im Oktober">
              Importiere einen Kontoauszug oder trag eine Buchung von Hand ein.
            </.empty_state>
          </:empty>
        </.table>
      </.demo>
    </.showcase>

    <section id="muster-tabelle" class="space-y-6">
      <div class="space-y-1">
        <h2 class="text-xl font-semibold">Muster: responsive Zahlentabelle (Depot-Bestand)</h2>
        <p class="max-w-prose">
          Höchstens zwei Spalten immer sichtbar: Name und Wert. Gewinn ab <code>sm</code>, Einstand
          und Anteil ab <code>md</code>, Stück und Kurs ab <code>lg</code>; was fehlt, steht als
          Unterzeile da. Fensterbreite ändern, um die Stufen zu sehen.
        </p>
      </div>
      <pre class="rounded-box bg-base-200 px-4 py-3 text-xs leading-5 overflow-x-auto"><code>{code(1)}</code></pre>
      <Setzkasten.Dev.Holdings.holdings_table groups={@groups} />
    </section>

    <.showcase id="list" name="<.list>, <.list_row>" title="Liste" apps="alle fünf" code={code(2)}>
      <:intro>
        Sammlungen mit Bild vorne, Titel, Meta-Zeile, Wert und Zeilenaktionen. Aktionen ab
        <code>md</code>
        als Icon-Buttons, darunter im ⋮-Menü. Zeilen mit Ziel bekommen einen Pfeil.
      </:intro>
      <.demo title="Posts (CMS), Aktionen mit Bestätigung">
        <.list>
          <.list_row
            :for={post <- @posts}
            id={"post-#{post.id}"}
            title={post.title}
            navigate="/tables"
          >
            <:leading><.icon name="file-text" class="size-5 text-base-content/70" /></:leading>
            <:meta>{post.meta}</:meta>
            <:trailing>
              <.badge :if={post.status == :published} tone={:success}>Veröffentlicht</.badge>
              <.badge :if={post.status == :draft}>Entwurf</.badge>
            </:trailing>
            <:action label="Bearbeiten" icon="pencil" navigate="/tables" />
            <:action
              label="Löschen"
              icon="trash-2"
              danger
              confirm={"„#{post.title}“ löschen?"}
              on_click={JS.push("delete", value: %{title: post.title})}
            />
          </.list_row>
        </.list>
      </.demo>
      <.demo title="Ausgaben mit Datumsgruppen und Plüsch">
        <.list>
          <.list_heading>Heute</.list_heading>
          <.list_row title="Wocheneinkauf" navigate="/tables">
            <:leading><.plush name="cart" size={:lg} /></:leading>
            <:meta>Jonas für alle · Lebensmittel</:meta>
            <:trailing><.amount value={8742} /></:trailing>
          </.list_row>
          <.list_row title="Pizza Da Michele" navigate="/tables">
            <:leading><.plush name="utensils" size={:lg} /></:leading>
            <:meta>Dana für Jonas, Dana</:meta>
            <:trailing><.amount value={4350} /></:trailing>
          </.list_row>
          <.list_heading>Montag, 5. Oktober</.list_heading>
          <.list_row title="Abschlag Strom Oktober" navigate="/tables">
            <:leading><.plush name="zap" size={:lg} /></:leading>
            <:meta>Dana für alle · wiederkehrend</:meta>
            <:trailing>
              <.badge icon="repeat" label="Wiederkehrend" /><.amount value={11_200} />
            </:trailing>
          </.list_row>
        </.list>
        <div class="pt-3"><.button size={:sm}>Mehr laden</.button></div>
      </.demo>
    </.showcase>
    """
  end

  defp code(0) do
    ~S"""
    <.table id="activity" rows={@entries} row_link={&~p"/buchungen/#{&1}"}>
      <:col :let={e} label="Datum">{e.date}</:col>
      <:col :let={e} label="Titel">{e.title}</:col>
      <:col :let={e} label="Betrag" align={:end}><.amount value={e.amount} signed tone /></:col>
      <:empty><.empty_state icon="inbox">Noch keine Buchungen.</.empty_state></:empty>
    </.table>
    """
  end

  defp code(1) do
    ~S"""
    <.table id="holdings" groups={@groups} row_link={&~p"/wertpapiere/#{&1}"}>
      <:col :let={h} label="Wertpapier">
        {h.name}
        <.cell_sub show_from={:lg}>{h.isin}</.cell_sub>
        <.cell_sub hide_from={:lg}>{h.shares} Stück · <.amount value={h.price} /></.cell_sub>
      </:col>
      <:col :let={h} label="Stück" align={:end} show_from={:lg}>{h.shares}</:col>
      <:col :let={h} label="Wert" align={:end}>
        <.amount value={h.value} />
        <.cell_sub hide_from={:sm}><.amount value={h.gain} signed tone /></.cell_sub>
      </:col>
      <:col :let={h} label="Gewinn" align={:end} show_from={:sm}><.amount value={h.gain} signed tone /></:col>
      <:foot>…Gesamt…</:foot>
    </.table>
    """
  end

  defp code(2) do
    ~S"""
    <.list>
      <.list_row :for={post <- @posts} title={post.title} navigate={~p"/posts/#{post}"}>
        <:leading><.icon name="file-text" class="size-5" /></:leading>
        <:meta>Geändert am 07.10.2026 · 1.240 Wörter</:meta>
        <:trailing><.badge tone={:success}>Veröffentlicht</.badge></:trailing>
        <:action label="Bearbeiten" icon="pencil" navigate={~p"/posts/#{post}/edit"} />
        <:action label="Löschen" icon="trash-2" danger confirm="Post löschen?"
                 on_click={JS.push("delete", value: %{id: post.id})} />
      </.list_row>
    </.list>
    """
  end
end
