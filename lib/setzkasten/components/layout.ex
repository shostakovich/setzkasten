defmodule Setzkasten.Components.Layout do
  @moduledoc """
  Page header, section headings, cards and theme switching.

  Layout rule: the page is base-100; sections are structured by
  `<.section_heading>`, spacing and hairlines. Tables, lists and forms sit on the page without
  a card. Cards are for independent objects only: dashboard tiles, KPI groups, titled charts,
  clickable object grids, dialogs.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.ColocatedHook
  import Setzkasten.Components.Icons

  @bleed %{none: nil, phone: "max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0"}

  @doc false
  def bleed_class(bleed), do: Map.fetch!(@bleed, bleed)

  @doc """
  The page header: optional back link, title (`text-2xl`), badge, subtitle and actions.
  The back link navigates within the live session (`back`), patches (`back_patch`) or loads
  the page (`back_href`, e.g. into or out of a live session behind a re-authentication plug).
  The title block grows from a 10rem basis, so a short title keeps its action on the same row
  on phones and long ones push the actions below; it is at least as tall as a button, so the
  title sits at the same height with or without actions. A `block` segmented control in
  `:actions` takes the full width under the title on phones.

      <.header back={~p"/bestand"} back_label="Bestand">
        Vanguard FTSE All-World
        <:subtitle>{join_meta(["IE00BK5BQT80", "Langfristig"])}</:subtitle>
        <:badge><.badge tone={:success}>aktuell</.badge></:badge>
        <:actions><.button variant={:primary} icon="plus">Buchung</.button></:actions>
      </.header>
  """
  attr :back, :string, default: nil, doc: "path of the back link (navigate)"
  attr :back_patch, :string, default: nil, doc: "path of the back link (patch), instead of `back`"

  attr :back_href, :string,
    default: nil,
    doc: "URL of the back link as a full page load, instead of `back`"

  attr :back_label, :string, default: "Zurück"
  attr :level, :integer, default: 1
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :subtitle
  slot :badge
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={["flex flex-wrap items-center gap-x-4 gap-y-2 pb-6", @class]} {@rest}>
      <div :if={@back || @back_patch || @back_href} class="basis-full">
        <.link
          navigate={@back}
          patch={@back_patch}
          href={@back_href}
          class="btn btn-ghost btn-sm -ms-3"
        >
          <.icon name="chevron-left" />{@back_label}
        </.link>
      </div>
      <div class="min-w-0 grow basis-40 min-h-10 flex flex-col justify-center">
        <div class="flex flex-wrap items-center gap-2">
          <.dynamic_tag
            tag_name={"h#{@level}"}
            class="min-w-0 text-2xl font-semibold tracking-[-0.01em] wrap-anywhere"
          >
            {render_slot(@inner_block)}
          </.dynamic_tag>
          {render_slot(@badge)}
        </div>
        <p :if={@subtitle != []} class="text-sm text-base-content/70 max-w-prose wrap-anywhere">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div
        :if={@actions != []}
        class="flex flex-wrap gap-2 max-sm:has-[>.setzkasten-segmented-block]:w-full"
      >
        {render_slot(@actions)}
      </div>
    </header>
    """
  end

  @doc """
  A section heading (sentence case, `text-lg` 600) with an optional count (quiet text)
  and actions. `mt-8` above it, none when it is the first child (`first:mt-0`): at the top of a
  page, card or dialog, and as the first child of its own `<section aria-labelledby>`. Sections
  wrapped like that are stacked by their parent with a gap (`flex flex-col gap-8`, `space-y-8`
  or the grid's gap). `size={:sm}` for compact surfaces such as a popover: 14px 600 with `mt-4`,
  so it stays below the surface's own title.

      <.section_heading count={2}>Depots
        <:actions><.button size={:sm} icon="plus">Depot</.button></:actions>
      </.section_heading>
  """
  attr :count, :integer, default: nil
  attr :level, :integer, default: 2
  attr :size, :atom, default: :md, values: [:md, :sm]
  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :actions

  def section_heading(assigns) do
    ~H"""
    <div
      class={[
        "first:mt-0 flex items-center justify-between gap-2",
        if(@size == :sm, do: "mt-4 mb-2", else: "mt-8 mb-3"),
        @class
      ]}
      {@rest}
    >
      <.dynamic_tag
        tag_name={"h#{@level}"}
        id={@id}
        class={[
          "flex min-w-0 items-center gap-2",
          if(@size == :sm, do: "text-sm", else: "text-lg"),
          "font-semibold wrap-anywhere"
        ]}
      >
        {render_slot(@inner_block)}
        <span :if={@count} class="font-normal text-base-content/70 tabular-nums">{@count}</span>
      </.dynamic_tag>
      <div :if={@actions != []} class="flex flex-wrap gap-2">{render_slot(@actions)}</div>
    </div>
    """
  end

  @doc """
  A card for an independent object: `card bg-base-100 border border-base-content/10`,
  flat, no margin.

  The header holds `:leading` (a plush, icon or avatar before the title), `title`
  (`card-title`), `subtitle` and `:actions`. Content goes into
  `card-body`; a flush `<.list flush>` or `<.table flush>` goes into `:list` (the header then
  uses `px-6 pt-6 pb-2` instead of the body padding). `:footer` adds a hairline note.
  With `navigate`/`href` the title link covers the whole card. `bleed={:phone}` runs the
  card edge to edge below `sm` (page gutter `px-4`).

      <.card title="Kosten" subtitle="gewichtet 0,20 %">
        76 € pro Jahr.
        <:footer>Laufende Kosten, die im Kurs stecken.</:footer>
      </.card>
  """
  attr :title, :string, default: nil
  attr :subtitle, :string, default: nil
  attr :level, :integer, default: 2
  attr :as, :string, default: "section"
  attr :bleed, :atom, default: :none, values: [:none, :phone]
  attr :navigate, :string, default: nil
  attr :href, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block
  slot :leading
  slot :actions
  slot :list
  slot :footer

  def card(assigns) do
    assigns = assign(assigns, :link?, assigns.navigate != nil or assigns.href != nil)

    ~H"""
    <.dynamic_tag
      tag_name={@as}
      class={[
        "card bg-base-100 border border-base-content/10",
        @link? &&
          "has-[a:focus-visible]:outline-2 has-[a:focus-visible]:outline-primary has-[a:focus-visible]:outline-offset-2",
        bleed_class(@bleed),
        @class
      ]}
      {@rest}
    >
      <div :if={@list != []} class="px-6 pt-6 pb-2">
        {card_head(assigns)}
        {render_slot(@inner_block)}
      </div>
      <div :if={@list == []} class="card-body">
        {card_head(assigns)}
        {render_slot(@inner_block)}
      </div>
      {render_slot(@list)}
      <div
        :if={@footer != []}
        class="border-t border-base-content/10 px-6 py-3 text-sm text-base-content/70"
      >
        {render_slot(@footer)}
      </div>
    </.dynamic_tag>
    """
  end

  defp card_head(assigns) do
    ~H"""
    <div :if={@title || @actions != []} class="flex flex-wrap items-start justify-between gap-2">
      <div :if={@leading != []} class="flex shrink-0 items-center self-center">
        {render_slot(@leading)}
      </div>
      <div :if={@title} class={["min-w-0", @leading != [] && "flex-1"]}>
        <.dynamic_tag tag_name={"h#{@level}"} class="card-title">
          <.link
            :if={@link?}
            navigate={@navigate}
            href={@href}
            class="after:absolute after:inset-0 focus-visible:outline-none"
          >
            {@title}
          </.link>
          <span :if={!@link?}>{@title}</span>
        </.dynamic_tag>
        <p :if={@subtitle} class="text-sm text-base-content/70 max-w-prose wrap-anywhere">
          {@subtitle}
        </p>
      </div>
      <div :if={@actions != []} class="relative z-10 flex flex-wrap items-center gap-2">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  @doc """
  Light/dark/system choice as an icon-only segmented control: square `label.btn` segments
  (`sun-moon`, `sun`, `moon`) around sr-only radios, the selected one in the selection fill. The
  `labels` are the radios' accessible names and the segments' `title` tooltips. "System" removes
  `data-theme`; light and dark set `zipfel-light`/`zipfel-dark` on `<html>` right away.

  `store={:local}` keeps the choice in `localStorage["setzkasten:theme"]` (pair with
  `<.theme_script>` in the root layout so it applies before paint). `store={:server}` renders
  a form that sends `on_change` with `%{"theme" => "system" | "light" | "dark"}`; the app saves
  it and renders `data-theme` itself.

  Where the browser has View Transitions, the new theme spreads as a soft-edged circle from the
  chosen icon (700 ms); with reduced motion, or when the shown scheme does not change, it switches
  at once.

      <.theme_toggle />
      <.theme_toggle store={:server} value={@current_user.theme} on_change="set-theme" />
  """
  attr :id, :string, default: "theme-toggle"
  attr :value, :string, default: "system", values: ~w(system light dark)
  attr :store, :atom, default: :local, values: [:local, :server]
  attr :on_change, :string, default: nil
  attr :label, :string, default: "Farbschema"
  attr :labels, :map, default: %{"system" => "System", "light" => "Hell", "dark" => "Dunkel"}
  attr :class, :any, default: nil

  def theme_toggle(assigns) do
    assigns =
      assign(assigns, :options, [{"system", "sun-moon"}, {"light", "sun"}, {"dark", "moon"}])

    ~H"""
    <form
      :if={@store == :server}
      id={@id}
      phx-change={@on_change}
      phx-hook=".ThemeToggle"
      data-store="server"
      class={@class}
    >
      {theme_options(assigns)}
    </form>
    <div
      :if={@store == :local}
      id={@id}
      phx-hook=".ThemeToggle"
      phx-update="ignore"
      data-store="local"
      class={@class}
    >
      {theme_options(assigns)}
    </div>
    <script :type={ColocatedHook} name=".ThemeToggle">
      const KEY = "setzkasten:theme"
      const root = document.documentElement
      const current = () => {
        const t = root.getAttribute("data-theme") || ""
        return t.endsWith("dark") ? "dark" : t.endsWith("light") ? "light" : "system"
      }
      const apply = (v) => {
        if (v === "light" || v === "dark") root.setAttribute("data-theme", "zipfel-" + v)
        else root.removeAttribute("data-theme")
      }
      // An explicit choice puts a meta without media first; the first matching one wins.
      const syncMeta = () => {
        const v = current()
        let meta = document.getElementById("setzkasten-theme-color")
        const source = document.querySelector('meta[name="theme-color"][media*="' + v + '"]')
        if (v === "system" || !source) return meta && meta.remove()
        if (!meta) {
          meta = document.createElement("meta")
          meta.id = "setzkasten-theme-color"
          meta.name = "theme-color"
          source.parentNode.insertBefore(meta, document.querySelector('meta[name="theme-color"]'))
        }
        meta.content = source.content
      }
      const scheme = (v) =>
        v !== "system" ? v : matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
      let reveals = 0
      // The origin goes in via CSSOM, which a strict style-src allows (a style attribute it would block).
      const reveal = (from, v) => {
        if (
          !document.startViewTransition ||
          matchMedia("(prefers-reduced-motion: reduce)").matches ||
          scheme(v) === scheme(current())
        ) return apply(v)
        const r = from.getBoundingClientRect()
        const x = r.left + r.width / 2
        const y = r.top + r.height / 2
        const radius = Math.hypot(Math.max(x, innerWidth - x), Math.max(y, innerHeight - y))
        root.style.setProperty("--setzkasten-reveal-x", x + "px")
        root.style.setProperty("--setzkasten-reveal-y", y + "px")
        root.style.setProperty("--setzkasten-reveal-r", radius + "px")
        root.setAttribute("data-setzkasten-reveal", "")
        const n = ++reveals
        document.startViewTransition(() => apply(v)).finished.finally(() => {
          if (n !== reveals) return
          root.removeAttribute("data-setzkasten-reveal")
          ;["x", "y", "r"].forEach((k) => root.style.removeProperty("--setzkasten-reveal-" + k))
          if (!root.getAttribute("style")) root.removeAttribute("style")
        })
      }
      export default {
        mounted() {
          this.el.addEventListener("change", (e) => {
            if (e.target.type !== "radio") return
            const v = e.target.value
            if (this.el.dataset.store === "local") {
              try { v === "system" ? localStorage.removeItem(KEY) : localStorage.setItem(KEY, v) } catch (_) {}
            }
            reveal(e.target.closest("label") || e.target, v)
          })
          this.onStorage = (e) => { if (e.key === KEY) apply(e.newValue || "system") }
          window.addEventListener("storage", this.onStorage)
          this.observer = new MutationObserver(() => { this.sync(); syncMeta() })
          this.observer.observe(root, { attributes: true, attributeFilter: ["data-theme"] })
          if (this.el.dataset.store === "local") this.sync()
          syncMeta()
        },
        destroyed() {
          window.removeEventListener("storage", this.onStorage)
          this.observer.disconnect()
        },
        sync() {
          const v = current()
          this.el.querySelectorAll("input[type=radio]").forEach((r) => { r.checked = r.value === v })
        }
      }
    </script>
    """
  end

  defp theme_options(assigns) do
    ~H"""
    <fieldset class="join">
      <legend class="sr-only">{@label}</legend>
      <label
        :for={{value, icon} <- @options}
        class={[
          "join-item btn btn-square has-checked:setzkasten-selected",
          "has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-primary"
        ]}
        title={@labels[value]}
      >
        <input
          type="radio"
          name={if @store == :server, do: "theme", else: @id}
          value={value}
          class="sr-only"
          checked={@value == value}
        />
        <.icon name={icon} /><span class="sr-only">{@labels[value]}</span>
      </label>
    </fieldset>
    """
  end

  @doc """
  Applies a stored `<.theme_toggle store={:local}>` choice and a collapsed `app_shell` sidebar
  (`data-sidebar="collapsed"` on `<html>`) before first paint, and points the browser's
  `theme-color` at an explicit choice (a `data-theme` set by the store or the server). Put it in the root layout's `<head>` after `<.theme_meta />`; pass the CSP nonce if
  the app sends one.

      <.theme_script nonce={assigns[:csp_nonce]} />
  """
  attr :nonce, :string, default: nil

  def theme_script(assigns) do
    ~H"""
    <script nonce={@nonce}>
      (() => { const r = document.documentElement; try { const t = localStorage.getItem("setzkasten:theme"); if (t === "light" || t === "dark") r.setAttribute("data-theme", "zipfel-" + t); if (localStorage.getItem("setzkasten:sidebar") === "collapsed") r.setAttribute("data-sidebar", "collapsed") } catch (_) {} const v = (r.getAttribute("data-theme") || "").match(/(light|dark)$/); const s = v && document.querySelector('meta[name="theme-color"][media*="' + v[1] + '"]'); if (s) { const m = document.createElement("meta"); m.id = "setzkasten-theme-color"; m.name = "theme-color"; m.content = s.content; s.parentNode.insertBefore(m, document.querySelector('meta[name="theme-color"]')) } })()
    </script>
    """
  end

  @doc """
  The two `theme-color` meta tags, in the page surface colour base-100, chosen by
  `prefers-color-scheme`. `<.theme_script>` and `<.theme_toggle>` make an explicit choice win.
  """
  def theme_meta(assigns) do
    ~H"""
    <meta name="theme-color" media="(prefers-color-scheme: light)" content="#ffffff" />
    <meta name="theme-color" media="(prefers-color-scheme: dark)" content="#202328" />
    """
  end
end
