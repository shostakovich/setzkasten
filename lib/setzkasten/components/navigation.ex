defmodule Setzkasten.Components.Navigation do
  @moduledoc "Segmented choices, tab navigation and dropdown menus."
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import Setzkasten.Components.Icons
  import Setzkasten.Click, only: [entry_click: 2]

  @doc """
  One choice out of a few (time range, view): a `join` of buttons, the selected one in the
  selection fill (`setzkasten-selected`, `bg-selected`).

  Modes:

    * `:patch` – links (`patch`), the selected one has `aria-current="page"`. Options are
      `{label, path}` (selected when `value` equals the path) or `{label, value, path}`.
    * `:button` – buttons with `aria-pressed`; each sends the button's `phx-click` (from
      `rest`) with `phx-value-value`. Options are `{label, value}`.
    * `:radio` – a form field: sr-only radios in `label.btn`, from `field` or `name`.

  Options may also be maps with `:label`, `:value`, `:path`, `:icon` and `:long_label`, the
  accessible name of a short label (`aria-label`, no tooltip): "1 M" reads "1 Monat". Let it
  contain the visible label, so voice control finds the option by what it shows.

  `block` stretches the group to the full width with options of equal width and tighter
  padding below `sm`, so five short options fit a 360px phone. `block={:phone}` does so only
  below `sm` (e.g. a period in the header's `:actions`, which then takes its own row under the
  title) and keeps the compact group from `sm`.

      <.segmented mode={:patch} value={@range} label="Zeitraum" size={:sm}
        options={[{"1M", "1m", ~p"/?r=1m"}, {"1J", "1y", ~p"/?r=1y"}]} />
      <.segmented mode={:patch} value={@range} label="Zeitraum" size={:sm}
        options={[%{label: "1 M", long_label: "1 Monat", value: "1m", path: ~p"/?r=1m"}]} />
      <.segmented mode={:button} value={@view} label="Ansicht" phx-click="view"
        options={[%{label: "Liste", value: "list", icon: "list"}, {"Anteile", "shares"}]} />
      <.segmented mode={:radio} field={@form[:split]} label="Aufteilung"
        options={[{"Gleich", "equal"}, {"Anteile", "shares"}]} />
      <.segmented mode={:patch} value={@range} label="Zeitraum" size={:sm} block options={…} />
      <.segmented mode={:patch} value={@range} label="Zeitraum" size={:sm} block={:phone} options={…} />
  """
  attr :id, :string, default: nil
  attr :mode, :atom, default: :patch, values: [:patch, :button, :radio]
  attr :options, :list, required: true
  attr :value, :any, default: nil
  attr :label, :string, required: true, doc: "accessible name of the group"
  attr :size, :atom, default: :md, values: [:sm, :md]

  attr :block, :any,
    default: false,
    values: [false, true, :phone],
    doc: "full width, options of equal width; `:phone` only below `sm`"

  attr :field, Phoenix.HTML.FormField, default: nil
  attr :name, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  def segmented(assigns) do
    assigns =
      assigns
      |> assign(:options, Enum.map(assigns.options, &normalize_option/1))
      |> assign(:option_class, [assigns.size == :sm && "btn-sm", block_option(assigns.block)])
      |> assign(:join_class, ["join", block_join(assigns.block)])
      |> assign_field()

    render_segmented(assigns)
  end

  # The marker class lets a container (the header's actions) make room for the full width.
  defp block_join(true), do: "flex w-full setzkasten-segmented-block"
  defp block_join(:phone), do: "max-sm:flex max-sm:w-full setzkasten-segmented-block"
  defp block_join(false), do: nil

  defp block_option(true), do: "min-w-0 flex-1 max-sm:px-2"
  defp block_option(:phone), do: "max-sm:min-w-0 max-sm:flex-1 max-sm:px-2"
  defp block_option(false), do: nil

  defp assign_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assign(assigns, name: assigns.name || field.name, value: assigns.value || field.value)
  end

  defp assign_field(assigns), do: assigns

  defp normalize_option({label, value}), do: %{label: label, value: value, path: value}
  defp normalize_option({label, value, path}), do: %{label: label, value: value, path: path}
  defp normalize_option(%{} = option), do: Map.put_new(option, :path, option[:value])

  defp render_segmented(%{mode: :patch} = assigns) do
    ~H"""
    <nav id={@id} aria-label={@label} class={[@join_class, @class]} {@rest}>
      <.link
        :for={option <- @options}
        patch={option.path}
        class={["join-item btn", @option_class, selected?(option, @value) && "setzkasten-selected"]}
        aria-current={selected?(option, @value) && "page"}
        aria-label={option[:long_label]}
      >
        <.icon :if={option[:icon]} name={option[:icon]} />{option.label}
      </.link>
    </nav>
    """
  end

  defp render_segmented(%{mode: :button} = assigns) do
    ~H"""
    <div id={@id} role="group" aria-label={@label} class={[@join_class, @class]}>
      <button
        :for={option <- @options}
        type="button"
        class={["join-item btn", @option_class, selected?(option, @value) && "setzkasten-selected"]}
        aria-pressed={to_string(selected?(option, @value))}
        aria-label={option[:long_label]}
        phx-value-value={option.value}
        {@rest}
      >
        <.icon :if={option[:icon]} name={option[:icon]} />{option.label}
      </button>
    </div>
    """
  end

  defp render_segmented(%{mode: :radio} = assigns) do
    ~H"""
    <fieldset id={@id} class={[@join_class, @class]} {@rest}>
      <legend class="sr-only">{@label}</legend>
      <label
        :for={option <- @options}
        class={[
          "join-item btn has-checked:setzkasten-selected",
          "has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-primary",
          @option_class
        ]}
      >
        <input
          type="radio"
          name={@name}
          value={option.value}
          class="sr-only"
          checked={selected?(option, @value)}
          aria-label={option[:long_label]}
        />
        <.icon :if={option[:icon]} name={option[:icon]} />{option.label}
      </label>
    </fieldset>
    """
  end

  defp selected?(%{value: value}, current), do: to_string(value) == to_string(current)

  @doc """
  Navigation between sibling views of one object (`tabs tabs-border`). Links only,
  server-rendered: the active tab carries `aria-current="page"` (daisyUI styles it, no
  `tab-active`). Scrolls horizontally on phones; 44px on touch screens.

      <.tabs label="Bereiche">
        <:tab navigate={~p"/sites/\#{@site}/posts"} active>Posts</:tab>
        <:tab navigate={~p"/sites/\#{@site}/pages"}>Seiten</:tab>
      </.tabs>
  """
  attr :label, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  slot :tab, required: true do
    attr :navigate, :string
    attr :patch, :string
    attr :href, :string
    attr :active, :boolean
    attr :class, :any, doc: "e.g. `ms-auto` to push a group of tabs to the end"
  end

  def tabs(assigns) do
    ~H"""
    <nav
      aria-label={@label}
      class={["tabs tabs-border flex-nowrap overflow-x-auto", @class]}
      {@rest}
    >
      <.link
        :for={tab <- @tab}
        navigate={tab[:navigate]}
        patch={tab[:patch]}
        href={tab[:href]}
        class={["tab shrink-0 whitespace-nowrap", tab[:class]]}
        aria-current={tab[:active] && "page"}
      >
        {render_slot(tab)}
      </.link>
    </nav>
    """
  end

  @doc """
  Where a page sits: the parent pages as links, then the current page as the page heading
  (`<h1>` by default, `aria-current="page"`), long titles cut with an ellipsis. Below `sm`
  it is a back chevron to the nearest parent (named for screen readers) and the current page.
  Made for the `:bar` of `app_shell/1`, followed by a status badge if the page has one.

      <.breadcrumbs label="Pfad">
        <:crumb navigate={~p"/beitraege"}>Beiträge</:crumb>
        <:crumb>Vorschau: Winterprojekte</:crumb>
      </.breadcrumbs>
  """
  attr :label, :string, default: "Seitenpfad"
  attr :heading, :boolean, default: true, doc: "the current page is the page's `<h1>`"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :crumb, required: true do
    attr :navigate, :string
    attr :patch, :string
    attr :href, :string
  end

  def breadcrumbs(assigns) do
    {parents, [current]} = Enum.split(assigns.crumb, -1)
    assigns = assign(assigns, parents: Enum.with_index(parents), current: current)
    assigns = assign(assigns, last_parent: length(parents) - 1)

    ~H"""
    <nav
      aria-label={@label}
      class={["breadcrumbs min-w-0 overflow-hidden py-0", @class]}
      {@rest}
    >
      <ol class="min-w-0">
        <li
          :for={{crumb, index} <- @parents}
          class={[
            "shrink-0",
            if(index == @last_parent, do: "max-sm:before:hidden", else: "max-sm:hidden")
          ]}
        >
          <.link
            navigate={crumb[:navigate]}
            patch={crumb[:patch]}
            href={crumb[:href]}
            class={[
              "flex items-center gap-1 text-base-content/70 pointer-coarse:min-h-11",
              index == @last_parent && "max-sm:-ms-1 max-sm:min-w-8 max-sm:pointer-coarse:min-w-11"
            ]}
          >
            <.icon :if={index == @last_parent} name="chevron-left" class="size-5 sm:hidden" />
            <span class={index == @last_parent && "max-sm:sr-only"}>{render_slot(crumb)}</span>
          </.link>
        </li>
        <li class={["min-w-0", @parents != [] && "max-sm:before:hidden"]}>
          <.dynamic_tag
            tag_name={if @heading, do: "h1", else: "span"}
            class="block truncate font-semibold"
            aria-current="page"
          >
            {render_slot(@current)}
          </.dynamic_tag>
        </li>
      </ol>
    </nav>
    """
  end

  @doc """
  A menu behind a button: `<details class="dropdown">` with a `menu`. Closes on outside
  click, Escape and after choosing an item; Escape and choosing return focus to the trigger.
  Stays open across LiveView patches. Disclosure semantics from `<details>` (no `role="menu"`).

  `:item` attrs: `navigate`/`patch`/`href` (+ `method`) or `on_click` (an event name with
  `phx-target`, e.g. `@myself`, or a `%JS{}` that carries its own target:
  `JS.push("undo", target: @myself)`),
  `icon`, `active` (selected, `aria-current="page"`), `danger`, `divider` (a line above the
  item, e.g. before a link to the whole list), `id`, `disabled`, `class` (e.g. `sm:hidden`
  for an entry that stands as a button next to the menu on wider screens), and `confirm` (+
  `confirm_text`, `confirm_label`) to ask in the shared `<.confirm_dialog>` first. `:header` is a line above the items
  (`menu-title`, e.g. the signed-in account). `trigger_class` adds classes to the trigger
  button (e.g. `btn-square` for an icon trigger, `btn-sm`). `position={:top}` opens the menu
  above the trigger, for a trigger at the bottom of the screen. The menu sets its own text
  colour and weight, so it reads the same inside the dark sidebar or a bold brand.

      <.dropdown id="account" label="Konto" align={:end} variant={:ghost}>
        <:trigger><.avatar initials="KM" size={:sm} /> kim@example.com</:trigger>
        <:item navigate={~p"/users/settings"} icon="settings">Einstellungen</:item>
        <:item href={~p"/users/log-out"} method="delete" icon="log-out">Abmelden</:item>
      </.dropdown>
  """
  attr :id, :string, required: true
  attr :label, :string, default: nil, doc: "accessible name when the trigger is not text"
  attr :align, :atom, default: :start, values: [:start, :end]
  attr :position, :atom, default: :bottom, values: [:bottom, :top]
  attr :variant, :atom, default: :neutral, values: [:neutral, :ghost]
  attr :chevron, :boolean, default: true
  attr :open, :boolean, default: false
  attr :trigger_class, :any, default: nil
  attr :confirm_id, :string, default: "confirm-delete"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :trigger, required: true
  slot :header

  slot :item do
    attr :navigate, :string
    attr :patch, :string
    attr :href, :string
    attr :method, :string
    attr :on_click, :any
    attr :"phx-target", :any, doc: "for an event name in `on_click`, e.g. `@myself`"
    attr :icon, :string
    attr :active, :boolean
    attr :danger, :boolean
    attr :divider, :boolean
    attr :id, :string
    attr :disabled, :boolean
    attr :class, :any
    attr :confirm, :string
    attr :confirm_text, :string
    attr :confirm_label, :string
  end

  def dropdown(assigns) do
    ~H"""
    <details
      id={@id}
      class={[
        "dropdown",
        @align == :end && "dropdown-end",
        @position == :top && "dropdown-top",
        @class
      ]}
      open={@open}
      phx-mounted={JS.ignore_attributes(["open"])}
      phx-click-away={JS.remove_attribute("open")}
      phx-window-keydown={JS.remove_attribute("open")}
      phx-key="Escape"
      {@rest}
    >
      <summary
        class={["btn", @variant == :ghost && "btn-ghost", @trigger_class]}
        aria-label={@label}
        phx-keydown={close_menu("##{@id}")}
        phx-key="Escape"
      >
        {render_slot(@trigger)}<.icon :if={@chevron} name="chevron-down" />
      </summary>
      <ul class={[
        "menu dropdown-content bg-popover text-base-content text-sm font-normal rounded-box",
        "border border-base-content/10 shadow-lg z-20 w-56",
        if(@position == :top, do: "mb-1", else: "mt-1")
      ]}>
        <li :for={header <- @header} class="menu-title min-w-0 truncate">{render_slot(header)}</li>
        <li
          :for={item <- @item}
          class={[
            item[:divider] && "mt-1 border-t border-base-content/10 pt-1",
            item[:disabled] && "menu-disabled",
            item[:class]
          ]}
        >
          <.link
            :if={item[:navigate] || item[:patch] || item[:href]}
            navigate={item[:navigate]}
            patch={item[:patch]}
            href={item[:href]}
            method={item[:method]}
            id={item[:id]}
            class={[item[:active] && "menu-active", item[:danger] && "text-error-ink"]}
            aria-current={item[:active] && "page"}
            phx-click={close_menu("##{@id}")}
            phx-keydown={close_menu("##{@id}")}
            phx-key="Escape"
          >
            <.icon :if={item[:icon]} name={item[:icon]} />{render_slot(item)}
          </.link>
          <button
            :if={!(item[:navigate] || item[:patch] || item[:href])}
            type="button"
            id={item[:id]}
            class={item[:danger] && "text-error-ink"}
            disabled={item[:disabled]}
            aria-haspopup={item[:confirm] && "dialog"}
            phx-click={close_menu("##{@id}") |> JS.concat(entry_click(item, @confirm_id))}
            phx-keydown={close_menu("##{@id}")}
            phx-key="Escape"
          >
            <.icon :if={item[:icon]} name={item[:icon]} />{render_slot(item)}
          </button>
        </li>
      </ul>
    </details>
    """
  end

  # Closes a `<details>` menu and puts focus back on its summary (the closed menu's items are
  # hidden, so focus would otherwise drop to <body>). LiveView runs an element's phx-keydown
  # only on the focused element itself, so the summary and every item carry the Escape binding.
  defp close_menu(to), do: JS.remove_attribute("open", to: to) |> JS.focus_first(to: to)
end
