defmodule Setzkasten.Components.Actions do
  @moduledoc "Buttons and the floating action button."
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import Setzkasten.Components.Icons
  import Setzkasten.Components.Overlays, only: [show_confirm: 5]

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

  `confirm` asks in the shared `<.confirm_dialog>` (decision E6b) before the button's
  `phx-click` runs: the click (a `%JS{}` or an event name plus `phx-value-*`) moves to the
  dialog's confirm button.

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
        <span :if={@loading} class="loading loading-spinner loading-sm"></span>
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
    action = confirm_action(click, values)

    js =
      show_confirm(%JS{}, assigns.confirm_id, assigns.confirm, action,
        text: assigns.confirm_text,
        label: assigns.confirm_label
      )

    assign(assigns, :rest, Map.merge(rest, %{"phx-click": js, "aria-haspopup": "dialog"}))
  end

  @doc false
  def confirm_action(%JS{} = js, _values), do: js

  def confirm_action(event, values) when is_binary(event) do
    # phx-value-* attributes reach the server as strings; keep that for the parked push.
    value =
      Map.new(values, fn {key, v} ->
        {String.replace_prefix(to_string(key), "phx-value-", ""), to_string(v)}
      end)

    JS.push(event, value: value)
  end

  def confirm_action(nil, _values), do: %JS{}

  @doc """
  The one main action on phones, floating above the dock (`md:hidden`).

      <.fab navigate={~p"/ausgaben/neu"} icon="plus" label="Ausgabe" />
  """
  attr :label, :string, required: true
  attr :icon, :string, default: "plus"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method)

  def fab(assigns) do
    assigns =
      assign(assigns, :classes, [
        "btn btn-primary btn-lg btn-circle shadow-lg fixed end-4 z-40 md:hidden",
        "bottom-[calc(4rem+env(safe-area-inset-bottom)+1rem)]",
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
