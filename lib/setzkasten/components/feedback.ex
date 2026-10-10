defmodule Setzkasten.Components.Feedback do
  @moduledoc "Flash toasts, alerts, status badges and empty states."
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import Setzkasten.Components.Icons

  @tone_icons %{
    info: "info",
    success: "circle-check",
    warning: "triangle-alert",
    error: "circle-alert",
    neutral: "info"
  }

  @tone_classes %{
    info: "alert-info",
    success: "alert-success",
    warning: "alert-warning",
    error: "alert-error",
    neutral: nil
  }

  @icon_colors %{
    info: "text-info",
    success: "text-success-ink",
    warning: "text-warning",
    error: "text-error-ink",
    neutral: nil
  }

  @doc """
  A message inside the page (decision E3a): `alert alert-soft alert-<tone>`, text in
  base-content, icon in the tone colour (`error-ink`/`success-ink` for error and success).

  `role` is `alert` for `:error` and `status` otherwise. With `:actions` the buttons sit at
  the end from `sm` and move under the text on phones. `on_close` (event name or `%JS{}`) adds
  a close button (`close_label`) that stays at the end on every screen size. `busy` swaps the
  icon for a spinner.

      <.alert tone={:warning} title="API-Key fehlt">
        Für Regionen und Sektoren braucht die App einen API-Key des Kursanbieters.
        <:actions><.button size={:sm}>Einrichten</.button></:actions>
      </.alert>
  """
  attr :tone, :atom, default: :info, values: [:info, :success, :warning, :error, :neutral]
  attr :title, :string, default: nil
  attr :icon, :any, default: nil, doc: "Lucide name; `false` hides the icon"
  attr :busy, :boolean, default: false
  attr :on_close, :any, default: nil, doc: "event name or `%JS{}` of the close button"
  attr :close_label, :string, default: "Schließen"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block
  slot :actions

  def alert(assigns) do
    assigns =
      assign(assigns,
        icon_name: if(assigns.icon == nil, do: @tone_icons[assigns.tone], else: assigns.icon),
        tone_class: @tone_classes[assigns.tone],
        icon_color: @icon_colors[assigns.tone],
        role: if(assigns.tone == :error, do: "alert", else: "status")
      )

    ~H"""
    <div
      role={@role}
      aria-busy={@busy && "true"}
      class={[
        "alert alert-soft text-base-content",
        @tone_class,
        grid_classes(@actions != [], @on_close != nil),
        @class
      ]}
      {@rest}
    >
      <span :if={@busy} class={["loading loading-spinner loading-sm", @icon_color]}></span>
      <.icon :if={@icon_name && !@busy} name={@icon_name} class={["size-5", @icon_color]} />
      <div class="min-w-0">
        <p :if={@title} class="font-semibold">{@title}</p>
        <div :if={@inner_block != []}>{render_slot(@inner_block)}</div>
      </div>
      <div :if={@actions != []} class="flex flex-wrap gap-2 max-sm:col-start-2 max-sm:row-start-2">
        {render_slot(@actions)}
      </div>
      <button
        :if={@on_close}
        type="button"
        class="btn btn-ghost btn-sm btn-square self-start max-sm:col-start-3 max-sm:row-start-1"
        aria-label={@close_label}
        phx-click={close_click(@on_close)}
      >
        <.icon name="x" />
      </button>
    </div>
    """
  end

  defp grid_classes(false, false), do: nil

  defp grid_classes(true, false),
    do:
      "max-sm:grid-flow-row max-sm:grid-cols-[auto_minmax(0,1fr)] sm:grid-cols-[auto_minmax(0,1fr)_auto]"

  defp grid_classes(false, true), do: "grid-cols-[auto_minmax(0,1fr)_auto] max-sm:grid-flow-col"

  defp grid_classes(true, true),
    do:
      "max-sm:grid-flow-row max-sm:grid-cols-[auto_minmax(0,1fr)_auto] sm:grid-cols-[auto_minmax(0,1fr)_auto_auto]"

  defp close_click(%JS{} = js), do: js
  defp close_click(event) when is_binary(event), do: JS.push(event)

  @doc """
  Phoenix's flash as a toast at the top (the dock and sticky action bars use the bottom).
  Same API as the generated `<.flash>`; `:info` is `alert-info`. Dismiss is a real button.

      <.flash kind={:info} flash={@flash} />
  """
  attr :id, :string, doc: "the optional id of the flash"
  attr :flash, :map, default: %{}
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], required: true
  attr :close_label, :string, default: "Schließen"
  attr :rest, :global
  slot :inner_block

  def flash(assigns) do
    ~H"""
    <div class="toast toast-top toast-center sm:toast-end z-50">
      {flash_alert(assigns)}
    </div>
    """
  end

  attr :id, :string
  attr :flash, :map, default: %{}
  attr :title, :string, default: nil
  attr :kind, :atom, required: true
  attr :close_label, :string, default: "Schließen"
  attr :rest, :global
  slot :inner_block

  defp flash_alert(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      role={if @kind == :error, do: "alert", else: "status"}
      class={[
        "alert alert-soft text-base-content w-80 sm:w-96 max-w-full",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}
      {@rest}
    >
      <.icon :if={@kind == :info} name="info" class="size-5 text-info" />
      <.icon :if={@kind == :error} name="circle-alert" class="size-5 text-error-ink" />
      <div class="min-w-0">
        <p :if={@title} class="font-semibold">{@title}</p>
        <p>{msg}</p>
      </div>
      <button
        type="button"
        class="btn btn-ghost btn-sm btn-square self-start"
        aria-label={@close_label}
        phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide_flash("##{@id}")}
      >
        <.icon name="x" />
      </button>
    </div>
    """
  end

  defp hide_flash(js, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0",
         "opacity-0 -translate-y-2"}
    )
  end

  @doc """
  All flashes of a page in one toast stack, plus the generator's connection-lost messages.

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true
  attr :id, :string, default: "flash-group"
  attr :close_label, :string, default: "Schließen"
  attr :client_error, :string, default: "Keine Verbindung"
  attr :server_error, :string, default: "Etwas ist schiefgelaufen"
  attr :reconnecting, :string, default: "Verbindung wird wiederhergestellt"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite" class="toast toast-top toast-center sm:toast-end z-50">
      <.flash_alert kind={:info} flash={@flash} close_label={@close_label} />
      <.flash_alert kind={:error} flash={@flash} close_label={@close_label} />
      <.flash_alert
        id="client-error"
        kind={:error}
        close_label={@close_label}
        title={@client_error}
        phx-disconnected={JS.remove_attribute("hidden", to: ".phx-client-error #client-error")}
        phx-connected={JS.set_attribute({"hidden", ""}, to: "#client-error")}
        hidden
      >
        {@reconnecting} <span class="loading loading-spinner loading-xs align-middle"></span>
      </.flash_alert>
      <.flash_alert
        id="server-error"
        kind={:error}
        close_label={@close_label}
        title={@server_error}
        phx-disconnected={JS.remove_attribute("hidden", to: ".phx-server-error #server-error")}
        phx-connected={JS.set_attribute({"hidden", ""}, to: "#server-error")}
        hidden
      >
        {@reconnecting} <span class="loading loading-spinner loading-xs align-middle"></span>
      </.flash_alert>
    </div>
    """
  end

  @badge_classes %{
    neutral: "badge-neutral",
    info: "badge-info",
    success: "badge-success",
    warning: "badge-warning",
    error: "badge-error",
    primary: "badge-primary"
  }

  @status_classes %{
    neutral: nil,
    info: "status-info",
    success: "status-success",
    warning: "status-warning",
    error: "status-error",
    primary: "status-primary"
  }

  @doc """
  A short status (decision E5a). `style={:dot}` (default) is a neutral badge with a coloured
  status dot and the label in base-content; `style={:solid}` fills the badge and is meant only
  for alarm states. An icon-only badge needs `label`.

      <.badge tone={:success}>Veröffentlicht</.badge>
      <.badge tone={:error} style={:solid}>überzogen</.badge>
      <.badge icon="repeat" label="Wiederkehrend" />
  """
  attr :tone, :atom,
    default: :neutral,
    values: [:neutral, :info, :success, :warning, :error, :primary]

  attr :style, :atom, default: :dot, values: [:dot, :solid]
  attr :size, :atom, default: :sm, values: [:sm, :md]
  attr :icon, :string, default: nil
  attr :label, :string, default: nil, doc: "accessible name for icon-only badges"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def badge(assigns) do
    assigns =
      assign(assigns,
        icon_only: assigns.icon != nil and assigns.inner_block == [],
        solid_class: @badge_classes[assigns.tone],
        status_class: @status_classes[assigns.tone]
      )

    ~H"""
    <span
      class={[
        "badge",
        @size == :sm && "badge-sm",
        @style == :solid && @solid_class,
        @class
      ]}
      role={@icon_only && "img"}
      aria-label={@icon_only && @label}
      {@rest}
    >
      <span
        :if={@style == :dot && !@icon}
        class={["status", @status_class]}
        aria-hidden="true"
      ></span>
      <.icon :if={@icon} name={@icon} class="size-3.5" />{render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  Says what belongs here and how to get it (one action). `layout={:inline}` (default) sits
  inside a section, list or card, left-aligned; `layout={:page}` is centred with a large
  plush. Data that arrives by itself needs no action.

  The inline title is a bold line in the surrounding text size; the page title is a heading
  (`level`, default 2) in `text-lg`.

      <.empty_state icon="inbox" title="Noch keine Depots">
        Lege ein Depot an oder importiere es aus Portfolio Performance.
        <:action><.button variant={:primary} icon="plus">Depot anlegen</.button></:action>
      </.empty_state>
  """
  attr :title, :string, default: nil
  attr :icon, :string, default: nil
  attr :plush, :string, default: nil
  attr :layout, :atom, default: :inline, values: [:inline, :page]
  attr :level, :integer, default: 2
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block
  slot :action

  def empty_state(%{layout: :page} = assigns) do
    ~H"""
    <div class={["flex flex-col items-center gap-3 px-6 py-12 text-center", @class]} {@rest}>
      <.plush :if={@plush} name={@plush} size={:xl} />
      <.icon :if={@icon && !@plush} name={@icon} class="size-12 text-base-content/70" />
      <.dynamic_tag :if={@title} tag_name={"h#{@level}"} class="text-lg font-semibold">
        {@title}
      </.dynamic_tag>
      <p :if={@inner_block != []} class="text-sm text-base-content/70 max-w-prose">
        {render_slot(@inner_block)}
      </p>
      <div :if={@action != []}>{render_slot(@action)}</div>
    </div>
    """
  end

  def empty_state(assigns) do
    ~H"""
    <div class={["flex items-start gap-3 py-6", @class]} {@rest}>
      <.plush :if={@plush} name={@plush} size={:lg} />
      <.icon :if={@icon && !@plush} name={@icon} class="size-6 shrink-0 text-base-content/70" />
      <div class="min-w-0">
        <p :if={@title} class="font-semibold">{@title}</p>
        <p :if={@inner_block != []} class="text-sm text-base-content/70 max-w-prose">
          {render_slot(@inner_block)}
        </p>
        <div :if={@action != []} class="mt-3">{render_slot(@action)}</div>
      </div>
    </div>
    """
  end
end
