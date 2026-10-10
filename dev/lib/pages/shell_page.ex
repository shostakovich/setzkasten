defmodule Setzkasten.Dev.Pages.ShellPage do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  import Setzkasten.Dev.Demo

  def title, do: "Gerüst"
  def summary, do: "app_shell :sidebar und :topbar, Dock"

  def render(assigns) do
    ~H"""
    <.showcase
      id="app-shell"
      name="<.app_shell>"
      title="Navigations-Gerüst"
      code={code(0)}
    >
      <:intro>
        Zwei Layouts. <code>:sidebar</code>: dunkle Seitenleiste ab <code>xl</code>, Icon-Leiste von
        <code>md</code>
        bis <code>xl</code>
        (ausklappbar als
        Dialog), auf dem Handy Kopfzeile + Dock. <code>:topbar</code>: Navbar ab <code>md</code>, darunter Dock und ggf. FAB. Die Vorschauen sind
        die echten Screens in festen Breiten.
      </:intro>
      <.demo
        :for={
          {slug, label} <- [
            {"holdings", ":sidebar"},
            {"posts", ":topbar mit FAB"},
            {"settings", ":topbar ohne Dock"},
            {"dashboard", ":topbar mit Plüsch-Dock"}
          ]
        }
        title={"#{label} – /screens/#{slug}"}
        class="flex gap-4 overflow-x-auto p-1 pb-2"
      >
        <figure :for={{w, h} <- [{390, 640}, {800, 640}, {1280, 640}]} class="shrink-0 space-y-1">
          <iframe
            src={"/screens/#{slug}"}
            width={w}
            height={h}
            title={"#{label} bei #{w}px"}
            loading="lazy"
            class="rounded-box border border-base-content/10 bg-base-100"
          ></iframe>
          <figcaption class="text-xs text-base-content/70">{w}px</figcaption>
        </figure>
      </.demo>
    </.showcase>
    """
  end

  defp code(0) do
    ~S"""
    <.app_shell layout={:sidebar} current={:holdings} width={:wide}>
      <:brand>Depotblick</:brand>
      <:nav key={:overview} label="Übersicht" icon="chart-line" navigate={~p"/"} />
      <:nav key={:holdings} label="Bestand" icon="list" navigate={~p"/bestand"} />
      <:nav key={:kinder} label="Kinderdepot" icon="wallet" amount={799_483} section="Depots" navigate={…} />
      <:account><.dropdown …/></:account>
      {@inner_content}
    </.app_shell>
    """
  end
end
