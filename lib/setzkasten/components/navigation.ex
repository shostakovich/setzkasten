defmodule Setzkasten.Components.Navigation do
  @moduledoc "Segmented choices, tab navigation and dropdown menus."
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import Setzkasten.Components.Icons

  @doc """
  One choice out of a few (time range, view): a `join` of buttons, selected = `btn-primary`.

  Modes:

    * `:patch` – links (`patch`), the selected one has `aria-current="page"`. Options are
      `{label, path}` (selected when `value` equals the path) or `{label, value, path}`.
    * `:button` – buttons with `aria-pressed`; each sends the button's `phx-click` (from
      `rest`) with `phx-value-value`. Options are `{label, value}`.
    * `:radio` – a form field: sr-only radios in `label.btn`, from `field` or `name`.

  Options may also be maps with `:label`, `:value`, `:path` and `:icon`.

      <.segmented mode={:patch} value={@range} label="Zeitraum" size={:sm}
        options={[{"1M", "1m", ~p"/?r=1m"}, {"1J", "1y", ~p"/?r=1y"}]} />
      <.segmented mode={:button} value={@view} label="Ansicht" phx-click="view"
        options={[%{label: "Liste", value: "list", icon: "list"}, {"Anteile", "shares"}]} />
      <.segmented mode={:radio} field={@form[:split]} label="Aufteilung"
        options={[{"Gleich", "equal"}, {"Anteile", "shares"}]} />
  """
  attr :id, :string, default: nil
  attr :mode, :atom, default: :patch, values: [:patch, :button, :radio]
  attr :options, :list, required: true
  attr :value, :any, default: nil
  attr :label, :string, required: true, doc: "accessible name of the group"
  attr :size, :atom, default: :md, values: [:sm, :md]
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :name, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  def segmented(assigns) do
    assigns =
      assigns
      |> assign(:options, Enum.map(assigns.options, &normalize_option/1))
      |> assign(:size_class, assigns.size == :sm && "btn-sm")
      |> assign_field()

    render_segmented(assigns)
  end

  defp assign_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assign(assigns, name: assigns.name || field.name, value: assigns.value || field.value)
  end

  defp assign_field(assigns), do: assigns

  defp normalize_option({label, value}), do: %{label: label, value: value, path: value}
  defp normalize_option({label, value, path}), do: %{label: label, value: value, path: path}
  defp normalize_option(%{} = option), do: Map.put_new(option, :path, option[:value])

  defp render_segmented(%{mode: :patch} = assigns) do
    ~H"""
    <nav id={@id} aria-label={@label} class={["join", @class]} {@rest}>
      <.link
        :for={option <- @options}
        patch={option.path}
        class={["join-item btn", @size_class, selected?(option, @value) && "btn-primary"]}
        aria-current={selected?(option, @value) && "page"}
      >
        <.icon :if={option[:icon]} name={option[:icon]} />{option.label}
      </.link>
    </nav>
    """
  end

  defp render_segmented(%{mode: :button} = assigns) do
    ~H"""
    <div id={@id} role="group" aria-label={@label} class={["join", @class]}>
      <button
        :for={option <- @options}
        type="button"
        class={["join-item btn", @size_class, selected?(option, @value) && "btn-primary"]}
        aria-pressed={to_string(selected?(option, @value))}
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
    <fieldset id={@id} class={["join", @class]} {@rest}>
      <legend class="sr-only">{@label}</legend>
      <label
        :for={option <- @options}
        class={[
          "join-item btn has-checked:btn-primary",
          "has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-primary",
          @size_class
        ]}
      >
        <input
          type="radio"
          name={@name}
          value={option.value}
          class="sr-only"
          checked={selected?(option, @value)}
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
  A menu behind a button: `<details class="dropdown">` with a `menu`. Closes on outside
  click, Escape and after choosing an item; Escape and choosing return focus to the trigger.
  Stays open across LiveView patches. Disclosure semantics from `<details>` (no `role="menu"`).

  `:item` attrs: `navigate`/`patch`/`href` (+ `method`) or `on_click` (event or `%JS{}`),
  `icon`, `active` (selected, `aria-current="page"`), `danger`. `:header` is a line above the
  items (`menu-title`, e.g. the signed-in account). `trigger_class` adds classes to the trigger
  button (e.g. `btn-square` for an icon trigger, `btn-sm`).

      <.dropdown id="account" label="Konto" align={:end} variant={:ghost}>
        <:trigger><.avatar initials="KM" size={:sm} /> kim@example.com</:trigger>
        <:item navigate={~p"/users/settings"} icon="settings">Einstellungen</:item>
        <:item href={~p"/users/log-out"} method="delete" icon="log-out">Abmelden</:item>
      </.dropdown>
  """
  attr :id, :string, required: true
  attr :label, :string, default: nil, doc: "accessible name when the trigger is not text"
  attr :align, :atom, default: :start, values: [:start, :end]
  attr :variant, :atom, default: :neutral, values: [:neutral, :ghost]
  attr :chevron, :boolean, default: true
  attr :open, :boolean, default: false
  attr :trigger_class, :any, default: nil
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
    attr :icon, :string
    attr :active, :boolean
    attr :danger, :boolean
  end

  def dropdown(assigns) do
    ~H"""
    <details
      id={@id}
      class={["dropdown", @align == :end && "dropdown-end", @class]}
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
      <ul class="menu dropdown-content bg-base-100 rounded-box border border-base-content/10 shadow-lg z-20 w-56 mt-1">
        <li :for={header <- @header} class="menu-title min-w-0 truncate">{render_slot(header)}</li>
        <li :for={item <- @item}>
          <.link
            :if={item[:navigate] || item[:patch] || item[:href]}
            navigate={item[:navigate]}
            patch={item[:patch]}
            href={item[:href]}
            method={item[:method]}
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
            class={item[:danger] && "text-error-ink"}
            phx-click={close_menu("##{@id}") |> JS.concat(click(item))}
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

  defp click(item) do
    case item[:on_click] do
      %JS{} = js -> js
      event when is_binary(event) -> JS.push(event)
      nil -> %JS{}
    end
  end
end
