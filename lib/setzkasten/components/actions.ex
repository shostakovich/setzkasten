defmodule Setzkasten.Components.Actions do
  @moduledoc "Buttons, the floating action button and the selection bar."
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
  `phx-value-*`, its `value` (as `"value"`, as LiveView's client sends it) and `phx-target`
  along. Without `confirm` a `phx-value-value` also renders as
  the button's `value`: LiveView's client sends that property in its place. `confirm` with `href`, `navigate`, `patch` or `method`
  raises: the link would navigate without asking; so does `confirm` without `phx-click` on a
  button that does not submit.

  On a `type="submit"` button (needs an `id`) `confirm` asks before the form is sent: the
  click and Enter in a field no longer submit, the dialog's confirm button submits the
  button's form (also one named by `form`) with the button as submitter, so its `name` and
  `value` go along; Cancel sends nothing. Its hook is Setzkasten's, so a `phx-hook` there raises.
  The hook does the asking, so the button needs a connected LiveView: before it mounts (a dead
  render, a slow connect) a click submits without asking. Its `id` becomes a `#id` selector: a
  plain CSS identifier, without `.` or `:`.

  `saved` (needs an `id`) confirms a save in place: after `push_saved(socket, id)` the button shows
  a check and `saved_label` for 1.5 s, then its label again, at the same width, announced in a
  polite live region. A `phx-disable-with` text becomes the pending label in the same stack.

  A button with an `icon` keeps it through `phx-disable-with` the same way: the text stands in
  a stack beside its label while the event runs. LiveView would replace the content with the
  text and restore only the text, losing the icon. An empty `phx-disable-with` keeps the label.
  A clicked button takes daisyUI's disabled look until the reply instead of `disabled`;
  LiveView ignores further clicks meanwhile. `icon_only` with a `phx-disable-with` text raises:
  the text would not fit the square.

      <.button variant={:primary} icon="plus">Neue Ausgabe</.button>
      <.button variant={:ghost} icon="trash-2" icon_only label="Löschen"
               confirm="Ausgabe löschen?" phx-click="delete" phx-value-id={@expense.id} />
      <.button navigate={~p"/depots"} size={:sm}>Alle Depots</.button>
      <.button type="submit" variant={:primary} id="settings-save" saved
               phx-disable-with="Speichert …">Speichern</.button>
      <.button type="submit" id="import-replace" name="mode" value="replace" variant={:danger}
               confirm="Alle Buchungen ersetzen?" confirm_label="Ersetzen">Ersetzen</.button>
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

  def button(%{icon_only: true, rest: %{"phx-disable-with": text}})
      when is_binary(text) and text != "" do
    raise ArgumentError,
          "<.button icon_only> takes no phx-disable-with text: it would not fit the square button"
  end

  def button(%{saved: true, rest: rest}) when not is_map_key(rest, :id) do
    raise ArgumentError, "<.button saved> needs an id: push_saved/2 addresses the button by it"
  end

  def button(%{saved: true, rest: rest})
      when is_map_key(rest, :href) or is_map_key(rest, :navigate) or is_map_key(rest, :patch) do
    raise ArgumentError, "<.button saved> must be a button, not a link"
  end

  def button(%{confirm: confirm, type: "submit", rest: rest})
      when is_binary(confirm) and not is_map_key(rest, :id) do
    raise ArgumentError,
          "<.button type=\"submit\" confirm> needs an id: the confirmation submits the form by it"
  end

  def button(%{confirm: confirm, type: "submit", saved: true}) when is_binary(confirm) do
    raise ArgumentError, "<.button type=\"submit\"> takes confirm or saved, not both"
  end

  def button(%{confirm: confirm, rest: rest})
      when is_binary(confirm) and
             (is_map_key(rest, :href) or is_map_key(rest, :navigate) or
                is_map_key(rest, :patch) or is_map_key(rest, :method)) do
    raise ArgumentError,
          "<.button confirm> cannot ask before a link (href, navigate, patch or method): " <>
            "it would navigate without asking; confirm a phx-click instead"
  end

  def button(%{confirm: confirm, type: type, rest: rest})
      when is_binary(confirm) and type != "submit" and not is_map_key(rest, :"phx-click") do
    raise ArgumentError,
          "<.button confirm> needs a phx-click (or type=\"submit\"): it would park nothing to confirm"
  end

  def button(%{confirm: confirm, type: "submit", rest: rest})
      when is_binary(confirm) and is_map_key(rest, :"phx-hook") do
    raise ArgumentError,
          "<.button type=\"submit\" confirm> takes no phx-hook: the confirmation needs its own"
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
      |> mirror_phx_value()

    cond do
      link?(assigns.rest) ->
        ~H"""
        <.link class={@classes} aria-label={@icon_only && @label} {@rest}>
          <.icon :if={@icon} name={@icon} />{render_slot(@inner_block)}
        </.link>
        """

      assigns.saved ->
        saved_button(assigns)

      assigns.icon && assigns.rest[:"phx-disable-with"] ->
        pending_button(assigns)

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
    <script :type={ColocatedHook} name=".ConfirmSubmit">
      export default {
        mounted() {
          // The click opens the confirmation (phx-click) instead of sending the form.
          this.el.addEventListener("click", (e) => e.preventDefault())
          this.el.addEventListener("setzkasten:confirm-submit", () => {
            if (this.el.form) this.el.form.requestSubmit(this.el)
          })
        }
      }
    </script>
    """
  end

  defp button_content(assigns) do
    ~H"""
    <span :if={@loading} class="loading loading-spinner loading-sm motion-reduce:hidden"></span>
    <.icon :if={@loading} name="ellipsis" class="motion-safe:hidden" />
    <.icon :if={@icon && !@loading} name={@icon} />{render_slot(@inner_block)}
    """
  end

  defp pending_button(assigns) do
    {pending, rest} = Map.pop(assigns.rest, :"phx-disable-with")

    assigns =
      assign(assigns, pending: if(pending in ["", true], do: nil, else: pending), rest: rest)

    ~H"""
    <button
      type={@type}
      class={["setzkasten-pending" | @classes]}
      disabled={@disabled || @loading}
      aria-busy={@loading && "true"}
      aria-label={@icon_only && @label}
      {@rest}
    >
      <span class="setzkasten-saved-stack">
        <span class="setzkasten-saved-idle">{button_content(assigns)}</span>
        <span :if={@pending} class="setzkasten-saved-pending">{@pending}</span>
      </span>
    </button>
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

  # LiveView's client sends a button's value property in place of its phx-value-value.
  defp mirror_phx_value(%{rest: %{"phx-value-value": value} = rest} = assigns)
       when not is_map_key(rest, :value) do
    if link?(rest), do: assigns, else: assign(assigns, :rest, Map.put(rest, :value, value))
  end

  defp mirror_phx_value(assigns), do: assigns

  defp move_click_to_confirm(%{confirm: nil} = assigns), do: assigns

  defp move_click_to_confirm(%{rest: rest} = assigns) do
    {values, rest} =
      Enum.split_with(rest, fn {key, _} -> String.starts_with?(to_string(key), "phx-value-") end)

    values = values ++ client_value(assigns.type, assigns.rest)
    {click, rest} = rest |> Map.new() |> Map.pop(:"phx-click")
    # An event name pushes from the dialog, outside a live component: it needs the target.
    {target, rest} =
      if is_binary(click), do: Map.pop(rest, :"phx-target"), else: {nil, rest}

    action = confirm_action(click, values, target) |> confirm_submit(assigns)

    js =
      show_confirm(%JS{}, assigns.confirm_id, assigns.confirm, action,
        text: assigns.confirm_text,
        label: assigns.confirm_label
      )

    rest = Map.merge(rest, %{"phx-click": js, "aria-haspopup": "dialog"})

    rest =
      if assigns.type == "submit",
        do: Map.put(rest, :"phx-hook", "#{inspect(__MODULE__)}.ConfirmSubmit"),
        else: rest

    assign(assigns, :rest, rest)
  end

  # LiveView's client sends a button's value property as "value", over any phx-value-value.
  defp client_value("submit", _rest), do: []
  defp client_value(_type, %{value: value}), do: [{:"phx-value-value", value}]
  defp client_value(_type, _rest), do: []

  # A confirmed submit button sends its form from the dialog; its own click only asks.
  defp confirm_submit(js, %{type: "submit", rest: %{id: id}}),
    do: JS.dispatch(js, "setzkasten:confirm-submit", to: "##{id}")

  defp confirm_submit(js, _assigns), do: js

  defp confirm_action(event, values, target) when is_binary(event) do
    # As rendered attributes: nil and false are left out, true is an empty value, the rest strings.
    value =
      for {key, v} <- values, v not in [nil, false], into: %{} do
        {String.replace_prefix(to_string(key), "phx-value-", ""),
         if(v == true, do: "", else: to_string(v))}
      end

    click_js(event, target, value: value)
  end

  defp confirm_action(click, _values, _target), do: click_js(click, nil, [])

  @doc """
  The bar for a multi-selection (e.g. checked rows of a table): fixed at the bottom of the
  content, with a button that clears the selection, the count and the actions for the selected
  items (buttons, dropdowns, popovers) in the inner block.

  Render it always and pass the count: at 0 it hides (focus inside moves to the closest
  `[data-focus-fallback]`, else `<main id="main">`), and a polite live region announces each
  new count. `label` is the count's text (`%{count}` is the number), `on_clear` an event name
  (with `phx-target`) or a `%JS{}`.

  It keeps to the content area: beside the sidebar or rail of `app_shell/1` (also collapsed),
  above the dock and the bottom safe area, with a spacer at its place so the last rows can
  scroll above it. Dropdowns inside open upwards; popovers flip above by themselves. While it
  shows, the floating action button steps back. It enters from below (a fade with reduced motion).

      <.selection_bar id="selection" count={length(@selected)} on_clear="clear_selection"
        label={ngettext("1 Buchung", "%{count} Buchungen", length(@selected))}>
        <.button size={:sm} variant={:ghost} icon="check" phx-click="approve_selected">Bestätigen</.button>
        <.dropdown id="selection-more" label="Mehr" variant={:ghost} trigger_class="btn-sm" align={:end}>
          <:trigger>Mehr</:trigger>
          <:item on_click="delete_selected" icon="trash-2" danger confirm="Auswahl löschen?">Löschen</:item>
        </.dropdown>
      </.selection_bar>
  """
  attr :id, :string, required: true
  attr :count, :integer, required: true
  attr :label, :string, default: "%{count} ausgewählt", doc: "`%{count}` is the number"
  attr :on_clear, :any, required: true, doc: "an event name or `%JS{}`"
  attr :"phx-target", :any, default: nil, doc: "for an event name in `on_clear`"
  attr :clear_label, :string, default: "Auswahl aufheben"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, doc: "the actions for the selected items"

  def selection_bar(assigns) do
    assigns =
      assign(assigns,
        text: String.replace(assigns.label, "%{count}", to_string(assigns.count)),
        clear: click_js(assigns.on_clear, assigns[:"phx-target"], [])
      )

    ~H"""
    <div id={@id} phx-hook=".SelectionBar" {@rest}>
      <p id={"#{@id}-status"} class="sr-only" role="status">{if @count > 0, do: @text}</p>
      <div :if={@count > 0} class="h-20" aria-hidden="true"></div>
      <div
        class={[
          "setzkasten-selection-bar fixed z-40 flex justify-center pointer-events-none",
          "start-(--setzkasten-shell-start,0px) end-0 px-4",
          "pe-[calc(1rem+env(safe-area-inset-right))]",
          "bottom-[calc(max(var(--setzkasten-dock-offset,0px),env(safe-area-inset-bottom))+1rem)]"
        ]}
        hidden={@count == 0}
      >
        <div
          role="group"
          aria-labelledby={"#{@id}-count"}
          class={[
            "pointer-events-auto flex max-w-full flex-wrap items-center gap-1 rounded-box",
            "border border-base-content/10 bg-popover p-1.5 text-sm shadow-lg",
            @class
          ]}
        >
          <.button
            variant={:ghost}
            size={:sm}
            icon="x"
            icon_only
            label={@clear_label}
            phx-click={@clear}
          />
          <span
            id={"#{@id}-count"}
            class="px-1 font-semibold whitespace-nowrap tabular-nums"
            aria-hidden="true"
          >
            {@text}
          </span>
          <span class="mx-1 h-6 w-px bg-base-content/10" aria-hidden="true"></span>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    <script :type={ColocatedHook} name=".SelectionBar">
      export default {
        beforeUpdate() { this.focused = this.el.contains(document.activeElement) },
        updated() {
          if (!this.focused || !this.el.querySelector(".setzkasten-selection-bar").hidden) return
          const target = this.el.closest("[data-focus-fallback]") || document.getElementById("main")
          if (!target) return
          if (!target.hasAttribute("tabindex")) target.setAttribute("tabindex", "-1")
          target.focus()
        }
      }
    </script>
    """
  end

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
