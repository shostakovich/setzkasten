defmodule Setzkasten.Components.Navigation do
  @moduledoc "Segmented choices, tab navigation and dropdown menus."
  use Phoenix.Component
  alias Phoenix.LiveView.ColocatedHook
  alias Phoenix.LiveView.JS
  import Setzkasten.Components.Icons
  import Setzkasten.Click, only: [entry_click: 2]

  import Setzkasten.Components.Forms,
    only: [field_error: 1, field_help: 1, field_describedby: 3, translate_error: 1]

  @doc """
  One choice out of a few (time range, view): a `join` of buttons, the selected one in the
  selection fill (`setzkasten-selected`, `bg-selected`).

  Modes:

    * `:patch` – links (`patch`), the selected one has `aria-current="page"`. Options are
      `{label, path}` (selected when `value` equals the path) or `{label, value, path}`. They
      replace the history entry (`replace`, default `true`): the choice filters the page, so
      Back leaves the page instead of stepping through every period; the URL still keeps it.
    * `:button` – buttons with `aria-pressed`; each sends the button's `phx-click` (from
      `rest`) with the option as `value` (the button's `value`, which LiveView sends over a
      `phx-value-value`; both are rendered). Options are `{label, value}`.
    * `:radio` – a form field: sr-only radios in `label.btn`, from `field` or `name`.
    * `:checkbox` – a form field with any number chosen (weekdays): sr-only checkboxes in
      `label.btn`, a group named by `label`, sent as `name[]` (from `field`, or `name` with
      `[]` added). `value` is a list. A hidden empty value goes along, so clearing every option
      still sends the field; Ecto's `cast/4` drops the empty string from an array.

  The form modes (`:radio`, `:checkbox`) are fields like `input`: `fieldset.fieldset` > legend
  (`label`, visible; `hide_label` keeps it for screen readers) > the options > errors > help.
  Errors come from `field` after `used_input?/1` (which then replaces `errors`, as in `input`)
  or from `errors`; `help` adds a help line;
  both are linked from the group by `aria-describedby`. With errors a radio group (`role`
  `radiogroup`) carries `aria-invalid`, in a checkbox group each checkbox does (ARIA has no
  invalid state for a plain group). `id` comes from `field`, else from `name` as Phoenix forms
  a field's id (`expense[days][]` gives `expense_days`), and names the error and help lines.

  Option values are sent as strings (`to_string/1`): `false` arrives as `"false"`, `nil` as
  `""`.

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
      <.segmented mode={:checkbox} field={@form[:weekdays]} label="Wochentage"
        options={[%{label: "Mo", long_label: "Montag", value: "mon"}, …]} />
      <.segmented mode={:patch} value={@range} label="Zeitraum" size={:sm} block options={…} />
      <.segmented mode={:patch} value={@range} label="Zeitraum" size={:sm} block={:phone} options={…} />
  """
  attr :id, :string, default: nil
  attr :mode, :atom, default: :patch, values: [:patch, :button, :radio, :checkbox]
  attr :options, :list, required: true
  attr :value, :any, default: nil
  attr :label, :string, required: true, doc: "accessible name of the group"
  attr :size, :atom, default: :md, values: [:sm, :md]

  attr :block, :any,
    default: false,
    values: [false, true, :phone],
    doc: "full width, options of equal width; `:phone` only below `sm`"

  attr :replace, :boolean,
    default: true,
    doc: "`:patch`: replace the history entry; `false` adds one per choice"

  attr :field, Phoenix.HTML.FormField, default: nil
  attr :name, :string, default: nil
  attr :hide_label, :boolean, default: false, doc: "form modes: the label for screen readers only"
  attr :errors, :list, default: [], doc: "form modes: messages or Ecto error tuples"
  attr :help, :string, default: nil, doc: "form modes: a help line under the options"
  attr :class, :any, default: nil
  attr :rest, :global

  def segmented(assigns) do
    assigns =
      assigns
      |> assign(:options, Enum.map(assigns.options, &normalize_option/1))
      |> assign(:option_class, [
        assigns.size == :sm && "btn-sm pointer-coarse:min-w-11",
        block_option(assigns.block)
      ])
      |> assign(:join_class, ["join", block_flex(assigns.block), block_marker(assigns.block)])
      |> assign_field()
      |> array_name()
      |> id_from_name()

    render_segmented(assigns)
  end

  defp block_flex(true), do: "flex w-full"
  defp block_flex(:phone), do: "max-sm:flex max-sm:w-full"
  defp block_flex(false), do: nil

  # The marker class lets a container (the header's actions) make room for the full width.
  defp block_marker(false), do: nil
  defp block_marker(_block), do: "setzkasten-segmented-block"

  defp block_option(true), do: "min-w-0 flex-1 max-sm:px-2"
  defp block_option(:phone), do: "max-sm:min-w-0 max-sm:flex-1 max-sm:px-2"
  defp block_option(false), do: nil

  defp assign_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assign(assigns,
      id: assigns.id || field.id,
      name: assigns.name || field.name,
      value: assigns.value || field.value,
      errors: errors
    )
  end

  defp assign_field(assigns), do: assigns

  defp array_name(%{mode: :checkbox, name: name} = assigns) when is_binary(name) do
    if String.ends_with?(name, "[]"), do: assigns, else: assign(assigns, :name, name <> "[]")
  end

  defp array_name(assigns), do: assigns

  # As Phoenix forms a field's id, so the error and help lines of two groups never share one.
  defp id_from_name(%{mode: mode, id: nil, name: name} = assigns)
       when mode in [:radio, :checkbox] and is_binary(name) do
    id =
      name
      |> String.trim_trailing("[]")
      |> String.replace(~r/[\[\]]+/, "_")
      |> String.trim_trailing("_")

    assign(assigns, :id, id)
  end

  defp id_from_name(assigns), do: assigns

  defp normalize_option({label, value}), do: %{label: label, value: value, path: value}
  defp normalize_option({label, value, path}), do: %{label: label, value: value, path: path}
  defp normalize_option(%{} = option), do: Map.put_new(option, :path, option[:value])

  defp render_segmented(%{mode: :patch} = assigns) do
    ~H"""
    <nav id={@id} aria-label={@label} class={[@join_class, @class]} {@rest}>
      <.link
        :for={option <- @options}
        patch={option.path}
        replace={@replace}
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
        value={to_string(option.value)}
        phx-value-value={to_string(option.value)}
        {@rest}
      >
        <.icon :if={option[:icon]} name={option[:icon]} />{option.label}
      </button>
    </div>
    """
  end

  defp render_segmented(%{mode: mode} = assigns) when mode in [:radio, :checkbox] do
    errors = Enum.map(assigns.errors, &translate_error/1)

    assigns =
      assign(assigns,
        errors: errors,
        invalid: errors != [] && "true",
        describedby: field_describedby(assigns.id, errors, assigns.help)
      )

    ~H"""
    <fieldset
      id={@id}
      class={["fieldset min-w-0", block_field(@block), block_marker(@block), @class]}
      role={@mode == :radio && "radiogroup"}
      aria-invalid={@mode == :radio && @invalid}
      aria-describedby={@describedby}
      {@rest}
    >
      <legend class={if @hide_label, do: "sr-only", else: "fieldset-legend"}>{@label}</legend>
      <input :if={@mode == :checkbox} type="hidden" name={@name} value="" />
      <div class={["join", block_flex(@block)]}>
        <label
          :for={option <- @options}
          class={[
            "join-item btn has-checked:setzkasten-selected",
            "has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-primary",
            @option_class
          ]}
        >
          <input
            type={to_string(@mode)}
            name={@name}
            value={to_string(option.value)}
            class="sr-only"
            checked={checked?(@mode, option, @value)}
            aria-label={option[:long_label]}
            aria-invalid={@mode == :checkbox && @invalid}
          />
          <.icon :if={option[:icon]} name={option[:icon]} />{option.label}
        </label>
      </div>
      <.field_error id={@id} errors={@errors} />
      <.field_help :if={@help} id={@id}>{@help}</.field_help>
    </fieldset>
    """
  end

  defp block_field(true), do: "w-full"
  defp block_field(:phone), do: "max-sm:w-full"
  defp block_field(false), do: nil

  defp selected?(%{value: value}, current), do: to_string(value) == to_string(current)

  defp checked?(:checkbox, option, values),
    do: values |> List.wrap() |> Enum.any?(&selected?(option, &1))

  defp checked?(:radio, option, value), do: selected?(option, value)

  @doc """
  Navigation between sibling views of one object (`tabs tabs-border`). Links only,
  server-rendered: the active tab carries `aria-current="page"` (daisyUI styles it, no
  `tab-active`). 44px on touch screens.

  The first tab's label lines up with the content edge (the page title above): the strip
  starts a tab's padding (12px) before it, so each tab keeps its full hit area.

  Tabs that do not fit scroll sideways: on phones the strip runs into `main`'s 16px gutters,
  tabs snap to the start, the end edge fades while more tabs follow, and an active tab out of
  view is scrolled into it (colocated hook; `id` defaults to one derived from `label`, so pass
  `id` when two tabs components share a label on one page).

      <.tabs label="Bereiche">
        <:tab navigate={~p"/sites/\#{@site}/posts"} active>Posts</:tab>
        <:tab navigate={~p"/sites/\#{@site}/pages"}>Seiten</:tab>
      </.tabs>
  """
  attr :id, :string,
    default: nil,
    doc: "needed when two tabs components share a label on one page"

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
      id={@id || "tabs-#{:erlang.phash2(@label)}"}
      aria-label={@label}
      phx-hook=".ScrollActive"
      class={[
        "setzkasten-scroller tabs tabs-border flex-nowrap overflow-x-auto snap-x scroll-pe-4",
        "-ms-3 max-sm:-mx-4 max-sm:ps-1 max-sm:pe-4 max-sm:scroll-ps-1",
        @class
      ]}
      {@rest}
    >
      <.link
        :for={tab <- @tab}
        navigate={tab[:navigate]}
        patch={tab[:patch]}
        href={tab[:href]}
        class={["tab shrink-0 snap-start whitespace-nowrap", tab[:class]]}
        aria-current={tab[:active] && "page"}
      >
        {render_slot(tab)}
      </.link>
    </nav>
    <script :type={ColocatedHook} name=".ScrollActive">
      export default {
        mounted() { this.reveal() },
        updated() { this.reveal() },
        reveal() {
          const el = this.el
          const item = el.querySelector('[aria-current="page"]')
          if (!item || el.scrollWidth <= el.clientWidth) return
          const pad = parseFloat(getComputedStyle(el).scrollPaddingInlineStart) || 0
          const box = el.getBoundingClientRect()
          const r = item.getBoundingClientRect()
          if (r.left < box.left + pad || r.right > box.right) el.scrollLeft += r.left - box.left - pad
        }
      }
    </script>
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
              "flex items-center gap-1 text-base-content/70 pointer-coarse:min-h-11 pointer-coarse:min-w-11",
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
  Escape in the open menu closes only the menu, not a `<dialog>` around it.
  Stays open across LiveView patches. Disclosure semantics from `<details>` (no `role="menu"`).

  `:item` attrs: `navigate`/`patch`/`href` (+ `method`) or `on_click` (an event name with
  `phx-target`, e.g. `@myself`, or a `%JS{}` that carries its own target:
  `JS.push("undo", target: @myself)`),
  `icon`, `active` (selected: `aria-current="page"` on a link, `"true"` on a button, e.g. the
  current sort order), `danger`, `divider` (a line above the
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
      phx-hook=".Dropdown"
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
            class={[item[:active] && "menu-active", item[:danger] && "text-error-ink"]}
            aria-current={item[:active] && "true"}
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
    <script :type={ColocatedHook} name=".Dropdown">
      export default {
        mounted() {
          this.el.addEventListener("keydown", (e) => {
            if (e.key === "Escape" && this.el.open) e.preventDefault()
          })
        }
      }
    </script>
    """
  end

  # Closes a `<details>` menu and puts focus back on its summary (the closed menu's items are
  # hidden, so focus would otherwise drop to <body>). LiveView runs an element's phx-keydown
  # only on the focused element itself, so the summary and every item carry the Escape binding.
  defp close_menu(to), do: JS.remove_attribute("open", to: to) |> JS.focus_first(to: to)
end
