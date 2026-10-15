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
          <:item label="tone={:negative}, Salden">
            <.amount value={248_310} tone={:negative} /> ·
            <.amount value={-48_230} tone={:negative} />
          </:item>
          <:item label="andere Währung"><.amount value={4200} currency="USD" /></:item>
          <:item label="currency_display={:code}">
            <.amount value={110} currency="USD" currency_display={:code} />
          </:item>
          <:item label="minor_digits={0} (Yen)">
            <.amount value={4850} currency="JPY" minor_digits={0} currency_display={:code} />
          </:item>
          <:item label="size={:lg}"><.amount value={6_327_914} size={:lg} /></:item>
          <:item label="decimals={0} (ganze Euro, KPIs)">
            <.amount value={6_327_914} decimals={0} />
          </:item>
        </.description_list>
      </.demo>
    </.showcase>

    <.showcase
      id="stat"
      name="<.stat>"
      title="Kennzahl"
      code={code(1)}
    >
      <:intro>
        Eine Kennzahl mit Titel, Einheit und Beschreibung, als Kachel. <code>:md</code>
        32px, <code>:sm</code>
        24px für Kachelraster. Veraltete Werte bekommen ein Badge, nie blasse Schrift.
      </:intro>
      <.demo title=":md" class="setzkasten-stat-grid grid gap-4 sm:grid-cols-2">
        <.stat label="Vermögen" value="63.279" unit="€" desc="+8,4 % seit Jahresbeginn" />
        <.stat
          label="Dein Saldo"
          value="−42,17"
          unit="€"
          tone={:error}
          desc="du schuldest Dana"
          navigate="/values"
        />
      </.demo>
      <.demo
        title="Beschreibung mit Markup, :note"
        class="setzkasten-stat-grid grid gap-4 sm:grid-cols-2"
      >
        <.stat label="Depotwert" value="63.279" unit="€">
          <:note><.amount value={50_000} signed tone /> heute</:note>
        </.stat>
        <.stat label="Letzte Buchung" value="−312,40" unit="€">
          <:note>07.10.2026<.meta_sep /><span class="font-semibold">Stadtwerke</span></:note>
        </.stat>
      </.demo>
      <.demo
        title="Kachelraster, size={:sm}, veraltet"
        class="setzkasten-stat-grid grid grid-cols-2 md:grid-cols-4 gap-4"
      >
        <.stat label="PV jetzt" value="1.234" unit="W" desc="Akku 82 %" size={:sm} />
        <.stat label="Netz" value="−312" unit="W" desc="Einspeisung" size={:sm} />
        <.stat label="Heute" value="9,8" unit="kWh" desc="Ertrag" size={:sm} />
        <.stat label="Keller" value="14,2" unit="°C" desc="seit 14:32" size={:sm} stale />
      </.demo>
      <.demo
        title="Figur, :figure (unter sm am Ende der Titelzeile)"
        class="setzkasten-stat-grid grid grid-cols-2 md:grid-cols-4 gap-4"
      >
        <.stat label="PV jetzt" value="486" unit="W" desc="Sonnig, 17 °C" size={:sm}>
          <:figure><.plush name="sunny" size={:lg} /></:figure>
        </.stat>
        <.stat label="Batterie" value="78" unit="%" desc="entlädt mit 120 W" size={:sm}>
          <:figure><.plush name="battery" size={:lg} /></:figure>
        </.stat>
        <.stat label="Netz" value="−312" unit="W" desc="Einspeisung" size={:sm}>
          <:figure><.icon name="zap" class="size-6 text-base-content/70" /></:figure>
        </.stat>
        <.stat label="Keller" loading size={:sm}>
          <:figure><.plush name="nav-sensors" size={:lg} /></:figure>
        </.stat>
      </.demo>
      <.demo
        title="Füllstand unter dem Wert, :meter mit bar hide_label"
        class="setzkasten-stat-grid grid grid-cols-2 md:grid-cols-4 gap-4"
      >
        <.stat label="Ladestand" value="78" unit="%" desc="entlädt mit 120 W" size={:sm}>
          <:meter><.bar label="Ladestand" value={78} tone={:success} hide_label /></:meter>
        </.stat>
        <.stat label="Speicher" value="64" unit="%" desc="von 2 TB" size={:sm}>
          <:meter><.bar label="Speicher belegt" value={64} tone={:neutral} hide_label /></:meter>
        </.stat>
        <.stat label="Netz" value="−312" unit="W" desc="Einspeisung" size={:sm} />
      </.demo>
      <.demo
        title="Laden (Skeleton im endgültigen Layout)"
        class="setzkasten-stat-grid grid grid-cols-2 md:grid-cols-4 gap-4"
      >
        <.stat label="PV jetzt" loading size={:sm} />
        <.stat label="Netz" loading size={:sm} />
      </.demo>
    </.showcase>

    <.showcase
      id="description-list"
      name="<.description_list>"
      title="Steckbrief"
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
      <.demo title="Rechnung mit strong und total" class="max-w-md">
        <.description_list>
          <:item label="Anfangswert" strong><.amount value={1_000_000} /></:item>
          <:item label="Einzahlungen"><.amount value={50_000} signed /></:item>
          <:item label="Dividenden"><.amount value={12_400} signed /></:item>
          <:item label="Kursgewinne"><.amount value={18_800} signed /></:item>
          <:item label="Endwert" total><.amount value={1_081_200} /></:item>
        </.description_list>
      </.demo>
    </.showcase>

    <.showcase id="bar" name="<.bar>" title="Balken" code={code(3)}>
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
      <.demo
        title="tone={:neutral} (Anteil ohne Zustand, steht allein), Ziel mit Nachkommastelle"
        class="grid gap-5 md:grid-cols-2"
      >
        <.bar label="Liquidität" value={12} tone={:neutral} target={12.5}>Ziel 12,5&nbsp;%</.bar>
        <.bar label="Rohstoffe" value={3} tone={:neutral} show_value />
      </.demo>
      <.demo
        title="color={n} (Farbe der Diagrammreihe, Füllung mit Linie wie im Diagramm)"
        class="grid gap-5 md:grid-cols-2"
      >
        <.bar label="Solar" value={64} color={2} show_value />
        <.bar label="Netz" value={24} color={1} show_value />
        <.bar label="Akku" value={9} color={3} show_value />
        <.bar label="Sonstige" value={3} color={:other} show_value />
      </.demo>
    </.showcase>

    <.showcase id="share-bar" name="<.share_bar>" title="Anteilsbalken" code={code(6)}>
      <:intro>
        Ein Ganzes in einem durchgehenden Balken: Segmente bündig, so breit wie ihre Werte, in der
        gegebenen Reihenfolge (größte zuerst, der gruppierte Rest zuletzt), getrennt nur durch eine
        2px-Lücke. Die Werte stehen als Text in der Legende.
      </:intro>
      <.demo title="Leistung je Steckdose, Rest gruppiert (color: :other)" class="max-w-xl">
        <.share_bar
          id="share-plugs"
          label="Steckdosen"
          value_label="756 W"
          segments={[
            %{label: "Waschmaschine", value: 412, color: 1, value_label: "412 W"},
            %{label: "Arbeitsplatz", value: 138, color: 2, value_label: "138 W"},
            %{label: "Kühlschrank", value: 86, color: 3, value_label: "86 W"},
            %{label: "Fernseher", value: 64, color: 4, value_label: "64 W"},
            %{label: "Router & NAS", value: 28, color: 5, value_label: "28 W"},
            %{label: "Sonstige (4)", value: 28, color: :other, value_label: "28 W"}
          ]}
        />
      </.demo>
      <.demo title="Depot nach Anlageklasse, size={:sm}" class="max-w-xl">
        <.share_bar
          id="share-portfolio"
          label="Depot"
          value_label="63.279 €"
          size={:sm}
          segments={[
            %{label: "Aktien weltweit", value: 72, color: 1, value_label: "72 %"},
            %{label: "Anleihen", value: 18, color: 6, value_label: "18 %"},
            %{label: "Liquidität", value: 7, color: 8, value_label: "7 %"},
            %{label: "Rohstoffe", value: 3, color: 7, value_label: "3 %"}
          ]}
        />
      </.demo>
      <.demo
        title="Geordnete Klassen: sequenzielle Rampe {:seq, 1..5}, nie Warnfarben"
        class="max-w-xl"
      >
        <.share_bar
          id="share-particles"
          label="Feinstaub nach Partikelgröße"
          value_label="18 µg/m³"
          segments={[
            %{label: "unter 1 µm", value: 6, color: {:seq, 1}, value_label: "6 µg/m³"},
            %{label: "1–2,5 µm", value: 5, color: {:seq, 2}, value_label: "5 µg/m³"},
            %{label: "2,5–4 µm", value: 4, color: {:seq, 4}, value_label: "4 µg/m³"},
            %{label: "4–10 µm", value: 3, color: {:seq, 5}, value_label: "3 µg/m³"}
          ]}
        />
      </.demo>
      <.demo
        title="Teilweise gefüllt: max={1000}, der Rest bleibt Spur; legend={false}"
        class="max-w-xl"
      >
        <.share_bar
          id="share-budget"
          label="Budget Oktober"
          value_label="620 € von 1.000 €"
          max={1000}
          legend={false}
          segments={[
            %{label: "Lebensmittel", value: 410, color: 3, value_label: "410 €"},
            %{label: "Essen gehen", value: 130, color: 2, value_label: "130 €"},
            %{label: "Sonstiges", value: 80, color: :other, value_label: "80 €"}
          ]}
        />
      </.demo>
    </.showcase>

    <.showcase
      id="avatar"
      name="<.avatar>"
      title="Avatar"
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
      <.demo title="loading (z. B. Bild oder Kurs lädt)" class="flex flex-wrap items-center gap-4">
        <.avatar initials="KD" size={:sm} loading />
        <.avatar initials="LF" tone={:success} loading />
        <.avatar icon="user" tone={:base} shape={:round} size={:lg} loading />
        <:note>
          Gleiche Größe und Farbe, <code>aria-busy</code>; bei reduzierter Bewegung drei Punkte
          statt Spinner.
        </:note>
      </.demo>
    </.showcase>

    <.showcase
      id="chart-card"
      name="<.chart_card>, <.legend>"
      title="Diagramm-Rahmen"
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
          summary="Vermögen von 52.400 € im Oktober 2025 auf 63.279 € im Oktober 2026, Einzahlungen von 50.000 € auf 52.900 €, Ziel 60.000 €"
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
            <line
              class="stroke-chart-8"
              x1="0"
              y1="60"
              x2="600"
              y2="60"
              stroke-width="1.5"
              stroke-dasharray="6 4"
              vector-effect="non-scaling-stroke"
            />
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
            <.legend
              id="networth-legend"
              items={[
                %{label: "Vermögen", color: 1, marker: :line},
                %{label: "Einzahlungen", color: 3, marker: :line},
                %{label: "Ziel", color: 8, marker: :dashed}
              ]}
            />
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
      <.demo title="<.legend>: marker :dot (Flächen, Balken) · :line · :dashed (Referenzlinie)">
        <.legend items={[%{label: "Aktien", color: 1}, %{label: "Anleihen", color: 2}]} />
        <.legend
          class="mt-2"
          items={[
            %{label: "Kurs", color: 1, marker: :line},
            %{label: "Einstand", color: 8, marker: :dashed},
            %{label: "Gewinn", color: :success, marker: :line}
          ]}
        />
      </.demo>
    </.showcase>
    """
  end

  defp code(0) do
    ~S"""
    <.amount value={-7420} signed tone />
    <.amount value={Decimal.new("63279.14")} size={:lg} />
    <.amount value={6_327_914} decimals={0} />
    <.amount value={110} currency="USD" currency_display={:code} />
    <.amount value={4850} currency="JPY" minor_digits={0} currency_display={:code} />
    """
  end

  defp code(1) do
    ~S"""
    <.stat label="Vermögen" value="63.279" unit="€" desc="+8,4 % seit Jahresbeginn" />
    <.stat label="PV jetzt" value="1.234" unit="W" size={:sm} stale />
    <.stat label="PV jetzt" value="486" unit="W" size={:sm}>
      <:figure><.plush name="sunny" size={:lg} /></:figure>
    </.stat>
    <.stat label="Depotwert" value="63.279" unit="€">
      <:note><.amount value={50_000} signed tone /> heute</:note>
    </.stat>
    """
  end

  defp code(2) do
    ~S"""
    <.description_list>
      <:item label="TER">0,22 %</:item>
      <:item label="Fondsgröße">15,8 Mrd. €</:item>
    </.description_list>

    <%!-- a calculation: once an item is marked, the other values are regular --%>
    <.description_list>
      <:item label="Anfangswert" strong><.amount value={@start} /></:item>
      <:item label="Einzahlungen"><.amount value={@deposits} signed /></:item>
      <:item label="Endwert" total><.amount value={@end} /></:item>
    </.description_list>
    """
  end

  defp code(3) do
    ~S"""
    <.bar label="Aktien" value={72} target={70} show_value>Ziel 70 %</.bar>
    <.bar label="Liquidität" value={12} tone={:neutral} target={12.5}>Ziel 12,5 %</.bar>
    """
  end

  defp code(6) do
    ~S"""
    <.share_bar label="Steckdosen" value_label="756 W" segments={[
      %{label: "Waschmaschine", value: 412, color: 1, value_label: "412 W"},
      %{label: "Arbeitsplatz", value: 138, color: 2, value_label: "138 W"},
      %{label: "Sonstige (4)", value: 28, color: :other, value_label: "28 W"}
    ]} />
    <.share_bar label="Budget Oktober" max={1000} legend={false} segments={…} />
    """
  end

  defp code(4) do
    ~S"""
    <.avatar initials="KD" size={:sm} />
    <.avatar icon="user" tone={:base} shape={:round} />
    <.avatar initials="KD" loading />
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
    <%!-- line charts: marker :line, or :dashed for a reference line --%>
    <.chart_card …>
      <:legend><.legend id="lines" items={[%{label: "Kurs", color: 1, marker: :line},
                                          %{label: "Einstand", color: 8, marker: :dashed}]} /></:legend>
    </.chart_card>
    """
  end
end
