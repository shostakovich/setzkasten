defmodule Setzkasten.OverlaysTest do
  use Setzkasten.ComponentCase, async: true

  test "the click helpers stay out of the component modules" do
    for module <- Setzkasten.component_modules(), fun <- [:click_js, :entry_click] do
      refute Enum.any?(module.__info__(:functions), &(elem(&1, 0) == fun))
    end
  end

  test "modal is a native dialog with the colocated hook" do
    assigns = %{}

    doc =
      parse(~H"""
      <.modal id="m" title="Buchung" on_cancel={JS.patch("/k")}>
        Body<:actions><.button>OK</.button></:actions>
      </.modal>
      """)

    assert classes(doc, "dialog") == ~w(modal modal-bottom sm:modal-middle)
    assert attr(doc, "dialog", "phx-hook") == "Setzkasten.Components.Overlays.Modal"
    assert attr(doc, "dialog", "aria-labelledby") == "m-title"
    assert attr(doc, "dialog", "data-cancel") =~ "patch"
    assert attr(doc, "dialog", "data-show") == nil
    assert count(doc, "form.modal-backdrop[method=dialog]") == 1
    assert count(doc, ".modal-action .btn") == 1
  end

  test "a scrolling dialog focuses its first field, not the box" do
    hook = colocated_js("Setzkasten.Components.Overlays")
    assert hook =~ "[box, this.el].includes(document.activeElement)) focusIn(box)"

    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    assert css =~ ~r/\.modal-box:focus-visible \{\s*outline: none;/
  end

  test "side panel placement and server-driven show" do
    assigns = %{}
    doc = parse(~H|<.modal id="p" placement={:end} show>Body</.modal>|)
    assert "modal-end" in classes(doc, "dialog")
    assert attr(doc, "dialog", "data-show") == "true"
    assert attr(doc, ".modal-box form button", "aria-label") == "Schließen"

    doc = parse(~H|<.modal id="p" placement={:start} close_button={false}>Body</.modal>|)
    assert count(doc, ".modal-box form") == 0
    assert count(doc, ".modal-box > div:first-child:not(:has(*))") == 0
  end

  test "show and hide modal dispatch to the dialog" do
    assert Jason.encode!(Setzkasten.Components.Overlays.show_modal("m")) =~
             "setzkasten:show-modal"

    assert Jason.encode!(Setzkasten.Components.Overlays.hide_modal("m")) =~ "#m"
  end

  test "confirm dialog: cancel focused first, destructive action executed from its attribute" do
    assigns = %{}
    doc = parse(~H|<.confirm_dialog />|)
    assert attr(doc, "dialog", "id") == "confirm-delete"
    assert attr(doc, ".modal-action button:first-child", "autofocus") != nil
    assert classes(doc, "#confirm-delete-confirm") == ~w(btn btn-error)
    assert attr(doc, "#confirm-delete-confirm", "phx-click") =~ "data-confirm-action"
    assert attr(doc, "#confirm-delete-title", "phx-update") == "ignore"
    assert text(doc, "#confirm-delete-confirm-label") == "Löschen"
    assert attr(doc, "#confirm-delete-confirm-label", "data-default") == "Löschen"
    assert count(doc, "#confirm-delete-confirm-icon svg.lucide") == 1
  end

  test "show_confirm with a label hides the trash icon, without it shows it again" do
    alias Setzkasten.Components.Overlays

    labelled =
      Jason.encode!(
        Overlays.show_confirm(%JS{}, "c", "Verwerfen?", JS.push("x"), label: "Verwerfen")
      )

    assert labelled =~ ~s("#c-confirm-label":"Verwerfen")
    assert labelled =~ "set_attr"
    assert labelled =~ "#c-confirm-icon"

    plain = Jason.encode!(Overlays.show_confirm(%JS{}, "c", "Löschen?", JS.push("x")))
    assert plain =~ ~s("#c-confirm-label":null)
    assert plain =~ "remove_attr"
  end

  test "disclosure keeps its open state across patches" do
    assigns = %{}
    doc = parse(~H|<.disclosure id="d" summary="Mehr" open>Inhalt</.disclosure>|)
    assert classes(doc, "details") |> Enum.take(2) == ~w(collapse collapse-arrow)
    assert attr(doc, "details", "open") != nil
    assert attr(doc, "details", "phx-mounted") =~ "ignore_attrs"
    assert text(doc, "summary.collapse-title") == "Mehr"

    assert classes(
             parse(~H|<.disclosure id="b" summary="x" variant={:button}>y</.disclosure>|),
             "summary"
           ) == ["btn"]
  end

  test "dialog titles and texts break long strings" do
    assigns = %{}
    modal = parse(~H|<.modal id="m" title="T">x</.modal>|)
    assert "wrap-anywhere" in classes(modal, "h2")

    confirm = parse(~H|<.confirm_dialog />|)
    assert "wrap-anywhere" in classes(confirm, "h2")
    assert "wrap-anywhere" in classes(confirm, "p")
  end

  test "neutral controls step up one level on the dark popover surface" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    assert css =~ "--setzkasten-popover-control: var(--color-base-200);"
    # Both ways into dark (system and explicit choice).
    assert length(String.split(css, "--setzkasten-popover-control: var(--color-base-300);")) == 3
    assert css =~ ~r/\.modal-box:not\(\.setzkasten-sidebar\), \.dropdown-content\)\s+\.btn:not\(/

    assert css =~
             ".file-input::file-selector-button {\n    --btn-bg: var(--setzkasten-popover-control);"
  end

  test "a disclosure's count is a quiet number after the summary" do
    assigns = %{}
    doc = parse(~H|<.disclosure id="d" summary="Ausgemustert" count={2}>x</.disclosure>|)
    assert text(doc, "summary span.tabular-nums") == "2"
    assert "text-base-content/70" in classes(doc, "summary span")
    refute text(doc, "summary") =~ "("

    doc =
      parse(~H|<.disclosure id="d" summary="Mehr" variant={:button} count={0}>x</.disclosure>|)

    assert text(doc, "summary span.tabular-nums") == "0"

    assert count(parse(~H|<.disclosure id="d" summary="Mehr">x</.disclosure>|), "summary span") ==
             0
  end

  test "show_confirm takes options last without a JS, or a JS first" do
    alias Setzkasten.Components.Overlays
    action = JS.push("delete")
    with_opts = Overlays.show_confirm("c", "Löschen?", action, text: "Weg ist weg.")
    assert Jason.encode!(with_opts) =~ ~s("#c-text":"Weg ist weg.")

    assert with_opts ==
             Overlays.show_confirm(%JS{}, "c", "Löschen?", action, text: "Weg ist weg.")

    assert Overlays.show_confirm("c", "Löschen?", action) ==
             Overlays.show_confirm(%JS{}, "c", "Löschen?", action)

    piped = JS.push("before") |> Overlays.show_confirm("c", "Löschen?", action)
    assert [["push", %{"event" => "before"}] | _] = Jason.decode!(Jason.encode!(piped))
  end
end
