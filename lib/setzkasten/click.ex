defmodule Setzkasten.Click do
  @moduledoc false
  # The commands behind `on_click`/`phx-click` in the components. Internal: neither
  # `use Setzkasten` nor importing a component module brings these into an app.

  alias Phoenix.LiveView.JS
  import Setzkasten.Components.Overlays, only: [show_confirm: 5]

  # A click given as `%JS{}` or event name.
  def click_js(%JS{} = js), do: js
  def click_js(nil), do: %JS{}
  def click_js(event) when is_binary(event), do: JS.push(event)

  # A dropdown item or list row action: its `on_click`, asked first in the shared confirmation
  # dialog `confirm_id` when it has `confirm`.
  def entry_click(entry, confirm_id) do
    js = click_js(entry[:on_click])

    if entry[:confirm] do
      show_confirm(%JS{}, confirm_id, entry[:confirm], js,
        text: entry[:confirm_text],
        label: entry[:confirm_label]
      )
    else
      js
    end
  end
end
