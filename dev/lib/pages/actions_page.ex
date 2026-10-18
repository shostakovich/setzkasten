defmodule Setzkasten.Dev.Pages.ActionsPage do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  import Setzkasten.Dev.Demo

  def title, do: "Aktionen"
  def summary, do: "button, fab, selection_bar, composer"

  def render(assigns) do
    ~H"""
    <.showcase
      id="button"
      name="<.button>"
      title="Schaltfläche"
      code={code(0)}
    >
      <:intro>Jede Aktion; feste Varianten.</:intro>
      <.demo title="Varianten" class="flex flex-wrap items-center gap-3">
        <.button variant={:primary}>Speichern</.button>
        <.button>Abbrechen</.button>
        <.button variant={:ghost}>Zurücksetzen</.button>
        <.button variant={:danger}>Löschen</.button>
        <.button variant={:danger_outline}>Depot entfernen</.button>
        <.button variant={:link}>Filter zurücksetzen</.button>
        <:note>:primary · :neutral (Standard) · :ghost · :danger · :danger_outline · :link</:note>
      </.demo>
      <.demo title="Größen" class="flex flex-wrap items-center gap-3">
        <.button variant={:primary} size={:sm}>Klein</.button>
        <.button variant={:primary}>Mittel</.button>
        <.button variant={:primary} size={:lg}>Groß</.button>
        <:note>32 / 40 / 48px mit Maus; auf Touch mindestens 44px (Theme-Patch).</:note>
      </.demo>
      <.demo title="Mit Icon, nur Icon, als Link" class="flex flex-wrap items-center gap-3">
        <.button variant={:primary} icon="plus">Neue Ausgabe</.button>
        <.button icon="download">Exportieren</.button>
        <.button variant={:ghost} icon="pencil" icon_only label="Bearbeiten" />
        <.button
          variant={:ghost}
          icon="trash-2"
          icon_only
          label="Löschen"
          confirm="Ausgabe „Wocheneinkauf“ löschen?"
          confirm_text="87,42 €, bezahlt von Jonas. Das lässt sich nicht rückgängig machen."
          phx-click="delete"
          phx-value-title="Wocheneinkauf"
        />
        <.button variant={:ghost} size={:sm} icon="x" icon_only label="Schließen" />
        <.button navigate="/tables" size={:sm}>
          Alle Depots<.icon name="chevron-right" />
        </.button>
      </.demo>
      <.demo title="Zustände" class="flex flex-wrap items-center gap-3">
        <.button variant={:primary}>Standard</.button>
        <.button variant={:primary} disabled>Deaktiviert</.button>
        <.button variant={:primary} loading>Speichert …</.button>
        <.button
          variant={:danger_outline}
          icon="trash-2"
          confirm="Depot entfernen?"
          phx-click="delete"
        >
          Mit Bestätigung
        </.button>
        <:note>
          Hover und Fokus mit Maus und Tab-Taste; Fokus ist ein 2px-Umriss in der Buttonfarbe.
        </:note>
      </.demo>
    </.showcase>

    <.showcase
      id="fab"
      name="<.fab>"
      title="Schwebende Aktion"
      code={code(1)}
    >
      <:intro>
        Die eine Hauptaktion auf dem Handy, über dem Dock; ab <code>md</code>
        ausgeblendet. Unten rechts auf
        dieser Seite, wenn das Fenster schmaler als 768px ist.
      </:intro>
      <.demo title="Statisch gezeigt (ohne fixed und md:hidden)" class="flex items-center gap-4">
        <.fab label="Ausgabe" class="static! flex!" />
      </.demo>
      <.fab label="Ausgabe (Demo)" class="bottom-4!" phx-click="flash" phx-value-kind="info" />
    </.showcase>

    <.showcase id="selection-bar" name="<.selection_bar>" title="Auswahlleiste" code={code(2)}>
      <:intro>
        Für eine Mehrfachauswahl: unten fest über dem Inhalt, neben Seitenleiste oder Icon-Leiste,
        über Dock und sicherem Rand. Aufheben, Anzahl (für Screenreader angesagt), Aktionen; Menüs
        darin öffnen nach oben. Bei 0 verschwindet sie.
      </:intro>
      <.demo title="Zeilen auswählen">
        <ul class="divide-y divide-base-content/10 border-y border-base-content/10">
          <li :for={{id, label} <- picks()} class="flex items-center gap-3 py-2">
            <input
              type="checkbox"
              id={"pick-#{id}"}
              class="checkbox"
              checked={id in @picked}
              phx-click="pick"
              phx-value-id={id}
            />
            <label for={"pick-#{id}"} class="text-sm">{label}</label>
          </li>
        </ul>
        <.selection_bar id="picked" count={length(@picked)} on_clear="clear_picked">
          <.button size={:sm} variant={:ghost} icon="archive" phx-click="clear_picked">
            Archivieren
          </.button>
          <.dropdown
            id="picked-more"
            label="Weitere Aktionen"
            variant={:ghost}
            align={:end}
            trigger_class="btn-sm"
          >
            <:trigger>Mehr</:trigger>
            <:item
              on_click="clear_picked"
              icon="trash-2"
              danger
              confirm="Auswahl löschen?"
              confirm_text="Die ausgewählten Einträge verschwinden."
            >
              Löschen
            </:item>
          </.dropdown>
        </.selection_bar>
        <:note>Bisher ausgewählt: {length(@picked)}.</:note>
      </.demo>
    </.showcase>

    <.showcase id="composer" name="<.composer>" title="Eingabeleiste" code={code(3)}>
      <:intro>
        Ein Formular, das nur aus der Leiste besteht (Suchen, Hinzufügen), fest am Fuß der
        Seitenspalte: über dem Dock, bei offener Tastatur direkt auf ihr. Auf dem Handy reicht die
        Fläche von Rand zu Rand, ab <code>sm</code>
        bündig mit der Spalte. Ein Platzhalter an ihrer Stelle lässt den letzten Eintrag
        darüber scrollen; schwebende Aktion und Toasts steigen über sie.
      </:intro>
      <.demo title="/screens/shopping" class="overflow-x-auto p-1 pb-2">
        <iframe
          src="/screens/shopping"
          width="390"
          height="640"
          title="Einkaufsliste mit Composer bei 390px"
          loading="lazy"
          class="rounded-box border border-base-content/10 bg-base-100"
        ></iframe>
        <:note>
          Weitere Breiten zeigt das <.link navigate="/shell" class="link">Gerüst</.link>.
        </:note>
      </.demo>
    </.showcase>
    """
  end

  defp picks,
    do: [
      {"a", "Wocheneinkauf, 87,42 €"},
      {"b", "Tanken, 64,30 €"},
      {"c", "Bäckerei, 12,60 €"},
      {"d", "Miete, 1.180,00 €"}
    ]

  defp code(0) do
    ~S"""
        <.button variant={:primary} icon="plus">Neue Ausgabe</.button>
        <.button>Abbrechen</.button>
        <.button variant={:ghost} icon="trash-2" icon_only label="Löschen"
                 confirm="Ausgabe löschen?" phx-click="delete" phx-value-id={@expense.id} />
        <.button variant={:primary} loading>Speichert …</.button>
        <.button navigate={~p"/depots"} size={:sm}>Alle Depots</.button>
    """
  end

  defp code(1) do
    ~S"""
        <.fab navigate={~p"/ausgaben/neu"} icon="plus" label="Ausgabe" />
    """
  end

  defp code(3) do
    ~S"""
    <.composer id="add-entry-bar">
      <.form for={@entry} id="add-entry" phx-submit="add" class="flex items-end gap-2">
        <div class="min-w-0 flex-1">
          <.input field={@entry[:name]} label="Was brauchst du?" hide_label
                  placeholder="Was brauchst du?" autocomplete="off" />
        </div>
        <.button type="submit" variant={:primary} icon="plus" icon_only label="Hinzufügen" />
      </.form>
    </.composer>
    """
  end

  defp code(2) do
    ~S"""
    <%!-- render it always: at 0 it hides, the count is announced --%>
    <.selection_bar id="selection" count={length(@selected)} on_clear="clear_selection"
                    label={ngettext("1 Buchung", "%{count} Buchungen", length(@selected))}>
      <.button size={:sm} variant={:ghost} icon="check" phx-click="approve_selected">Bestätigen</.button>
      <.dropdown id="selection-more" label="Weitere Aktionen" variant={:ghost} align={:end}
                 trigger_class="btn-sm">
        <:trigger>Mehr</:trigger>
        <:item on_click="delete_selected" icon="trash-2" danger confirm="Auswahl löschen?">Löschen</:item>
      </.dropdown>
    </.selection_bar>
    """
  end
end
