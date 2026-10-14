defmodule Setzkasten.Dev.Pages.OverlaysPage do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  import Setzkasten.Dev.Demo
  alias Phoenix.LiveView.JS

  def title, do: "Dialoge"
  def summary, do: "modal, confirm_dialog, popover, disclosure, tooltip"

  def render(assigns) do
    ~H"""
    <.showcase
      id="modal"
      name="<.modal>"
      title="Dialog"
      code={code(0)}
    >
      <:intro>
        Natives <code>&lt;dialog&gt;</code>: auf dem Handy ein Blatt von unten, ab <code>sm</code>
        mittig; <code>:end</code>/<code>:start</code>
        als Seitenpanel. Escape, Klick auf den
        Hintergrund und Fokus-Rückgabe kommen vom Browser.
      </:intro>
      <.demo title="Öffnen" class="flex flex-wrap gap-3">
        <.button variant={:primary} phx-click={show_modal("booking")} aria-haspopup="dialog">
          Dialog öffnen
        </.button>
        <.button
          icon="panel-left-open"
          phx-click={show_modal("category-panel")}
          aria-haspopup="dialog"
        >
          Seitenpanel öffnen
        </.button>
        <.button phx-click={show_modal("long-form")} aria-haspopup="dialog">
          Langes Formular (sticky action_bar)
        </.button>
      </.demo>
      <.modal id="booking" title="Buchung bearbeiten">
        <div class="grid gap-4 py-4">
          <.input name="m[payee]" id="m-payee" label="Empfänger" value="Tankstelle Aral" />
          <.input
            name="m[amount]"
            id="m-amount"
            label="Betrag"
            value="64,30"
            suffix="€"
            numeric
            class="max-w-40"
          />
        </div>
        <:actions>
          <.button phx-click={hide_modal("booking")}>Abbrechen</.button>
          <.button variant={:primary} phx-click={hide_modal("booking")}>Speichern</.button>
        </:actions>
      </.modal>
      <.modal id="long-form" title="Dauerauftrag anlegen">
        <form class="grid gap-4 pt-4" phx-submit="noop">
          <.segmented
            id="l-kind"
            label="Art"
            mode={:radio}
            name="l[kind]"
            value="transfer"
            block
            options={[{"Überweisung", "transfer"}, {"Lastschrift", "debit"}]}
          />
          <.input name="l[payee]" id="l-payee" label="Empfänger" value="Hausverwaltung Ost" />
          <.input name="l[iban]" id="l-iban" label="IBAN" value="DE02 1203 0000 0000 2020 51" />
          <.input
            name="l[amount]"
            id="l-amount"
            label="Betrag"
            value="1.180,00"
            suffix="€"
            numeric
            class="max-w-40"
          />
          <.input
            name="l[first]"
            id="l-first"
            type="date"
            label="Erste Ausführung"
            value="2026-11-01"
          />
          <.input
            name="l[interval]"
            id="l-interval"
            type="select"
            label="Rhythmus"
            options={[{"Monatlich", "monthly"}, {"Vierteljährlich", "quarterly"}]}
            value="monthly"
          />
          <.input name="l[purpose]" id="l-purpose" type="textarea" label="Verwendungszweck" rows="3" />
          <.input name="l[notify]" id="l-notify" type="toggle" label="Vor jeder Ausführung erinnern" />
          <.action_bar sticky>
            <:secondary>
              <.button
                type="button"
                id="long-form-discard"
                variant={:danger_outline}
                icon="trash-2"
                phx-click={hide_modal("long-form")}
              >
                Verwerfen
              </.button>
            </:secondary>
            <.button type="button" phx-click={hide_modal("long-form")}>Abbrechen</.button>
            <.button type="submit" variant={:primary} phx-click={hide_modal("long-form")}>
              Anlegen
            </.button>
          </.action_bar>
        </form>
      </.modal>
      <.modal id="category-panel" title="Kategorie Lebensmittel" placement={:end}>
        <p class="py-4 text-sm">
          Budget Oktober <.amount value={45_000} />, ausgegeben <.amount value={31_248} />.
        </p>
        <.bar label="Verbraucht" value={69} show_value />
      </.modal>
    </.showcase>

    <.showcase
      id="confirm"
      name="<.confirm_dialog>"
      title="Löschen bestätigen"
      code={code(1)}
    >
      <:intro>
        Jede unumkehrbare Löschung fragt in einem gemeinsamen Dialog; Archivieren fragt nicht. Die
        Löschaktion liegt auf dem Bestätigen-Button des Dialogs; Abbrechen, Escape und Hintergrund
        schließen nur. Der Fokus startet auf „Abbrechen“.
      </:intro>
      <.demo title="Auslöser" class="flex flex-wrap gap-3">
        <.button
          variant={:danger_outline}
          icon="trash-2"
          confirm="Ausgabe „Wocheneinkauf“ löschen?"
          confirm_text="87,42 €, bezahlt von Jonas. Das lässt sich nicht rückgängig machen."
          phx-click="delete"
          phx-value-title="Wocheneinkauf"
        >
          Löschen
        </.button>
        <.button icon="archive">Archivieren (ohne Frage)</.button>
        <:note>Bisher gelöscht (Demo): {@deleted}</:note>
      </.demo>
      <.demo title="In einer LiveComponent, phx-target">
        <.live_component module={Setzkasten.Dev.TargetDemo} id="target-demo" />
        <:note>
          Das Ereignis geht mit <code>phx-target</code>
          an die Komponente, nicht an die Seite; der Zähler oben bleibt stehen.
        </:note>
      </.demo>
    </.showcase>

    <.showcase id="popover" name="<.popover>" title="Popover" code={code(4)}>
      <:intro>
        Freier Inhalt an seinem Auslöser, meist ein kleines Formular; kein Menü. Liegt in der
        obersten Ebene (Popover-API) und entkommt so scrollenden Tabellen. Schließt bei Klick
        daneben, mit Escape und <code>hide_popover/1</code>; Escape gibt den Fokus zurück. Platziert
        per CSS-Anchor-Positioning, sonst per Hook; kippt, wenn kein Platz ist. Unter <code>sm</code>
        ein Blatt von unten.
      </:intro>
      <.demo title="Formular, align={:end}, position={:top}" class="flex flex-wrap gap-3">
        <.popover id="pop-rename" title="Kategorie umbenennen">
          <:trigger><.icon name="pencil" />Umbenennen</:trigger>
          <form
            id="pop-rename-form"
            class="grid gap-3"
            phx-submit={JS.push("rename") |> hide_popover("pop-rename")}
          >
            <.input name="name" id="pop-rename-name" label="Name" value="Lebensmittel" autofocus />
            <div class="flex justify-end gap-2">
              <.button
                id="pop-rename-delete"
                size={:sm}
                variant={:danger_outline}
                class="me-auto"
                confirm="Kategorie „Lebensmittel“ löschen?"
                phx-click={JS.push("delete") |> hide_popover("pop-rename")}
              >
                Löschen
              </.button>
              <.button size={:sm} phx-click={hide_popover("pop-rename")}>Abbrechen</.button>
              <.button type="submit" size={:sm} variant={:primary}>Speichern</.button>
            </div>
          </form>
        </.popover>
        <.popover id="pop-end" title="Farbe" align={:end} variant={:ghost} chevron>
          <:trigger>Markierung</:trigger>
          <p>Rechtsbündig am Auslöser, mit Pfeil.</p>
        </.popover>
        <.popover id="pop-top" position={:top} label="Hinweis" trigger_class="btn-square">
          <:trigger><.icon name="info" /></:trigger>
          <p class="max-w-60">Öffnet nach oben, für Auslöser am unteren Rand.</p>
        </.popover>
      </.demo>
      <.demo title="In einer scrollenden Tabelle, vom Server geöffnet (anchor, show, on_cancel)">
        <div class="max-h-40 overflow-auto rounded-box border border-base-content/10">
          <table class="table">
            <tbody>
              <tr :for={{cell, label, amount} <- cover_cells()}>
                <td>{label}</td>
                <td class="text-end">
                  <button
                    id={"cover-#{cell}"}
                    type="button"
                    class="btn btn-ghost btn-sm tabular-nums"
                    aria-haspopup="dialog"
                    phx-click="open_cover"
                    phx-value-cell={cell}
                  >
                    <.amount value={amount} tone />
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <.popover
          :if={@cover}
          id="pop-cover"
          title="Überzug decken"
          anchor={"cover-#{@cover}"}
          align={:end}
          show
          on_cancel={JS.push("cover_closed")}
        >
          <form id="pop-cover-form" class="grid gap-3" phx-submit="cover">
            <.input
              name="from"
              id="pop-cover-from"
              type="select"
              label="Decken aus"
              options={["Zu verteilen", "Urlaub", "Geschenke"]}
              autofocus
            />
            <.button type="submit" size={:sm} variant={:primary} class="justify-self-end">
              Decken
            </.button>
          </form>
        </.popover>
        <:note>
          Der Betrag öffnet das Popover über den Server; es entkommt dem Rahmen der Tabelle.
        </:note>
      </.demo>
    </.showcase>

    <.showcase
      id="disclosure"
      name="<.disclosure>"
      title="Aufklappbereich"
      code={code(2)}
    >
      <:intro>
        Selten gebrauchte Optionen und Details; Zusammenfassung mindestens 44px auf Touch. Der
        offene Zustand übersteht LiveView-Updates.
      </:intro>
      <.demo title="Zu, offen, mit Anzahl, als Button" class="space-y-4">
        <.disclosure id="split-more" summary="Weitere Aufteilungsoptionen">
          Nach Anteilen oder mit genauen Beträgen je Person aufteilen.
        </.disclosure>
        <.disclosure id="values-open" summary="Werte als Tabelle (offen)" open>
          Oktober 9,8&nbsp;kWh · September 212,4&nbsp;kWh · August 341,0&nbsp;kWh
        </.disclosure>
        <.disclosure id="retired-funds" summary="Ausgemustert" count={2}>
          Zwei Fonds ohne Bestand.
        </.disclosure>
        <.disclosure id="more-options" variant={:button} icon="settings" summary="Weitere Optionen">
          <.input name="o[notify]" id="o-notify" type="toggle" label="Beteiligte benachrichtigen" />
        </.disclosure>
      </.demo>
    </.showcase>

    <.showcase id="tooltip" name="<.tooltip>" title="Tooltip" code={code(3)}>
      <:intro>
        Ein kurzer Hinweis bei Zeiger und Tastaturfokus. Screenreader bekommen den Text als
        Beschreibung des ersten fokussierbaren Elements, außer er wiederholt nur dessen Namen. Auf
        Touch-Geräten erscheint er höchstens beim Tippen: nie für etwas, das man wissen muss.
      </:intro>
      <.demo title="Oben, unten, links, rechts" class="flex flex-wrap items-center gap-6 py-8">
        <.tooltip id="tip-sync" text="Zuletzt vor 5 Minuten abgeglichen">
          <.button icon="refresh-cw">Abgleichen</.button>
        </.tooltip>
        <.tooltip id="tip-edit" text="Bearbeiten" placement={:bottom}>
          <.button variant={:ghost} icon="pencil" icon_only label="Bearbeiten" />
        </.tooltip>
        <.tooltip id="tip-left" text="Wird am Monatsende gebucht" placement={:left}>
          <.badge tone={:info} tabindex="0">Geplant</.badge>
        </.tooltip>
        <.tooltip id="tip-right" text="Gemeinsames Haushaltskonto" placement={:right}>
          <span class="inline-block max-w-32 truncate text-sm" tabindex="0">
            Gemeinsames Haushaltskonto
          </span>
        </.tooltip>
      </.demo>
    </.showcase>
    """
  end

  defp code(0) do
    ~S"""
    <.button phx-click={show_modal("booking")}>Buchung</.button>
    <.modal id="booking" title="Buchung bearbeiten" on_cancel={JS.patch(~p"/konten")}>
      …
      <:actions>
        <.button phx-click={hide_modal("booking")}>Abbrechen</.button>
        <.button type="submit" form="booking-form" variant={:primary}>Speichern</.button>
      </:actions>
    </.modal>

    <%!-- long form: a sticky action bar pins to the dialog's bottom edge --%>
    <.modal id="standing-order" title="Dauerauftrag anlegen">
      <.form for={@form} phx-submit="save">
        …
        <.action_bar sticky>
          <.button phx-click={hide_modal("standing-order")}>Abbrechen</.button>
          <.button type="submit" variant={:primary}>Anlegen</.button>
        </.action_bar>
      </.form>
    </.modal>
    """
  end

  defp code(1) do
    ~S"""
    <%!-- once, in the app layout --%>
    <.confirm_dialog id="confirm-delete" />

    <.button variant={:danger_outline} icon="trash-2" confirm="Ausgabe löschen?"
             phx-click="delete" phx-value-id={@expense.id}>Löschen</.button>

    <%!-- inside a live component --%>
    <.button confirm="Eintrag löschen?" phx-click="delete" phx-target={@myself}>Löschen</.button>
    """
  end

  defp code(4) do
    ~S"""
    <.popover id="rename" title="Kategorie umbenennen">
      <:trigger><.icon name="pencil" /> Umbenennen</:trigger>
      <form phx-submit={JS.push("rename") |> hide_popover("rename")} class="grid gap-3">
        <.input name="name" id="rename-name" label="Name" value={@category.name} autofocus />
        <.button type="submit" variant={:primary} size={:sm}>Speichern</.button>
      </form>
    </.popover>

    <%!-- opened by the server at a cell elsewhere --%>
    <.popover :if={@cover} id="cover" title="Überzug decken" anchor={"cover-#{@cover}"}
              align={:end} show on_cancel={JS.push("cover_closed")}>…</.popover>
    """
  end

  defp code(3) do
    ~S"""
    <.tooltip id="sync-hint" text="Zuletzt vor 5 Minuten abgeglichen">
      <.button icon="refresh-cw">Abgleichen</.button>
    </.tooltip>
    <%!-- the text repeats the button's name: no description --%>
    <.tooltip id="edit-hint" text="Bearbeiten" placement={:bottom}>
      <.button variant={:ghost} icon="pencil" icon_only label="Bearbeiten" />
    </.tooltip>
    """
  end

  defp code(2) do
    ~S"""
    <.disclosure id="split-more" summary="Weitere Aufteilungsoptionen">…</.disclosure>
    <.disclosure id="retired" summary="Ausgemustert" count={length(@retired)}>…</.disclosure>
    """
  end

  defp cover_cells do
    for {label, amount, i} <- [
          {"Lebensmittel", -4_210, 1},
          {"Tanken", -1_890, 2},
          {"Drogerie", -560, 3},
          {"Geschenke", -2_500, 4},
          {"Urlaub", -12_000, 5}
        ],
        do: {"cell-#{i}", label, amount}
  end
end
