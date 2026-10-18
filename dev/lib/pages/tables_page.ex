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
        holdings: Data.holdings()
      )

    ~H"""
    <.showcase
      id="table"
      name="<.table>"
      title="Tabelle"
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
      <.demo title="row_attrs (aktuelle Zeile: aria-current), Zeile ohne Ziel (row_link gibt nil)">
        <.table
          id="entries-attrs"
          rows={@entries}
          row_link={&entry_link/1}
          row_attrs={&entry_attrs/1}
        >
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
      <.demo title=":dense (Datenraster), eine Zeile in Bearbeitung">
        <.table
          id="entries-dense"
          rows={@entries}
          size={:dense}
          row_attrs={&%{"aria-current": &1.id == 2 && "true"}}
        >
          <:col :let={e} label="Datum" class="whitespace-nowrap">{e.date}</:col>
          <:col :let={e} label="Titel">
            <.input
              :if={e.id == 2}
              id="dense-title"
              name="title"
              value={e.title}
              label="Titel"
              hide_label
            />
            <span :if={e.id != 2}>{e.title}</span>
          </:col>
          <:col :let={e} label="Betrag" align={:end}>
            <.input
              :if={e.id == 2}
              id="dense-amount"
              name="amount"
              value="−112,00"
              label="Betrag"
              hide_label
              numeric
              suffix="€"
              class="max-w-32 ms-auto"
            />
            <.amount :if={e.id != 2} value={e.amount} signed tone />
          </:col>
          <:col :let={e} label="" class="w-0">
            <.button :if={e.id == 2} size={:sm} icon="check" icon_only label="Speichern" />
          </:col>
        </.table>
        <:note>
          36px-Zeilen mit der Feinzeigerhöhe, 44px mit dem Finger; Felder und Buttons in Zellen
          sind 32px hoch, so bleibt die Zeile beim Bearbeiten gleich hoch. Die bearbeitete Zeile
          trägt <code>aria-current</code>: Fläche <code>row-selected</code> und ein 3px-Balken vorn.
        </:note>
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
          und Anteil ab <code>md</code>, Dividendenrendite ab <code>lg</code>, Stück und Kurs ab <code>xl</code>; was fehlt, steht als Unterzeile da. Kontozeilen haben kein Ziel
          (<code>row_link</code> gibt nil). Fensterbreite ändern, um die Stufen zu sehen.
        </p>
      </div>
      <pre class="rounded-box bg-base-200 px-4 py-3 text-xs leading-5 overflow-x-auto"><code>{code(1)}</code></pre>
      <Setzkasten.Dev.Holdings.holdings_table holdings={@holdings} />
    </section>

    <.showcase id="list" name="<.list>, <.list_row>" title="Liste" code={code(2)}>
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
            <:meta>Dein Saldo: <.amount value={-2175} signed tone={:negative} /></:meta>
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
      <.demo title="Betrag in der Titelzeile (trailing_on_phone={:title})">
        <.list>
          <.list_row title="Kinderdepot" navigate="/tables" trailing_on_phone={:title}>
            <:leading><.avatar icon="wallet" tone={:base} /></:leading>
            <:meta>2 Wertpapiere<.meta_sep />Konto <.amount value={786_774} /></:meta>
            <:trailing>
              <.amount value={949_047} class="font-semibold" />
              <span class="text-sm text-success-ink">+1,7&nbsp;% YTD</span>
            </:trailing>
          </.list_row>
          <.list_row title="Steuerrückerstattung" navigate="/tables" trailing_on_phone={:title}>
            <:leading><.avatar icon="wallet" tone={:base} /></:leading>
            <:meta>{join_meta(["08.03.2024", "Girokonto"])}</:meta>
            <:trailing><.amount value={300} signed tone /></:trailing>
            <:action label="Bearbeiten" icon="pencil" navigate="/tables" />
            <:action label="Löschen" icon="trash-2" on_click="noop" danger />
          </.list_row>
        </.list>
        <:note>
          Unter <code>md</code>
          bleibt ein kurzer Wert am Ende der Titelzeile, beide Zeilen rechtsbündig; die
          Meta-Zeile nimmt darunter die volle Breite (wie ein Kontoauszug).
        </:note>
      </.demo>
      <.demo title="Summe unter der Liste (:foot), auch mit Aktionen">
        <.list id="foot-demo">
          <.list_row
            :for={{title, value} <- [{"Miete", -118_000}, {"Strom", -8_600}, {"Gehalt", 312_450}]}
            title={title}
            trailing_on_phone={:title}
          >
            <:meta>Oktober</:meta>
            <:trailing><.amount value={value} signed tone /></:trailing>
            <:action label="Bearbeiten" icon="pencil" navigate="/tables" />
            <:action label="Löschen" icon="trash-2" on_click="noop" danger />
          </.list_row>
          <:foot label="Summe" actions={2}><.amount value={185_850} signed tone /></:foot>
        </.list>
      </.demo>
      <.demo title="Titel als Button (on_click), z. B. für einen Dialog">
        <.list>
          <.list_heading id="accounts-heading">Konten</.list_heading>
          <.list_row title="Girokonto" on_click={show_modal("account-detail")}>
            <:leading><.avatar initials="GK" size={:sm} /></:leading>
            <:meta>DE02 1203 0000 0000 2020 51</:meta>
            <:trailing><.amount value={248_310} /></:trailing>
          </.list_row>
          <.list_row title="Tagesgeld" on_click={show_modal("account-detail")}>
            <:leading><.avatar initials="TG" tone={:success} size={:sm} /></:leading>
            <:meta>DE89 3704 0044 0532 0130 00</:meta>
            <:trailing><.amount value={1_200_000} /></:trailing>
          </.list_row>
        </.list>
        <.modal id="account-detail" title="Konto">
          <p class="py-4 text-sm">Details zum Konto.</p>
        </.modal>
        <:note>
          Ein <code>&lt;button&gt;</code>
          über die ganze Zeile, Hover-Fläche wie bei Links; der Tastaturfokus umrandet die Zeile.
        </:note>
      </.demo>
      <.demo title="Kompakt (size={:dense}) und gedämpft (muted)">
        <.list size={:dense}>
          <.list_row title="Bananen" on_click="noop">
            <:leading><.plush name="cart" size={:lg} /></:leading>
            <:meta>6 Stück, nicht zu reif</:meta>
          </.list_row>
          <.list_row title="Brot" on_click="noop">
            <:leading><.plush name="utensils" size={:lg} /></:leading>
          </.list_row>
          <.list_row title="Butter" on_click="noop" muted>
            <:leading><.plush name="utensils" size={:lg} /></:leading>
          </.list_row>
        </.list>
        <:note>
          Zeilen 53px, auch mit Meta-Zeile. Abhaken mit <code>exit={"{:strike}"}</code>,
          „Zuletzt verwendet“ und Eingabeleiste zeigt die Einkaufsliste: <.link
            navigate="/screens/shopping"
            class="link"
          >/screens/shopping</.link>.
        </:note>
      </.demo>
    </.showcase>
    """
  end

  defp entry_link(%{amount: amount}) when amount < 0, do: "/tables"
  defp entry_link(_entry), do: nil

  defp entry_attrs(%{id: 1}), do: %{"aria-current": "true"}
  defp entry_attrs(_entry), do: %{}

  defp code(0) do
    ~S"""
    <.table id="activity" rows={@entries} row_link={&~p"/buchungen/#{&1}"}>
      <:col :let={e} label="Datum">{e.date}</:col>
      <:col :let={e} label="Titel">{e.title}</:col>
      <:col :let={e} label="Betrag" align={:end}><.amount value={e.amount} signed tone /></:col>
      <:empty><.empty_state icon="inbox">Noch keine Buchungen.</.empty_state></:empty>
    </.table>

    <%!-- nil: this row has no link; row_attrs: extra <tr> attributes, class is merged --%>
    <.table id="activity" rows={@entries}
      row_link={&if(&1.editable, do: ~p"/buchungen/#{&1}")}
      row_attrs={&%{"aria-current": &1.id == @current && "true", "data-kind": &1.kind}}>
      …
    </.table>

    <%!-- data grid: 36px rows (44px on touch), 32px controls in cells --%>
    <.table id="register" rows={@rows} size={:dense}>
      <:col :let={r} label="Titel"><.input name="title" value={r.title} label="Titel" hide_label /></:col>
      …
    </.table>
    """
  end

  defp code(1) do
    ~S"""
    <.table id="holdings" groups={@groups} row_link={&if(&1.isin, do: ~p"/wertpapiere/#{&1}")}>
      <:col :let={h} label="Wertpapier">
        {h.name}
        <.cell_sub show_from={:xl}>{h.isin}</.cell_sub>
        <.cell_sub hide_from={:xl}>{h.shares} Stück<.meta_sep /><.amount value={h.price} /></.cell_sub>
      </:col>
      <:col :let={h} label="Stück" align={:end} show_from={:xl}>{h.shares}</:col>
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
        <%!-- join_meta/1 and <.meta_sep />: the dot never starts a line --%>
        <:meta>{join_meta(["Geändert am 07.10.2026", "1.240 Wörter"])}</:meta>
        <:trailing><.badge tone={:success}>Veröffentlicht</.badge></:trailing>
        <:action label="Bearbeiten" icon="pencil" navigate={~p"/posts/#{post}/edit"} />
        <:action label="Löschen" icon="trash-2" danger confirm="Post löschen?"
                 on_click={JS.push("delete", value: %{id: post.id})} />
      </.list_row>
    </.list>

    <%!-- a short value stays on the title line on phones, meta takes the width below --%>
    <.list_row title={depot.name} navigate={…} trailing_on_phone={:title}>
      <:meta>{depot.count} Wertpapiere<.meta_sep />Konto <.amount value={depot.cash} /></:meta>
      <:trailing><.amount value={depot.value} /><span class="text-sm">+1,7 % YTD</span></:trailing>
    </.list_row>

    <%!-- the title as a button: on_click takes an event name (+ phx-target) or %JS{} --%>
    <.list_row title={account.name} on_click={JS.push("edit", value: %{id: account.id})} />

    <%!-- shopping list: 53px rows, a tap strikes the title, the removed row collapses --%>
    <.list id="items" size={:dense} phx-update="stream">
      <.list_row :for={{id, item} <- @streams.items} id={id} title={item.name} exit={:strike}
                 on_click={JS.push("check", value: %{id: item.id})}>
        <:leading><.plush name={item.plush} size={:lg} /></:leading>
        <:meta :if={item.note}>{item.note}</:meta>
      </.list_row>
    </.list>
    <.list id="recent" size={:dense}>
      <.list_row :for={item <- @recent} id={"recent-#{item.id}"} title={item.name} muted
                 on_click={JS.push("uncheck", value: %{id: item.id})} />
    </.list>
    """
  end
end
