defmodule Setzkasten.Components.Actions do
  @moduledoc "Buttons and the floating action button."
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import Setzkasten.Components.Icons
  import Setzkasten.Components.Overlays, only: [show_confirm: 5]
  import Setzkasten.Click, only: [click_js: 3]

  @variants %{
    primary: "btn-primary",
    neutral: nil,
    ghost: "btn-ghost",
    danger: "btn-error",
    danger_outline: "btn-error btn-outline",
    link: "btn-link"
  }

  @sizes %{sm: "btn-sm", md: nil, lg: "btn-lg"}

  @doc """
  A button, or a link styled as one when `href`, `navigate` or `patch` is set.

  Variants are fixed: `:primary`, `:neutral` (default; also cancel/secondary), `:ghost`,
  `:danger`, `:danger_outline`, `:link`. `class` is appended to the base classes.
  `loading` disables the button and shows a spinner, a still ellipsis with reduced motion.

  `confirm` asks in the shared `<.confirm_dialog>` before the button's
  `phx-click` runs: the click moves to the dialog's confirm button. A `%JS{}` click carries
  its own target (`JS.push("delete", target: @myself)`); only an event name takes the button's
  `phx-value-*` and `phx-target` along. `confirm` with `href`, `navigate`, `patch` or `method`
  raises: the link would navigate without asking.

      <.button variant={:primary} icon="plus">Neue Ausgabe</.button>
      <.button variant={:ghost} icon="trash-2" icon_only label="Löschen"
               confirm="Ausgabe löschen?" phx-click="delete" phx-value-id={@expense.id} />
      <.button navigate={~p"/depots"} size={:sm}>Alle Depots</.button>
  """
  attr :variant, :atom, default: :neutral, values: Map.keys(@variants)
  attr :size, :atom, default: :md, values: Map.keys(@sizes)
  attr :icon, :string, default: nil, doc: "Lucide name, rendered before the label"
  attr :icon_only, :boolean, default: false, doc: "square button; requires `label`"
  attr :label, :string, default: nil, doc: "accessible name (`aria-label`)"
  attr :loading, :boolean, default: false
  attr :confirm, :string, default: nil, doc: "question for the confirmation dialog"
  attr :confirm_text, :string, default: nil, doc: "sentence below the question"

  attr :confirm_label, :string,
    default: nil,
    doc: "confirm button label for actions other than a plain delete"

  attr :confirm_id, :string, default: "confirm-delete"
  attr :type, :string, default: "button"
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil

  attr :rest, :global,
    include:
      ~w(href navigate patch method download replace form name value phx-disable-with target rel)

  slot :inner_block

  def button(%{icon_only: true, label: nil}) do
    raise ArgumentError, "<.button icon_only> needs a label"
  end

  def button(%{confirm: confirm, rest: rest})
      when is_binary(confirm) and
             (is_map_key(rest, :href) or is_map_key(rest, :navigate) or
                is_map_key(rest, :patch) or is_map_key(rest, :method)) do
    raise ArgumentError,
          "<.button confirm> cannot ask before a link (href, navigate, patch or method): " <>
            "it would navigate without asking; confirm a phx-click instead"
  end

  def button(assigns) do
    assigns =
      assigns
      |> assign(:classes, [
        "btn",
        @variants[assigns.variant],
        @sizes[assigns.size],
        assigns.icon_only && "btn-square",
        assigns.class
      ])
      |> move_click_to_confirm()

    if link?(assigns.rest) do
      ~H"""
      <.link class={@classes} aria-label={@icon_only && @label} {@rest}>
        <.icon :if={@icon} name={@icon} />{render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button
        type={@type}
        class={@classes}
        disabled={@disabled || @loading}
        aria-busy={@loading && "true"}
        aria-label={@icon_only && @label}
        {@rest}
      >
        <span :if={@loading} class="loading loading-spinner loading-sm motion-reduce:hidden"></span>
        <.icon :if={@loading} name="ellipsis" class="motion-safe:hidden" />
        <.icon :if={@icon && !@loading} name={@icon} />{render_slot(@inner_block)}
      </button>
      """
    end
  end

  defp link?(rest), do: Enum.any?([:href, :navigate, :patch], &Map.has_key?(rest, &1))

  defp move_click_to_confirm(%{confirm: nil} = assigns), do: assigns

  defp move_click_to_confirm(%{rest: rest} = assigns) do
    {values, rest} =
      Enum.split_with(rest, fn {key, _} -> String.starts_with?(to_string(key), "phx-value-") end)

    {click, rest} = rest |> Map.new() |> Map.pop(:"phx-click")
    # An event name pushes from the dialog, outside a live component: it needs the target.
    {target, rest} =
      if is_binary(click), do: Map.pop(rest, :"phx-target"), else: {nil, rest}

    action = confirm_action(click, values, target)

    js =
      show_confirm(%JS{}, assigns.confirm_id, assigns.confirm, action,
        text: assigns.confirm_text,
        label: assigns.confirm_label
      )

    assign(assigns, :rest, Map.merge(rest, %{"phx-click": js, "aria-haspopup": "dialog"}))
  end

  defp confirm_action(event, values, target) when is_binary(event) do
    # phx-value-* attributes reach the server as strings; keep that for the parked push.
    value =
      Map.new(values, fn {key, v} ->
        {String.replace_prefix(to_string(key), "phx-value-", ""), to_string(v)}
      end)

    click_js(event, target, value: value)
  end

  defp confirm_action(click, _values, _target), do: click_js(click, nil, [])

  @doc """
  The one main action on phones (`md:hidden`): 16px above the dock inside `<.app_shell>`
  (`--setzkasten-dock-offset`), 16px above the bottom safe edge without one.

      <.fab navigate={~p"/ausgaben/neu"} icon="plus" label="Ausgabe" />
  """
  attr :label, :string, required: true
  attr :icon, :string, default: "plus"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method)

  def fab(assigns) do
    assigns =
      assign(assigns, :classes, [
        "btn btn-primary btn-lg btn-circle shadow-lg fixed z-40 md:hidden",
        "end-[calc(1rem+env(safe-area-inset-right))]",
        "bottom-[calc(max(var(--setzkasten-dock-offset,0px),env(safe-area-inset-bottom))+1rem)]",
        assigns.class
      ])

    if link?(assigns.rest) do
      ~H"""
      <.link class={@classes} aria-label={@label} {@rest}><.icon name={@icon} class="size-6" /></.link>
      """
    else
      ~H"""
      <button type="button" class={@classes} aria-label={@label} {@rest}>
        <.icon name={@icon} class="size-6" />
      </button>
      """
    end
  end
end
