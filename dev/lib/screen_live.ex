defmodule Setzkasten.Dev.ScreenLive do
  @moduledoc false
  use Phoenix.LiveView
  use Setzkasten
  alias Phoenix.LiveView.JS
  alias Setzkasten.Dev.{Budget, Dashboard, Data, Holdings, Shopping}

  @screens [
    {"posts", "Beiträge (CMS)",
     "Posts einer Website: Kopf mit Aktionen, Reiter, Filter, Liste mit Zeilenaktionen."},
    {"post", "Post bearbeiten (CMS)",
     "Detailseite: Seitenpfad, Status und ⋮-Menü in der Leiste, Formular mit Fehler."},
    {"settings", "Einstellungen (Ausgaben)",
     "Formular in schmaler Spalte, Mitglieder, Farbschema, Aktionsleiste, Dock."},
    {"holdings", "Bestand (Depot)",
     "Seitenleiste mit Depots und Konten, Depot-Menü, Zahlentabelle mit Gruppen, Aufteilung, Kosten."},
    {"dashboard", "Startseite (Hausautomation)",
     "Live-Kacheln, Raumluft, Energiefluss, Steckdosen und Diagramme, Plüsch-Dock."},
    {"budget", "Konto (Haushaltsbuch)",
     "Seitenleiste mit Kontogruppen, Summen, negativen Salden und ziehbaren Konten; Auswahlleiste mit Kategorisieren."},
    {"shopping", "Einkaufsliste (Haushalt)",
     "Kompakte Liste mit Abhaken, „Zuletzt verwendet“, Composer über dem Dock; Toasts mit Aktion."}
  ]

  # Allocation tab, its URL parameter and label; the first is the default.
  @allocation_tabs [
    regions: {nil, "Regionen"},
    sectors: {"sektoren", "Sektoren"},
    classes: {"anlage", "Anlageklassen"}
  ]
  @allocation_params Map.new(@allocation_tabs, fn {tab, {param, _}} -> {param, tab} end)

  def screens, do: Enum.map(@screens, fn {slug, title, _} -> {slug, title} end)
  def screens(:full), do: @screens

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       filter: "all",
       posts: Data.posts(),
       holdings: Data.holdings(),
       allocation: Data.allocation(),
       live_step: 0,
       ticking: false,
       transactions: Budget.transactions(),
       account_groups: Budget.groups(),
       selected: [],
       shopping: Map.new(Shopping.open() ++ Shopping.recent(), &{&1.id, &1}),
       open_ids: Enum.map(Shopping.open(), & &1.id),
       recent_ids: Enum.map(Shopping.recent(), & &1.id),
       entry: ""
     )
     |> stream_configure(:items, dom_id: &"item-#{&1.id}")
     |> stream(:items, Shopping.open())}
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
       depot: Holdings.depot(socket.assigns.holdings, params["d"]),
       marked: params["k"],
       settings?: params["m"] == "settings",
       allocation_tab: Map.get(@allocation_params, params["a"], :regions)
     )
     |> start_ticking()}
  end

  defp update_selected(socket, fun) do
    selected = socket.assigns.selected

    update(socket, :transactions, fn txs ->
      Enum.map(txs, &if(&1.id in selected, do: fun.(&1), else: &1))
    end)
  end

  # The dashboard's live values change every 10 s, slow enough for the change animation.
  defp start_ticking(%{assigns: %{screen: "dashboard", ticking: false}} = socket) do
    if connected?(socket), do: Process.send_after(self(), :tick, 10_000)
    assign(socket, ticking: connected?(socket))
  end

  defp start_ticking(socket), do: socket

  @impl true
  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 10_000)
    {:noreply, update(socket, :live_step, &(&1 + 1))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> update(:posts, fn posts -> Enum.reject(posts, &(&1.id == id)) end)
     |> put_flash(:info, "Post gelöscht.")}
  end

  def handle_event("book", _params, socket),
    do: {:noreply, put_flash(socket, :info, "Hier öffnet die App den Dialog „Buchung erfassen“.")}

  def handle_event("save", _params, socket), do: {:noreply, push_saved(socket, "settings-save")}

  def handle_event("toggle_tx", %{"id" => id}, socket) do
    {:noreply,
     update(socket, :selected, &if(id in &1, do: List.delete(&1, id), else: &1 ++ [id]))}
  end

  def handle_event("clear_selection", _params, socket),
    do: {:noreply, assign(socket, selected: [])}

  def handle_event("approve_selected", _params, socket) do
    {:noreply,
     socket
     |> update_selected(&%{&1 | approved: true})
     |> assign(selected: [])}
  end

  def handle_event("categorise_selected", %{"category" => category}, socket)
      when category != "" do
    {:noreply,
     socket
     |> update_selected(&%{&1 | category: category})
     |> assign(selected: [])}
  end

  def handle_event("categorise_selected", _params, socket), do: {:noreply, socket}

  def handle_event("delete_selected", _params, socket) do
    selected = socket.assigns.selected

    {:noreply,
     socket
     |> update(:transactions, fn txs -> Enum.reject(txs, &(&1.id in selected)) end)
     |> assign(selected: [])
     |> put_flash(:info, "Buchungen gelöscht (Demo).")}
  end

  def handle_event("sort_account", %{"section" => section, "id" => id, "index" => index}, socket),
    do: {:noreply, update(socket, :account_groups, &Budget.move(&1, section, id, index))}

  def handle_event("add_account", _params, socket),
    do: {:noreply, put_flash(socket, :info, "Hier öffnet die App den Dialog „Konto hinzufügen“.")}

  def handle_event("check", %{"id" => id}, socket) do
    if id in socket.assigns.open_ids do
      item = socket.assigns.shopping[id]

      {:noreply,
       socket
       |> check(item)
       |> put_toast("#{item.name} abgehakt",
         action: "Rückgängig",
         on_action: JS.push("uncheck", value: %{id: id})
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_event("check_elsewhere", _params, %{assigns: %{open_ids: [id | _]}} = socket),
    do: {:noreply, check(socket, socket.assigns.shopping[id])}

  def handle_event("uncheck", %{"id" => id}, socket) do
    if id in socket.assigns.recent_ids do
      item = socket.assigns.shopping[id]
      open_ids = Shopping.put_back(socket.assigns.open_ids, id)

      {:noreply,
       socket
       |> assign(open_ids: open_ids)
       |> update(:recent_ids, &List.delete(&1, id))
       |> stream_insert(:items, item, at: Enum.find_index(open_ids, &(&1 == id)))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("entry", %{"entry" => %{"name" => name}}, socket),
    do: {:noreply, assign(socket, entry: name)}

  def handle_event("add_entry", %{"entry" => %{"name" => name}}, socket) do
    case String.trim(name) do
      "" ->
        {:noreply, socket}

      name ->
        item = Shopping.item(name)

        {:noreply,
         socket
         |> update(:shopping, &Map.put(&1, item.id, item))
         |> update(:open_ids, &(&1 ++ [item.id]))
         |> stream_insert(:items, item)
         |> assign(entry: "")
         |> put_toast("#{name} hinzugefügt",
           action: "Angabe",
           on_action: JS.push("entry_detail", value: %{id: item.id})
         )}
    end
  end

  def handle_event("entry_detail", %{"id" => id}, socket) do
    case socket.assigns.shopping[id] do
      nil ->
        {:noreply, socket}

      item ->
        {:noreply, put_flash(socket, :info, "Hier öffnet die App die Angaben zu „#{item.name}“.")}
    end
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  defp check(socket, item) do
    socket
    |> update(:open_ids, &List.delete(&1, item.id))
    |> update(:recent_ids, &[item.id | &1])
    |> stream_delete(:items, item)
  end

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
      <:nav
        key={:media}
        label="Medien"
        icon="image"
        count={3}
        count_label="neu"
        navigate="/screens/posts"
      />
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
            id={"post-#{post.id}-delete"}
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
        <.action_bar sticky>
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
    <.app_shell layout={:topbar} current={:settings} width={:narrow} bar_width={:default}>
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
        <.input
          name="member[name]"
          id="new-member"
          label="Neues Mitglied"
          placeholder="Name, z. B. Alex"
          inline
        >
          <.button icon="plus" class="join-item">Hinzufügen</.button>
        </.input>

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

        <.action_bar sticky>
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
          <.button
            type="submit"
            variant={:primary}
            id="settings-save"
            saved
            phx-disable-with="Speichert …"
          >
            Speichern
          </.button>
        </.action_bar>
      </form>
    </.app_shell>
    <.flash_group flash={@flash} />
    <.confirm_dialog />
    """
  end

  def render(%{screen: "holdings"} = assigns) do
    ~H"""
    <.app_shell layout={:sidebar} current={holdings_nav_key(assigns)} width={:wide}>
      <:brand><.icon name="chart-line" class="size-5 text-sidebar-accent" />Depotblick</:brand>
      <:nav key={:overview} label="Übersicht" icon="house" navigate="/screens/holdings" />
      <:nav key={:holdings} label="Bestand" icon="layers" navigate="/screens/holdings" />
      <:nav key={:dividends} label="Dividenden" icon="coins" navigate="/screens/holdings" />
      <:nav
        key={:bookings}
        label="Buchungen"
        icon="list"
        count={2}
        count_label="im Eingang"
        navigate="/screens/holdings"
      />
      <:nav key={:performance} label="Performance" icon="trending-up" navigate="/screens/holdings" />
      <:nav
        :for={depot <- @holdings.depots}
        key={{:depot, depot.id}}
        label={depot.name}
        icon="briefcase"
        amount={Holdings.securities_value(depot)}
        section="Depots"
        rail={false}
        navigate={holdings_path(d: depot.id)}
      />
      <:nav
        :for={account <- Holdings.accounts(@holdings)}
        key={{:account, account.id}}
        label={account.name}
        icon="wallet"
        amount={account.value}
        section="Konten"
        rail={false}
        navigate={holdings_path(d: account.depot, k: account.id)}
      />
      <:nav key={:settings} label="Einstellungen" icon="settings" navigate="/screens/holdings" />
      <:nav_footer :let={place}>
        <div class="px-5 py-3">
          <.button
            id={"side-book-#{place}"}
            variant={:neutral}
            icon="plus"
            class="w-full"
            phx-click={book(place)}
          >
            Buchung
          </.button>
        </div>
      </:nav_footer>
      <:account :let={place}>
        <.button
          :if={place == :bar}
          id="bar-book"
          variant={:neutral}
          size={:sm}
          icon="plus"
          class="max-md:hidden"
          phx-click="book"
        >
          Buchung
        </.button>
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
            <.avatar initials="D" size={:sm} shape={:round} />
            <span :if={place == :sidebar} class="truncate">dana@example.com</span>
          </:trigger>
          <:header :if={place != :sidebar}>dana@example.com</:header>
          <:item navigate="/screens/holdings" icon="key-round">Passkeys</:item>
          <:item navigate="/" icon="log-out">Abmelden</:item>
        </.dropdown>
      </:account>
      <:fab><.fab id="fab-book" label="Buchung" phx-click="book" /></:fab>
      <.header>
        Bestand
        <:subtitle>{Holdings.subtitle(@holdings, @depot)}</:subtitle>
        <:actions>
          <.dropdown id="portfolio-menu" label="Depot" align={:end} trigger_class="btn-sm">
            <:trigger>
              <.icon name="briefcase" />{if @depot, do: @depot.name, else: "Gesamt"}
            </:trigger>
            <:item patch={holdings_path(a: @allocation_tab)} active={!@depot}>Gesamt</:item>
            <:item
              :for={{depot, index} <- Enum.with_index(@holdings.depots)}
              patch={holdings_path(d: depot.id, a: @allocation_tab)}
              active={@depot && @depot.id == depot.id}
              divider={index == 0}
            >
              {depot.name}
            </:item>
          </.dropdown>
        </:actions>
      </.header>
      <Holdings.holdings_table holdings={@holdings} depot={@depot} marked={@marked} />
      <p class="mt-2 hidden text-sm text-base-content/70 lg:block">
        Div.-Rendite: brutto, nächste 12 Monate auf den heutigen Wert.
      </p>
      <div class="mt-8 grid grid-cols-1 gap-x-10 gap-y-8 2xl:grid-cols-2">
        <Holdings.allocation
          allocation={@allocation}
          tab={@allocation_tab}
          tabs={allocation_tabs(assigns)}
        />
        <Holdings.costs depots={if @depot, do: [@depot], else: @holdings.depots} />
      </div>
    </.app_shell>
    <.flash_group flash={@flash} />
    """
  end

  def render(%{screen: "budget"} = assigns) do
    assigns = assign(assigns, account: Budget.account(assigns.marked))

    ~H"""
    <.app_shell
      layout={:sidebar}
      current={if @settings?, do: :access, else: {:account, @account.id}}
      width={:wide}
      amount_tone={:negative}
      current_area={:finances}
      on_sort="sort_account"
    >
      <:brand><.icon name="coins" class="size-5 text-sidebar-accent" />Haushaltsbuch</:brand>
      <:back :if={@settings?} label="Zurück zu Finanzen" navigate="/screens/budget" />
      <:area
        key={:finances}
        label="Finanzen"
        plush="piggy"
        icon="wallet"
        navigate="/screens/budget"
      />
      <:area key={:kasse} label="Kasse" plush="receipt" icon="receipt" navigate="/screens/settings" />
      <:nav
        :for={{key, label, icon, section} <- settings_nav(@settings?)}
        key={key}
        label={label}
        icon={icon}
        section={section}
        navigate="/screens/budget?m=settings"
      />
      <:nav :if={!@settings?} key={:budget} label="Budget" icon="wallet" navigate="/screens/budget" />
      <:nav
        :if={!@settings?}
        key={:accounts}
        label="Alle Konten"
        icon="landmark"
        navigate="/screens/budget"
      />
      <:nav
        :for={
          {group, account, first?} <-
            if(@settings?, do: [], else: Budget.nav_accounts(@account_groups))
        }
        key={{:account, account.id}}
        label={account.name}
        glyph={account.glyph || String.first(account.name)}
        amount={account.balance}
        count={account.open}
        count_label="offen"
        section={group.label}
        section_amount={first? && Budget.total(group)}
        sort_id={account.id}
        rail={false}
        dock={false}
        parent={:accounts}
        navigate={"/screens/budget?k=#{account.id}"}
      />
      <:nav
        :if={!@settings?}
        key={:add_account}
        label="Konto hinzufügen"
        icon="plus"
        section={List.last(@account_groups).label}
        on_click="add_account"
      />
      <:nav :if={!@settings?} key={:import} label="Import" icon="upload" navigate="/screens/budget" />
      <:nav
        :if={!@settings?}
        key={:reports}
        label="Berichte"
        navigate="/screens/budget"
        rail={false}
        dock={false}
      />
      <:nav
        :if={!@settings?}
        key={:settings}
        label="Einstellungen"
        icon="settings"
        navigate="/screens/budget?m=settings"
      />
      <:account :let={place}>
        <.dropdown
          id={"budget-account-#{place}"}
          label="Konto"
          align={if place == :bar, do: :end, else: :start}
          position={if place == :sidebar, do: :top, else: :bottom}
          variant={:ghost}
          chevron={false}
          class={place == :sidebar && "w-full"}
          trigger_class={if place == :sidebar, do: "w-full justify-start", else: "btn-square"}
        >
          <:trigger>
            <.avatar initials="M" size={:sm} shape={:round} />
            <span :if={place == :sidebar} class="truncate">mira@example.com</span>
          </:trigger>
          <:item navigate="/screens/budget" icon="settings">Einstellungen</:item>
          <:item navigate="/" icon="log-out">Abmelden</:item>
        </.dropdown>
      </:account>
      <.header>
        {@account.name}
        <:subtitle>
          Saldo <.amount value={@account.balance} tone={:negative} />
        </:subtitle>
      </.header>
      <.table id="budget-transactions" rows={@transactions} row_id={&"tx-#{&1.id}"}>
        <:col :let={tx}>
          <input
            type="checkbox"
            class="checkbox checkbox-sm"
            checked={tx.id in @selected}
            aria-label={"Auswählen: #{tx.payee}"}
            phx-click="toggle_tx"
            phx-value-id={tx.id}
          />
        </:col>
        <:col :let={tx} label="Datum">{tx.date}</:col>
        <:col :let={tx} label="Empfänger">
          {tx.payee}
          <.badge :if={!tx.approved} tone={:info} class="ms-1">offen</.badge>
        </:col>
        <:col :let={tx} label="Kategorie" show_from={:md}>
          {Budget.category_label(tx.category) || "–"}
        </:col>
        <:col :let={tx} label="Betrag" align={:end}><.amount value={tx.amount} tone /></:col>
      </.table>
      <.selection_bar
        id="tx-selection"
        count={length(@selected)}
        on_clear="clear_selection"
        label={if length(@selected) == 1, do: "1 Buchung", else: "%{count} Buchungen"}
      >
        <.popover
          id="categorise"
          title="Kategorisieren"
          position={:top}
          variant={:ghost}
          trigger_class="btn-sm"
        >
          <:trigger><.icon name="tag" />Kategorisieren</:trigger>
          <form id="categorise-form" phx-submit="categorise_selected" class="grid gap-3">
            <.combobox
              id="categorise-category"
              name="category"
              label="Kategorie"
              hide_label
              placeholder="Kategorie suchen"
              options={Budget.categories()}
              autofocus
            />
            <.button type="submit" size={:sm} variant={:primary} class="justify-self-end">
              Zuweisen
            </.button>
          </form>
        </.popover>
        <.button
          :if={Enum.any?(@transactions, &(&1.id in @selected and !&1.approved))}
          size={:sm}
          variant={:ghost}
          icon="check"
          phx-click="approve_selected"
        >
          Bestätigen
        </.button>
        <.dropdown
          id="tx-selection-more"
          label="Weitere Aktionen"
          variant={:ghost}
          align={:end}
          chevron={false}
          trigger_class="btn-sm btn-square"
        >
          <:trigger><.icon name="ellipsis-vertical" /></:trigger>
          <:item
            on_click="delete_selected"
            icon="trash-2"
            danger
            confirm={"#{length(@selected)} Buchungen löschen?"}
          >
            Löschen
          </:item>
        </.dropdown>
      </.selection_bar>
    </.app_shell>
    <.flash_group flash={@flash} />
    <.confirm_dialog />
    """
  end

  def render(%{screen: "shopping"} = assigns) do
    ~H"""
    <.app_shell layout={:topbar} current={:list} width={:narrow}>
      <:brand><.icon name="list" class="size-5 text-primary" />Schmaus</:brand>
      <:nav key={:list} label="Liste" icon="list" navigate="/screens/shopping" />
      <:nav key={:stock} label="Vorrat" icon="archive" navigate="/screens/shopping" />
      <:nav key={:recipes} label="Rezepte" icon="book-open" navigate="/screens/shopping" />
      <:nav key={:settings} label="Einstellungen" icon="settings" navigate="/screens/shopping" />
      <.header>
        Einkaufsliste
        <:subtitle>{length(@open_ids)} Dinge · Wocheneinkauf</:subtitle>
        <:actions>
          <.button size={:sm} phx-click="check_elsewhere" disabled={@open_ids == []}>
            Auf anderem Gerät abhaken
          </.button>
        </:actions>
      </.header>
      <.list id="shopping" size={:dense} phx-update="stream">
        <.list_row
          :for={{dom_id, item} <- @streams.items}
          id={dom_id}
          title={item.name}
          exit={:strike}
          on_click={JS.push("check", value: %{id: item.id})}
        >
          <:leading><.plush name={item.plush} size={:lg} /></:leading>
          <:meta :if={item.note}>{item.note}</:meta>
        </.list_row>
      </.list>
      <.empty_state :if={@open_ids == []} icon="check" title="Alles im Korb">
        Was noch fehlt, kommt unten ins Feld.
      </.empty_state>
      <.section_heading :if={@recent_ids != []} id="recent-heading" size={:sm} class="pt-6">
        Zuletzt verwendet
      </.section_heading>
      <.list :if={@recent_ids != []} id="recent" size={:dense} aria-labelledby="recent-heading">
        <.list_row
          :for={item <- Enum.map(Enum.take(@recent_ids, 5), &@shopping[&1])}
          id={"recent-#{item.id}"}
          title={item.name}
          muted
          on_click={JS.push("uncheck", value: %{id: item.id})}
        >
          <:leading><.plush name={item.plush} size={:lg} /></:leading>
          <:meta :if={item.note}>{item.note}</:meta>
        </.list_row>
      </.list>
      <.composer id="add-entry-bar">
        <form
          id="add-entry"
          phx-change="entry"
          phx-submit="add_entry"
          class="flex items-end gap-2"
        >
          <div class="min-w-0 flex-1">
            <.input
              name="entry[name]"
              id="entry-name"
              value={@entry}
              label="Was brauchst du?"
              hide_label
              placeholder="Was brauchst du?"
              autocomplete="off"
            />
          </div>
          <.button type="submit" variant={:primary} icon="plus" icon_only label="Hinzufügen" />
        </form>
      </.composer>
    </.app_shell>
    <.flash_group flash={@flash} />
    <.confirm_dialog />
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
        <div class="setzkasten-stat-grid grid grid-cols-2 gap-4">
          <.stat
            id="live-pv"
            label="PV jetzt"
            value={Dashboard.live(:pv, @live_step)}
            unit="W"
            desc="Sonnig, 17 °C"
          >
            <:figure><.plush name="sunny" size={:lg} /></:figure>
          </.stat>
          <.stat
            id="live-battery"
            label="Batterie"
            value={Dashboard.live(:battery, @live_step)}
            unit="%"
            desc="entlädt mit 120 W"
          >
            <:figure><.plush name="battery" size={:lg} /></:figure>
          </.stat>
        </div>

        <div class="setzkasten-stat-grid grid grid-cols-2 md:grid-cols-4 gap-4">
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
          <.share_bar
            id="plug-power"
            label="Leistung je Steckdose"
            value_label="650 W"
            segments={
              for {plug, color} <- Enum.with_index(Dashboard.plugs(), 1),
                  do: %{
                    label: plug.name,
                    value: plug.watt,
                    color: color,
                    value_label: "#{plug.watt} W"
                  }
            }
          />
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

  # The sidebar row of what is open: the account the page was opened for, the depot or „Bestand“.
  defp holdings_nav_key(%{marked: account}) when is_binary(account), do: {:account, account}
  defp holdings_nav_key(%{depot: %{id: depot}}), do: {:depot, depot}
  defp holdings_nav_key(_assigns), do: :holdings

  # The holdings with `params` (`d` depot, `k` marked account, `a` allocation tab); nil and the
  # default tab are left out.
  defp holdings_path(params) do
    query =
      params
      |> Keyword.update(:a, nil, &(@allocation_tabs |> Keyword.fetch!(&1) |> elem(0)))
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)

    if query == [], do: "/screens/holdings", else: "/screens/holdings?" <> URI.encode_query(query)
  end

  # A tab keeps the depot and the marked account.
  defp allocation_tabs(assigns) do
    for {tab, {_param, label}} <- @allocation_tabs do
      path = holdings_path(d: assigns.depot && assigns.depot.id, k: assigns.marked, a: tab)
      %{label: label, path: path, active: tab == assigns.allocation_tab}
    end
  end

  # The expanded sidebar is a native dialog, so it closes first.
  defp book(:dialog), do: "app-shell-sidebar" |> hide_modal() |> JS.push("book")
  defp book(_place), do: JS.push("book")

  defp settings_nav(false), do: []

  defp settings_nav(true) do
    [
      {:access, "Zugang", "key-round", "Allgemein"},
      {:look, "Aussehen", "eye", "Allgemein"},
      {:ynab, "YNAB-Import", "download", "Budget"},
      {:group, "Gruppe", "users", "Kasse"}
    ]
  end
end
