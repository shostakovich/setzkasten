defmodule Setzkasten.Components.Shell do
  @moduledoc "The navigation shell around every page."
  use Phoenix.Component
  alias Setzkasten.Format
  import Setzkasten.Components.Icons
  import Setzkasten.Components.Overlays, only: [modal: 1, show_modal: 1]

  @widths %{narrow: "max-w-3xl", default: "max-w-5xl", wide: "max-w-7xl", full: nil}

  @doc """
  Page shell with skip link, navigation and `<main id="main">`.

  `layout={:sidebar}` (e.g. a portfolio tracker): a dark sidebar from `xl` (18.5rem), an icon rail
  with tooltips from `md` to `xl` whose expand button opens the full sidebar as a native
  dialog (scrim, inert page, focus return), and below `md` a top bar with brand and account
  plus the dock.

  `layout={:topbar}` (e.g. a dashboard or a CMS): a navbar with a horizontal menu from
  `md`, the dock below. With `dock={false}` the menu stays in the navbar on phones and
  scrolls sideways. Without `:nav` entries the navbar has no menu, for apps whose navigation
  lives in the page (e.g. `<.tabs>` at the top of `main`).

  `:nav` entries: `key`, `label`, `navigate`/`href`, `icon` (Lucide) or `plush`, `count`,
  `amount` (minor units, sidebar balances), `section` (sidebar group title, shown before the
  first entry of a section) and `dock` (default true; the first five go into the dock).
  The entry whose `key` equals `current` is marked with `aria-current="page"`.
  `:fab` reserves space for a floating action above the dock.

  The brand shrinks before the account does, so the bar stays one row: give long brand
  text `truncate` (and a dropdown in it a `truncate` label) so it ends in an ellipsis.

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
    attr :amount, :integer
    attr :section, :string
    attr :dock, :boolean
  end

  slot :nav_footer
  slot :account
  slot :fab

  def app_shell(assigns) do
    dock_items = assigns.nav |> Enum.reject(&(&1[:dock] == false)) |> Enum.take(5)

    assigns =
      assign(assigns,
        width_class: @widths[assigns.width],
        dock_items: if(assigns.dock, do: dock_items, else: [])
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
        "min-h-dvh",
        @layout == :sidebar && "md:flex",
        @dock_items != [] &&
          "max-md:[--setzkasten-dock-offset:calc(4rem+env(safe-area-inset-bottom))]",
        @class
      ]}
    >
      <%= if @layout == :sidebar do %>
        <aside class="hidden xl:flex w-74 shrink-0 flex-col bg-sidebar text-sidebar-content sticky top-0 h-dvh overflow-y-auto">
          {sidebar(assigns)}
        </aside>
        <aside class="hidden md:flex xl:hidden w-17 shrink-0 flex-col items-center gap-1 py-3 bg-sidebar text-sidebar-content sticky top-0 h-dvh">
          <.link
            :for={item <- @nav}
            navigate={item[:navigate]}
            href={item[:href]}
            class={[
              "btn btn-ghost btn-square text-sidebar-content hover:bg-white/10 border-0 tooltip tooltip-right",
              "focus-visible:outline-sidebar-accent",
              current?(item, @current) && "bg-white/10"
            ]}
            data-tip={item.label}
            aria-label={item.label}
            aria-current={current?(item, @current) && "page"}
          >
            {nav_icon(item)}
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
          class="bg-sidebar text-sidebar-content w-74 max-w-[85vw] p-0"
        >
          <div class="flex h-full flex-col">{sidebar(assigns)}</div>
        </.modal>
      <% end %>
      <div class={["min-w-0", @layout == :sidebar && "flex-1"]}>
        <header
          :if={@layout == :sidebar}
          class={[
            "navbar min-h-14 gap-2 px-4 sm:px-6 lg:px-8 mx-auto",
            "max-md:bg-base-100 max-md:border-b max-md:border-base-content/10",
            @account == [] && "md:hidden",
            @width_class
          ]}
        >
          <div class="flex-1 flex min-w-0 items-center gap-2 font-semibold">
            <span class="contents md:hidden">{render_slot(@brand)}</span>
          </div>
          {render_slot(@account)}
        </header>
        <header :if={@layout == :topbar} class="bg-base-100 border-b border-base-content/10">
          <div class={[
            "navbar mx-auto gap-4 px-4 sm:px-6 lg:px-8",
            @width_class,
            @dock_items == [] && "max-md:flex-wrap"
          ]}>
            <div class="flex min-w-0 items-center gap-2 font-semibold *:min-w-0 max-md:flex-1">
              {render_slot(@brand)}
            </div>
            <nav
              :if={@nav != []}
              aria-label={@nav_label}
              class={[
                "min-w-0 overflow-x-auto",
                if(@dock_items == [], do: "max-md:order-last max-md:w-full", else: "hidden md:block")
              ]}
            >
              <ul class="menu menu-horizontal flex-nowrap gap-1">
                <li :for={item <- @nav}>
                  <.link
                    navigate={item[:navigate]}
                    href={item[:href]}
                    class={["whitespace-nowrap", current?(item, @current) && "menu-active"]}
                    aria-current={current?(item, @current) && "page"}
                  >
                    {nav_icon(item, :sm)}{item.label}
                    <span :if={item[:count]} class="badge badge-sm tabular-nums">{item[:count]}</span>
                  </.link>
                </li>
              </ul>
            </nav>
            <div class="ms-auto flex shrink-0 items-center gap-2">{render_slot(@account)}</div>
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
          aria-current={current?(item, @current) && "page"}
        >
          {nav_icon(item, :md)}<span class="dock-label">{item.label}</span>
        </.link>
      </nav>
    </div>
    """
  end

  defp sidebar(assigns) do
    ~H"""
    <div class="flex items-center gap-2 px-5 py-4 text-lg font-semibold">{render_slot(@brand)}</div>
    <nav aria-label={@nav_label} class="flex-1">
      <ul class="menu w-full gap-0.5">
        <%= for {item, index} <- Enum.with_index(@nav) do %>
          <li
            :if={item[:section] && section_start?(@nav, index)}
            class="menu-title text-sidebar-muted"
          >
            {item[:section]}
          </li>
          <li>
            <.link
              navigate={item[:navigate]}
              href={item[:href]}
              class={[
                "text-sidebar-content hover:bg-white/10 focus-visible:outline-sidebar-accent",
                current?(item, @current) &&
                  "relative bg-white/10 before:absolute before:inset-y-1.5 before:start-0 before:w-[3px] before:rounded-full before:bg-sidebar-accent"
              ]}
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
    <div :if={@nav_footer != []} class="border-t border-white/10">{render_slot(@nav_footer)}</div>
    """
  end

  defp section_start?(nav, 0), do: Enum.at(nav, 0)[:section] != nil

  defp section_start?(nav, index),
    do: Enum.at(nav, index - 1)[:section] != Enum.at(nav, index)[:section]

  defp current?(item, current), do: current != nil and item.key == current

  defp nav_icon(item, size \\ :lg)

  defp nav_icon(%{plush: name} = _item, size) when is_binary(name) do
    assigns = %{name: name, size: if(size == :lg, do: :sm, else: size)}

    ~H"""
    <.plush name={@name} size={@size} />
    """
  end

  defp nav_icon(%{icon: name}, size) when is_binary(name) do
    assigns = %{name: name, class: if(size == :sm, do: "size-4", else: "size-5")}

    ~H"""
    <.icon name={@name} class={@class} />
    """
  end

  defp nav_icon(_item, _size), do: nil
end
