defmodule Setzkasten.Components.Overlays do
  @moduledoc """
  Native `<dialog>` modals, the shared delete confirmation, `<details>` disclosures, popovers
  and tooltips.

  The modal, popover and tooltip hooks are colocated; apps import them from
  `phoenix-colocated/setzkasten` (see the README).

  `show_modal/1`, `hide_modal/1`, `show_confirm/5`, `show_popover/1` and `hide_popover/1` turn
  an id into a `#id` selector, so ids are plain CSS identifiers, without `.` or `:`.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.ColocatedHook
  alias Phoenix.LiveView.JS
  import Setzkasten.Components.Icons
  import Setzkasten.Components.Forms, only: [field_error: 1, field_describedby: 3]

  @doc """
  Opens the modal `id` (`<.modal>` or `<.confirm_dialog>`).

      <.button phx-click={show_modal("booking")}>Buchung</.button>
  """
  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    JS.dispatch(js, "setzkasten:show-modal", to: "##{id}")
  end

  @doc "Closes the modal `id`; its `on_cancel` runs afterwards."
  def hide_modal(js \\ %JS{}, id) when is_binary(id) do
    JS.dispatch(js, "setzkasten:hide-modal", to: "##{id}")
  end

  @doc """
  Asks in the shared `<.confirm_dialog id={id}>` before running `action`.

  Writes `question` (and the optional `text:` sentence) into the dialog, stores `action` on its
  confirm button and opens it. Cancel, Escape and the backdrop only close the dialog.
  `label:` names the confirm button for an irreversible action that is not a plain delete
  (e.g. "Verwerfen"); the button then drops its trash icon. Without it the dialog's own
  `confirm_label` shows. `<.button confirm="…">` and `<.list_row>` actions call this for you.

      <.button phx-click={show_confirm("confirm-delete", "Post löschen?", JS.push("delete", value: %{id: 1}))}>
        Löschen
      </.button>

  Both call styles work: with options last, `show_confirm(id, question, action, text: "…")`,
  and piped onto commands, `JS.push("x") |> show_confirm(id, question, action, opts)`. The first
  argument tells them apart: an id string or a `%JS{}`.
  """
  def show_confirm(id, question, %JS{} = action) when is_binary(id),
    do: show_confirm(%JS{}, id, question, action, [])

  def show_confirm(id, question, %JS{} = action, opts) when is_binary(id) and is_list(opts),
    do: show_confirm(%JS{}, id, question, action, opts)

  def show_confirm(%JS{} = js, id, question, %JS{} = action) when is_binary(id),
    do: show_confirm(js, id, question, action, [])

  def show_confirm(%JS{} = js, id, question, %JS{} = action, opts)
      when is_binary(id) and is_list(opts) do
    label = opts[:label]

    js
    |> JS.set_attribute({"data-confirm-action", encode(action)}, to: "##{id}-confirm")
    |> toggle_confirm_icon(id, label)
    |> JS.dispatch("setzkasten:show-modal",
      to: "##{id}",
      detail: %{
        text: %{
          "##{id}-title" => question,
          "##{id}-text" => opts[:text],
          "##{id}-confirm-label" => label
        }
      }
    )
  end

  defp toggle_confirm_icon(js, id, nil),
    do: JS.remove_attribute(js, "hidden", to: "##{id}-confirm-icon")

  defp toggle_confirm_icon(js, id, _label),
    do: JS.set_attribute(js, {"hidden", ""}, to: "##{id}-confirm-icon")

  defp encode(%JS{ops: ops}), do: Phoenix.json_library().encode!(ops)

  @doc """
  A native `<dialog>`: a bottom sheet on phones, its content and a sticky action bar above the
  bottom safe area, and centred from `sm` (`placement={:center}`),
  or a side panel (`placement={:end}` or `{:start}`, with a ✕ close button unless
  `close_button={false}`, for content that brings its own). Escape, the backdrop and `<form method="dialog">`
  close it; focus moves in and back natively; `on_cancel` runs after every close. The title
  row and `:actions` stay in place while a long body scrolls between them; they reach into the
  box's 24px padding, so a `class` should leave the padding as it is.

  `placement={:top}` is the centred dialog held at a fixed distance from the top from `sm`,
  so it grows downwards instead of jumping when fields appear or go (a form that changes
  with its input); on phones it is the same bottom sheet.

  Focus starts on a field with `autofocus`, at every width and before anything above it (a
  segmented control). Without one, the bottom sheet focuses the dialog itself, so no
  on-screen keyboard comes up; from `sm` and in side panels it goes to the first control, as
  the browser does.

  The `:heading` slot takes the title as markup in place of `title`, e.g. a `title_input/1`
  (a name edited in place) with the id `<id>-title`, which then names the dialog.

  Open it with `show_modal/1`, or from the server with `show={true}` (closing again with
  `show={false}` skips `on_cancel`). `show` acts when it changes: closed by the user, the modal
  stays closed until `show` turns `true` again.

      <.modal id="booking" title="Buchung bearbeiten" on_cancel={JS.patch(~p"/konten")}>
        …
        <:actions>
          <.button phx-click={hide_modal("booking")}>Abbrechen</.button>
          <.button type="submit" form="booking-form" variant={:primary}>Speichern</.button>
        </:actions>
      </.modal>
  """
  attr :id, :string, required: true
  attr :title, :string, default: nil
  attr :show, :boolean, default: nil
  attr :on_cancel, JS, default: nil
  attr :placement, :atom, default: :center, values: [:center, :top, :start, :end]
  attr :close_label, :string, default: "Schließen"
  attr :close_button, :boolean, default: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block
  slot :actions
  slot :heading, doc: "the title as markup in place of `title`, e.g. a `title_input/1`"

  def modal(assigns) do
    assigns =
      assign(assigns, :close?, assigns.close_button and assigns.placement in [:start, :end])

    ~H"""
    <dialog
      id={@id}
      class={["modal", placement_class(@placement)]}
      tabindex="-1"
      aria-labelledby={(@title || @heading != []) && "#{@id}-title"}
      phx-hook=".Modal"
      phx-mounted={JS.ignore_attributes(["open"])}
      data-show={show_attr(@show)}
      data-cancel={@on_cancel}
      {@rest}
    >
      <div class={[
        "modal-box",
        @placement in [:start, :end] && "h-full max-h-none rounded-none",
        @class
      ]}>
        <div
          :if={@title || @heading != [] || @close?}
          class={[
            "setzkasten-modal-head flex items-start justify-between gap-2",
            "sticky -top-6 z-30 -mx-6 -mt-6 bg-inherit px-6 pt-6"
          ]}
        >
          <h2
            :if={@title && @heading == []}
            id={"#{@id}-title"}
            class="min-w-0 text-lg font-semibold wrap-anywhere"
          >
            {@title}
          </h2>
          <div :if={@heading != []} class="min-w-0 flex-1">{render_slot(@heading)}</div>
          <form :if={@close?} method="dialog" class="ms-auto">
            <button class="btn btn-ghost btn-sm btn-square" aria-label={@close_label}>
              <.icon name="x" />
            </button>
          </form>
        </div>
        {render_slot(@inner_block)}
        <div
          :if={@actions != []}
          class={[
            "modal-action setzkasten-modal-foot",
            "sticky -bottom-6 z-30 -mx-6 mt-2 -mb-6 bg-inherit px-6 pt-4 pb-6"
          ]}
        >
          {render_slot(@actions)}
        </div>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button tabindex="-1">{@close_label}</button>
      </form>
      <div id={"#{@id}-toasts"} class="setzkasten-modal-toasts" phx-update="ignore"></div>
    </dialog>
    <script :type={ColocatedHook} name=".Modal">
      const FOCUSABLE = "a[href], button:not([disabled]), input:not([disabled], [type=hidden]), select:not([disabled]), textarea:not([disabled]), summary, [tabindex]:not([tabindex='-1'])"
      const visible = (el) => el.isConnected && el.getClientRects().length > 0
      const usable = (el) => visible(el) && el.matches(FOCUSABLE)
      const focusIn = (el) => {
        const target = [el, ...el.querySelectorAll(FOCUSABLE)].find(usable)
        if (target) target.focus()
        return !!target
      }
      export default {
        mounted() {
          this.el.addEventListener("setzkasten:show-modal", (e) => this.open(e.detail))
          this.el.addEventListener("setzkasten:hide-modal", () => this.el.close())
          this.el.addEventListener("close", () => {
            this.resume()
            this.returnFocus()
            this.announce("close")
            if (this.silent) { this.silent = false; return }
            const cancel = this.el.getAttribute("data-cancel")
            if (cancel) this.js().exec(cancel)
          })
          this.sync()
        },
        updated() { this.sync() },
        destroyed() {
          if (this.unwatch) this.unwatch()
          this.announce("close")
        },
        // For the toast stack, which moves into the topmost open modal.
        announce(change) {
          document.dispatchEvent(new CustomEvent(`setzkasten:modal-${change}`, { detail: this.el }))
        },
        sync() {
          const show = this.el.getAttribute("data-show")
          if (show === this.shown) return
          this.shown = show
          if (show === "true") this.show()
          if (show === "false" && this.el.open) { this.silent = true; this.el.close() }
        },
        open(detail) {
          const texts = (detail && detail.text) || {}
          for (const [selector, text] of Object.entries(texts)) {
            const target = this.el.querySelector(selector)
            if (target) target.textContent = text ?? target.dataset.default ?? ""
          }
          this.show()
        },
        show() {
          if (this.el.open) return
          this.trigger = document.activeElement
          // showModal() closes the open popovers; they come back with the trigger inside them.
          this.suspended = [...document.querySelectorAll(".setzkasten-popover:popover-open")]
            .filter((popover) => !popover.contains(this.el))
          for (const popover of this.suspended) this.js().setAttribute(popover, "data-suspended", "")
          // A bottom sheet opens on itself, so no field brings up the keyboard unless it asks to.
          const sheet = this.el.classList.contains("modal-bottom") && matchMedia("(width < 40rem)").matches
          if (sheet && !this.el.querySelector(".modal-box [autofocus]")) this.el.setAttribute("autofocus", "")
          this.el.showModal()
          this.announce("open")
          this.el.removeAttribute("autofocus")
          const asked = [...this.el.querySelectorAll(".modal-box [autofocus]")].find(usable)
          const box = this.el.querySelector(".modal-box")
          if (asked) asked.focus()
          else if (sheet) this.el.focus()
          // Chrome focuses a scrolling box itself instead of its first field.
          else if (box && [box, this.el].includes(document.activeElement)) focusIn(box)
        },
        resume() {
          let resumed = false
          for (const popover of this.suspended || []) {
            if (!popover.hasAttribute("data-suspended")) continue
            this.js().removeAttribute(popover, "data-suspended")
            if (!popover.isConnected) continue
            popover.dispatchEvent(new CustomEvent("setzkasten:resume-popover"))
            resumed = true
          }
          this.suspended = []
          // A reopened popover focuses its autofocus field; the trigger inside it comes first.
          if (resumed && this.trigger && usable(this.trigger)) this.trigger.focus()
        },
        // The browser's own return misses a trigger in a closed menu and one the action removes.
        returnFocus() {
          if (this.unwatch) this.unwatch()
          const trigger = this.trigger
          this.trigger = null
          if (!trigger || trigger === document.body || !trigger.isConnected) return
          const scope = trigger.closest("[data-focus-fallback]")
          const row = scope && [...scope.children].find((child) => child.contains(trigger))
          const siblings = (key) => {
            const list = []
            for (let n = row && row[key]; n; n = n[key]) list.push(n)
            return list
          }
          const candidates = [row, ...siblings("nextElementSibling"), ...siblings("previousElementSibling")]
          const fallback = () => {
            if (candidates.some((el) => el && el.isConnected && focusIn(el))) return
            const target = scope && visible(scope) ? scope : document.getElementById("main")
            if (!target) return
            if (!target.hasAttribute("tabindex")) target.setAttribute("tabindex", "-1")
            target.focus()
          }
          // A confirmed submit disables its form's buttons until the reply: wait for the trigger.
          const pending = (el) => el.isConnected && el.hasAttribute("data-phx-disabled")
          let current = trigger
          if (!usable(trigger) && !pending(trigger)) {
            const menu = trigger.closest("details")
            const popover = trigger.closest(".setzkasten-popover")
            const opener = menu
              ? menu.querySelector(":scope > summary")
              : popover && document.getElementById(popover.dataset.anchor || `${popover.id}-trigger`)
            if (!opener || !usable(opener)) return fallback()
            current = opener
            current.focus()
          }
          const check = () => {
            const active = document.activeElement
            if ((active && active !== document.body) || pending(current)) return
            stop()
            if (usable(current)) current.focus()
            else fallback()
          }
          const observer = new MutationObserver(check)
          const onFocus = (e) => { if (e.target !== current) stop() }
          const stop = () => {
            observer.disconnect()
            document.removeEventListener("focusin", onFocus)
            document.removeEventListener("pointerdown", stop, true)
            clearTimeout(timer)
            this.unwatch = null
          }
          const timer = setTimeout(stop, 10000)
          observer.observe(document.body, { childList: true, subtree: true, attributes: true, attributeFilter: ["disabled", "class", "hidden"] })
          document.addEventListener("focusin", onFocus)
          document.addEventListener("pointerdown", stop, true)
          this.unwatch = stop
          check()
        }
      }
    </script>
    """
  end

  @doc """
  A name edited in place as the title of a `<.modal>` (its `:heading` slot) or sheet: a text
  field set like the title, its frame showing on hover and focus. Give it the id `<modal
  id>-title`, so its value names the dialog; `label` names the field itself for screen readers
  (e.g. "Name"). Escape puts back the saved `value` and keeps the dialog open; once the value
  is the saved one, Escape closes the dialog. Saving is the app's: `phx-blur` on the field and
  `phx-submit` (Enter) on its form. Errors show under it, as `input/1`'s do; `field` works as
  there.

      <.modal id="category" show={@open} on_cancel={JS.push("close")}>
        <:heading>
          <form phx-submit="rename">
            <.title_input id="category-title" name="name" value={@category.name} label="Name"
                          errors={@name_errors} required phx-blur="rename" />
          </form>
        </:heading>
        …
      </.modal>
  """
  attr :id, :string, default: nil
  attr :name, :string
  attr :value, :any
  attr :field, Phoenix.HTML.FormField, doc: "a form field, e.g. `@form[:name]`"
  attr :label, :string, required: true, doc: "the field's name for screen readers"
  attr :errors, :list, default: []
  attr :rest, :global, include: ~w(disabled form maxlength minlength pattern placeholder required)

  def title_input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id, errors: errors)
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> title_input()
  end

  def title_input(assigns) do
    assigns =
      assigns
      |> assign_new(:value, fn -> nil end)
      |> assign_new(:name, fn -> assigns.id end)
      |> assign(:value, Phoenix.HTML.Form.normalize_value("text", assigns[:value]))

    ~H"""
    <div class="setzkasten-title-input">
      <label for={@id} class="sr-only">{@label}</label>
      <input
        type="text"
        id={@id}
        name={@name}
        value={@value}
        class={["input", @errors != [] && "input-error"]}
        autocomplete="off"
        enterkeyhint="done"
        aria-invalid={@errors != [] && "true"}
        aria-describedby={field_describedby(@id, @errors, nil)}
        data-saved={@value}
        phx-hook=".TitleInput"
        {@rest}
      />
      <.field_error id={@id} errors={@errors} />
    </div>
    <script :type={ColocatedHook} name=".TitleInput">
      export default {
        mounted() {
          this.el.addEventListener("keydown", (e) => {
            if (e.key !== "Escape" || this.el.value === this.el.dataset.saved) return
            e.preventDefault()
            e.stopPropagation()
            // While a save waits for its reply, data-saved is not yet the value being saved.
            if (!this.el.form?.classList.contains("phx-submit-loading")) this.el.value = this.el.dataset.saved
          })
        }
      }
    </script>
    """
  end

  defp placement_class(:center), do: "modal-bottom sm:modal-middle"
  defp placement_class(:top), do: "modal-bottom sm:modal-middle setzkasten-modal-top"
  defp placement_class(:start), do: "modal-start"
  defp placement_class(:end), do: "modal-end"

  defp show_attr(nil), do: nil
  defp show_attr(show), do: to_string(show)

  @doc """
  The one confirmation dialog per layout for irreversible deletes.

  Render it once in the app layout, inside the LiveView (not the root layout): its confirm
  button pushes the parked event, which needs a LiveView around it, and
  `Setzkasten.Test.Confirm` finds it there. Triggers (`<.button confirm>`, list row actions,
  `show_confirm/4`) write their question into it and park their destructive command on its
  confirm button; Cancel, Escape and the backdrop only close. Focus starts on Cancel. On phones
  it is a bottom sheet with full-width buttons, the destructive one on top.

  On close, focus returns to the trigger (the summary of its menu if the menu closed, the
  trigger or anchor of its popover if the confirmed action hid the popover). When the
  confirmed action removes the trigger, focus moves to the next (else previous) row of the
  closest `[data-focus-fallback]` element (`<.list>` and `<.table>` bodies carry it), else to
  that element, else to `<main>`. `<.modal>` behaves the same.

      <.confirm_dialog id="confirm-delete" />
  """
  attr :id, :string, default: "confirm-delete"
  attr :title, :string, default: "Wirklich löschen?"
  attr :text, :string, default: "Das lässt sich nicht rückgängig machen."
  attr :confirm_label, :string, default: "Löschen"
  attr :cancel_label, :string, default: "Abbrechen"
  attr :close_label, :string, default: "Schließen"

  def confirm_dialog(assigns) do
    ~H"""
    <dialog
      id={@id}
      class="modal modal-bottom sm:modal-middle"
      aria-labelledby={"#{@id}-title"}
      aria-describedby={"#{@id}-text"}
      phx-hook=".Modal"
      phx-mounted={JS.ignore_attributes(["open"])}
    >
      <div class="modal-box">
        <h2
          id={"#{@id}-title"}
          class="text-lg font-semibold wrap-anywhere"
          data-default={@title}
          phx-update="ignore"
        >
          {@title}
        </h2>
        <p
          id={"#{@id}-text"}
          class="py-2 text-sm wrap-anywhere"
          data-default={@text}
          phx-update="ignore"
        >
          {@text}
        </p>
        <div class="modal-action max-sm:flex-col-reverse max-sm:*:w-full">
          <button type="button" class="btn" phx-click={hide_modal(@id)} autofocus>
            {@cancel_label}
          </button>
          <button
            type="button"
            id={"#{@id}-confirm"}
            class="btn btn-error"
            data-confirm-action="[]"
            phx-click={JS.exec("data-confirm-action") |> hide_modal(@id)}
          >
            <span id={"#{@id}-confirm-icon"} class="contents" phx-update="ignore">
              <.icon name="trash-2" />
            </span>
            <span id={"#{@id}-confirm-label"} data-default={@confirm_label} phx-update="ignore">
              {@confirm_label}
            </span>
          </button>
        </div>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button tabindex="-1">{@close_label}</button>
      </form>
      <div id={"#{@id}-toasts"} class="setzkasten-modal-toasts" phx-update="ignore"></div>
    </dialog>
    """
  end

  @doc """
  Opens the `<.popover>` `id`, anchored to its trigger or `anchor`.

      <.button phx-click={show_popover("cover")}>Decken</.button>
  """
  def show_popover(js \\ %JS{}, id) when is_binary(id) do
    JS.dispatch(js, "setzkasten:show-popover", to: "##{id}")
  end

  @doc "Closes the `<.popover>` `id`; focus returns to where it was, its `on_cancel` runs."
  def hide_popover(js \\ %JS{}, id) when is_binary(id) do
    JS.dispatch(js, "setzkasten:hide-popover", to: "##{id}")
  end

  @doc """
  Free content next to what it belongs to: a small form (move money, rename, a colour), not a
  menu (that is `dropdown/1`). The panel lives in the top layer (HTML Popover API), so it
  escapes scrolling tables and other `overflow` containers.

  The `:trigger` button toggles it natively (`popovertarget`); a click on an `anchor` of an
  open popover closes it too, without opening it again. It closes on a click outside, on
  Escape, with `hide_popover/1` or `show={false}`; Escape and `hide_popover/1` return focus to
  where it was (the trigger). Its open state survives LiveView patches. Give the first field
  `autofocus` to start there.

  Placement: below the trigger, its start edge at the trigger's (`align={:end}`: end edges),
  `position={:top}` above; it flips when there is no room. When neither side holds it, it takes
  the side with more room, as tall as that room, and scrolls inside; along the trigger it takes
  the other edge when that one keeps it inside the window, else it shifts to stay 8px inside. CSS anchor positioning places it while one side holds it; a
  colocated hook does otherwise, where the browser has none, and always for `anchor` (the id of
  an element elsewhere, e.g. a table cell that opened it with `show_popover/1`; then `:trigger`
  may be left out). Below `sm` it is a bottom sheet over a scrim, as `modal/1` is on phones, and
  the page under it holds still.

  `layout={:list}` is the panel for a `pick_list/1`: a narrow padding around its cards and the
  `title` as a quiet section title in line with the rows. On phones it is a half-height sheet,
  as tall as its list up to half the screen, and a longer list scrolls inside.

  Open it from the server with `show={true}` (closing with `show={false}` skips `on_cancel`) or
  with `show_popover/1`. As for `modal/1`, `show` acts when it changes. `on_cancel` runs after every other close, e.g. to clear the server's
  state of an open popover. A modal opened meanwhile (a confirmation from inside it) closes it
  without `on_cancel` and opens it again when the modal closes, unless the confirmed action
  hid it.

      <.popover id="rename" title="Kategorie umbenennen" align={:end} variant={:ghost}>
        <:trigger><.icon name="pencil" /> Umbenennen</:trigger>
        <form phx-submit={JS.push("rename") |> hide_popover("rename")} class="grid gap-3">
          <.input name="name" id="rename-name" label="Name" value={@category.name} autofocus />
          <.button type="submit" variant={:primary} size={:sm}>Speichern</.button>
        </form>
      </.popover>

      <.popover id="cover" title="50,00 € decken aus" anchor={@cover_cell} show={@cover != nil}
                on_cancel={JS.push("cover_closed")} layout={:list}>
        <.pick_list id="cover-sources">…</.pick_list>
      </.popover>
  """
  attr :id, :string, required: true
  attr :title, :string, default: nil, doc: "heading of the panel, its accessible name"
  attr :label, :string, default: nil, doc: "accessible name of the trigger when it is no text"
  attr :align, :atom, default: :start, values: [:start, :end]
  attr :position, :atom, default: :bottom, values: [:bottom, :top]
  attr :variant, :atom, default: :neutral, values: [:neutral, :ghost]
  attr :chevron, :boolean, default: false
  attr :trigger_class, :any, default: nil

  attr :anchor, :string,
    default: nil,
    doc: "id of the element to place it at, instead of the trigger"

  attr :show, :boolean, default: nil
  attr :on_cancel, JS, default: nil
  attr :layout, :atom, default: :form, values: [:form, :list]
  attr :class, :any, default: nil, doc: "on the panel, e.g. a width (`w-80`)"
  attr :rest, :global
  slot :trigger
  slot :inner_block, required: true

  def popover(%{trigger: [], anchor: nil}) do
    raise ArgumentError, "<.popover> needs a :trigger or an anchor to be placed at"
  end

  def popover(assigns) do
    ~H"""
    <div
      class={["setzkasten-popover-root", if(@trigger != [], do: "inline-block", else: "contents")]}
      {@rest}
    >
      <button
        :if={@trigger != []}
        type="button"
        id={"#{@id}-trigger"}
        class={["btn", @variant == :ghost && "btn-ghost", @trigger_class]}
        popovertarget={@id}
        aria-haspopup="dialog"
        aria-label={@label}
      >
        {render_slot(@trigger)}<.icon :if={@chevron} name="chevron-down" />
      </button>
      <div
        id={@id}
        popover="auto"
        role="dialog"
        aria-labelledby={@title && "#{@id}-title"}
        class={[
          "setzkasten-popover shadow-lg",
          @align == :end && "setzkasten-popover-end",
          @position == :top && "setzkasten-popover-top",
          @layout == :list && "setzkasten-popover-list",
          @class
        ]}
        phx-hook=".Popover"
        data-anchor={@anchor}
        data-show={show_attr(@show)}
        data-cancel={@on_cancel}
      >
        <h2
          :if={@title}
          id={"#{@id}-title"}
          class={[
            "font-semibold wrap-anywhere",
            if(@layout == :list, do: "px-3 pt-1 pb-1.5 text-base-content/70", else: "mb-3")
          ]}
        >
          {@title}
        </h2>
        {render_slot(@inner_block)}
      </div>
    </div>
    <script :type={ColocatedHook} name=".Popover">
      // Anchor positioning with anchor-scope places a popover at its own trigger while one side
      // holds it; otherwise, and for an anchor elsewhere, the hook does.
      const NATIVE = CSS.supports("anchor-scope: all") && CSS.supports("position-area: block-end")
      const phone = window.matchMedia("(width < 40rem)")
      const EDGE = 8
      const GAP = 4
      export default {
        mounted() {
          this.onMove = () => {
            cancelAnimationFrame(this.frame)
            this.frame = requestAnimationFrame(() => this.place())
          }
          // A press on the anchor dismisses the open popover; its click must not open it again.
          this.onPointer = (e) => {
            if (this.el.contains(e.target)) return
            this.byPointer = true
            const anchor = this.el.hasAttribute("data-anchor") && this.anchor()
            if (anchor && anchor.contains(e.target)) this.swallow = e.timeStamp
          }
          this.onClick = (e) => {
            const pressed = this.swallow
            this.swallow = null
            const anchor = this.anchor()
            if (pressed == null || e.timeStamp - pressed > 1000 || !anchor || !anchor.contains(e.target)) return
            e.preventDefault()
            e.stopPropagation()
          }
          document.addEventListener("click", this.onClick, true)
          // Synchronous, unlike toggle: this close must reach the server before another popover's open.
          this.el.addEventListener("beforetoggle", (e) => {
            if (e.newState === "open") {
              if (this.resuming) return
              const active = document.activeElement
              this.returnTo = active && !this.el.contains(active) ? active : null
              this.byPointer = false
              return
            }
            if (!this.el.hasAttribute("data-suspended")) this.cancel()
          })
          this.el.addEventListener("toggle", (e) => {
            if (e.newState === "open") {
              this.place()
              window.addEventListener("scroll", this.onMove, { capture: true, passive: true })
              window.addEventListener("resize", this.onMove)
              document.addEventListener("pointerdown", this.onPointer, true)
            } else {
              this.stopTracking()
              if (!this.el.hasAttribute("data-suspended")) this.returnFocus()
            }
          })
          this.el.addEventListener("setzkasten:show-popover", () => this.show())
          this.el.addEventListener("setzkasten:resume-popover", () => {
            this.resuming = true
            this.show()
            this.resuming = false
          })
          this.el.addEventListener("setzkasten:hide-popover", () => this.hide())
          this.sync()
        },
        updated() {
          this.sync()
          if (this.isOpen()) this.place()
        },
        destroyed() {
          this.stopTracking()
          document.removeEventListener("click", this.onClick, true)
          this.returnFocus()
        },
        isOpen() { return this.el.matches(":popover-open") },
        sync() {
          const show = this.el.getAttribute("data-show")
          if (show === this.shown) return
          this.shown = show
          if (show === "true") this.show()
          if (show === "false" && this.isOpen()) { this.silent = true; this.hide() }
        },
        anchor() {
          const id = this.el.getAttribute("data-anchor")
          return id ? document.getElementById(id) : document.getElementById(`${this.el.id}-trigger`)
        },
        show() {
          if (this.isOpen() || !this.el.isConnected || this.el.hasAttribute("data-suspended")) return
          this.el.showPopover({ source: this.anchor() || undefined })
        },
        // Hidden while a modal holds it (the confirmed action closes it): it stays closed.
        hide() {
          if (this.el.hasAttribute("data-suspended")) {
            this.js().removeAttribute(this.el, "data-suspended")
            this.cancel()
          } else if (this.isOpen()) this.el.hidePopover()
        },
        cancel() {
          if (this.silent) { this.silent = false; return }
          const cancel = this.el.getAttribute("data-cancel")
          if (cancel) this.js().exec(cancel)
        },
        // The browser returns focus only while it is inside the popover; a form submit inside it
        // can drop it to <body> first. A click outside keeps focus where it went.
        returnFocus() {
          const target = this.returnTo
          this.returnTo = null
          const active = document.activeElement
          if (this.byPointer || !target || !target.isConnected) return
          if (!active || active === document.body || this.el.contains(active)) target.focus()
        },
        stopTracking() {
          document.removeEventListener("pointerdown", this.onPointer, true)
          cancelAnimationFrame(this.frame)
          window.removeEventListener("scroll", this.onMove, { capture: true })
          window.removeEventListener("resize", this.onMove)
        },
        place() {
          const style = this.el.style
          const anchor = this.anchor()
          const reset = () => {
            for (const property of ["left", "top", "max-height"]) style.removeProperty(property)
            if (this.el.hasAttribute("data-placed")) this.js().removeAttribute(this.el, "data-placed")
          }
          if (!anchor || phone.matches) return reset()
          const a = anchor.getBoundingClientRect()
          const width = this.el.offsetWidth
          const height = this.el.scrollHeight + this.el.offsetHeight - this.el.clientHeight
          const vw = document.documentElement.clientWidth
          const below = window.innerHeight - EDGE - a.bottom - GAP
          const above = a.top - GAP - EDGE
          const rtl = getComputedStyle(this.el).direction === "rtl"
          const end = this.el.classList.contains("setzkasten-popover-end") !== rtl
          const starts = end ? [a.right - width, a.left] : [a.left, a.right - width]
          const inside = (left) => left >= EDGE && left + width <= vw - EDGE
          const native = NATIVE && !this.el.hasAttribute("data-anchor")
          if (native && (height <= below || height <= above) && starts.some(inside)) return reset()
          // Neither side holds it: the side with more room, scrolling inside.
          const up = this.el.classList.contains("setzkasten-popover-top")
            ? height <= above || (height > below && above >= below)
            : height > below && (height <= above || above > below)
          const room = Math.max(0, up ? above : below)
          if (native && !this.el.hasAttribute("data-placed")) this.js().setAttribute(this.el, "data-placed", "")
          style.maxHeight = `${room}px`
          const start = starts.find(inside) ?? starts[0]
          style.left = `${Math.max(EDGE, Math.min(start, vw - width - EDGE))}px`
          style.top = `${up ? a.top - GAP - Math.min(height, room) : a.bottom + GAP}px`
        }
      }
    </script>
    """
  end

  @tooltip_placements %{
    top: "tooltip-top",
    bottom: "tooltip-bottom",
    left: "tooltip-left",
    right: "tooltip-right"
  }

  @doc """
  A short hint on hover and keyboard focus around one element: daisyUI's `tooltip` with
  `data-tip`, `placement` `:top` (default), `:bottom`, `:left` or `:right`.

  Screen readers get the text as the description of the first control inside
  (`aria-describedby` to a hidden copy, set by a colocated hook), unless it only repeats that
  element's name, as for an icon button whose `label` is the tooltip.

  Touch screens show it at best on a tap, so a tooltip never holds what the user needs to know:
  a hint, a full name behind an ellipsis or an icon's name, not an error or a value.

      <.tooltip id="sync-hint" text="Zuletzt vor 5 Minuten abgeglichen">
        <.button icon="refresh-cw" icon_only label="Abgleichen" />
      </.tooltip>
  """
  attr :id, :string, required: true
  attr :text, :string, required: true
  attr :placement, :atom, default: :top, values: [:top, :bottom, :left, :right]
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def tooltip(assigns) do
    assigns = assign(assigns, :tooltip_placements, @tooltip_placements)

    ~H"""
    <span
      id={@id}
      class={["tooltip", @tooltip_placements[@placement], @class]}
      data-tip={@text}
      phx-hook=".Tooltip"
      {@rest}
    >
      {render_slot(@inner_block)}<span id={"#{@id}-text"} hidden>{@text}</span>
    </span>
    <script :type={ColocatedHook} name=".Tooltip">
      const FOCUSABLE = "a[href], button, input:not([type=hidden]), select, textarea, summary, [tabindex]:not([tabindex='-1'])"
      export default {
        mounted() { this.describe() },
        updated() { this.describe() },
        describe() {
          const target = this.el.querySelector(FOCUSABLE)
          const text = this.el.querySelector(`#${CSS.escape(this.el.id)}-text`)
          if (!target || !text) return
          const name = (target.getAttribute("aria-label") || target.textContent).trim()
          const ids = (target.getAttribute("aria-describedby") || "").split(" ").filter((id) => id && id !== text.id)
          if (name !== text.textContent.trim()) ids.push(text.id)
          if (ids.length) this.js().setAttribute(target, "aria-describedby", ids.join(" "))
          else this.js().removeAttribute(target, "aria-describedby")
        }
      }
    </script>
    """
  end

  @doc """
  A `<details>` disclosure. `variant={:collapse}` (default) draws daisyUI's bordered
  `collapse collapse-arrow`; `variant={:row}` is a quiet 14px row with only a hairline above,
  inside a card or under a chart (`chart_card`'s "Werte als Tabelle" is one); `variant={:button}`
  renders the summary as a button (with `icon`) for compact "more options" triggers. The summary is at least 44px on touch screens.
  The open state survives LiveView patches. `count` follows the summary as a quiet number, as
  in `section_heading` (not "Kurse (3)"); in the button it is a small neutral badge, set apart
  from the label it would otherwise read as part of.

      <.disclosure id="split-more" summary="Weitere Aufteilungsoptionen">…</.disclosure>
      <.disclosure id="retired" summary="Ausgemustert" count={2}>…</.disclosure>

  The `:title` slot takes the summary as markup instead of `summary` (e.g. with a toned
  amount; an attribute and a slot cannot share the name):

      <.disclosure id="overspent">
        <:title>Überzogen <.amount value={-4_210} tone /></:title>
        …
      </.disclosure>
  """
  attr :id, :string, required: true
  attr :summary, :string, default: nil, doc: "the summary text; or the `:title` slot"
  attr :count, :integer, default: nil
  attr :open, :boolean, default: false
  attr :variant, :atom, default: :collapse, values: [:collapse, :row, :button]
  attr :icon, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :title, doc: "the summary as markup, instead of `summary`"

  def disclosure(%{summary: nil, title: []}) do
    raise ArgumentError, "<.disclosure> needs a summary or a :title slot"
  end

  def disclosure(%{variant: :button} = assigns) do
    ~H"""
    <details
      id={@id}
      class={@class}
      open={@open}
      phx-mounted={JS.ignore_attributes(["open"])}
      {@rest}
    >
      <summary class="btn">
        <.icon :if={@icon} name={@icon} />{@summary}{render_slot(@title)}
        <span :if={@count} class="badge badge-sm tabular-nums">{@count}</span>
      </summary>
      <div class="mt-3 text-sm">{render_slot(@inner_block)}</div>
    </details>
    """
  end

  def disclosure(assigns) do
    ~H"""
    <details
      id={@id}
      class={[
        "collapse collapse-arrow",
        if(@variant == :row,
          do: "rounded-none border-t border-base-content/10",
          else: "border border-base-content/10 bg-base-100"
        ),
        @class
      ]}
      open={@open}
      phx-mounted={JS.ignore_attributes(["open"])}
      {@rest}
    >
      <summary class={["collapse-title font-semibold", @variant == :row && "text-sm"]}>
        {@summary}{render_slot(@title)}<.summary_count count={@count} />
      </summary>
      <div class={["collapse-content text-sm", @variant == :row && "overflow-x-auto"]}>
        {render_slot(@inner_block)}
      </div>
    </details>
    """
  end

  attr :count, :integer, required: true

  defp summary_count(%{count: nil} = assigns), do: ~H""

  defp summary_count(assigns) do
    ~H"""
    <span class="ms-2 font-normal text-base-content/70 tabular-nums">{@count}</span>
    """
  end
end
