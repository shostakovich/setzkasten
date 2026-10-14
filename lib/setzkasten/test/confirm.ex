defmodule Setzkasten.Test.Confirm do
  @moduledoc """
  Drives the shared confirmation dialog (`Setzkasten.Components.Overlays.confirm_dialog/1`)
  and modals in `Phoenix.LiveViewTest`, so tests need not know the dialog's internals.

  A trigger with `confirm` (`<.button>`, also `type="submit"`, a dropdown `:item`, a
  `list_row` `:action`, `show_confirm/5`) does not send its event: its `phx-click` writes the
  question into the dialog, parks the command on the dialog's confirm button and opens it, all
  in the browser. `asked/3` returns what the dialog would show and fails when the trigger sends
  its event itself; `confirm_click/4` then runs the parked command as the confirm button would:
  a push goes to its `target` (a LiveComponent's `@myself`), a confirmed submit button submits
  its form, with the button as submitter when it has a `name` (without one it adds nothing to
  the form data, and LiveViewTest takes only named submitters).

  For test code only; it needs `lazy_html`, which `Phoenix.LiveViewTest` needs too.

      import Setzkasten.Test.Confirm

      test "deletes after asking", %{conn: conn} do
        {:ok, view, _html} = live(conn, ~p"/posts")
        assert asked(view, "#post-1-delete").question == "„Winter“ löschen?"
        confirm_click(view, "#post-1-delete")
        refute has_element?(view, "#post-1")
      end

  The dialog id defaults to `"confirm-delete"`; pass `dialog: id` for another. The dialog must
  render inside the LiveView (the app layout, not the root layout), where the view's
  `has_element?/2` sees it.
  """
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  @compile {:no_warn_undefined, LazyHTML}

  @doc """
  Clicks the trigger `selector`, asserts that it asks (with `question` when given) and confirms:
  runs the parked command. Returns what the last `render_click/3` or `render_submit/2` returns
  (HTML or a redirect error tuple).

  Pushes run with the values the browser sends (an empty `"value"`, the confirm button's, under
  the parked ones), a confirmed submit as a submit; commands that only change the page in the browser
  (`JS.hide/1`, `hide_popover/1`, classes, attributes, focus) are skipped. `JS.navigate/1`,
  `JS.patch/1` and `JS.exec/1` fail the test: it cannot follow them.

  Options: `dialog:` (the confirm dialog's id), `with:` (form data for a confirmed submit, merged
  as `render_submit/2` does, e.g. a combobox's value).
  """
  def confirm_click(view, selector, question \\ nil, opts \\ []) do
    asked = asked(view, selector, opts)
    if question, do: assert(asked.question == question)
    dialog = Keyword.get(opts, :dialog, "confirm-delete")
    assert has_element?(view, "dialog##{dialog} ##{dialog}-confirm")

    case asked.action do
      [] -> flunk("#{selector} parks no command on the confirm dialog")
      ops -> Enum.reduce(ops, nil, fn op, html -> run(view, op, selector, opts) || html end)
    end
  end

  @doc """
  What the dialog would show for the trigger `selector`, and the parked command:
  `%{question:, text:, label:, action:}` (`label` is nil for the dialog's own one; `action` the
  decoded JS ops). Fails when the trigger sends an event itself.
  """
  def asked(view, selector, opts \\ []) do
    dialog = Keyword.get(opts, :dialog, "confirm-delete")
    ops = view |> element(selector) |> render() |> ops("phx-click", selector)

    refute Enum.any?(ops, &match?(["push", _], &1)),
           "#{selector} sends its event itself instead of leaving it to the confirm dialog"

    action =
      Enum.find_value(ops, fn
        ["set_attr", %{"attr" => ["data-confirm-action", json], "to" => "#" <> to}]
        when to == dialog <> "-confirm" ->
          decode(json)

        _ ->
          nil
      end) || flunk("#{selector} does not park a command on the confirm dialog ##{dialog}")

    texts =
      Enum.find_value(ops, fn
        ["dispatch", %{"event" => "setzkasten:show-modal", "to" => "#" <> ^dialog} = op] ->
          op["detail"]["text"]

        _ ->
          nil
      end) || flunk("#{selector} does not open the confirm dialog ##{dialog}")

    %{
      question: texts["##{dialog}-title"],
      text: texts["##{dialog}-text"],
      label: texts["##{dialog}-confirm-label"],
      action: action
    }
  end

  @doc """
  Clicks `selector`, which closes the modal `id` natively: asserts that the click does only
  that, then sends what the modal's `on_cancel` pushes once it is closed, as the browser would.
  """
  def close_modal(view, selector, id) do
    assert view |> element(selector) |> render() |> ops("phx-click", selector) ==
             [["dispatch", %{"event" => "setzkasten:hide-modal", "to" => "#" <> id}]]

    case view |> element("#" <> id) |> render() |> ops("data-cancel", "#" <> id) do
      [["push", %{"event" => event} = push]] ->
        view |> with_target(push["target"]) |> render_click(event, push["value"] || %{})

      other ->
        flunk("expected the modal's on_cancel to push one event, got: #{inspect(other)}")
    end
  end

  defp run(view, ["push", %{"event" => event} = push], _selector, _opts) do
    value = Map.merge(%{"value" => ""}, push["value"] || %{})
    view |> with_target(push["target"]) |> render_click(event, value)
  end

  defp run(view, ["dispatch", %{"event" => "setzkasten:confirm-submit", "to" => button}], _, opts) do
    html = view |> element(button) |> render()

    form =
      case attribute(html, "form") do
        nil -> "form:has(#{button})"
        id -> "#" <> id
      end

    form = form(view, form)
    form = if attribute(html, "name"), do: put_submitter(form, button), else: form
    render_submit(form, Keyword.get(opts, :with, %{}))
  end

  defp run(_view, [kind, _] = op, selector, _opts) when kind in ~w(navigate patch exec),
    do: flunk("#{selector} parks a command the test cannot run: #{inspect(op)}")

  defp run(_view, _client_only, _selector, _opts), do: nil

  # A plain event name in phx-click is a push of its own.
  defp ops(html, name, selector) do
    case attribute(html, name) do
      nil -> flunk("#{selector} has no #{name}")
      "[" <> _ = json -> decode(json)
      event -> [["push", %{"event" => event}]]
    end
  end

  defp attribute(html, name) do
    case html |> LazyHTML.from_fragment() |> LazyHTML.attribute(name) do
      [value | _] -> value
      [] -> nil
    end
  end

  defp decode(json), do: Phoenix.json_library().decode!(json)
end
