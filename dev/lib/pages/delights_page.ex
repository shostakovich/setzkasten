defmodule Setzkasten.Dev.Pages.DelightsPage do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  import Setzkasten.Dev.Demo
  alias Setzkasten.Format

  def title, do: "Delights"
  def summary, do: "Gespeichert, Farbschema-Kreis, rollende Zahlen"

  def render(assigns) do
    ~H"""
    <div class="max-w-prose space-y-3">
      <p>
        Drei kurze Momente, die etwas bestätigen, das gerade passiert ist. In einem Backend sind sie
        selten und schnell; die Oberfläche funktioniert ohne sie genauso.
      </p>
      <ul class="list-disc ps-5 space-y-1 text-sm">
        <li>Nie beim Laden der Seite, nie in einer Schleife.</li>
        <li>Ein Moment pro Aktion, nie zwei gleichzeitig am selben Element.</li>
        <li>Ein Moment ersetzt die Erfolgsmeldung, er kommt nicht zum Toast dazu.</li>
        <li>Weniger Bewegung: keine Bewegung, der Wechsel selbst bleibt.</li>
      </ul>
    </div>

    <.showcase id="saved" name="<.button saved>" title="Gespeichert" code={code(:saved)}>
      <:intro>
        Nach erfolgreichem Speichern zeigt der Button 1,5 s ein Häkchen und „Gespeichert“, dann
        wieder seine Beschriftung. Gleiche Breite, für Screenreader angesagt.
      </:intro>
      <div class="grid gap-6 lg:grid-cols-2">
        <.demo title="Ausprobieren">
          <form id="delight-save-form" phx-submit="save-demo" class="space-y-4 max-w-sm">
            <.input name="group[name]" id="delight-name" label="Gruppenname" value="WG Gartenstraße" />
            <.button
              type="submit"
              id="demo-save"
              variant={:primary}
              saved
              phx-disable-with="Speichert …"
            >
              Speichern
            </.button>
          </form>
        </.demo>
        <.guidance
          fits="Formulare, die nach dem Speichern auf der Seite bleiben: Einstellungen, Detailformulare, Inline-Bearbeitung."
          not_fits="Speichern, das wegnavigiert; Anlegen, das eine Zeile hinzufügt (die Zeile ist die Bestätigung); Fehler (Hinweis oder Feldfehler)."
          limits="Ersetzt den Erfolgs-Toast, nie beides. Erneutes Speichern verlängert die Anzeige, statt neu zu starten."
          reduced="Kein Zeichnen des Häkchens, nur der Wechsel der Beschriftung."
        />
      </div>
    </.showcase>

    <.showcase
      id="theme-reveal"
      name="<.theme_toggle>"
      title="Farbschema als Kreis"
      code={code(:theme)}
    >
      <:intro>
        Das gewählte Schema breitet sich in 700 ms ruhig als Kreis mit weichem Rand vom angeklickten
        Symbol aus (View Transitions). Jeder <code>&lt;.theme_toggle&gt;</code> macht das; nichts
        einzurichten.
      </:intro>
      <div class="grid gap-6 lg:grid-cols-2">
        <.demo title="Ausprobieren">
          <.theme_toggle id="theme-delight" />
        </.demo>
        <.guidance
          fits="Die bewusste Wahl im Schalter."
          not_fits="Wechsel durch das System oder einen anderen Tab, und eine Wahl, die das sichtbare Schema nicht ändert (z. B. System, wenn das System schon hell ist): sofort."
          limits="Ein Kreis pro Klick; ein schneller zweiter Klick ersetzt den ersten."
          reduced="Sofortiger Wechsel, wie in Browsern ohne View Transitions."
        />
      </div>
    </.showcase>

    <.showcase
      id="rolling"
      name="<.stat id> · <.amount animate>"
      title="Rollende Zahlen"
      code={code(:values)}
    >
      <:intro>
        Ändert ein LiveView-Update einen Wert, zählt er in 500 ms vom alten zum neuen. Der letzte
        Stand ist der Text des Servers.
      </:intro>
      <div class="grid gap-6 lg:grid-cols-2">
        <.demo title="Ausprobieren" class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <.stat id="live-assets" label="Vermögen" value={assets(@level)} unit="€" size={:sm} />
            <.stat id="live-rate" label="Kurs" value={rate(@level)} unit="€" size={:sm} />
            <.stat id="live-delta" label="Abweichung" value={delta(@level)} unit="%" size={:sm} />
            <.stat id="live-quote" label="Quote" value={share(@level)} unit="%" size={:sm} />
          </div>
          <.stat id="live-balance" label="Kontostand">
            <.amount id="live-balance-amount" value={balance(@level)} signed tone animate />
            <:note>
              heute <.amount id="live-today" value={today(@level)} signed tone animate />
            </:note>
          </.stat>
          <div class="flex flex-wrap gap-3">
            <.button id="live-up" phx-click="value-up">Wert erhöhen</.button>
            <.button id="live-down" phx-click="value-down">Wert senken</.button>
          </div>
        </.demo>
        <.guidance
          fits="Kennzahlen und Salden, die sich durch eine Aktion oder ein Ereignis ändern: eine Buchung, ein neuer Messwert alle paar Sekunden."
          not_fits="Erstes Rendern, Wiederverbinden mit gleichem Wert, Tabellenzellen und lange Listen."
          limits="Nicht für Ströme im Sekundentakt: auf dem Server drosseln oder animate={false}. In einer Kennzahl animiert nur eine Stelle die Zahl."
          reduced="Kein Zählen, der neue Wert steht sofort."
        />
      </div>
    </.showcase>
    """
  end

  attr :fits, :string, required: true
  attr :not_fits, :string, required: true
  attr :limits, :string, required: true
  attr :reduced, :string, required: true

  defp guidance(assigns) do
    ~H"""
    <dl class="space-y-3 border-t border-base-content/10 pt-5 text-sm max-w-prose">
      <div :for={
        {term, text} <- [
          {"Wann einsetzen", @fits},
          {"Wann nicht", @not_fits},
          {"Grenzen", @limits},
          {"Reduzierte Bewegung", @reduced}
        ]
      }>
        <dt class="font-semibold">{term}</dt>
        <dd>{text}</dd>
      </div>
    </dl>
    """
  end

  defp assets(level), do: Format.number(63_279 + level * 133)
  defp rate(level), do: Format.number(214 + level * 17, minor_units: true)
  defp delta(level), do: Format.number(-88 + level * 65, minor_units: true, signed: true)
  defp share(level), do: Format.number(94.4 + level * 0.7, decimals: 1)
  defp balance(level), do: 1_252_100 + level * 54_050
  defp today(level), do: 4_210 + level * 4_820

  defp code(:saved) do
    ~S"""
    <.button type="submit" id="settings-save" variant={:primary} saved
             phx-disable-with="Speichert …">Speichern</.button>

    def handle_event("save", params, socket) do
      # … save, then instead of put_flash:
      {:noreply, push_saved(socket, "settings-save")}
    end
    """
  end

  defp code(:theme) do
    ~S"""
    <.theme_toggle />
    """
  end

  defp code(:values) do
    ~S"""
    <.stat id="assets" label="Vermögen" value={@assets} unit="€" />
    <.stat id="pv" label="PV jetzt" value={@watt} unit="W" animate={false} />  <%!-- every second --%>
    <.amount id="today" value={@today} signed tone animate />
    """
  end
end
