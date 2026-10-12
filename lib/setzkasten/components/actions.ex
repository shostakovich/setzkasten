defmodule Setzkasten.Components.Actions do
  @moduledoc "Buttons and the floating action button."
  use Phoenix.Component
  alias Phoenix.LiveView.ColocatedHook
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

  `saved` (needs an `id`) confirms a save in place: after `push_saved(socket, id)` the button shows
  a check and `saved_label` for 1.5 s, then its label again, at the same width, announced in a
  polite live region. A `phx-disable-with` text becomes the pending label in the same stack.

      <.button variant={:primary} icon="plus">Neue Ausgabe</.button>
      <.button variant={:ghost} icon="trash-2" icon_only label="Löschen"
               confirm="Ausgabe löschen?" phx-click="delete" phx-value-id={@expense.id} />
      <.button navigate={~p"/depots"} size={:sm}>Alle Depots</.button>
      <.button type="submit" variant={:primary} id="settings-save" saved
               phx-disable-with="Speichert …">Speichern</.button>
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
  attr :saved, :boolean, default: false, doc: "confirms `push_saved/2` in place; needs `id`"
  attr :saved_label, :string, default: "Gespeichert"
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

  def button(%{saved: true, rest: rest}) when not is_map_key(rest, :id) do
    raise ArgumentError, "<.button saved> needs an id: push_saved/2 addresses the button by it"
  end

  def button(%{saved: true, rest: rest})
      when is_map_key(rest, :href) or is_map_key(rest, :navigate) or is_map_key(rest, :patch) do
    raise ArgumentError, "<.button saved> must be a button, not a link"
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

    cond do
      link?(assigns.rest) ->
        ~H"""
        <.link class={@classes} aria-label={@icon_only && @label} {@rest}>
          <.icon :if={@icon} name={@icon} />{render_slot(@inner_block)}
        </.link>
        """

      assigns.saved ->
        saved_button(assigns)

      true ->
        plain_button(assigns)
    end
  end

  defp plain_button(assigns) do
    ~H"""
    <button
      type={@type}
      class={@classes}
      disabled={@disabled || @loading}
      aria-busy={@loading && "true"}
      aria-label={@icon_only && @label}
      {@rest}
    >
      {button_content(assigns)}
    </button>
    """
  end

  defp button_content(assigns) do
    ~H"""
    <span :if={@loading} class="loading loading-spinner loading-sm motion-reduce:hidden"></span>
    <.icon :if={@loading} name="ellipsis" class="motion-safe:hidden" />
    <.icon :if={@icon && !@loading} name={@icon} />{render_slot(@inner_block)}
    """
  end

  # LiveView swaps a phx-disable-with text in via textContent, which would flatten the stack.
  defp saved_button(assigns) do
    {pending, rest} = Map.pop(assigns.rest, :"phx-disable-with")
    assigns = assign(assigns, pending: pending, rest: rest)

    ~H"""
    <button
      type={@type}
      class={["setzkasten-saved" | @classes]}
      disabled={@disabled || @loading}
      aria-busy={@loading && "true"}
      aria-label={@icon_only && @label}
      phx-hook=".Saved"
      data-saved-label={@saved_label}
      {@rest}
    >
      <span class="setzkasten-saved-stack">
        <span class="setzkasten-saved-idle">{button_content(assigns)}</span>
        <span :if={@pending} class="setzkasten-saved-pending">{@pending}</span>
        <span class="setzkasten-saved-done"><.icon name="check" />{@saved_label}</span>
      </span>
    </button>
    <script :type={ColocatedHook} name=".Saved">
      const live = () => {
        let region = document.getElementById("setzkasten-live-region")
        if (!region) {
          region = document.createElement("div")
          region.id = "setzkasten-live-region"
          region.className = "sr-only"
          region.setAttribute("role", "status")
          document.body.appendChild(region)
        }
        return region
      }
      export default {
        mounted() {
          live()
          this.handleEvent("setzkasten:saved", ({ id }) => { if (id === this.el.id) this.saved() })
        },
        saved() {
          const region = live()
          region.textContent = ""
          clearTimeout(this.timer)
          clearTimeout(this.say)
          this.js().setAttribute(this.el, "data-saved", "")
          // A fresh text node after a tick, so a second save is announced again.
          this.say = setTimeout(() => { region.textContent = this.el.dataset.savedLabel }, 50)
          this.timer = setTimeout(() => {
            this.js().removeAttribute(this.el, "data-saved")
            region.textContent = ""
          }, 1500)
        },
        destroyed() {
          clearTimeout(this.timer)
          clearTimeout(this.say)
        }
      }
    </script>
    """
  end

  @doc """
  Confirms a save on the `<.button saved>` with this `id`; use it instead of a success flash
  when the form stays on the page.

      {:noreply, push_saved(socket, "settings-save")}
  """
  def push_saved(socket, id),
    do: Phoenix.LiveView.push_event(socket, "setzkasten:saved", %{id: id})

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
        "setzkasten-fab btn btn-primary btn-lg btn-circle shadow-lg fixed z-40 md:hidden",
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
