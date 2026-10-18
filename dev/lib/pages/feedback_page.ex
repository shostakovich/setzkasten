defmodule Setzkasten.Dev.Pages.FeedbackPage do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  import Setzkasten.Dev.Demo

  def title, do: "Rückmeldung"
  def summary, do: "alert, flash, flash_group, put_toast, badge, empty_state"

  def render(assigns) do
    ~H"""
    <.showcase id="alert" name="<.alert>" title="Hinweis im Inhalt" code={code(0)}>
      <:intro>
        Dauerhafte Hinweise auf der Seite; getönt, Schrift in Grundfarbe, Icon in der Tinte
        des Tons: <code>info-ink</code>
        bei Info, <code>warning-ink</code>
        bei Warnung, <code>success-ink</code>
        und <code>error-ink</code>
        bei Erfolg und Fehler. <code>role="alert"</code>
        nur für Fehler.
      </:intro>
      <.demo title="Töne" class="space-y-3">
        <.alert tone={:info} title="Abruf läuft täglich um 18:00">
          Kurse und Fondsdaten kommen vom Kursanbieter.
          <:actions><.button size={:sm}>Jetzt abrufen</.button></:actions>
        </.alert>
        <.alert tone={:success} title="Alles ausgeglichen">
          Niemand schuldet gerade jemandem etwas.
          <:actions><.button size={:sm}>Verlauf</.button></:actions>
        </.alert>
        <.alert tone={:warning} title="API-Key fehlt">
          Für Regionen und Sektoren braucht die App einen API-Key des Kursanbieters in <code>QUOTES_API_KEY</code>.
          <:actions><.button size={:sm}>Einrichten</.button></:actions>
        </.alert>
        <.alert tone={:error} title="2 Felder sind noch nicht richtig">
          Bitte prüfe Titel und Betrag.
          <:actions><.button size={:sm}>Zum ersten Feld</.button></:actions>
        </.alert>
        <.alert tone={:neutral} title="Neutral">
          Archivierte Gruppen erscheinen nicht in der Übersicht.
          <:actions>
            <.button size={:sm}>Archiv</.button>
            <.button size={:sm} variant={:primary}>Wiederherstellen</.button>
          </:actions>
        </.alert>
        <.alert tone={:info} title="Wird geladen (busy)" busy>
          Wechselrichter wird abgefragt …
        </.alert>
        <.alert tone={:warning}>Nur ein Satz, ohne Titel.</.alert>
        <:note>
          Mit Aktionen: rechts, solange der Hinweis mindestens 32rem breit ist, sonst unter dem Text.
          Neutrale Buttons bekommen auf der Tönung eine hellere Fläche und den Feldrand (50 %).
        </:note>
      </.demo>
      <.demo title="In einer schmalen Seitenspalte (18rem)">
        <div class="w-72">
          <.alert tone={:warning} title="Konto nicht abgeglichen" on_close="noop">
            Der Saldo weicht 12,40 € von der Bank ab.
            <:actions><.button size={:sm}>Abgleichen</.button></:actions>
          </.alert>
        </div>
      </.demo>
    </.showcase>

    <.showcase
      id="flash"
      name="<.flash>, <.flash_group>, put_toast"
      title="Rückmeldung"
      code={code(1)}
    >
      <:intro>
        Phoenix-Flash als Toast unten, über Dock, Tastatur, Composer und Aktionsleiste; deckend
        von Anfang an, steigt 8px ein. Info und Toast schließen sich nach 5 s (Pause, solange
        Zeiger oder Fokus darauf liegen), Fehler bleiben. <code>put_toast</code>
        meldet eine erledigte Aktion mit einer Aktion zum Zurücknehmen; ein neuer ersetzt den alten.
      </:intro>
      <.demo title="Echt auslösen" class="flex flex-wrap gap-3">
        <.button phx-click="flash" phx-value-kind="info" icon="check">Info-Flash</.button>
        <.button phx-click="flash" phx-value-kind="error" icon="circle-alert">Fehler-Flash</.button>
        <.button id="toast-action-demo" phx-click="toast" phx-value-kind="action" icon="check">
          Toast mit Aktion
        </.button>
        <.button id="toast-plain-demo" phx-click="toast" phx-value-kind="plain" icon="plus">
          Toast ohne Aktion
        </.button>
      </.demo>
      <.demo
        title="Vorschau in Rahmen (sie halten den fest positionierten Toast)"
        class="grid gap-4 lg:grid-cols-2"
      >
        <div
          :for={
            {kind, title, msg} <- [
              {:info, "Gespeichert", "Ausgabe „Wocheneinkauf“ angelegt."},
              {:error, "Keine Verbindung", "Verbindung wird wiederhergestellt …"}
            ]
          }
          class="relative h-40 overflow-hidden border-y border-base-content/10 bg-base-200 translate-z-0"
        >
          <.flash id={"preview-#{kind}"} kind={kind} title={title}>{msg}</.flash>
        </div>
      </.demo>
    </.showcase>

    <.showcase id="badge" name="<.badge>" title="Status-Badge" code={code(2)}>
      <:intro>
        Standard: neutrales Badge mit farbigem Punkt; gefüllt nur für Alarmzustände. Keine
        getönten Badges.
      </:intro>
      <.demo title="Punkt (Standard), Größe :sm" class="flex flex-wrap items-center gap-2">
        <.badge>Entwurf</.badge>
        <.badge tone={:info}>Geplant</.badge>
        <.badge tone={:success}>Veröffentlicht</.badge>
        <.badge tone={:warning}>veraltet</.badge>
        <.badge tone={:error}>Fehler</.badge>
        <.badge tone={:primary}>Du</.badge>
      </.demo>
      <.demo title="Größe :md" class="flex flex-wrap items-center gap-2">
        <.badge size={:md} tone={:success}>Veröffentlicht</.badge>
        <.badge size={:md} tone={:warning}>Unterfinanziert</.badge>
      </.demo>
      <.demo
        title="Gefüllt (style={:solid}, nur Alarm) und mit Icon"
        class="flex flex-wrap items-center gap-2"
      >
        <.badge tone={:error} style={:solid}>überzogen</.badge>
        <.badge tone={:warning} style={:solid}>Senf</.badge>
        <.badge icon="archive">Archiviert</.badge>
        <.badge icon="repeat" label="Wiederkehrend" />
      </.demo>
    </.showcase>

    <.showcase
      id="empty-state"
      name="<.empty_state>"
      title="Leerzustand"
      code={code(3)}
    >
      <:intro>
        Sagt, was hier hingehört und wie man es bekommt (eine Aktion). Inline in Abschnitten und
        Listen, zentriert als Seite.
      </:intro>
      <.demo title="Inline mit Aktion">
        <.section_heading>Depots</.section_heading>
        <.empty_state icon="inbox" title="Noch keine Depots">
          Lege ein Depot an oder importiere eine CSV-Datei.
          <:action><.button variant={:primary} icon="plus">Depot anlegen</.button></:action>
        </.empty_state>
      </.demo>
      <.demo title="Inline ohne Aktion (Daten kommen von selbst)">
        <.empty_state icon="thermometer" title="Noch keine Messwerte">
          Die Werte erscheinen, sobald der Sensor das erste Mal sendet.
        </.empty_state>
      </.demo>
      <.demo title="Inline mit Plüsch">
        <.empty_state plush="scale" title="Alles ausgeglichen">
          Sobald jemand etwas auslegt, steht hier, wer wem was schuldet.
        </.empty_state>
      </.demo>
      <.demo title="Plüsch ohne Bild: fällt auf icon zurück, ohne icon keine Figur">
        <.empty_state plush="no-such-plush" icon="tag" title="Noch keine Kategorien">
          Kategorien entstehen, sobald du eine Ausgabe einordnest.
        </.empty_state>
        <.empty_state plush="no-such-plush" title="Noch keine Notizen">
          Notizen zu einer Ausgabe erscheinen hier.
        </.empty_state>
      </.demo>
      <.demo title="Seite (layout={:page})">
        <.empty_state plush="receipt" layout={:page} title="Noch keine Ausgaben" level={3}>
          Trag die erste gemeinsame Ausgabe ein. Die App rechnet dann aus, wer wem wie viel
          schuldet.
          <:action><.button variant={:primary} icon="plus">Ausgabe eintragen</.button></:action>
        </.empty_state>
      </.demo>
    </.showcase>
    """
  end

  defp code(0) do
    ~S"""
    <.alert tone={:warning} title="API-Key fehlt">
      Für Regionen und Sektoren braucht die App einen API-Key des Kursanbieters.
      <:actions><.button size={:sm}>Einrichten</.button></:actions>
    </.alert>
    """
  end

  defp code(1) do
    ~S"""
    <.flash_group flash={@flash} />
    <.flash kind={:info} title="Gespeichert" flash={@flash} />

    {:noreply,
     put_toast(socket, "Bananen abgehakt",
       action: "Rückgängig", on_action: JS.push("uncheck", value: %{id: item.id}))}
    {:noreply, put_toast(socket, "Milch hinzugefügt")}
    """
  end

  defp code(2) do
    ~S"""
    <.badge tone={:success}>Veröffentlicht</.badge>
    <.badge tone={:error} style={:solid}>überzogen</.badge>
    <.badge icon="repeat" label="Wiederkehrend" />
    """
  end

  defp code(3) do
    ~S"""
    <.empty_state icon="inbox" title="Noch keine Depots">
      Lege ein Depot an oder importiere eine CSV-Datei.
      <:action><.button variant={:primary} icon="plus">Depot anlegen</.button></:action>
    </.empty_state>
    <.empty_state plush="receipt" layout={:page} title="Noch keine Ausgaben">…</.empty_state>
    <%!-- no image for the plush: the icon stands in --%>
    <.empty_state plush={category.plush} icon="tag" title="Noch keine Kategorien">…</.empty_state>
    """
  end
end
