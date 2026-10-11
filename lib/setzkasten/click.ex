defmodule Setzkasten.Click do
  @moduledoc false
  # The commands behind `on_click`/`phx-click` in the components. Internal: neither
  # `use Setzkasten` nor importing a component module brings these into an app.

  alias Phoenix.LiveView.JS
  import Setzkasten.Components.Overlays, only: [show_confirm: 5]

  # A click given as `%JS{}` or event name; an event name pushes to `target` (e.g. `@myself`)
  # when set, also when it runs from the confirmation dialog. A `%JS{}` carries its own target.
  def click_js(click, target, opts \\ [])
  def click_js(%JS{} = js, _target, _opts), do: js
  def click_js(nil, _target, _opts), do: %JS{}
  def click_js(event, nil, opts) when is_binary(event), do: JS.push(event, opts)

  def click_js(event, target, opts) when is_binary(event),
    do: JS.push(event, [target: target] ++ opts)

  # A dropdown item or list row action: its `on_click`, asked first in the shared confirmation
  # dialog `confirm_id` when it has `confirm`.
  def entry_click(entry, confirm_id) do
    js = click_js(entry[:on_click], entry[:"phx-target"])

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
