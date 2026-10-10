defmodule Setzkasten.Dev.Pages.ActionsPage do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  import Setzkasten.Dev.Demo

  def title, do: "Aktionen"
  def summary, do: "button, fab"

  def render(assigns) do
    ~H"""
    <.showcase
      id="button"
      name="<.button>"
      title="Schaltfläche"
      apps="alle fünf"
      code={code(0)}
    >
      <:intro>Jede Aktion; feste Varianten statt freier Klassen-Strings.</:intro>
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
      apps="Ausgaben, Budget"
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
    """
  end

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
end
