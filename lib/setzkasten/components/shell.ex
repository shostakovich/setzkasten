defmodule Setzkasten.Components.Shell do
  @moduledoc "The navigation shell around every page."
  use Phoenix.Component
  alias Phoenix.LiveView.ColocatedHook
  alias Phoenix.LiveView.JS
  alias Setzkasten.Format
  import Setzkasten.Components.Icons
  import Setzkasten.Click, only: [click_js: 2]
  import Setzkasten.Components.Overlays, only: [modal: 1, show_modal: 1, hide_modal: 1]

  # A width's cap as a class and as the variable that bars fixed to the column read (gutter/1 alike).
  @widths %{
    narrow: {"max-w-3xl", "[--setzkasten-column:var(--container-3xl)]"},
    default: {"max-w-5xl", "[--setzkasten-column:var(--container-5xl)]"},
    wide: {"max-w-7xl", "[--setzkasten-column:var(--container-7xl)]"},
    full: {nil, nil}
  }

  @doc """
  Page shell with skip link, navigation and `<main id="main">`.

  `layout={:sidebar}` (e.g. a portfolio tracker): a dark sidebar from `lg` (16rem) with the
  account and a collapse button at its foot, an icon rail with tooltips from `md` to `lg`, and
  below `lg` a top bar with brand and account, below `md` plus the dock. Without a dock
  (`dock={false}`, or every entry left out of it) the top bar starts with an `expand_label`
  button below `md` that opens the sidebar as a dialog. Collapsed, the sidebar
  gives way to the rail and the top bar also from `lg`; the choice is kept per device
  (`localStorage`, applied before paint by `<.theme_script>` as `data-sidebar="collapsed"` on
  `<html>`). The rail has one expand button at its foot: from `lg` it brings the sidebar back
  in place, below it opens the sidebar as a native dialog (scrim, inert page, focus return),
  which its collapse button, Escape or the scrim close. Ghost buttons in the sidebar take its
  colours.

  `width` (`:narrow`, `:default`, `:wide`, `:full`) caps the page column. With
  `layout={:sidebar}` the column starts at the content edge (sidebar or rail plus the page
  padding), so every page starts at the same x whatever its width; the top bar row takes the
  same width. With `layout={:topbar}` the column and the navbar row are centred together.
  `:full` keeps a 16px side gutter at every width, the others widen it to 24px from `sm` and
  32px from `lg`.
  The shell exports the column as `--setzkasten-column`, `--setzkasten-gutter` and
  `--setzkasten-column-align` for bars fixed to it, such as `<.composer>`.
  `bar_width` gives the top bar row a width of its own (default: `width`), so an app whose
  pages differ in width can keep one header: `<.app_shell bar_width={:wide} width={@width}>`.

  `layout={:topbar}` (e.g. a dashboard or a CMS): a navbar with a horizontal menu from
  `md`, the dock below. With `dock={false}` the menu stays in the navbar on phones and
  scrolls sideways. Without `:nav` entries the navbar has no menu, for apps whose navigation
  lives in the page (e.g. `<.tabs>` at the top of `main`).

  `:nav` entries: `key`, `label`, `navigate`/`href`, `icon` (Lucide) or `plush` (falls back
  to `icon` when the plush module has no image for it) or `glyph` (a short text such as an
  emoji or an initial in the icon's place), `count`
  (+ `count_label`, e.g. "neu": the link is then named "Buchungen, 2 neu"; the rail and the
  dock show a positive count as a badge on the icon), `amount` (minor units, sidebar balances), `section` (sidebar group title, shown before the
  first entry of a section; an entry without one after a section stands apart by the same gap),
  `section_amount` (on a section's first entry: the section's total next to its title), `dock` (default true; up to six go into the dock) and `rail` (default
  true; `false` leaves the entry out of the icon rail, e.g. object lists
  such as accounts, which stay in the full sidebar, its dialog and the dock). The rail keeps a
  gap between sections, without their titles. With more than six dock entries, or entries
  left out of the dock, the dock shows at most five and a `more_label` button: with
  `layout={:sidebar}` it opens the full sidebar, with `layout={:topbar}` a sheet (`<.modal>`)
  listing the entries the dock leaves out. With `layout={:sidebar}` a `:nav_footer` brings the
  button too, since the sidebar is the footer's only place on phones.
  The entry whose `key` equals `current` is marked with `aria-current="page"`. An entry left
  out of the dock or the rail (an account under "Konten") names the entry that stands in for
  it there with `parent` (that entry's key): while it is current, dock and rail mark the parent
  (`aria-current="true"`) instead of "more" or nothing.

  In the sidebar, its dialog and the top-bar sheet all labels share one text column: once any
  entry has an icon, plush or glyph, an entry without one keeps its place empty. Without any,
  labels start at the section titles' edge.

  Long labels end in an ellipsis (the full label as `title`, the accessible name unchanged).
  With both `count` and `amount`, a positive count is a small badge before the amount, so it
  does not read as part of the number. `amount_tone={:negative}` tones entry and section
  amounts as `<.amount tone={:negative}>` does: negative in `sidebar-negative`, zero muted,
  positive in the sidebar's full text colour.

  An entry with `on_click` (an event name with `phx-target`, or a `%JS{}`) is a button, a
  quiet action in its place, e.g. "Konto hinzufügen" as the last entry of the accounts'
  section. It stays out of the rail and the dock unless `rail` or `dock` is `true`. In the
  sidebar dialog and the top-bar sheet it closes them before its action runs.

  An entry with `sort_id` can be dragged within its `section` in the sidebar (from `lg`) with a mouse,
  trackpad or pen; touch does not drag, and the rail, dock and dialog keep their order. On a drop at a
  new place the shell pushes `on_sort` with `%{"section" => section, "id" => sort_id, "index" => index}`,
  `index` counting from 0 among the section's entries with a `sort_id`; the server renders the new order.
  Entries of other sections and without `sort_id` are no drop target, a drop outside the section puts
  the entry back, and a click without movement still follows the entry.

  An entry renders once per place, so its `id` becomes `<id>-sidebar`, `<id>-dialog` (the
  sidebar as a dialog), `<id>-rail`, `<id>-menu` (the top-bar menu), `<id>-more` (the top-bar
  sheet behind the dock's `more_label`) and `<id>-dock`.
  `:fab` reserves space for a floating action above the dock.

  The brand shrinks before the account does, so the bar stays one row: give long brand
  text `truncate` (and a dropdown in it a `truncate` label) so it ends in an ellipsis.

  With `layout={:sidebar}` the brand renders in the sidebar, in the expanded sidebar dialog
  and in the top bar, the `:nav_footer` in the first two, the `:account` in the top bar and
  the sidebar. The slots receive where they render (`:sidebar`, `:dialog`, `:bar`), so ids
  inside stay unique and a menu at the sidebar's foot can open upwards:
  `<:brand :let={place}><.live_component id={"switcher-\#{place}"} … /></:brand>`,
  `<:account :let={place}><.dropdown id={"account-\#{place}"} position={if place == :sidebar, do: :top, else: :bottom} …>`.

  `:area` entries (`layout={:sidebar}`): with more than one, a segmented switch between the
  app's areas tops the sidebar and its dialog (icon and label) and the rail (icons, the label as
  tooltip; an area without `icon` or `plush` shows its initial). `current_area` is the current
  entry's key (`aria-current="page"`), `area_label` the switch's accessible name. Entries take
  `key`, `label`, `icon` (Lucide) or `plush` (20px, falls back to `icon` when the plush module has
  no image for it), `navigate`/`href` and `id` (suffixed `-sidebar`, `-dialog`, `-rail`). The dock
  leaves it out: on phones the app keeps its own area menu, e.g. in the brand.

  `:back` puts the sidebar in a mode of its own, such as the settings: a way back (`label`,
  `navigate`/`href`, `id` suffixed per place) in place of the area switch, at the top of the
  sidebar, its dialog and the rail, then the page's `:nav` entries with their sections. The dock
  leaves out such a page, so on phones the top bar's `expand_label` button opens the sidebar.

      <.app_shell layout={:sidebar} current={:access}>
        <:back label="Zurück zu Finanzen" navigate={~p"/budget"} />
        <:nav key={:access} label="Zugang" icon="key-round" section="Allgemein" navigate={…} />
        …
      </.app_shell>

  `:bar` is for detail pages: it takes the brand's place in the top bar (breadcrumbs, then a
  status), the bar sticks to the top, and with `layout={:sidebar}` it also shows from `lg`
  (without the account while the expanded sidebar holds it). `:bar_actions` holds the page's own
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

  attr :bar_width, :atom,
    default: nil,
    values: [nil, :narrow, :default, :wide, :full],
    doc: "the top bar row's width; `nil` follows `width`"

  attr :dock, :boolean, default: true
  attr :nav_label, :string, default: "Hauptnavigation"
  attr :skip_label, :string, default: "Zum Inhalt springen"
  attr :expand_label, :string, default: "Seitenleiste ausklappen"
  attr :collapse_label, :string, default: "Seitenleiste einklappen"
  attr :more_label, :string, default: "Mehr"

  attr :amount_tone, :any,
    default: false,
    values: [false, :negative],
    doc: "`:negative`: nav and section amounts toned as `<.amount tone={:negative}>`"

  attr :on_sort, :string,
    default: nil,
    doc:
      ~s(event pushed when a `:nav` entry with `sort_id` is dropped at a new place in its section)

  attr :current_area, :any, default: nil, doc: "the current `:area` entry's key"
  attr :area_label, :string, default: "Bereich"
  attr :class, :any, default: nil
  slot :inner_block, required: true
  slot :brand, required: true

  slot :area, doc: "with more than one: the sidebar's area switch" do
    attr :key, :any, required: true
    attr :id, :string, doc: "renders as `<id>-sidebar`, `-dialog`, `-rail`"
    attr :label, :string, required: true
    attr :icon, :string
    attr :plush, :string, doc: "falls back to `icon` without an image"
    attr :navigate, :string
    attr :href, :string
  end

  slot :back, doc: "a sidebar mode with the page's own navigation: the way back at its top" do
    attr :label, :string, required: true
    attr :id, :string, doc: "renders as `<id>-sidebar`, `-dialog`, `-rail`"
    attr :navigate, :string
    attr :href, :string
  end

  slot :nav do
    attr :key, :any, required: true

    attr :id, :string,
      doc:
        "the entry renders once per place, as `<id>-sidebar`, `-dialog`, `-rail`, `-menu`, `-more`, `-dock`"

    attr :label, :string, required: true
    attr :navigate, :string
    attr :href, :string
    attr :icon, :string
    attr :plush, :string
    attr :glyph, :string, doc: "an emoji or initial in the icon's place"
    attr :count, :integer
    attr :count_label, :string, doc: ~s(what the count counts, for screen readers, e.g. "neu")
    attr :amount, :integer
    attr :section, :string
    attr :section_amount, :integer, doc: "on the section's first entry: its total"
    attr :sort_id, :string, doc: "makes the entry draggable within its section in the sidebar"
    attr :on_click, :any, doc: "makes the entry a button: an event name or `%JS{}`"
    attr :"phx-target", :any, doc: "for an event name in `on_click`, e.g. `@myself`"
    attr :dock, :boolean
    attr :rail, :boolean, doc: "false leaves the entry out of the icon rail"

    attr :parent, :any,
      doc: "key of the entry that dock and rail mark while this one is current but left out there"
  end

  slot :nav_footer
  slot :account
  slot :bar, doc: "page context (breadcrumbs, status) in place of the brand in the top bar"
  slot :bar_actions, doc: "the page's own actions at the end of the bar (e.g. a `⋮` dropdown)"
  slot :fab

  def app_shell(assigns) do
    assigns = assign_sidebar_mode(assigns)
    {dock_items, more?, more_items} = dock_split(assigns)

    rail_items = rail_items(assigns.nav)
    dock_current = place_current(assigns.nav, dock_items, assigns.current)

    assigns =
      assign(assigns,
        width_class: width_class(assigns.width),
        bar_width_class: width_class(assigns.bar_width || assigns.width),
        gutter_class: gutter_class(assigns.width),
        bar_gutter_class: gutter_class(assigns.bar_width || assigns.width),
        bar_full?: (assigns.bar_width || assigns.width) == :full,
        dock_items: dock_items,
        rail_items: rail_items,
        media?: Enum.any?(assigns.nav, &media?/1),
        rail_current:
          place_current(assigns.nav, Enum.map(rail_items, &elem(&1, 0)), assigns.current),
        dock_current: dock_current,
        # "Mehr" is marked only while the current entry has no stand-in in the dock.
        more_current?:
          dock_current == nil and Enum.any?(assigns.nav, &current?(&1, assigns.current)),
        dock_more?: more?,
        more_items: more_items,
        bar_expand?:
          assigns.layout == :sidebar and dock_items == [] and assigns.bar == [] and
            (assigns.nav != [] or assigns.back != nil)
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
          do: [
            "md:flex max-md:pl-[env(safe-area-inset-left)]",
            "md:[--setzkasten-shell-start:calc(4.25rem+env(safe-area-inset-left))]",
            "lg:[--setzkasten-shell-start:16rem]",
            "lg:sidebar-collapsed:[--setzkasten-shell-start:calc(4.25rem+env(safe-area-inset-left))]"
          ],
          else: "pl-[env(safe-area-inset-left)]"
        ),
        column_vars(@width, @layout),
        @class
      ]}
    >
      <%= if @layout == :sidebar do %>
        <aside
          id={"#{@id}-sidebar-full"}
          phx-hook=".Sidebar"
          class={[
            "setzkasten-sidebar hidden lg:flex lg:sidebar-collapsed:hidden w-64 shrink-0 flex-col",
            "bg-sidebar text-sidebar-content sticky top-0 z-30 h-dvh overflow-y-auto",
            sidebar_ghost()
          ]}
        >
          {sidebar(assign(assigns, :place, :sidebar))}
        </aside>
        <aside
          id={"#{@id}-rail"}
          phx-hook=".Sidebar"
          class={[
            "setzkasten-sidebar hidden md:flex lg:hidden lg:sidebar-collapsed:flex",
            "w-[calc(4.25rem+env(safe-area-inset-left))]",
            "ps-[env(safe-area-inset-left)] shrink-0 flex-col items-center gap-1 py-3",
            "bg-sidebar text-sidebar-content sticky top-0 z-30 h-dvh"
          ]}
        >
          <.link
            :if={@back}
            id={@back[:id] && "#{@back[:id]}-rail"}
            navigate={@back[:navigate]}
            href={@back[:href]}
            class={[rail_button(), "tooltip tooltip-right mb-3"]}
            data-tip={@back.label}
            aria-label={@back.label}
          >
            <.icon name="chevron-left" class="size-5" />
          </.link>
          <nav :if={@areas?} aria-label={@area_label} class="join join-vertical mb-3">
            <.area_target
              :for={area <- @area}
              area={area}
              place={:rail}
              current={@current_area}
              class="btn-square tooltip tooltip-right"
              data-tip={area.label}
              aria-label={area.label}
            >
              <.area_icon area={area} />
            </.area_target>
          </nav>
          <.nav_target
            :for={{item, gap?} <- @rail_items}
            item={item}
            place={:rail}
            class={[
              rail_button(),
              "tooltip tooltip-right",
              gap? && "mt-3",
              mark(@rail_current, item) && "bg-white/10"
            ]}
            data-tip={item.label}
            aria-label={nav_name(item) || item.label}
            aria-current={mark(@rail_current, item)}
          >
            <.icon_count count={item[:count]} class="bg-sidebar-accent text-sidebar border-0">
              {nav_icon(item)}
            </.icon_count>
          </.nav_target>
          <button
            type="button"
            class={[rail_button(), "mt-auto"]}
            aria-label={@expand_label}
            aria-expanded="false"
            aria-controls={"#{@id}-sidebar-full"}
            data-sidebar-toggle="expand"
            data-sidebar-dialog={"#{@id}-sidebar"}
            phx-mounted={JS.ignore_attributes(["aria-controls", "aria-haspopup"])}
          >
            <.icon name="panel-left-open" class="size-5" />
          </button>
        </aside>
        <.modal
          id={"#{@id}-sidebar"}
          placement={:start}
          close_button={false}
          class={[
            "setzkasten-sidebar bg-sidebar text-sidebar-content w-64 max-w-[85vw] p-0",
            sidebar_ghost()
          ]}
        >
          <div class="flex h-full flex-col">{sidebar(assign(assigns, :place, :dialog))}</div>
        </.modal>
        <script :type={ColocatedHook} name=".Sidebar">
          const KEY = "setzkasten:sidebar"
          const root = document.documentElement
          const wide = window.matchMedia("(min-width: 64rem)")
          const apply = (collapsed) => {
            if (collapsed) root.setAttribute("data-sidebar", "collapsed")
            else root.removeAttribute("data-sidebar")
          }
          export default {
            mounted() {
              try { if (localStorage.getItem(KEY) === "collapsed") apply(true) } catch (_) {}
              this.expand = this.el.querySelector("[data-sidebar-toggle=expand]")
              this.sync = () => {
                if (!this.expand) return
                const dialog = this.expand.dataset.sidebarDialog
                if (wide.matches) this.expand.removeAttribute("aria-haspopup")
                else this.expand.setAttribute("aria-haspopup", "dialog")
                this.expand.setAttribute("aria-controls", wide.matches ? `${dialog}-full` : dialog)
              }
              this.sync()
              wide.addEventListener("change", this.sync)
              this.el.addEventListener("click", (e) => {
                const button = e.target.closest("[data-sidebar-toggle]")
                if (!button) return
                const collapse = button.dataset.sidebarToggle === "collapse"
                if (!collapse && !wide.matches) {
                  const dialog = document.getElementById(button.dataset.sidebarDialog)
                  if (dialog) dialog.dispatchEvent(new CustomEvent("setzkasten:show-modal"))
                  return
                }
                apply(collapse)
                try { collapse ? localStorage.setItem(KEY, "collapsed") : localStorage.removeItem(KEY) } catch (_) {}
                const next = this.el.parentElement.querySelector(`[data-sidebar-toggle="${collapse ? "expand" : "collapse"}"]`)
                if (next) next.focus()
              })
              this.onStorage = (e) => { if (e.key === KEY) apply(e.newValue === "collapsed") }
              window.addEventListener("storage", this.onStorage)
            },
            destroyed() {
              window.removeEventListener("storage", this.onStorage)
              wide.removeEventListener("change", this.sync)
            }
          }
        </script>
        <script :type={ColocatedHook} name=".Sortable">
          const THRESHOLD = 4
          const EVENTS = ["pointermove", "pointerup", "pointercancel", "keydown", "scroll"]
          const MARKS = ["setzkasten-sort-lifted", "setzkasten-sort-before", "setzkasten-sort-after"]
          // The dragged row's new index among its section's rows for its centre y; null outside the section.
          const dropIndex = (boxes, from, y) => {
            const half = boxes[from].height / 2
            if (y < boxes[0].top - half || y > boxes[boxes.length - 1].bottom + half) return null
            return boxes.filter((box, i) => i !== from && box.top + box.height / 2 < y).length
          }
          export default {
            mounted() {
              this.el.addEventListener("pointerdown", (e) => this.press(e))
              this.el.addEventListener("dragstart", (e) => {
                if (e.target.closest("[data-sort-id]")) e.preventDefault()
              })
            },
            // A patch drops the marks and the offset; the drag state is the hook's, so draw it again.
            updated() {
              if (this.drag && this.drag.lifted && !this.drag.pushed) this.render()
            },
            destroyed() {
              this.release()
            },
            press(e) {
              const row = e.target.closest("[data-sort-id]")
              if (this.drag || !row || e.button !== 0 || e.pointerType === "touch") return
              this.drag = {
                pointer: e.pointerId,
                id: row.dataset.sortId,
                section: row.getAttribute("data-sort-section"),
                startX: e.clientX,
                startY: e.clientY,
                x: e.clientX,
                y: e.clientY,
                grab: e.clientY - row.getBoundingClientRect().top,
                lifted: false,
                index: null
              }
              this.listener = (ev) => this.on(ev)
              for (const type of EVENTS) window.addEventListener(type, this.listener, true)
            },
            on(e) {
              const d = this.drag
              if (e.type === "keydown") {
                if (e.key !== "Escape") return
                if (d.lifted) e.preventDefault()
                return this.release()
              }
              if (e.type === "scroll") return d.lifted && this.render()
              if (e.pointerId !== d.pointer) return
              if (e.type === "pointercancel") return this.release()
              if (e.type === "pointerup") return this.drop()
              d.x = e.clientX
              d.y = e.clientY
              if (!d.lifted && Math.hypot(d.x - d.startX, d.y - d.startY) < THRESHOLD) return
              if (!d.lifted) this.lift()
              this.render()
            },
            lift() {
              this.drag.lifted = true
              document.documentElement.classList.add("setzkasten-sorting")
              // Without ids the patch reuses the links in place, so the press's focus would land on another entry.
              if (this.el.contains(document.activeElement)) document.activeElement.blur()
              // The click that ends a drag would follow the entry's link.
              this.swallow = (e) => {
                e.preventDefault()
                e.stopPropagation()
              }
              window.addEventListener("click", this.swallow, true)
            },
            rows() {
              return [...this.el.querySelectorAll("[data-sort-id]")].filter(
                (row) => row.getAttribute("data-sort-section") === this.drag.section
              )
            },
            render() {
              const d = this.drag
              const rows = this.rows()
              const from = rows.findIndex((row) => row.dataset.sortId === d.id)
              if (from < 0) return this.release()
              const row = rows[from]
              for (const other of this.el.querySelectorAll("[data-sort-id]")) {
                other.classList.remove(...MARKS)
                other.style.removeProperty("translate")
              }
              const boxes = rows.map((r) => r.getBoundingClientRect())
              const nav = this.el.getBoundingClientRect()
              const inside = d.x >= nav.left && d.x <= nav.right
              d.index = inside ? dropIndex(boxes, from, d.y - d.grab + boxes[from].height / 2) : null
              row.style.translate = `0 ${d.y - d.grab - boxes[from].top}px`
              row.classList.add("setzkasten-sort-lifted")
              if (d.index === null || d.index === from) return
              const others = rows.filter((r) => r !== row)
              if (d.index < others.length) others[d.index].classList.add("setzkasten-sort-before")
              else others[others.length - 1].classList.add("setzkasten-sort-after")
            },
            // The row stays where it was dropped until the reply, which comes after the patch with the new order.
            drop() {
              const d = this.drag
              this.stopListening()
              const from = this.rows().findIndex((row) => row.dataset.sortId === d.id)
              if (!d.lifted || d.index === null || d.index === from) return this.release()
              d.pushed = true
              const done = () => this.drag === d && this.release()
              this.timer = setTimeout(done, 5000)
              this.pushEvent(this.el.dataset.sortEvent, {section: d.section, id: d.id, index: d.index}, done)
            },
            stopListening() {
              if (this.listener) for (const type of EVENTS) window.removeEventListener(type, this.listener, true)
              this.listener = null
              const swallow = this.swallow
              this.swallow = null
              if (swallow) setTimeout(() => window.removeEventListener("click", swallow, true))
            },
            release() {
              this.stopListening()
              clearTimeout(this.timer)
              document.documentElement.classList.remove("setzkasten-sorting")
              for (const row of this.el.querySelectorAll("[data-sort-id]")) {
                row.classList.remove(...MARKS)
                row.style.removeProperty("translate")
              }
              this.drag = null
            }
          }
        </script>
      <% end %>
      <div class={["min-w-0", @layout == :sidebar && "flex-1"]}>
        <header
          :if={@layout == :sidebar}
          class={[
            "bg-base-100 border-b border-base-content/10 pt-[env(safe-area-inset-top)]",
            if(@bar == [], do: "lg:hidden lg:sidebar-collapsed:block", else: "sticky top-0 z-20")
          ]}
        >
          <div class={["navbar min-h-14 gap-2", @bar_gutter_class, @bar_width_class]}>
            <button
              :if={@bar_expand?}
              type="button"
              class="btn btn-ghost btn-square -ms-2.5 md:hidden"
              aria-label={@expand_label}
              aria-haspopup="dialog"
              phx-click={show_modal("#{@id}-sidebar")}
            >
              <.icon name="panel-left-open" class="size-5" />
            </button>
            <div :if={@bar == []} class="flex-1 flex min-w-0 items-center gap-2 font-semibold">
              {render_slot(@brand, :bar)}
            </div>
            <div :if={@bar != []} class="setzkasten-page-bar flex-1 flex min-w-0 items-center gap-3">
              {render_slot(@bar)}
            </div>
            <div :if={@bar != [] and @bar_actions != []} class="flex shrink-0 items-center gap-2">
              {render_slot(@bar_actions)}
            </div>
            <div class={[
              "flex shrink-0 items-center gap-2",
              @bar != [] && "max-sm:hidden lg:hidden lg:sidebar-collapsed:flex"
            ]}>
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
            "navbar mx-auto gap-4",
            @bar_gutter_class,
            @bar_width_class,
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
                cond do
                  @dock_items != [] ->
                    "hidden md:block"

                  @bar_full? ->
                    "max-md:order-last max-md:-mx-4 max-md:w-[calc(100%+2rem)] max-md:px-4 max-md:scroll-px-6"

                  true ->
                    [
                      "max-md:order-last max-sm:-mx-4 max-sm:w-[calc(100%+2rem)] max-sm:px-4",
                      "max-sm:scroll-px-6 sm:max-md:-mx-6 sm:max-md:w-[calc(100%+3rem)]",
                      "sm:max-md:px-6 sm:max-md:scroll-px-8"
                    ]
                end
              ]}
            >
              <ul class="menu menu-horizontal flex-nowrap gap-1">
                <li :for={item <- @nav} class="snap-start">
                  <.nav_target
                    item={item}
                    place={:menu}
                    class={["whitespace-nowrap", current?(item, @current) && "menu-active"]}
                    aria-label={nav_name(item)}
                    aria-current={current?(item, @current) && "page"}
                  >
                    {nav_icon(item, :menu)}{item.label}
                    <span :if={item[:count]} class="badge badge-sm tabular-nums">{item[:count]}</span>
                  </.nav_target>
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
            "py-6",
            @gutter_class,
            @layout == :topbar && "mx-auto",
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
        class="setzkasten-dock dock md:hidden z-30 border-t border-base-content/10"
      >
        <.nav_target
          :for={item <- @dock_items}
          item={item}
          place={:dock}
          class={["min-w-0", mark(@dock_current, item) && "dock-active"]}
          aria-label={nav_name(item)}
          aria-current={mark(@dock_current, item)}
        >
          <.icon_count count={item[:count]} class="badge-primary">{nav_icon(item, :md)}</.icon_count>
          <span class="dock-label max-w-full truncate">{item.label}</span>
        </.nav_target>
        <button
          :if={@dock_more?}
          type="button"
          class={["min-w-0", @more_current? && "dock-active"]}
          aria-current={@more_current? && "true"}
          aria-haspopup="dialog"
          phx-click={show_modal(if @layout == :sidebar, do: "#{@id}-sidebar", else: "#{@id}-more")}
        >
          <.icon name="ellipsis" class="size-5 m-0.5" />
          <span class="dock-label max-w-full truncate">{@more_label}</span>
        </button>
      </nav>
      <.modal :if={@dock_more? and @layout == :topbar} id={"#{@id}-more"} title={@more_label}>
        <nav aria-label={@nav_label}>
          <ul class="menu -mx-3 w-auto flex-nowrap gap-0.5 px-0">
            <li :for={item <- @more_items} class="flex-nowrap">
              <.nav_target
                item={item}
                place={:more}
                dialog={"#{@id}-more"}
                class={["flex", current?(item, @current) && "menu-active"]}
                aria-label={nav_name(item)}
                aria-current={current?(item, @current) && "page"}
              >
                {nav_icon(item)}
                <span :if={@media? and not media?(item)} class="size-5 shrink-0" aria-hidden="true"></span>
                <span class="min-w-0 flex-1 truncate" title={item.label}>{item.label}</span>
                <span :if={item[:count]} class="badge badge-sm tabular-nums">{item[:count]}</span>
              </.nav_target>
            </li>
          </ul>
        </nav>
      </.modal>
    </div>
    """
  end

  defp assign_sidebar_mode(%{layout: :sidebar, back: [back | _]} = assigns),
    do: assign(assigns, back: back, areas?: false)

  defp assign_sidebar_mode(%{layout: :sidebar} = assigns),
    do: assign(assigns, back: nil, areas?: length(assigns.area) > 1)

  defp assign_sidebar_mode(assigns), do: assign(assigns, back: nil, areas?: false)

  defp sidebar(assigns) do
    assigns = assign(assigns, :sortable?, assigns.place == :sidebar and assigns.on_sort != nil)

    ~H"""
    <%!-- One inner edge (20px) for everything in the sidebar: ghost buttons in the brand and the
         account pull their padding into the gutter, so their icon or text lines up with the nav
         icons; the account's hover pill spans like the nav pills. --%>
    <div class="flex items-center gap-2 px-5 py-4 text-lg font-semibold [&_.btn-ghost]:-ms-2 [&_.btn-ghost]:px-2">
      {render_slot(@brand, @place)}
    </div>
    <ul :if={@back} class="menu w-full pb-0">
      <li>
        <.link
          id={@back[:id] && "#{@back[:id]}-#{@place}"}
          navigate={@back[:navigate]}
          href={@back[:href]}
          class="text-sidebar-muted hover:bg-white/10 hover:text-sidebar-content focus-visible:outline-sidebar-accent"
        >
          <.icon name="chevron-left" class="size-5" />
          <span class="min-w-0 flex-1 truncate" title={@back.label}>{@back.label}</span>
        </.link>
      </li>
    </ul>
    <nav :if={@areas?} aria-label={@area_label} class="join flex px-5 pb-2">
      <.area_target
        :for={area <- @area}
        area={area}
        place={@place}
        current={@current_area}
        class="btn-sm min-w-0 flex-1 px-2"
      >
        {nav_icon(area, :sm)}
        <span class="truncate">{area.label}</span>
      </.area_target>
    </nav>
    <nav aria-label={@nav_label} class="flex-1">
      <ul
        id={@sortable? && "#{@id}-sidebar-sort"}
        class="menu w-full flex-nowrap gap-0.5"
        phx-hook={@sortable? && "Setzkasten.Components.Shell.Sortable"}
        data-sort-event={@sortable? && @on_sort}
      >
        <%= for {item, index} <- Enum.with_index(@nav) do %>
          <li
            :if={item[:section] && section_start?(@nav, index)}
            class={[
              "menu-title flex flex-row flex-nowrap items-baseline gap-2 text-sidebar-muted",
              index > 0 && "mt-4"
            ]}
          >
            <span class="min-w-0 flex-1 truncate" title={item[:section]}>{item[:section]}</span>
            <.nav_amount amount={item[:section_amount]} tone={@amount_tone} />
          </li>
          <li
            class={["flex-nowrap", section_end?(@nav, index) && "mt-4"]}
            data-sort-id={@sortable? && item[:sort_id]}
            data-sort-section={@sortable? && item[:sort_id] && item[:section]}
          >
            <.nav_target
              item={item}
              place={@place}
              dialog={@place == :dialog && "#{@id}-sidebar"}
              class={[
                "flex hover:bg-white/10 focus-visible:outline-sidebar-accent",
                if(item[:on_click],
                  do: "text-sidebar-muted hover:text-sidebar-content",
                  else: "text-sidebar-content"
                ),
                current?(item, @current) &&
                  "relative bg-white/10 before:absolute before:inset-y-1.5 before:start-0 before:w-[3px] before:rounded-full before:bg-sidebar-accent"
              ]}
              aria-label={nav_name(item)}
              aria-current={current?(item, @current) && "page"}
            >
              {nav_icon(item)}
              <span :if={@media? and not media?(item)} class="size-5 shrink-0" aria-hidden="true"></span>
              <span class="min-w-0 flex-1 truncate" title={item.label}>{item.label}</span>
              <span
                :if={item[:count] && !item[:amount]}
                class="tabular-nums text-sidebar-muted"
              >
                {item[:count]}
              </span>
              <span
                :if={item[:amount] && is_integer(item[:count]) && item[:count] > 0}
                class="badge badge-sm shrink-0 tabular-nums bg-sidebar-accent text-sidebar border-0"
              >
                {item[:count]}
              </span>
              <.nav_amount amount={item[:amount]} tone={@amount_tone} />
            </.nav_target>
          </li>
        <% end %>
      </ul>
    </nav>
    <div :if={@nav_footer != []} class="border-t border-white/10">
      {render_slot(@nav_footer, @place)}
    </div>
    <div class="flex items-center gap-4 border-t border-white/10 px-5 pt-3 pb-[max(0.75rem,env(safe-area-inset-bottom))]">
      <div
        :if={@account != [] and @place == :sidebar}
        class="flex min-w-0 flex-1 items-center gap-2 [&_.btn-ghost]:-mx-3 [&_.btn-ghost]:px-3"
      >
        {render_slot(@account, :sidebar)}
      </div>
      <button
        :if={@place == :sidebar}
        type="button"
        class="btn btn-ghost btn-square ms-auto -me-2.5"
        aria-label={@collapse_label}
        aria-expanded="true"
        aria-controls={"#{@id}-sidebar-full"}
        data-sidebar-toggle="collapse"
      >
        <.icon name="panel-left-close" class="size-5" />
      </button>
      <form :if={@place == :dialog} method="dialog" class="ms-auto -me-2.5">
        <button class="btn btn-ghost btn-square" aria-label={@collapse_label}>
          <.icon name="panel-left-close" class="size-5" />
        </button>
      </form>
    </div>
    """
  end

  attr :area, :map, required: true
  attr :place, :atom, required: true
  attr :current, :any, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  defp area_target(assigns) do
    assigns = assign(assigns, :current?, assigns.area.key == assigns.current)

    ~H"""
    <.link
      id={@area[:id] && "#{@area[:id]}-#{@place}"}
      navigate={@area[:navigate]}
      href={@area[:href]}
      class={["join-item btn", @class, @current? && "setzkasten-selected"]}
      aria-current={@current? && "page"}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  attr :area, :map, required: true

  defp area_icon(assigns) do
    if media?(assigns.area) do
      ~H"{nav_icon(@area)}"
    else
      ~H"""
      <span class="size-5 leading-5" aria-hidden="true">{String.first(@area.label)}</span>
      """
    end
  end

  # A link closes the sidebar dialog by replacing the view; a button has to close it itself.
  attr :item, :map, required: true
  attr :place, :atom, required: true
  attr :dialog, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  defp nav_target(%{item: %{on_click: click}} = assigns) when not is_nil(click) do
    js = click_js(click, assigns.item[:"phx-target"])
    js = if assigns.dialog, do: JS.concat(hide_modal(assigns.dialog), js), else: js
    assigns = assign(assigns, :click, js)

    ~H"""
    <button
      type="button"
      id={@item[:id] && "#{@item[:id]}-#{@place}"}
      class={@class}
      phx-click={@click}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp nav_target(assigns) do
    ~H"""
    <.link
      id={@item[:id] && "#{@item[:id]}-#{@place}"}
      navigate={@item[:navigate]}
      href={@item[:href]}
      class={@class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  attr :amount, :integer, default: nil
  attr :tone, :any, required: true

  defp nav_amount(%{amount: nil} = assigns), do: ~H""

  defp nav_amount(assigns) do
    ~H"""
    <span class={[
      "shrink-0 tabular-nums whitespace-nowrap",
      amount_class(@tone, @amount)
    ]}>
      {Format.money(@amount)}
    </span>
    """
  end

  defp gutter(:full), do: {"px-4", "[--setzkasten-gutter:--spacing(4)]"}

  defp gutter(_width),
    do:
      {"px-4 sm:px-6 lg:px-8",
       "[--setzkasten-gutter:--spacing(4)] sm:[--setzkasten-gutter:--spacing(6)] lg:[--setzkasten-gutter:--spacing(8)]"}

  defp width_class(width), do: elem(@widths[width], 0)
  defp gutter_class(width), do: elem(gutter(width), 0)

  defp column_vars(width, layout) do
    [
      elem(@widths[width], 1),
      elem(gutter(width), 1),
      layout == :sidebar && "[--setzkasten-column-align:0px]"
    ]
  end

  defp amount_class(:negative, amount) when amount < 0, do: "text-sidebar-negative"
  defp amount_class(:negative, amount) when amount > 0, do: "text-sidebar-content"
  defp amount_class(_tone, _amount), do: "text-sidebar-muted"

  # Detail pages (a `:bar`) go back through the bar, so they keep the screen without the dock.
  defp dock_split(%{dock: true, bar: [], back: nil, nav: nav} = assigns) do
    entries = Enum.filter(nav, &shown?(&1, :dock))
    # The sidebar dialog behind "more" is the only place a phone shows the nav footer.
    footer? = assigns.layout == :sidebar and assigns.nav_footer != []
    left_out? = length(entries) < length(nav) or footer?
    more? = length(entries) > 6 or (entries != [] and left_out?)
    items = Enum.take(entries, if(more?, do: 5, else: 6))
    {items, more?, if(more?, do: nav -- items, else: [])}
  end

  defp dock_split(_assigns), do: {[], false, []}

  # Button entries are actions in the sidebar; the rail and the dock take them only when asked.
  defp shown?(%{on_click: click} = item, place) when not is_nil(click), do: item[place] == true
  defp shown?(item, place), do: item[place] != false

  defp rail_button do
    [
      "btn btn-ghost btn-square text-sidebar-content hover:bg-white/10 border-0",
      "focus-visible:outline-sidebar-accent"
    ]
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
        not shown?(item, :rail) -> {items, gap?}
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

  defp mark({key, value}, %{key: key}), do: value
  defp mark(_place_current, _item), do: nil

  defp place_current(_nav, _items, nil), do: nil

  defp place_current(nav, items, current) do
    keys = Enum.map(items, & &1.key)
    parent = Enum.find_value(nav, &(&1.key == current && &1[:parent]))

    cond do
      current in keys -> {current, "page"}
      parent != nil and parent in keys -> {parent, "true"}
      true -> nil
    end
  end

  defp media?(item), do: Setzkasten.Plush.media(item) != nil

  defp nav_icon(item, size \\ :lg), do: nav_icon(Setzkasten.Plush.media(item), item, size)

  # Plush artwork needs 24px to read in the top-bar menu and the dock; Lucide icons keep 16/20px.
  @nav_plush_sizes %{lg: :sm, sm: :sm, md: :md, menu: :md}

  defp nav_icon(:plush, item, size) do
    # In the top-bar menu it overhangs the item's padding, so the 21px line keeps the bar's height.
    assigns = %{
      name: item[:plush],
      size: @nav_plush_sizes[size],
      class: size == :menu && "-my-[1.5px]"
    }

    ~H"""
    <.plush name={@name} size={@size} class={@class} />
    """
  end

  defp nav_icon(:icon, item, size) do
    assigns = %{name: item[:icon], class: nav_icon_class(size)}

    ~H"""
    <.icon name={@name} class={@class} />
    """
  end

  defp nav_icon(:glyph, item, size) do
    assigns = %{glyph: item[:glyph], class: nav_icon_class(size)}

    ~H"""
    <span class={["grid shrink-0 place-items-center leading-none", @class]} aria-hidden="true">
      {@glyph}
    </span>
    """
  end

  defp nav_icon(nil, _item, _size), do: nil

  # In the dock a 20px icon keeps the 24px box of a plush, so every label sits on one line.
  defp nav_icon_class(:menu), do: "size-4"
  defp nav_icon_class(:sm), do: "size-4 shrink-0"
  defp nav_icon_class(:md), do: "size-5 m-0.5"
  defp nav_icon_class(_size), do: "size-5"
end
