defmodule Setzkasten.Dev.Pages.ValuesPage do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  import Setzkasten.Dev.Demo

  def title, do: "Werte und Diagramme"
  def summary, do: "amount, stat, description_list, bar, avatar, chart_card, legend"

  def render(assigns) do
    ~H"""
    <.showcase
      id="amount"
      name="<.amount>"
      title="Betrag"
      apps="Depot, Budget, Ausgaben"
      code={code(0)}
    >
      <:intro>
        Geld in de-DE: Tausenderpunkt, Dezimalkomma, echtes Minus (U+2212), geschütztes
        Leerzeichen vor der Einheit, <code>tabular-nums</code>.
      </:intro>
      <.demo title="Varianten">
        <.description_list class="grid sm:grid-cols-2 sm:gap-x-8">
          <:item label="neutral"><.amount value={123_456} /></:item>
          <:item label="tone, negativ"><.amount value={-7420} tone /></:item>
          <:item label="signed tone, positiv"><.amount value={35_020} signed tone /></:item>
          <:item label="tone, null"><.amount value={0} tone /></:item>
          <:item label="andere Währung"><.amount value={4200} currency="USD" /></:item>
          <:item label="size={:lg}"><.amount value={6_327_914} size={:lg} /></:item>
        </.description_list>
      </.demo>
    </.showcase>

    <.showcase
      id="stat"
      name="<.stat>"
      title="Kennzahl"
      apps="Hausautomation, Depot, Budget, Ausgaben"
      code={code(1)}
    >
      <:intro>
        Eine Kennzahl mit Titel, Einheit und Beschreibung, als Kachel. <code>:md</code>
        32px, <code>:sm</code>
        24px für Kachelraster. Veraltete Werte bekommen ein Badge, nie blasse Schrift.
      </:intro>
      <.demo title=":md" class="grid gap-4 sm:grid-cols-2">
        <.stat label="Vermögen" value="63.279" unit="€" desc="+8,4 % seit Jahresbeginn" />
        <.stat label="Dein Saldo" value="−42,17" unit="€" tone={:error} desc="du schuldest Dana" />
      </.demo>
      <.demo title="Kachelraster, size={:sm}, veraltet" class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <.stat label="PV jetzt" value="1.234" unit="W" desc="Akku 82 %" size={:sm} />
        <.stat label="Netz" value="−312" unit="W" desc="Einspeisung" size={:sm} />
        <.stat label="Heute" value="9,8" unit="kWh" desc="Ertrag" size={:sm} />
        <.stat label="Keller" value="14,2" unit="°C" desc="seit 14:32" size={:sm} stale />
      </.demo>
      <.demo
        title="Laden (Skeleton im endgültigen Layout)"
        class="grid grid-cols-2 md:grid-cols-4 gap-4"
      >
        <.stat label="PV jetzt" loading size={:sm} />
        <.stat label="Netz" loading size={:sm} />
      </.demo>
    </.showcase>

    <.showcase
      id="description-list"
      name="<.description_list>"
      title="Steckbrief"
      apps="Hausautomation, Depot, Ausgaben"
      code={code(2)}
    >
      <:intro>Label → Wert, Werte rechtsbündig mit festen Ziffernbreiten.</:intro>
      <.demo title="Auf der Seite" class="max-w-md">
        <.description_list>
          <:item label="ISIN">IE00BK5BQT80</:item>
          <:item label="TER">0,22&nbsp;%</:item>
          <:item label="Fondsgröße">15,8&nbsp;Mrd.&nbsp;€</:item>
          <:item label="Kosten pro Jahr"><.amount value={3000} /></:item>
          <:item label="Ertragsverwendung">thesaurierend</:item>
        </.description_list>
      </.demo>
    </.showcase>

    <.showcase id="bar" name="<.bar>" title="Balken" apps="Hausautomation, Depot" code={code(3)}>
      <:intro>
        Anteil oder Füllstand als natives <code>&lt;progress&gt;</code> mit Label und Wert; die
        Zielmarke ist SVG-Geometrie, kein Inline-Style (strikte CSP).
      </:intro>
      <.demo title="Töne, Zielmarke" class="grid gap-5 md:grid-cols-2">
        <.bar label="Aktien weltweit" value={72} target={70} show_value>Ziel 70&nbsp;%</.bar>
        <.bar label="Anleihen" value={18} tone={:info} show_value />
        <.bar label="Solar-Anteil heute" value={64} tone={:warning} show_value />
        <.bar label="Akku" value={82} tone={:success} show_value />
        <.bar label="Budget Essen gehen" value={112} tone={:error} show_value />
        <.bar label="Schwellen­länder" value={6} target={10} show_value>Ziel 10&nbsp;%</.bar>
      </.demo>
    </.showcase>

    <.showcase
      id="avatar"
      name="<.avatar>"
      title="Avatar"
      apps="CMS, Depot"
      code={code(4)}
    >
      <:intro>
        Initialen oder Icon auf einer Theme-Farbe; eckig (Standard) oder rund. Neben einem
        sichtbaren Namen <code>aria-hidden</code>.
      </:intro>
      <.demo title="Größen, Töne, Formen" class="flex flex-wrap items-center gap-4">
        <.avatar initials="KD" size={:sm} />
        <.avatar initials="LF" tone={:success} />
        <.avatar initials="JM" tone={:neutral} size={:lg} />
        <.avatar initials="DS" tone={:info} shape={:round} />
        <.avatar icon="user" tone={:base} shape={:round} />
        <span class="flex items-center gap-2 text-sm"><.avatar initials="K" size={:sm} />Kinderdepot</span>
      </.demo>
    </.showcase>

    <.showcase
      id="chart-card"
      name="<.chart_card>, <.legend>"
      title="Diagramm-Rahmen"
      apps="Hausautomation, Depot (nur Rahmen)"
      code={code(5)}
    >
      <:intro>
        Die Bibliothek liefert den Rahmen: Karte, Höhe, Legende, Zusammenfassung für Screenreader,
        Werte-Tabelle zum Aufklappen, Skeleton. Das Diagramm zeichnet die App; hier ein statisches SVG.
      </:intro>
      <.demo
        title="Mit Zeitraum, Legende und Werten · lädt"
        class="grid gap-4 md:gap-6 lg:grid-cols-2"
      >
        <.chart_card
          id="networth"
          title="Vermögen"
          level={3}
          summary="Vermögen von 52.400 € im Oktober 2025 auf 63.279 € im Oktober 2026, Einzahlungen von 50.000 € auf 52.900 €"
        >
          <:actions>
            <.segmented
              mode={:patch}
              size={:sm}
              label="Zeitraum"
              value={@range}
              options={[
                {"6M", "6m", "/values?r=6m"},
                {"1J", "1y", "/values?r=1y"},
                {"Max", "max", "/values?r=max"}
              ]}
            />
          </:actions>
          <svg
            class="w-full flex-1"
            viewBox="0 0 600 220"
            preserveAspectRatio="none"
            aria-hidden="true"
          >
            <g class="stroke-base-content/10" stroke-width="1">
              <line
                :for={y <- [20, 80, 140, 200]}
                x1="0"
                y1={y}
                x2="600"
                y2={y}
                vector-effect="non-scaling-stroke"
              />
            </g>
            <polyline
              class="stroke-chart-3"
              fill="none"
              stroke-width="2"
              vector-effect="non-scaling-stroke"
              points="0,190 50,188 100,186 150,183 200,181 250,178 300,176 350,173 400,171 450,168 500,166 550,163 600,161"
            />
            <polyline
              class="stroke-chart-1"
              fill="none"
              stroke-width="2.5"
              vector-effect="non-scaling-stroke"
              points="0,170 50,160 100,166 150,140 200,132 250,120 300,128 350,98 400,90 450,76 500,64 550,58 600,40"
            />
          </svg>
          <div
            class="flex justify-between text-xs text-base-content/70 tabular-nums"
            aria-hidden="true"
          >
            <span>Okt 25</span><span>Jan</span><span>Apr</span><span>Jul</span><span>Okt 26</span>
          </div>
          <:legend>
            <.legend items={[%{label: "Vermögen", color: 1}, %{label: "Einzahlungen", color: 3}]} />
          </:legend>
          <:data>
            <.table
              id="networth-values"
              size={:sm}
              flush
              rows={[
                {"10/2025", 5_240_000, 5_000_000},
                {"04/2026", 5_795_000, 5_145_000},
                {"10/2026", 6_327_900, 5_290_000}
              ]}
            >
              <:col :let={{month, _, _}} label="Monat">{month}</:col>
              <:col :let={{_, value, _}} label="Vermögen" align={:end}>
                <.amount value={value} />
              </:col>
              <:col :let={{_, _, paid}} label="Einzahlungen" align={:end}>
                <.amount value={paid} />
              </:col>
            </.table>
          </:data>
        </.chart_card>
        <.chart_card id="pv-today" title="PV heute" level={3} summary="PV-Ertrag heute" loading />
      </.demo>
    </.showcase>
    """
  end

  defp code(0) do
    ~S"""
    <.amount value={-7420} signed tone />
    <.amount value={Decimal.new("63279.14")} size={:lg} />
    """
  end

  defp code(1) do
    ~S"""
    <.stat label="Vermögen" value="63.279" unit="€" desc="+8,4 % seit Jahresbeginn" />
    <.stat label="PV jetzt" value="1.234" unit="W" size={:sm} stale />
    """
  end

  defp code(2) do
    ~S"""
    <.description_list>
      <:item label="TER">0,22 %</:item>
      <:item label="Fondsgröße">15,8 Mrd. €</:item>
    </.description_list>
    """
  end

  defp code(3) do
    ~S"""
    <.bar label="Aktien" value={72} target={70} show_value>Ziel 70 %</.bar>
    """
  end

  defp code(4) do
    ~S"""
    <.avatar initials="KD" size={:sm} />
    <.avatar icon="user" tone={:base} shape={:round} />
    """
  end

  defp code(5) do
    ~S"""
    <.chart_card id="networth" title="Vermögen" hook="NetWorthChart" height={:md}
                 summary="Vermögen von 52.400 € im Oktober 2025 auf 63.279 € im Oktober 2026">
      <:actions><.segmented mode={:patch} size={:sm} … /></:actions>
      <:legend><.legend items={[%{label: "Vermögen", color: 1}, %{label: "Einzahlungen", color: 3}]} /></:legend>
      <:data><.table size={:sm} flush …/></:data>
    </.chart_card>
    """
  end
end
