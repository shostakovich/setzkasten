defmodule Setzkasten.Dev.Pages.IconsPage do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  import Setzkasten.Dev.Demo

  def title, do: "Icons"
  def summary, do: "icon (Lucide) und plush (WebP)"

  @categories [
    {"cart", "Lebensmittel"},
    {"utensils", "Essen gehen"},
    {"home", "Wohnen"},
    {"car", "Auto"},
    {"zap", "Strom"},
    {"plane", "Urlaub"},
    {"gift", "Geschenke"},
    {"baby", "Kinder"},
    {"paw", "Haustier"},
    {"heart", "Gesundheit"},
    {"ticket", "Freizeit"},
    {"piggy", "Sparen"}
  ]

  @nav_icons [
    {"nav-dashboard", "Übersicht"},
    {"nav-solar", "PV"},
    {"nav-sensors", "Sensoren"},
    {"nav-switches", "Schalter"},
    {"nav-weather", "Wetter"},
    {"nav-reports", "Berichte"}
  ]

  def render(assigns) do
    assigns =
      assign(assigns,
        builtin: Setzkasten.Lucide.names(),
        app_icons: Setzkasten.Dev.Icons.names(),
        categories: @categories,
        nav_icons: @nav_icons
      )

    ~H"""
    <.showcase
      id="icon"
      name="<.icon>"
      title="Strich-Icon (Lucide)"
      apps="alle fünf"
      code={code(0)}
    >
      <:intro>
        Aktionen, Pfeile, Status-Zeichen. Inline-SVG in <code>currentColor</code>; die Bibliothek
        bringt nur die Icons ihrer eigenen Komponenten mit, die App kompiliert ihre eigenen mit <code>use Setzkasten.Icons, path: "…"</code>.
      </:intro>
      <.demo
        title="Größen: size-4 (Standard) · size-5 (alleinstehend) · size-6 (Leerzustand)"
        class="flex flex-wrap items-end gap-6"
      >
        <span class="flex items-center gap-2 text-sm"><.icon name="pencil" />size-4</span>
        <span class="flex items-center gap-2 text-sm"><.icon name="pencil" class="size-5" />size-5</span>
        <span class="flex items-center gap-2 text-sm"><.icon name="pencil" class="size-6" />size-6</span>
        <span class="flex items-center gap-2 text-sm text-error-ink">
          <.icon name="circle-alert" class="size-5" label="Fehler" />mit Label (role="img")
        </span>
      </.demo>
      <.demo
        title={"Im Paket (#{length(@builtin)})"}
        class="grid grid-cols-3 sm:grid-cols-6 lg:grid-cols-8 gap-3 text-xs text-base-content/70"
      >
        <span :for={name <- @builtin} class="flex flex-col items-center gap-1.5 text-center">
          <.icon name={name} class="size-5 text-base-content" />{name}
        </span>
      </.demo>
      <.demo
        title={"Vom Katalog ergänzt (#{length(@app_icons)}, wie eine App)"}
        class="grid grid-cols-3 sm:grid-cols-6 lg:grid-cols-8 gap-3 text-xs text-base-content/70"
      >
        <span :for={name <- @app_icons} class="flex flex-col items-center gap-1.5 text-center">
          <.icon name={name} class="size-5 text-base-content" />{name}
        </span>
      </.demo>
    </.showcase>

    <.showcase
      id="plush"
      name="<.plush>"
      title="Plüsch-Icon"
      apps="Hausautomation, Ausgaben"
      code={code(1)}
    >
      <:intro>
        Navigation, Kategorien, Wetter, Einstellungs-Links. WebP mit heller und dunkler Datei; die
        App liefert die Bilder (<code>config :setzkasten, plush: MyAppWeb.Plush</code>). Der Katalog
        zeigt Platzhalter.
      </:intro>
      <.demo
        title="Größen :sm 20 · :md 24 · :lg 32 · :xl 48px"
        class="flex flex-wrap items-end gap-6 text-xs text-base-content/70"
      >
        <span :for={size <- [:sm, :md, :lg, :xl]} class="flex flex-col items-center gap-1.5">
          <.plush name="home" size={size} />:{size}
        </span>
      </.demo>
      <.demo
        title="Kategorien (helle und dunkle Datei, wechselt mit dem Theme)"
        class="grid grid-cols-3 sm:grid-cols-6 gap-3 text-xs text-base-content/70"
      >
        <span :for={{name, label} <- @categories} class="flex flex-col items-center gap-1.5">
          <.plush name={name} size={:lg} />{label}
        </span>
      </.demo>
      <.demo
        title="Navigation (eine Datei für beide Themes)"
        class="grid grid-cols-3 sm:grid-cols-6 gap-3 text-xs text-base-content/70"
      >
        <span :for={{name, label} <- @nav_icons} class="flex flex-col items-center gap-1.5">
          <.plush name={name} size={:lg} />{label}
        </span>
      </.demo>
    </.showcase>
    """
  end

  defp code(0) do
    ~S"""
        <.icon name="trash-2" />
        <.icon name="circle-alert" class="size-5 text-error-ink" label="Fehler" />
    """
  end

  defp code(1) do
    ~S"""
        <.plush name="cart" size={:lg} />
        <.plush src={~p"/images/mascot.webp"} size={:xl} alt="Maskottchen" />
    """
  end
end
