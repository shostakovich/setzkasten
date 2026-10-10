defmodule Setzkasten.Components.Overlays do
  @moduledoc """
  Native `<dialog>` modals, the shared delete confirmation and `<details>` disclosures.

  The modal hook is colocated; apps import it from `phoenix-colocated/setzkasten`
  (see the README).
  """
  use Phoenix.Component
  alias Phoenix.LiveView.ColocatedHook
  alias Phoenix.LiveView.JS
  import Setzkasten.Components.Icons

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
  """
  def show_confirm(js \\ %JS{}, id, question, %JS{} = action, opts \\ []) when is_binary(id) do
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
  A native `<dialog>`: a bottom sheet on phones and centred from `sm` (`placement={:center}`),
  or a side panel (`placement={:end}` or `{:start}`, with a close button). Escape, the backdrop and `<form method="dialog">`
  close it; focus moves in and back natively; `on_cancel` runs after every close.

  Open it with `show_modal/1`, or from the server with `show={true}` (closing again with
  `show={false}` skips `on_cancel`).

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
  attr :placement, :atom, default: :center, values: [:center, :start, :end]
  attr :close_label, :string, default: "Schließen"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block
  slot :actions

  def modal(assigns) do
    ~H"""
    <dialog
      id={@id}
      class={["modal", placement_class(@placement)]}
      aria-labelledby={@title && "#{@id}-title"}
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
        <div :if={@title || @placement != :center} class="flex items-start justify-between gap-2">
          <h2 :if={@title} id={"#{@id}-title"} class="min-w-0 text-lg font-semibold wrap-anywhere">
            {@title}
          </h2>
          <form :if={@placement != :center} method="dialog" class="ms-auto">
            <button class="btn btn-ghost btn-sm btn-square" aria-label={@close_label}>
              <.icon name="x" />
            </button>
          </form>
        </div>
        {render_slot(@inner_block)}
        <div :if={@actions != []} class="modal-action">{render_slot(@actions)}</div>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button tabindex="-1">{@close_label}</button>
      </form>
    </dialog>
    <script :type={ColocatedHook} name=".Modal">
      export default {
        mounted() {
          this.el.addEventListener("setzkasten:show-modal", (e) => this.open(e.detail))
          this.el.addEventListener("setzkasten:hide-modal", () => this.el.close())
          this.el.addEventListener("close", () => {
            if (this.silent) { this.silent = false; return }
            const cancel = this.el.getAttribute("data-cancel")
            if (cancel) this.js().exec(cancel)
          })
          this.sync()
        },
        updated() { this.sync() },
        sync() {
          const show = this.el.getAttribute("data-show")
          if (show === "true" && !this.el.open) this.el.showModal()
          if (show === "false" && this.el.open) { this.silent = true; this.el.close() }
        },
        open(detail) {
          const texts = (detail && detail.text) || {}
          for (const [selector, text] of Object.entries(texts)) {
            const target = this.el.querySelector(selector)
            if (target) target.textContent = text ?? target.dataset.default ?? ""
          }
          if (!this.el.open) this.el.showModal()
        }
      }
    </script>
    """
  end

  defp placement_class(:center), do: "modal-bottom sm:modal-middle"
  defp placement_class(:start), do: "modal-start"
  defp placement_class(:end), do: "modal-end"

  defp show_attr(nil), do: nil
  defp show_attr(show), do: to_string(show)

  @doc """
  The one confirmation dialog per layout for irreversible deletes.

  Render it once in the app layout. Triggers (`<.button confirm>`, list row actions,
  `show_confirm/4`) write their question into it and park their destructive command on its
  confirm button; Cancel, Escape and the backdrop only close. Focus starts on Cancel.

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
        <div class="modal-action">
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
    </dialog>
    """
  end

  @doc """
  A `<details>` disclosure. `variant={:collapse}` (default) draws daisyUI's bordered
  `collapse collapse-arrow`; `variant={:button}` renders the summary as a button (with `icon`)
  for compact "more options" triggers. The summary is at least 44px on touch screens.
  The open state survives LiveView patches.

      <.disclosure id="split-more" summary="Weitere Aufteilungsoptionen">…</.disclosure>
  """
  attr :id, :string, required: true
  attr :summary, :string, required: true
  attr :open, :boolean, default: false
  attr :variant, :atom, default: :collapse, values: [:collapse, :button]
  attr :icon, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def disclosure(%{variant: :button} = assigns) do
    ~H"""
    <details
      id={@id}
      class={@class}
      open={@open}
      phx-mounted={JS.ignore_attributes(["open"])}
      {@rest}
    >
      <summary class="btn"><.icon :if={@icon} name={@icon} />{@summary}</summary>
      <div class="mt-3 text-sm">{render_slot(@inner_block)}</div>
    </details>
    """
  end

  def disclosure(assigns) do
    ~H"""
    <details
      id={@id}
      class={["collapse collapse-arrow border border-base-content/10 bg-base-100", @class]}
      open={@open}
      phx-mounted={JS.ignore_attributes(["open"])}
      {@rest}
    >
      <summary class="collapse-title font-semibold">{@summary}</summary>
      <div class="collapse-content text-sm">{render_slot(@inner_block)}</div>
    </details>
    """
  end
end
