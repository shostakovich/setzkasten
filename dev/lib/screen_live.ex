defmodule Setzkasten.Dev.ScreenLive do
  @moduledoc false
  use Phoenix.LiveView
  use Setzkasten
  alias Phoenix.LiveView.JS
  alias Setzkasten.Dev.{Dashboard, Data}

  @screens [
    {"posts", "Beiträge (CMS)",
     "Posts einer Website: Kopf mit Aktionen, Reiter, Filter, Liste mit Zeilenaktionen."},
    {"post", "Post bearbeiten (CMS)",
     "Detailseite: Seitenpfad, Status und ⋮-Menü in der Leiste, Formular mit Fehler."},
    {"settings", "Einstellungen (Ausgaben)",
     "Formular in schmaler Spalte, Mitglieder, Farbschema, Aktionsleiste, Dock."},
    {"holdings", "Bestand (Depot)",
     "Seitenleiste, Kennzahlen, responsive Zahlentabelle mit Gruppen und Summe."},
    {"dashboard", "Startseite (Hausautomation)",
     "Live-Kacheln, Raumluft, Energiefluss, Steckdosen und Diagramme, Plüsch-Dock."}
  ]

  def screens, do: Enum.map(@screens, fn {slug, title, _} -> {slug, title} end)
  def screens(:full), do: @screens

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, filter: "all", depot: "all", posts: Data.posts(), groups: Data.holdings())}
  end

  @impl true
  def handle_params(%{"screen" => screen} = params, _uri, socket) do
    screen = if List.keymember?(@screens, screen, 0), do: screen, else: "posts"
    {_, title, _} = List.keyfind(@screens, screen, 0)

    {:noreply,
     assign(socket,
       screen: screen,
       page_title: title,
       filter: params["f"] || "all",
       depot: params["d"] || "all"
     )}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> update(:posts, fn posts -> Enum.reject(posts, &(&1.id == id)) end)
     |> put_flash(:info, "Post gelöscht.")}
  end

  def handle_event("save", _params, socket),
    do: {:noreply, put_flash(socket, :info, "Einstellungen gespeichert.")}

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  @impl true
  def render(%{screen: "posts"} = assigns) do
    assigns =
      assign(assigns,
        visible:
          Enum.filter(assigns.posts, fn p ->
            assigns.filter == "all" or Atom.to_string(p.status) == assigns.filter
          end)
      )

    ~H"""
    <.app_shell layout={:topbar} current={:sites} width={:default} dock={false}>
      <:brand>
        <.icon name="book-open" class="size-5 text-primary" />Blattwerk
      </:brand>
      <:nav key={:sites} label="Websites" icon="globe" navigate="/screens/posts" />
      <:nav key={:media} label="Medien" icon="image" navigate="/screens/posts" />
      <:nav key={:settings} label="Konto" icon="settings" navigate="/screens/settings" />
      <:account>
        <.dropdown id="account" label="Konto" align={:end} variant={:ghost} chevron={false}>
          <:trigger><.avatar initials="JM" size={:sm} /></:trigger>
          <:item navigate="/screens/settings" icon="settings">Einstellungen</:item>
          <:item navigate="/" icon="log-out">Abmelden</:item>
        </.dropdown>
      </:account>
      <.header back="/screens/posts" back_label="Websites">
        Feldnotizen
        <:subtitle>
          feldnotizen.example.com · 42 Posts · zuletzt veröffentlicht am 07.10.2026
        </:subtitle>
        <:badge>
          <.badge tone={:success}>Live</.badge>
        </:badge>
        <:actions>
          <.button icon="external-link" href="https://example.com" target="_blank">Ansehen</.button>
          <.button variant={:primary} icon="plus">Neuer Post</.button>
        </:actions>
      </.header>
      <.tabs label="Bereiche der Website" class="mb-6">
        <:tab patch="/screens/posts" active>Posts</:tab>
        <:tab patch="/screens/posts">Seiten</:tab>
        <:tab patch="/screens/posts">Bücher</:tab>
        <:tab patch="/screens/posts">Medien</:tab>
        <:tab patch="/screens/posts">Links</:tab>
        <:tab patch="/screens/posts">Navigation</:tab>
        <:tab patch="/screens/posts">Einstellungen</:tab>
      </.tabs>
      <div class="flex flex-wrap items-end gap-3">
        <div class="grow basis-64">
          <.input
            name="q"
            id="post-search"
            type="search"
            label="Posts durchsuchen"
            hide_label
            icon="search"
            placeholder="Titel oder Text"
          />
        </div>
        <.segmented
          id="post-filter"
          mode={:patch}
          size={:md}
          label="Status"
          value={@filter}
          options={[
            {"Alle", "all", "/screens/posts"},
            {"Veröffentlicht", "published", "/screens/posts?f=published"},
            {"Entwürfe", "draft", "/screens/posts?f=draft"}
          ]}
        />
      </div>
      <.section_heading count={length(@visible)}>Posts</.section_heading>
      <.list id="posts">
        <.list_row
          :for={post <- @visible}
          id={"post-#{post.id}"}
          title={post.title}
          navigate="/screens/posts"
        >
          <:leading><.icon name="file-text" class="size-5 text-base-content/70" /></:leading>
          <:meta>{post.meta}</:meta>
          <:trailing>
            <.badge :if={post.status == :published} tone={:success}>Veröffentlicht</.badge>
            <.badge :if={post.status == :draft}>Entwurf</.badge>
            <.badge :if={post.status == :scheduled} tone={:info}>Geplant</.badge>
          </:trailing>
          <:action label="Bearbeiten" icon="pencil" navigate="/screens/posts" />
          <:action
            label="Löschen"
            icon="trash-2"
            danger
            confirm={"„#{post.title}“ löschen?"}
            confirm_text="Der Post und seine Bilder verschwinden von der Website."
            on_click={JS.push("delete", value: %{id: post.id})}
          />
        </.list_row>
      </.list>
      <.empty_state :if={@visible == []} icon="inbox" title="Keine Posts mit diesem Status">
        Wähle „Alle“, um alle Posts zu sehen.
      </.empty_state>
    </.app_shell>
    <.flash_group flash={@flash} />
    <.confirm_dialog />
    """
  end

  def render(%{screen: "post"} = assigns) do
    ~H"""
    <.app_shell layout={:sidebar} current={:posts} width={:narrow}>
      <:brand><.icon name="book-open" class="size-5 text-sidebar-accent" />Blattwerk</:brand>
      <:nav key={:sites} label="Websites" icon="globe" navigate="/screens/posts" />
      <:nav
        key={:posts}
        label="Posts"
        icon="file-text"
        section="Website"
        navigate="/screens/post"
      />
      <:nav key={:media} label="Medien" icon="image" section="Website" navigate="/screens/post" />
      <:nav key={:links} label="Links" icon="link" section="Website" navigate="/screens/post" />
      <:account :let={place}>
        <.button :if={place == :bar} size={:sm} icon="upload" icon_only label="Veröffentlichen" />
        <.button :if={place == :sidebar} size={:sm} icon="upload">Veröffentlichen</.button>
        <.dropdown
          id={"post-account-#{place}"}
          label="Konto"
          align={:end}
          position={if place == :sidebar, do: :top, else: :bottom}
          variant={:ghost}
          chevron={false}
          class={place == :sidebar && "ms-auto"}
          trigger_class="btn-square"
        >
          <:trigger><.avatar initials="JM" size={:sm} /></:trigger>
          <:header>jonas@example.com</:header>
          <:item navigate="/screens/settings" icon="settings">Einstellungen</:item>
          <:item navigate="/" icon="log-out">Abmelden</:item>
        </.dropdown>
      </:account>
      <:bar>
        <.breadcrumbs>
          <:crumb navigate="/screens/posts">Feldnotizen</:crumb>
          <:crumb navigate="/screens/posts">Posts</:crumb>
          <:crumb>Was ich aus 100 Code-Reviews gelernt habe (überarbeitet)</:crumb>
        </.breadcrumbs>
        <.badge>Entwurf</.badge>
      </:bar>
      <:bar_actions>
        <.dropdown
          id="post-menu"
          label="Aktionen"
          align={:end}
          variant={:ghost}
          chevron={false}
          trigger_class="btn-square"
        >
          <:trigger><.icon name="ellipsis-vertical" /></:trigger>
          <:item navigate="/screens/post" icon="eye">Vorschau</:item>
          <:item on_click="archive" icon="archive">Archivieren</:item>
          <:item
            on_click="delete-post"
            icon="trash-2"
            danger
            divider
            confirm="Post löschen?"
          >
            Löschen
          </:item>
        </.dropdown>
      </:bar_actions>
      <form id="post-form" phx-submit="save" class="space-y-2">
        <.input
          name="post[title]"
          id="post-title"
          label="Titel"
          value="Was ich aus 100 Code-Reviews gelernt habe (überarbeitet)"
        />
        <.input
          name="post[slug]"
          id="post-slug"
          label="Adresse"
          value="code-reviews"
          errors={["ist schon vergeben"]}
          help="Kleinbuchstaben und Bindestriche, z. B. code-reviews-2026."
        />
        <.input name="post[body]" id="post-body" type="textarea" label="Text" rows="8" />
        <.action_bar sticky class="mt-6">
          <.button navigate="/screens/posts">Abbrechen</.button>
          <.button type="submit" variant={:primary}>Speichern</.button>
        </.action_bar>
      </form>
    </.app_shell>
    <.flash_group flash={@flash} />
    <.confirm_dialog />
    """
  end

  def render(%{screen: "settings"} = assigns) do
    ~H"""
    <.app_shell layout={:topbar} current={:settings} width={:narrow}>
      <:brand><.plush name="mascot" size={:lg} />Teilbar</:brand>
      <:nav key={:expenses} label="Ausgaben" plush="receipt" navigate="/screens/settings" />
      <:nav key={:balances} label="Salden" plush="scale" navigate="/screens/settings" />
      <:nav key={:activity} label="Aktivität" plush="activity" navigate="/screens/settings" />
      <:nav key={:settings} label="Einstellungen" plush="settings" navigate="/screens/settings" />
      <:account>
        <.avatar initials="J" size={:sm} label="Du bist Jonas" />
      </:account>
      <.header>
        Einstellungen
        <:subtitle>WG Gartenstraße · 3 Mitglieder</:subtitle>
      </.header>
      <form id="settings-form" phx-submit="save" class="space-y-2">
        <.section_heading>Gruppe</.section_heading>
        <div class="grid gap-4 md:grid-cols-2">
          <div class="md:col-span-2">
            <.input name="group[name]" id="group-name" label="Name" value="WG Gartenstraße" required />
          </div>
          <.input
            name="group[currency]"
            id="group-currency"
            type="select"
            label="Währung"
            options={[{"Euro (€)", "EUR"}, {"Schweizer Franken (CHF)", "CHF"}]}
            value="EUR"
          />
          <.input
            name="group[limit]"
            id="group-limit"
            label="Erinnern ab"
            suffix="€"
            numeric
            class="max-w-40"
            value="50,00"
            help="Ab diesem Saldo bekommt die Person eine Erinnerung."
          />
        </div>

        <.section_heading count={3}>Mitglieder</.section_heading>
        <.list>
          <.list_row
            :for={
              {initials, name, meta} <- [
                {"J", "Jonas", "Du · Admin"},
                {"D", "Dana", "seit März 2024"},
                {"K", "Kim", "seit Juni 2025"}
              ]
            }
            title={name}
          >
            <:leading>
              <.avatar
                initials={initials}
                tone={if initials == "J", do: :primary, else: :base}
                shape={:round}
              />
            </:leading>
            <:meta>{meta}</:meta>
          </.list_row>
        </.list>
        <div class="join max-sm:join-vertical w-full pt-3">
          <label for="new-member" class="sr-only">Neues Mitglied</label>
          <input
            id="new-member"
            name="member[name]"
            type="text"
            class="input join-item w-full"
            placeholder="Name, z. B. Alex"
          />
          <.button variant={:primary} icon="plus" class="join-item">Hinzufügen</.button>
        </div>

        <.section_heading>Darstellung</.section_heading>
        <.theme_toggle id="settings-theme" />

        <.section_heading>Benachrichtigungen</.section_heading>
        <.input
          name="notify[expense]"
          id="notify-expense"
          type="toggle"
          label="Neue Ausgaben"
          value="true"
        />
        <.input
          name="notify[weekly]"
          id="notify-weekly"
          type="toggle"
          label="Wöchentliche Zusammenfassung"
        />

        <.alert tone={:info} title="Abrechnung zum Monatsende" class="mt-6">
          Am Monatsende schlägt Teilbar vor, wer wem wie viel überweist.
        </.alert>

        <.action_bar sticky class="mt-6">
          <:secondary>
            <.button
              variant={:danger_outline}
              icon="trash-2"
              confirm="Gruppe „WG Gartenstraße“ löschen?"
              confirm_text="Alle Ausgaben und Salden der Gruppe gehen verloren."
              phx-click="delete-group"
            >
              Gruppe löschen
            </.button>
          </:secondary>
          <.button navigate="/screens/settings">Abbrechen</.button>
          <.button type="submit" variant={:primary} phx-disable-with="Speichert …">Speichern</.button>
        </.action_bar>
      </form>
    </.app_shell>
    <.flash_group flash={@flash} />
    <.confirm_dialog />
    """
  end

  def render(%{screen: "holdings"} = assigns) do
    ~H"""
    <.app_shell layout={:sidebar} current={:holdings} width={:wide}>
      <:brand><.icon name="chart-line" class="size-5 text-sidebar-accent" />Depotblick</:brand>
      <:nav key={:overview} label="Übersicht" icon="chart-line" navigate="/screens/holdings" />
      <:nav key={:holdings} label="Bestand" icon="list" navigate="/screens/holdings" />
      <:nav
        key={:kinder}
        label="Kinderdepot"
        icon="wallet"
        amount={799_483}
        section="Depots"
        navigate="/screens/holdings"
      />
      <:nav
        key={:lang}
        label="Langfristig"
        icon="wallet"
        amount={4_241_291}
        section="Depots"
        navigate="/screens/holdings"
      />
      <:nav
        key={:tagesgeld}
        label="Tagesgeld"
        icon="landmark"
        amount={1_287_140}
        section="Konten"
        navigate="/screens/holdings"
        dock={false}
      />
      <:nav key={:settings} label="Einstellungen" icon="settings" navigate="/screens/holdings" />
      <:account :let={place}>
        <.dropdown
          id={"account-#{place}"}
          label="Konto"
          align={if place == :bar, do: :end, else: :start}
          position={if place == :sidebar, do: :top, else: :bottom}
          variant={:ghost}
          chevron={false}
          class={place == :sidebar && "w-full"}
          trigger_class={if place == :sidebar, do: "w-full justify-start", else: "btn-square"}
        >
          <:trigger>
            <.avatar initials="D" size={:sm} />
            <span :if={place == :sidebar} class="truncate">dana@example.com</span>
          </:trigger>
          <:item navigate="/screens/holdings" icon="settings">Einstellungen</:item>
          <:item navigate="/" icon="log-out">Abmelden</:item>
        </.dropdown>
      </:account>
      <.header>
        Bestand
        <:subtitle>2 Depots · 11 Wertpapiere · 2 Konten · Stand 09.10.2026, 18:00</:subtitle>
        <:actions>
          <.segmented
            id="depot"
            mode={:patch}
            size={:sm}
            label="Depot"
            value={@depot}
            options={[
              {"Gesamt", "all", "/screens/holdings"},
              {"Kinderdepot", "kinder", "/screens/holdings?d=kinder"},
              {"Langfristig", "lang", "/screens/holdings?d=lang"}
            ]}
          />
        </:actions>
      </.header>
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <.stat label="Vermögen" value="63.279" unit="€" desc="+8,4 % seit Jahresbeginn" size={:sm} />
        <.stat
          label="Gewinn"
          value="+10.353"
          unit="€"
          tone={:success}
          desc="+39,1 % auf Einstand"
          size={:sm}
        />
        <.stat label="Kosten pro Jahr" value="76" unit="€" desc="TER gewichtet 0,20 %" size={:sm} />
        <.stat label="Kurse" value="18:00" desc="täglich vom Kursanbieter" size={:sm} />
      </div>
      <.section_heading count={7}>Positionen</.section_heading>
      <Setzkasten.Dev.Holdings.holdings_table groups={@groups} />
      <p class="mt-3 text-sm text-base-content/70 max-w-prose">
        Auszug: 7 von 11 Positionen. Kurse vom täglichen Abruf um 18:00.
      </p>
    </.app_shell>
    <.flash_group flash={@flash} />
    """
  end

  def render(%{screen: "dashboard"} = assigns) do
    ~H"""
    <.app_shell layout={:topbar} current={:home} width={:default}>
      <:brand><.plush name="buddy" size={:lg} />Hauswart</:brand>
      <:nav key={:home} label="Home" plush="nav-dashboard" navigate="/screens/dashboard" />
      <:nav key={:pv} label="PV" plush="nav-solar" navigate="/screens/dashboard" />
      <:nav key={:switches} label="Schalten" plush="nav-switches" navigate="/screens/dashboard" />
      <:nav key={:reports} label="Berichte" plush="nav-reports" navigate="/screens/dashboard" />
      <:nav key={:weather} label="Wetter" plush="nav-weather" navigate="/screens/dashboard" />
      <:nav key={:sensors} label="Sensoren" plush="nav-sensors" navigate="/screens/dashboard" />
      <.header>
        Dashboard
        <:subtitle>Stand 10.10.2026, 13:42 · aktualisiert sich live</:subtitle>
        <:badge>
          <.badge tone={:success}>Live</.badge>
        </:badge>
      </.header>

      <div class="space-y-4">
        <div class="grid grid-cols-2 gap-4">
          <.stat label="PV jetzt" unit="W" desc="Sonnig, 17 °C">
            <span class="inline-flex items-center gap-2">
              <.plush name="sunny" size={:lg} />486
            </span>
          </.stat>
          <.stat label="Batterie" unit="%" desc="entlädt mit 120 W">
            <span class="inline-flex items-center gap-2">
              <.plush name="battery" size={:lg} />78
            </span>
          </.stat>
        </div>

        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
          <.stat
            :for={tile <- Dashboard.tiles()}
            label={tile.label}
            value={tile.value}
            unit={tile.unit}
            tone={tile[:tone]}
            size={:sm}
          />
        </div>
      </div>

      <.section_heading>Raumluft</.section_heading>
      <.card
        title="Wohnzimmer: Luft gut"
        subtitle="Kein Lüften nötig, CO₂ deutlich unter der Grenze."
        navigate="/screens/dashboard"
      >
        <:leading><.plush name="nav-sensors" size={:lg} /></:leading>
        <:actions>
          <.badge tone={:success}>niedrig</.badge>
        </:actions>
        <.bar
          label="CO₂"
          value={640}
          max={2000}
          target={1000}
          tone={:success}
          show_value
          value_label="640 ppm"
        >
          Lüften ab 1.000 ppm · gemessen vor 2 Min
        </.bar>
      </.card>

      <.section_heading>Energie</.section_heading>
      <div class="space-y-4">
        <.chart_card
          id="energy-flow"
          title="Energiefluss"
          summary="PV liefert 486 W, Batterie 120 W und Netz 106 W, zusammen 712 W ins Haus."
          height={:lg}
        >
          <Dashboard.energy_flow />
          <:legend>
            <.legend items={[
              %{label: "PV", color: 2},
              %{label: "Netz", color: 1},
              %{label: "Batterie", color: 3}
            ]} />
          </:legend>
        </.chart_card>

        <.card title="Steckdosen" subtitle="Verbrauch gesamt 650 W · Balkonkraftwerk erzeugt 486 W">
          <div class="space-y-3">
            <.bar
              :for={plug <- Dashboard.plugs()}
              label={plug.name}
              value={plug.watt}
              max={650}
              show_value
              value_label={"#{plug.watt} W"}
            />
          </div>
        </.card>

        <.chart_card
          id="today-energy"
          title="Gesamtenergie"
          summary="Erzeugte und verbrauchte Energie je Stunde der letzten 24 Stunden."
        >
          <Dashboard.energy_chart />
          <:legend>
            <.legend items={[%{label: "Erzeugt", color: 2}, %{label: "Verbraucht", color: 1}]} />
            <p class="text-xs text-base-content/70">kWh je Stunde · letzte 24 h</p>
          </:legend>
          <:data>
            <.table id="today-energy-data" rows={Dashboard.energy_rows()} size={:sm} flush>
              <:col :let={r} label="Stunde">{r.hour}</:col>
              <:col :let={r} label="Erzeugt (kWh)" align={:end}>{r.produced}</:col>
              <:col :let={r} label="Verbraucht (kWh)" align={:end}>{r.consumed}</:col>
            </.table>
          </:data>
        </.chart_card>

        <.chart_card
          id="today-power"
          title="Leistung"
          summary="PV-Leistung und Verbrauch in Watt über die letzten 24 Stunden."
        >
          <Dashboard.power_chart />
          <:legend>
            <.legend items={[%{label: "PV", color: 2}, %{label: "Verbrauch", color: 1}]} />
            <p class="text-xs text-base-content/70">Watt · letzte 24 h</p>
          </:legend>
          <:data>
            <.table id="today-power-data" rows={Dashboard.power_rows()} size={:sm} flush>
              <:col :let={r} label="Zeit">{r.hour}</:col>
              <:col :let={r} label="PV (W)" align={:end}>{r.pv}</:col>
              <:col :let={r} label="Verbrauch (W)" align={:end}>{r.home}</:col>
            </.table>
          </:data>
        </.chart_card>

        <.chart_card
          id="history"
          title="Ertrag"
          summary="PV-Ertrag je Tag der letzten 14 Tage, zwischen 0,7 und 3,2 kWh."
        >
          <Dashboard.yield_chart />
          <:legend>
            <p class="text-xs text-base-content/70">kWh je Tag · letzte 14 Tage</p>
          </:legend>
          <:data>
            <.table id="history-data" rows={Dashboard.yield_rows()} size={:sm} flush>
              <:col :let={r} label="Tag">{r.day}</:col>
              <:col :let={r} label="Ertrag (kWh)" align={:end}>{r.kwh}</:col>
            </.table>
          </:data>
        </.chart_card>
      </div>
    </.app_shell>
    <.flash_group flash={@flash} />
    """
  end
end
