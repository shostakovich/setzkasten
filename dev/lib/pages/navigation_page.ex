defmodule Setzkasten.Dev.Pages.NavigationPage do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  import Setzkasten.Dev.Demo
  alias Phoenix.LiveView.JS

  def title, do: "Navigation"
  def summary, do: "segmented, tabs, breadcrumbs, dropdown"

  def render(assigns) do
    ~H"""
    <.showcase
      id="segmented"
      name="<.segmented>"
      title="Segment-Auswahl"
      code={code(0)}
    >
      <:intro>
        Eine Wahl aus wenigen Optionen (Zeitraum, Ansicht): <code>join</code>
        aus Buttons, die gewählte
        Option in der neutralen Auswahlfarbe <code>selected</code>. Vier Modi: Links, Buttons, Formularfeld
        mit einer oder mehreren Optionen.
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
      <.demo title="Kurze Labels mit long_label (Screenreader: „1 Monat“, „6 Monate“ …)">
        <.segmented
          id="range-long"
          mode={:patch}
          size={:sm}
          label="Zeitraum"
          value={@range}
          options={[
            %{label: "1 M", long_label: "1 Monat", value: "1m", path: "/navigation?r=1m"},
            %{label: "6 M", long_label: "6 Monate", value: "6m", path: "/navigation?r=6m"},
            %{label: "1 J", long_label: "1 Jahr", value: "1y", path: "/navigation?r=1y"},
            %{label: "5 J", long_label: "5 Jahre", value: "5y", path: "/navigation?r=5y"},
            {"Max", "max", "/navigation?r=max"}
          ]}
        />
      </.demo>
      <.demo title="block (volle Breite, gleich breite Optionen; fünf passen auf 360px)">
        <.segmented
          id="range-block"
          mode={:patch}
          size={:sm}
          label="Zeitraum"
          value={@range}
          block
          options={[
            {"1M", "1m", "/navigation?r=1m"},
            {"6M", "6m", "/navigation?r=6m"},
            {"1J", "1y", "/navigation?r=1y"},
            {"5J", "5y", "/navigation?r=5y"},
            {"Max", "max", "/navigation?r=max"}
          ]}
        />
      </.demo>
      <.demo title="block={:phone} im Seitenkopf (unter sm eigene Zeile unter dem Titel)">
        <.header level={2}>
          Performance
          <:actions>
            <.button size={:sm} icon="chevron-down">Gesamt</.button>
            <.segmented
              id="range-phone"
              mode={:patch}
              size={:sm}
              label="Zeitraum"
              value={@range}
              block={:phone}
              options={[
                {"1 M", "1m", "/navigation?r=1m"},
                {"YTD", "ytd", "/navigation?r=ytd"},
                {"1 J", "1y", "/navigation?r=1y"},
                {"Max", "max", "/navigation?r=max"}
              ]}
            />
          </:actions>
        </.header>
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
      <.demo title="Als Formularfeld: sichtbares Label, Fehler und Hilfe wie bei input">
        <form class="max-w-md" phx-submit="noop">
          <.segmented
            id="plan-weekdays"
            mode={:checkbox}
            name="plan[weekdays]"
            label="Wochentage"
            value={[]}
            size={:sm}
            errors={["Wähle mindestens einen Tag"]}
            help="Die Erinnerung kommt an diesen Tagen um 7 Uhr."
            options={[
              %{label: "Mo", long_label: "Montag", value: "mon"},
              %{label: "Di", long_label: "Dienstag", value: "tue"},
              %{label: "Mi", long_label: "Mittwoch", value: "wed"},
              %{label: "Do", long_label: "Donnerstag", value: "thu"},
              %{label: "Fr", long_label: "Freitag", value: "fri"},
              %{label: "Sa", long_label: "Samstag", value: "sat"},
              %{label: "So", long_label: "Sonntag", value: "sun"}
            ]}
          />
        </form>
      </.demo>
      <.demo title="mode={:checkbox} (Mehrfachauswahl, gesendet als weekdays[])">
        <.segmented
          id="weekdays-seg"
          mode={:checkbox}
          name="weekdays"
          label="Wochentage"
          value={~w(mon tue wed thu fri)}
          size={:sm}
          options={[
            %{label: "Mo", long_label: "Montag", value: "mon"},
            %{label: "Di", long_label: "Dienstag", value: "tue"},
            %{label: "Mi", long_label: "Mittwoch", value: "wed"},
            %{label: "Do", long_label: "Donnerstag", value: "thu"},
            %{label: "Fr", long_label: "Freitag", value: "fri"},
            %{label: "Sa", long_label: "Samstag", value: "sat"},
            %{label: "So", long_label: "Sonntag", value: "sun"}
          ]}
        />
      </.demo>
    </.showcase>

    <.showcase
      id="tabs"
      name="<.tabs>"
      title="Reiter-Navigation"
      code={code(1)}
    >
      <:intro>
        Wechsel zwischen Geschwister-Ansichten eines Objekts. Nur Links, serverseitig, aktiv per <code>aria-current="page"</code>; scrollt auf dem Handy waagerecht, randlos, mit Ausblendung am Ende, solange mehr folgt. Ein aktiver Reiter außer Sicht wird beim Laden hereingescrollt.
      </:intro>
      <.demo title="Sieben Bereiche (CMS), aktiv: Navigation">
        <.tabs label="Bereiche">
          <:tab patch="/navigation">Posts</:tab>
          <:tab patch="/navigation">Seiten</:tab>
          <:tab patch="/navigation">Bücher</:tab>
          <:tab patch="/navigation">Medien</:tab>
          <:tab patch="/navigation">Links</:tab>
          <:tab patch="/navigation" active>Navigation</:tab>
          <:tab patch="/navigation">Einstellungen</:tab>
        </.tabs>
        <:note>Inaktive Reiter in base-content 70 % (Theme-Patch; daisyUI: 50 %, 3,4:1).</:note>
      </.demo>
    </.showcase>

    <.showcase
      id="breadcrumbs"
      name="<.breadcrumbs>"
      title="Seitenpfad"
      code={code(3)}
    >
      <:intro>
        Für Detailseiten, im <code>:bar</code> des Gerüsts statt der Marke. Eltern als Links, die
        aktuelle Seite als <code>&lt;h1&gt;</code>; auf dem Handy nur „‹ Eltern“.
      </:intro>
      <.demo title="Mit Status">
        <div class="flex min-w-0 items-center gap-3 border-b border-base-content/10 pb-3">
          <.breadcrumbs>
            <:crumb patch="/navigation">Posts</:crumb>
            <:crumb>Was ich aus 100 Code-Reviews gelernt habe (überarbeitet)</:crumb>
          </.breadcrumbs>
          <.badge tone={:info}>Ungespeicherte Änderungen</.badge>
        </div>
      </.demo>
    </.showcase>

    <.showcase
      id="dropdown"
      name="<.dropdown>"
      title="Aufklappmenü"
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
          <:item patch="/navigation" icon="building-2" divider>Alle Websites</:item>
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
      <.demo title="Buttons mit aktivem Eintrag (Sortierung)" class="flex h-56 items-start">
        <.dropdown id="sort" label="Sortierung" variant={:ghost} chevron>
          <:trigger>Sortiert nach {if @sort == "amount", do: "Betrag", else: "Datum"}</:trigger>
          <:item on_click={JS.push("sort", value: %{by: "date"})} active={@sort == "date"}>
            Datum
          </:item>
          <:item on_click={JS.push("sort", value: %{by: "amount"})} active={@sort == "amount"}>
            Betrag
          </:item>
        </.dropdown>
      </.demo>
    </.showcase>
    """
  end

  defp code(0) do
    ~S"""
    <.segmented mode={:patch} value={@range} label="Zeitraum" size={:sm}
      options={[{"1M", "1m", ~p"/?r=1m"}, {"1J", "1y", ~p"/?r=1y"}, {"Max", "max", ~p"/?r=max"}]} />
    <.segmented mode={:patch} value={@range} label="Zeitraum" size={:sm}
      options={[%{label: "1 M", long_label: "1 Monat", value: "1m", path: ~p"/?r=1m"}, …]} />
    <.segmented mode={:button} value={@view} label="Ansicht" phx-click="view"
      options={[%{label: "Liste", value: "list", icon: "list"}, {"Anteile", "shares"}]} />
    <.segmented mode={:radio} field={@form[:split]} label="Aufteilung" options={…} />
    <.segmented mode={:checkbox} field={@form[:weekdays]} label="Wochentage"
      help="Die Erinnerung kommt an diesen Tagen um 7 Uhr."
      options={[%{label: "Mo", long_label: "Montag", value: "mon"}, …]} />
    <.segmented mode={:patch} value={@range} label="Zeitraum" size={:sm} block options={…} />
    <%!-- in the header's actions: full width under the title on phones only --%>
    <.segmented mode={:patch} value={@range} label="Zeitraum" size={:sm} block={:phone} options={…} />
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

  defp code(3) do
    ~S"""
    <:bar>
      <.breadcrumbs>
        <:crumb navigate={~p"/posts"}>Posts</:crumb>
        <:crumb>{@post.title}</:crumb>
      </.breadcrumbs>
      <.badge tone={:info}>Ungespeicherte Änderungen</.badge>
    </:bar>
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
