defmodule Setzkasten.Dev.Pages.Foundations do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  import Setzkasten.Dev.Demo

  def title, do: "Grundlagen"
  def summary, do: "Farben, Text-Stufen, Diagrammreihen, Typografie"

  @roles [
    {"bg-primary text-primary-content", "primary", "Hauptaktion, Links, Fokus"},
    {"bg-selected text-selected-content", "selected", "Auswahl, aktueller Menüpunkt"},
    {"bg-neutral text-neutral-content", "neutral", "Tooltip"},
    {"bg-secondary text-secondary-content", "secondary", "selten"},
    {"bg-accent text-accent-content", "accent", "reserviert"},
    {"bg-info text-info-content", "info", "Hinweise"},
    {"bg-success text-success-content", "success", "Gewinne, erledigt"},
    {"bg-warning text-warning-content", "warning", "Warnungen"},
    {"bg-error text-error-content", "error", "Fehler, Verlust"}
  ]

  # {series, name, fill (bars, areas, legend), line}
  @series [
    {1, "Blau", "bg-chart-1-fill", "bg-chart-1"},
    {2, "Bernstein", "bg-chart-2-fill", "bg-chart-2"},
    {3, "Grün", "bg-chart-3-fill", "bg-chart-3"},
    {4, "Rot", "bg-chart-4-fill", "bg-chart-4"},
    {5, "Violett", "bg-chart-5-fill", "bg-chart-5"},
    {6, "Cyan", "bg-chart-6-fill", "bg-chart-6"},
    {7, "Pink", "bg-chart-7-fill", "bg-chart-7"},
    {8, "Schiefer", "bg-chart-8-fill", "bg-chart-8"},
    {"other", "Rest", "bg-chart-other-fill", "bg-chart-other"},
    {"seq-1", "geordnet, niedrig", "bg-seq-1", "bg-seq-1"},
    {"seq-2", "geordnet", "bg-seq-2", "bg-seq-2"},
    {"seq-3", "geordnet", "bg-seq-3", "bg-seq-3"},
    {"seq-4", "geordnet", "bg-seq-4", "bg-seq-4"},
    {"seq-5", "geordnet, hoch", "bg-seq-5", "bg-seq-5"}
  ]

  def render(assigns) do
    assigns = assign(assigns, roles: @roles, series: @series)

    ~H"""
    <section id="farben" class="space-y-6">
      <div class="space-y-1">
        <h2 class="text-xl font-semibold">Farben</h2>
        <p class="max-w-prose text-sm text-base-content/70">
          Palette „Hell und weich“: eine Akzentfarbe (Blau als <code>primary</code>), die übrigen
          Rollen als Pastellflächen mit dunkler Schrift. Farbe trägt Zustand, nicht Dekoration.
        </p>
      </div>
      <.demo title="Flächen und Text" class="grid grid-cols-2 sm:grid-cols-4 gap-3 text-sm">
        <div class="rounded-box border border-base-content/10 bg-base-100 p-3">
          <p class="font-semibold">base-100</p>
          <p class="text-base-content/70">Seite, Karten, Felder</p>
        </div>
        <div class="rounded-box bg-base-200 p-3">
          <p class="font-semibold">base-200</p>
          <p class="text-base-content/70">Gruppen, Zebra</p>
        </div>
        <div class="rounded-box bg-base-300 p-3">
          <p class="font-semibold">base-300</p>
          <p class="text-base-content/70">Mulden, kbd</p>
        </div>
        <div class="rounded-box bg-base-content text-base-100 p-3">
          <p class="font-semibold">base-content</p>
          <p>aller Text</p>
        </div>
      </.demo>
      <.demo title="Rollen" class="grid grid-cols-2 sm:grid-cols-4 gap-3 text-sm">
        <div :for={{class, name, use} <- @roles} class={["rounded-box p-3", class]}>
          <p class="font-semibold">{name}</p>
          <p>{use}</p>
        </div>
      </.demo>
      <.demo title="Text-Stufen" class="space-y-1">
        <p>Grundtext <code>text-base-content</code></p>
        <p class="text-base-content/70">Meta und Hinweise <code>text-base-content/70</code></p>
        <p class="text-sm">
          <span class="text-primary">Link primary</span>
          · <.amount value={35020} signed tone /> success-ink
          · <.amount value={-7420} tone /> error-ink
          · <span class="text-info-ink">info-ink</span>
          · <span class="text-warning-ink">warning-ink</span>
        </p>
        <:note>
          Farbiger Text nur in <code>primary</code>
          und den Inks <code>success-ink</code>, <code>error-ink</code>, <code>info-ink</code>
          und <code>warning-ink</code>.
          Die übrigen Rollen sind im hellen Theme Flächen (1,5–2,7:1 auf Weiß).
        </:note>
      </.demo>
      <.demo title="Diagrammreihen chart-1…8, chart-other und die sequenzielle Rampe seq-1…5">
        <ul class="grid grid-cols-2 gap-x-4 gap-y-3 text-sm sm:grid-cols-4">
          <li :for={{n, name, fill, line} <- @series} class="flex items-end gap-3">
            <span class="flex h-10 items-end gap-1" aria-hidden="true">
              <span class={["h-6 w-3", fill]}></span>
              <span class={["h-10 w-3", fill]}></span>
            </span>
            <span class="min-w-0 flex-1">
              <span class={["mb-1.5 block h-0.5 rounded-full", line]} aria-hidden="true"></span>
              <span class="font-semibold tabular-nums">{n}</span> {name}
            </span>
          </li>
        </ul>
        <:note>
          Eigene Grafikfarben, nicht die Rollen oder Inks: in beiden Themes ≥ 3:1 auf
          base-100/200. Fläche <code>chart-N-fill</code>
          und Linie <code>chart-N</code>
          sind dieselbe Farbe, Balken ohne Kontur. PV und Warnungen Reihe 2, Einnahmen
          Reihe 3, Überziehung Reihe 4.
        </:note>
      </.demo>
    </section>

    <section id="typografie" class="space-y-6">
      <div class="space-y-1">
        <h2 class="text-xl font-semibold">Typografie</h2>
        <p class="max-w-prose text-sm text-base-content/70">
          Tailwind-Skala, System-Schrift, nichts unter 12px. Zahlen mit <code>tabular-nums</code>.
        </p>
      </div>
      <dl class="divide-y divide-base-content/10 border-y border-base-content/10">
        <div class="grid sm:grid-cols-[14rem_1fr] gap-x-4 gap-y-1 py-3">
          <dt class="text-sm text-base-content/70">Seitentitel · text-2xl 600</dt>
          <dd class="text-2xl font-semibold">Bestand</dd>
        </div>
        <div class="grid sm:grid-cols-[14rem_1fr] gap-x-4 gap-y-1 py-3">
          <dt class="text-sm text-base-content/70">KPI · stat-value 32px 800</dt>
          <dd class="text-[2rem] leading-10 font-extrabold tabular-nums">63.279,14&nbsp;€</dd>
        </div>
        <div class="grid sm:grid-cols-[14rem_1fr] gap-x-4 gap-y-1 py-3">
          <dt class="text-sm text-base-content/70">Kartentitel · text-lg 600</dt>
          <dd class="text-lg font-semibold">Kosten</dd>
        </div>
        <div class="grid sm:grid-cols-[14rem_1fr] gap-x-4 gap-y-1 py-3">
          <dt class="text-sm text-base-content/70">Abschnitt · text-base 600</dt>
          <dd class="text-base font-semibold">Depots</dd>
        </div>
        <div class="grid sm:grid-cols-[14rem_1fr] gap-x-4 gap-y-1 py-3">
          <dt class="text-sm text-base-content/70">Fließtext · text-base</dt>
          <dd class="max-w-prose">
            Laufende Kosten, die im Kurs stecken. Ordergebühren kommen aus den Buchungen.
          </dd>
        </div>
        <div class="grid sm:grid-cols-[14rem_1fr] gap-x-4 gap-y-1 py-3">
          <dt class="text-sm text-base-content/70">Bedienelemente · text-sm</dt>
          <dd class="text-sm">Tabellen, Menüs, Alerts, Kartentext</dd>
        </div>
        <div class="grid sm:grid-cols-[14rem_1fr] gap-x-4 gap-y-1 py-3">
          <dt class="text-sm text-base-content/70">Feldlabel · text-xs 600</dt>
          <dd class="text-xs font-semibold">Betrag</dd>
        </div>
      </dl>
      <.demo title="Rechenzeichen in Zahlen (tabular-nums)">
        <div id="signs" class="grid gap-x-8 gap-y-2 tabular-nums sm:grid-cols-2">
          <p :for={size <- ["text-sm", "text-2xl font-semibold"]} class={["flex flex-col", size]}>
            <span>+1.150,00&nbsp;€</span>
            <span>−1.150,00&nbsp;€</span>
            <span>–1.150,00&nbsp;€
            <span class="text-sm font-normal text-base-content/70">(Halbgeviertstrich)</span></span>
            <span>−0,88 · −7.420 · −2,5&nbsp;%</span>
          </p>
        </div>
        <:note>
          Das Minus (U+2212) ist Figtrees Plus ohne senkrechten Balken: gleiche Breite, Höhe,
          Strichstärke und Vor- und Nachbreite wie das Plus, in jeder Strichstärke.
        </:note>
      </.demo>
    </section>
    """
  end
end
