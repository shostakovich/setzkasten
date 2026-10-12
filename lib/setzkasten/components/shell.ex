defmodule Setzkasten.Components.Shell do
  @moduledoc "The navigation shell around every page."
  use Phoenix.Component
  alias Setzkasten.Format
  import Setzkasten.Components.Icons
  import Setzkasten.Components.Overlays, only: [modal: 1, show_modal: 1]

  @widths %{narrow: "max-w-3xl", default: "max-w-5xl", wide: "max-w-7xl", full: nil}

  @doc """
  Page shell with skip link, navigation and `<main id="main">`.

  `layout={:sidebar}` (e.g. a portfolio tracker): a dark sidebar from `xl` (18.5rem) with the
  account at its foot, an icon rail with tooltips from `md` to `xl` whose expand button opens
  the full sidebar as a native dialog (scrim, inert page, focus return), and below `xl` a top
  bar with brand and account, below `md` plus the dock. Ghost buttons in the sidebar take its
  colours.

  `layout={:topbar}` (e.g. a dashboard or a CMS): a navbar with a horizontal menu from
  `md`, the dock below. With `dock={false}` the menu stays in the navbar on phones and
  scrolls sideways. Without `:nav` entries the navbar has no menu, for apps whose navigation
  lives in the page (e.g. `<.tabs>` at the top of `main`).

  `:nav` entries: `key`, `label`, `navigate`/`href`, `icon` (Lucide) or `plush` (falls back
  to `icon` when the plush module has no image for it), `count`
  (+ `count_label`, e.g. "neu": the link is then named "Buchungen, 2 neu"; the rail and the
  dock show a positive count as a badge on the icon), `amount` (minor units, sidebar balances), `section` (sidebar group title, shown before the
  first entry of a section; an entry without one after a section stands apart by the same gap), `dock` (default true; the first five go into the dock) and `rail` (default
  true; `false` leaves the entry out of the icon rail from `md` to `xl`, e.g. object lists
  such as accounts, which stay in the full sidebar, its dialog and the dock). The rail keeps a
  gap between sections, without their titles. With
  `layout={:sidebar}` and more than five dock entries, the dock shows four and a `more_label`
  button that opens the full sidebar.
  The entry whose `key` equals `current` is marked with `aria-current="page"`.
  `:fab` reserves space for a floating action above the dock.

  The brand shrinks before the account does, so the bar stays one row: give long brand
  text `truncate` (and a dropdown in it a `truncate` label) so it ends in an ellipsis.

  With `layout={:sidebar}` the brand renders in the sidebar, in the expanded sidebar dialog
  and in the top bar, the `:nav_footer` in the first two, the `:account` in the top bar and
  the sidebar. The slots receive where they render (`:sidebar`, `:dialog`, `:bar`), so ids
  inside stay unique and a menu at the sidebar's foot can open upwards:
  `<:brand :let={place}><.live_component id={"switcher-\#{place}"} … /></:brand>`,
  `<:account :let={place}><.dropdown id={"account-\#{place}"} position={if place == :sidebar, do: :top, else: :bottom} …>`.

  `:bar` is for detail pages: it takes the brand's place in the top bar (breadcrumbs, then a
  status), the bar sticks to the top, and with `layout={:sidebar}` it also shows from `xl`
  (without the account, which sits in the sidebar there). `:bar_actions` holds the page's own
  actions (e.g. a `⋮` dropdown) at the end of the bar. On phones (below `sm`) a badge in the
  bar shows as its dot (the label stays for screen readers; a neutral badge shows no dot), the
  top bar leaves out the `:account` (global actions and the account menu), so the bar actions
  sit at the right edge, and a page with a bar has no dock: the bar's back link is the way
  back. Buttons in the sidebar without a colour variant take a quiet sidebar style, so a global
  action there does not compete with the page's primary. Pages render it through their layout:

      <:bar>
        <.breadcrumbs><:crumb navigate={~p"/beitraege"}>Beiträge</:crumb><:crumb>{@title}</:crumb></.breadcrumbs>
        <.badge tone={:info}>Geplant</.badge>
      </:bar>
      <:bar_actions>
        <.dropdown id="post-menu" label="Aktionen" align={:end} variant={:ghost} chevron={false}
          trigger_class="btn-square">…</.dropdown>
      </:bar_actions>

      <.app_shell layout={:topbar} current={:expenses} width={:narrow}>
        <:brand><.plush name="mascot" size={:lg} /> Teilbar</:brand>
        <:nav key={:expenses} label="Ausgaben" plush="receipt" navigate={~p"/"} />
        <:nav key={:balances} label="Salden" plush="scale" navigate={~p"/salden"} />
        <:account>…</:account>
        <:fab><.fab navigate={~p"/ausgaben/neu"} label="Ausgabe" /></:fab>
        {@inner_content}
      </.app_shell>
  """
  attr :id, :string, default: "app-shell"
  attr :layout, :atom, default: :topbar, values: [:sidebar, :topbar]
  attr :current, :any, default: nil
  attr :width, :atom, default: :default, values: [:narrow, :default, :wide, :full]
  attr :dock, :boolean, default: true
  attr :nav_label, :string, default: "Hauptnavigation"
  attr :skip_label, :string, default: "Zum Inhalt springen"
  attr :expand_label, :string, default: "Seitenleiste ausklappen"
  attr :more_label, :string, default: "Mehr"
  attr :class, :any, default: nil
  slot :inner_block, required: true
  slot :brand, required: true

  slot :nav do
    attr :key, :any, required: true
    attr :label, :string, required: true
    attr :navigate, :string
    attr :href, :string
    attr :icon, :string
    attr :plush, :string
    attr :count, :integer
    attr :count_label, :string, doc: ~s(what the count counts, for screen readers, e.g. "neu")
    attr :amount, :integer
    attr :section, :string
    attr :dock, :boolean
    attr :rail, :boolean, doc: "false leaves the entry out of the icon rail (md–xl)"
  end

  slot :nav_footer
  slot :account
  slot :bar, doc: "page context (breadcrumbs, status) in place of the brand in the top bar"
  slot :bar_actions, doc: "the page's own actions at the end of the bar (e.g. a `⋮` dropdown)"
  slot :fab

  def app_shell(assigns) do
    dock_entries = Enum.reject(assigns.nav, &(&1[:dock] == false))
    # Detail pages (a `:bar`) go back through the bar, so they keep the screen without the dock.
    dock? = assigns.dock and assigns.bar == []
    more? = dock? and assigns.layout == :sidebar and length(dock_entries) > 5
    dock_items = Enum.take(dock_entries, if(more?, do: 4, else: 5))

    assigns =
      assign(assigns,
        width_class: @widths[assigns.width],
        dock_items: if(dock?, do: dock_items, else: []),
        rail_items: rail_items(assigns.nav),
        dock_more?: more?
      )

    ~H"""
    <a
      href="#main"
      class="sr-only focus:not-sr-only focus:fixed focus:top-2 focus:start-2 btn btn-sm z-50"
    >
      {@skip_label}
    </a>
    <div
      id={@id}
      class={[
        "min-h-dvh pr-[env(safe-area-inset-right)]",
        if(@layout == :sidebar,
          do: "md:flex max-md:pl-[env(safe-area-inset-left)]",
          else: "pl-[env(safe-area-inset-left)]"
        ),
        @dock_items != [] &&
          "max-md:[--setzkasten-dock-offset:calc(4rem+env(safe-area-inset-bottom))]",
        @class
      ]}
    >
      <%= if @layout == :sidebar do %>
        <aside class={[
          "setzkasten-sidebar hidden xl:flex w-74 shrink-0 flex-col bg-sidebar text-sidebar-content",
          "sticky top-0 z-30 h-dvh overflow-y-auto",
          sidebar_ghost()
        ]}>
          {sidebar(assign(assigns, :place, :sidebar))}
        </aside>
        <aside class="hidden md:flex xl:hidden w-[calc(4.25rem+env(safe-area-inset-left))] ps-[env(safe-area-inset-left)] shrink-0 flex-col items-center gap-1 py-3 bg-sidebar text-sidebar-content sticky top-0 z-30 h-dvh">
          <.link
            :for={{item, gap?} <- @rail_items}
            navigate={item[:navigate]}
            href={item[:href]}
            class={[
              "btn btn-ghost btn-square text-sidebar-content hover:bg-white/10 border-0 tooltip tooltip-right",
              "focus-visible:outline-sidebar-accent",
              gap? && "mt-3",
              current?(item, @current) && "bg-white/10"
            ]}
            data-tip={item.label}
            aria-label={nav_name(item) || item.label}
            aria-current={current?(item, @current) && "page"}
          >
            <.icon_count count={item[:count]} class="bg-sidebar-accent text-sidebar border-0">
              {nav_icon(item)}
            </.icon_count>
          </.link>
          <button
            type="button"
            class="btn btn-ghost btn-square text-sidebar-content hover:bg-white/10 border-0 mt-auto focus-visible:outline-sidebar-accent"
            aria-label={@expand_label}
            aria-haspopup="dialog"
            phx-click={show_modal("#{@id}-sidebar")}
          >
            <.icon name="panel-left" class="size-5" />
          </button>
        </aside>
        <.modal
          id={"#{@id}-sidebar"}
          placement={:start}
          class={[
            "setzkasten-sidebar bg-sidebar text-sidebar-content w-74 max-w-[85vw] p-0",
            sidebar_ghost()
          ]}
        >
          <div class="flex h-full flex-col">{sidebar(assign(assigns, :place, :dialog))}</div>
        </.modal>
      <% end %>
      <div class={["min-w-0", @layout == :sidebar && "flex-1"]}>
        <header
          :if={@layout == :sidebar}
          class={[
            "bg-base-100 border-b border-base-content/10 pt-[env(safe-area-inset-top)]",
            if(@bar == [], do: "xl:hidden", else: "sticky top-0 z-20")
          ]}
        >
          <div class={["navbar min-h-14 gap-2 px-4 sm:px-6 lg:px-8 mx-auto", @width_class]}>
            <div :if={@bar == []} class="flex-1 flex min-w-0 items-center gap-2 font-semibold">
              {render_slot(@brand, :bar)}
            </div>
            <div :if={@bar != []} class="setzkasten-page-bar flex-1 flex min-w-0 items-center gap-3">
              {render_slot(@bar)}
            </div>
            <div :if={@bar != [] and @bar_actions != []} class="flex shrink-0 items-center gap-2">
              {render_slot(@bar_actions)}
            </div>
            <div class={["flex shrink-0 items-center gap-2", @bar != [] && "max-sm:hidden xl:hidden"]}>
              {render_slot(@account, :bar)}
            </div>
          </div>
        </header>
        <header
          :if={@layout == :topbar}
          class={[
            "bg-base-100 border-b border-base-content/10 pt-[env(safe-area-inset-top)]",
            @bar != [] && "sticky top-0 z-20"
          ]}
        >
          <div class={[
            "navbar mx-auto gap-4 px-4 sm:px-6 lg:px-8",
            @width_class,
            @dock_items == [] && "max-md:flex-wrap"
          ]}>
            <div
              :if={@bar == []}
              class="flex min-w-0 items-center gap-2 font-semibold *:min-w-0 max-md:flex-1"
            >
              {render_slot(@brand, :bar)}
            </div>
            <div :if={@bar != []} class="setzkasten-page-bar flex flex-1 min-w-0 items-center gap-3">
              {render_slot(@bar)}
            </div>
            <div :if={@bar != [] and @bar_actions != []} class="flex shrink-0 items-center gap-2">
              {render_slot(@bar_actions)}
            </div>
            <nav
              :if={@nav != []}
              id={"#{@id}-nav"}
              aria-label={@nav_label}
              phx-hook="Setzkasten.Components.Navigation.ScrollActive"
              class={[
                "setzkasten-scroller min-w-0 overflow-x-auto snap-x md:scroll-px-2",
                if(@dock_items == [],
                  do: [
                    "max-md:order-last max-sm:-mx-4 max-sm:w-[calc(100%+2rem)] max-sm:px-4",
                    "max-sm:scroll-px-6 sm:max-md:-mx-6 sm:max-md:w-[calc(100%+3rem)]",
                    "sm:max-md:px-6 sm:max-md:scroll-px-8"
                  ],
                  else: "hidden md:block"
                )
              ]}
            >
              <ul class="menu menu-horizontal flex-nowrap gap-1">
                <li :for={item <- @nav} class="snap-start">
                  <.link
                    navigate={item[:navigate]}
                    href={item[:href]}
                    class={["whitespace-nowrap", current?(item, @current) && "menu-active"]}
                    aria-label={nav_name(item)}
                    aria-current={current?(item, @current) && "page"}
                  >
                    {nav_icon(item, :sm)}{item.label}
                    <span :if={item[:count]} class="badge badge-sm tabular-nums">{item[:count]}</span>
                  </.link>
                </li>
              </ul>
            </nav>
            <div class={["ms-auto flex shrink-0 items-center gap-2", @bar != [] && "max-sm:hidden"]}>
              {render_slot(@account, :bar)}
            </div>
          </div>
        </header>
        <main
          id="main"
          class={[
            "mx-auto px-4 sm:px-6 lg:px-8 py-6",
            @width_class,
            @dock_items != [] && @fab == [] && "max-md:pb-[calc(5.5rem+env(safe-area-inset-bottom))]",
            @dock_items != [] && @fab != [] && "max-md:pb-[calc(10rem+env(safe-area-inset-bottom))]"
          ]}
        >
          {render_slot(@inner_block)}
        </main>
      </div>
      {render_slot(@fab)}
      <nav
        :if={@dock_items != []}
        aria-label={@nav_label}
        class="dock md:hidden z-30 border-t border-base-content/10"
      >
        <.link
          :for={item <- @dock_items}
          navigate={item[:navigate]}
          href={item[:href]}
          class={current?(item, @current) && "dock-active"}
          aria-label={nav_name(item)}
          aria-current={current?(item, @current) && "page"}
        >
          <.icon_count count={item[:count]} class="badge-primary">{nav_icon(item, :md)}</.icon_count>
          <span class="dock-label">{item.label}</span>
        </.link>
        <button
          :if={@dock_more?}
          type="button"
          class={more_current?(@nav, @dock_items, @current) && "dock-active"}
          aria-haspopup="dialog"
          phx-click={show_modal("#{@id}-sidebar")}
        >
          <.icon name="ellipsis" class="size-5" /><span class="dock-label">{@more_label}</span>
        </button>
      </nav>
    </div>
    """
  end

  defp sidebar(assigns) do
    ~H"""
    <%!-- One inner edge (20px) for everything in the sidebar: ghost buttons in the brand and the
         account pull their padding into the gutter, so their icon or text lines up with the nav
         icons; the account's hover pill spans like the nav pills. --%>
    <div class="flex items-center gap-2 px-5 py-4 text-lg font-semibold [&_.btn-ghost]:-ms-2 [&_.btn-ghost]:px-2">
      {render_slot(@brand, @place)}
    </div>
    <nav aria-label={@nav_label} class="flex-1">
      <ul class="menu w-full gap-0.5">
        <%= for {item, index} <- Enum.with_index(@nav) do %>
          <li
            :if={item[:section] && section_start?(@nav, index)}
            class={["menu-title text-sidebar-muted", index > 0 && "mt-4"]}
          >
            {item[:section]}
          </li>
          <li class={section_end?(@nav, index) && "mt-4"}>
            <.link
              navigate={item[:navigate]}
              href={item[:href]}
              class={[
                "text-sidebar-content hover:bg-white/10 focus-visible:outline-sidebar-accent",
                current?(item, @current) &&
                  "relative bg-white/10 before:absolute before:inset-y-1.5 before:start-0 before:w-[3px] before:rounded-full before:bg-sidebar-accent"
              ]}
              aria-label={nav_name(item)}
              aria-current={current?(item, @current) && "page"}
            >
              {nav_icon(item)}<span class="flex-1">{item.label}</span>
              <span :if={item[:count]} class="tabular-nums text-sidebar-muted">{item[:count]}</span>
              <span :if={item[:amount]} class="tabular-nums whitespace-nowrap text-sidebar-muted">
                {Format.money(item[:amount])}
              </span>
            </.link>
          </li>
        <% end %>
      </ul>
    </nav>
    <div :if={@nav_footer != []} class="border-t border-white/10">
      {render_slot(@nav_footer, @place)}
    </div>
    <div
      :if={@account != [] and @place == :sidebar}
      class="flex items-center gap-2 border-t border-white/10 px-5 py-3 [&_.btn-ghost]:-mx-3 [&_.btn-ghost]:px-3"
    >
      {render_slot(@account, :sidebar)}
    </div>
    """
  end

  # daisyUI's ghost button turns base-200 with base-content text on hover; in the dark sidebar
  # it keeps the sidebar text and gets the same hover and focus ring as the nav entries.
  defp sidebar_ghost do
    [
      "[&_.btn-ghost]:text-sidebar-content [&_.btn-ghost:hover]:bg-white/10",
      "[&_.btn-ghost]:border-0 [&_.btn-ghost:focus-visible]:outline-sidebar-accent"
    ]
  end

  defp section_start?(nav, 0), do: Enum.at(nav, 0)[:section] != nil

  defp section_start?(nav, index),
    do: Enum.at(nav, index - 1)[:section] != Enum.at(nav, index)[:section]

  # An entry without a section after a sectioned one leaves the section: the gap a section
  # title gets, without a title.
  defp section_end?(_nav, 0), do: false

  defp section_end?(nav, index),
    do: Enum.at(nav, index)[:section] == nil and Enum.at(nav, index - 1)[:section] != nil

  # The rail's entries, each with whether a new group starts with it or with an entry left out
  # since the rail entry before it (a section change in the full nav), so groups keep the
  # sidebar's gap without their titles, also when a whole section stays out of the rail.
  defp rail_items(nav) do
    nav
    |> Enum.with_index()
    |> Enum.reduce({[], false}, fn {item, index}, {items, gap?} ->
      gap? = gap? or (index > 0 and Enum.at(nav, index - 1)[:section] != item[:section])

      cond do
        item[:rail] == false -> {items, gap?}
        items == [] -> {[{item, false}], false}
        true -> {[{item, gap?} | items], false}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  defp current?(item, current), do: current != nil and item.key == current

  # With a count the link names it in words ("Buchungen, 2 neu"): the number alone sits in a
  # badge or a separate column, and the rail shows only the icon.
  defp nav_name(%{count: count} = item) when is_integer(count) do
    [
      item.label,
      Enum.join([count, item[:count_label]] |> Enum.reject(&is_nil/1), " "),
      item[:amount] && Format.money(item[:amount])
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(", ")
  end

  defp nav_name(_item), do: nil

  # A positive count as a badge on the icon (rail, dock); nothing to see at 0. The link's
  # aria-label says it in words.
  attr :count, :integer, default: nil
  attr :class, :any, required: true
  slot :inner_block, required: true

  defp icon_count(%{count: count} = assigns) when is_integer(count) and count > 0 do
    ~H"""
    <span class="indicator">
      {render_slot(@inner_block)}
      <span class={["indicator-item badge badge-sm tabular-nums", @class]} aria-hidden="true">
        {@count}
      </span>
    </span>
    """
  end

  defp icon_count(assigns), do: ~H"{render_slot(@inner_block)}"

  # The "more" button is active while the current page is one of the entries it holds.
  defp more_current?(nav, dock_items, current),
    do: Enum.any?(nav -- dock_items, &current?(&1, current))

  # A plush without an image falls back to the entry's icon.
  defp nav_icon(item, size \\ :lg) do
    cond do
      is_binary(item[:plush]) and Setzkasten.Plush.available?(item[:plush]) ->
        assigns = %{name: item[:plush], size: if(size == :lg, do: :sm, else: size)}

        ~H"""
        <.plush name={@name} size={@size} />
        """

      is_binary(item[:icon]) ->
        assigns = %{name: item[:icon], class: if(size == :sm, do: "size-4", else: "size-5")}

        ~H"""
        <.icon name={@name} class={@class} />
        """

      true ->
        nil
    end
  end
end
