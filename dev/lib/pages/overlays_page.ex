defmodule Setzkasten.Dev.Pages.OverlaysPage do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  import Setzkasten.Dev.Demo

  def title, do: "Dialoge"
  def summary, do: "modal, confirm_dialog, disclosure"

  def render(assigns) do
    ~H"""
    <.showcase
      id="modal"
      name="<.modal>"
      title="Dialog"
      apps="Hausautomation, CMS, Budget"
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
        <.button icon="panel-left" phx-click={show_modal("category-panel")} aria-haspopup="dialog">
          Seitenpanel öffnen
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
      apps="alle (E6b)"
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
    </.showcase>

    <.showcase
      id="disclosure"
      name="<.disclosure>"
      title="Aufklappbereich"
      apps="Hausautomation, CMS, Depot, Ausgaben"
      code={code(2)}
    >
      <:intro>
        Selten gebrauchte Optionen und Details; Zusammenfassung mindestens 44px auf Touch. Der
        offene Zustand übersteht LiveView-Updates.
      </:intro>
      <.demo title="Zu, offen, als Button" class="space-y-4">
        <.disclosure id="split-more" summary="Weitere Aufteilungsoptionen">
          Nach Anteilen oder mit genauen Beträgen je Person aufteilen.
        </.disclosure>
        <.disclosure id="values-open" summary="Werte als Tabelle (offen)" open>
          Oktober 9,8&nbsp;kWh · September 212,4&nbsp;kWh · August 341,0&nbsp;kWh
        </.disclosure>
        <.disclosure id="more-options" variant={:button} icon="settings" summary="Weitere Optionen">
          <.input name="o[notify]" id="o-notify" type="toggle" label="Beteiligte benachrichtigen" />
        </.disclosure>
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
    """
  end

  defp code(1) do
    ~S"""
    <%!-- once, in the app layout --%>
    <.confirm_dialog id="confirm-delete" />

    <.button variant={:danger_outline} icon="trash-2" confirm="Ausgabe löschen?"
             phx-click="delete" phx-value-id={@expense.id}>Löschen</.button>
    """
  end

  defp code(2) do
    ~S"""
    <.disclosure id="split-more" summary="Weitere Aufteilungsoptionen">…</.disclosure>
    """
  end
end
