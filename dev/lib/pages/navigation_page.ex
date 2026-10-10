defmodule Setzkasten.Dev.Pages.NavigationPage do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  import Setzkasten.Dev.Demo

  def title, do: "Navigation"
  def summary, do: "segmented, tabs, dropdown"

  def render(assigns) do
    ~H"""
    <.showcase
      id="segmented"
      name="<.segmented>"
      title="Segment-Auswahl"
      apps="alle fünf (heute fünf Techniken)"
      code={code(0)}
    >
      <:intro>
        Eine Wahl aus wenigen Optionen (Zeitraum, Ansicht): <code>join</code> aus Buttons, gewählt =
        Primary. Drei Modi: Links, Buttons, Formularfeld.
      </:intro>
      <.demo title="mode={:patch}, size={:sm} (klickbar, Zustand in der URL)">
        <.segmented
          id="range"
          mode={:patch}
          size={:sm}
          label="Zeitraum"
          value={@range}
          options={[
            {"1M", "1m", "/navigation?r=1m"},
            {"6M", "6m", "/navigation?r=6m"},
            {"1J", "1y", "/navigation?r=1y"},
            {"5J", "5y", "/navigation?r=5y"},
            {"Max", "max", "/navigation?r=max"}
          ]}
        />
      </.demo>
      <.demo title="mode={:button}, size={:md}">
        <.segmented
          id="view"
          mode={:button}
          label="Ansicht"
          value={@view}
          phx-click="view"
          options={[
            %{label: "Liste", value: "list", icon: "list"},
            %{label: "Anteile", value: "shares", icon: "chart-pie"}
          ]}
        />
      </.demo>
      <.demo title="mode={:radio} (Formularfeld, native Radios)">
        <.segmented
          id="split-seg"
          mode={:radio}
          name="split"
          label="Aufteilung"
          value="equal"
          options={[{"Gleich", "equal"}, {"Anteile", "shares"}, {"Beträge", "exact"}]}
        />
      </.demo>
    </.showcase>

    <.showcase
      id="tabs"
      name="<.tabs>"
      title="Reiter-Navigation"
      apps="CMS, Depot, Hausautomation, Budget"
      code={code(1)}
    >
      <:intro>
        Wechsel zwischen Geschwister-Ansichten eines Objekts. Nur Links, serverseitig, aktiv per <code>aria-current="page"</code>; scrollt auf dem Handy waagerecht.
      </:intro>
      <.demo title="Sieben Bereiche (CMS)">
        <.tabs label="Bereiche">
          <:tab patch="/navigation" active>Posts</:tab>
          <:tab patch="/navigation">Seiten</:tab>
          <:tab patch="/navigation">Bücher</:tab>
          <:tab patch="/navigation">Medien</:tab>
          <:tab patch="/navigation">Links</:tab>
          <:tab patch="/navigation">Navigation</:tab>
          <:tab patch="/navigation">Einstellungen</:tab>
        </.tabs>
        <:note>Inaktive Reiter in base-content 70 % (Theme-Patch; daisyUI: 50 %, 3,4:1).</:note>
      </.demo>
    </.showcase>

    <.showcase
      id="dropdown"
      name="<.dropdown>"
      title="Aufklappmenü"
      apps="CMS, Depot, Budget"
      code={code(2)}
    >
      <:intro>
        Konto-Menü, Zeilen-Menü, Website-Wechsler. Natives <code>&lt;details&gt;</code>; schließt
        bei Klick daneben, Escape und nach der Auswahl.
      </:intro>
      <.demo
        title="Website-Wechsler (offen) und Konto"
        class="flex h-72 flex-wrap items-start justify-between gap-4"
      >
        <.dropdown id="site-switcher" open>
          <:trigger><.icon name="globe" />Feldnotizen</:trigger>
          <:item patch="/navigation" active>Feldnotizen</:item>
          <:item patch="/navigation">Gartenbuch</:item>
          <:item patch="/navigation">Rezepte</:item>
          <:item patch="/navigation" icon="building-2">Alle Websites</:item>
        </.dropdown>
        <.dropdown id="account" label="Konto" align={:end} variant={:ghost}>
          <:trigger>
            <.avatar initials="JM" size={:sm} />
            <span class="hidden sm:inline">demo@example.com</span>
          </:trigger>
          <:item patch="/navigation" icon="settings">Einstellungen</:item>
          <:item patch="/navigation" icon="key-round">Passkeys</:item>
          <:item patch="/navigation" icon="log-out">Abmelden</:item>
        </.dropdown>
      </.demo>
    </.showcase>
    """
  end

  defp code(0) do
    ~S"""
    <.segmented mode={:patch} value={@range} label="Zeitraum" size={:sm}
      options={[{"1M", "1m", ~p"/?r=1m"}, {"1J", "1y", ~p"/?r=1y"}, {"Max", "max", ~p"/?r=max"}]} />
    <.segmented mode={:button} value={@view} label="Ansicht" phx-click="view"
      options={[%{label: "Liste", value: "list", icon: "list"}, {"Anteile", "shares"}]} />
    <.segmented mode={:radio} field={@form[:split]} label="Aufteilung" options={…} />
    """
  end

  defp code(1) do
    ~S"""
    <.tabs label="Bereiche">
      <:tab navigate={~p"/sites/#{@site}/posts"} active>Posts</:tab>
      <:tab navigate={~p"/sites/#{@site}/pages"}>Seiten</:tab>
    </.tabs>
    """
  end

  defp code(2) do
    ~S"""
    <.dropdown id="account" label="Konto" align={:end} variant={:ghost}>
      <:trigger><.avatar initials="JM" size={:sm} /> jonas@…</:trigger>
      <:item navigate={~p"/users/settings"} icon="settings">Einstellungen</:item>
      <:item href={~p"/users/log-out"} method="delete" icon="log-out">Abmelden</:item>
    </.dropdown>
    """
  end
end
