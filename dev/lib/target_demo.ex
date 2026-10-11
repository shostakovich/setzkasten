defmodule Setzkasten.Dev.TargetDemo do
  @moduledoc false
  # A live component whose confirmed delete must come back to itself, not to the page.
  use Phoenix.LiveComponent
  use Setzkasten

  @impl true
  def mount(socket), do: {:ok, assign(socket, deleted: 0)}

  @impl true
  def handle_event("delete", _params, socket), do: {:noreply, update(socket, :deleted, &(&1 + 1))}

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="flex flex-wrap items-center gap-3">
      <.button
        variant={:danger_outline}
        icon="trash-2"
        confirm="Eintrag in der Komponente löschen?"
        phx-click="delete"
        phx-target={@myself}
      >
        Löschen
      </.button>
      <.dropdown
        id={"#{@id}-menu"}
        label="Aktionen"
        variant={:ghost}
        chevron={false}
        trigger_class="btn-square"
      >
        <:trigger><.icon name="ellipsis-vertical" /></:trigger>
        <:item on_click="delete" phx-target={@myself} icon="trash-2" danger confirm="Löschen?">
          Löschen
        </:item>
      </.dropdown>
      <span id={"#{@id}-count"} class="text-sm text-base-content/70">
        In der Komponente gelöscht: {@deleted}
      </span>
    </div>
    """
  end
end
