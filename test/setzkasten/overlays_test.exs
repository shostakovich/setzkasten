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

  test "a side panel keeps its content clear of the top and bottom safe areas" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    assert css =~
             ~r/  :is\(\.modal-start, \.modal-end\) > \.modal-box \{\s*border-top: env\(safe-area-inset-top\) solid transparent;/

    assert css =~
             ~r/:is\(\.modal-start, \.modal-end\) > \.modal-box:not\(\.setzkasten-sidebar\) \{\s*border-bottom: env\(safe-area-inset-bottom\) solid transparent;/
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

  test "focus waits for a confirmed submit button that LiveView disables until the reply" do
    assigns = %{}
    doc = parse(~H|<.confirm_dialog />|)
    # The parked action submits first, so the trigger is already disabled when the dialog closes.
    assert [["exec", _], ["dispatch", %{"event" => "setzkasten:hide-modal"}]] =
             Jason.decode!(attr(doc, "#confirm-delete-confirm", "phx-click"))

    live_view = Application.app_dir(:phoenix_live_view, "priv/static/phoenix_live_view.esm.js")
    assert File.read!(live_view) =~ ~s|var PHX_DISABLED = "data-phx-disabled";|

    hook = colocated_js("Setzkasten.Components.Overlays")

    assert hook =~
             ~s|const pending = (el) => el.isConnected && el.hasAttribute("data-phx-disabled")|

    assert hook =~ "if (!usable(trigger) && !pending(trigger)) {"
    assert hook =~ "if ((active && active !== document.body) || pending(current)) return"
  end

  test "a modal opened from a popover suspends it and brings it back on close" do
    assigns = %{}

    doc =
      parse(~H"""
      <.popover id="p" on_cancel={JS.push("closed")}><:trigger>Auf</:trigger>x</.popover>
      """)

    assert "setzkasten-popover" in classes(doc, "#p")
    assert attr(doc, "#p", "popover") == "auto"

    hook = colocated_js("Setzkasten.Components.Overlays")
    assert hook =~ ~s|document.querySelectorAll(".setzkasten-popover:popover-open")|
    assert hook =~ ~s|this.js().setAttribute(popover, "data-suspended", "")|

    assert hook =~
             ~r/this.el.addEventListener\("close", \(\) => \{\s*this.resume\(\)\s*this.returnFocus\(\)/

    assert hook =~ ~s|popover.dispatchEvent(new CustomEvent("setzkasten:resume-popover"))|
    # A suspended popover runs no on_cancel and returns no focus; its return keeps the old target.
    assert hook =~ ~s|if (!this.el.hasAttribute("data-suspended")) this.cancel()|

    assert hook =~ ~r/if \(e.newState === "open"\) \{\s*if \(this.resuming\) return/
    # The confirmed action may hide it: then it stays closed and focus goes to its trigger.
    assert hook =~
             ~r/hide\(\) \{\s*if \(this.el.hasAttribute\("data-suspended"\)\) \{\s*this.js\(\).removeAttribute\(this.el, "data-suspended"\)\s*this.cancel\(\)/

    assert hook =~ ~s|if (!popover.hasAttribute("data-suspended")) continue|
    assert hook =~ "if (resumed && this.trigger && usable(this.trigger)) this.trigger.focus()"
    assert hook =~ "document.getElementById(popover.dataset.anchor || `${popover.id}-trigger`)"
    assert attr(doc, "#p-trigger", "popovertarget") == "p"
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

    assert css =~
             ~r/\.modal-box:not\(\.setzkasten-sidebar\), \.dropdown-content, \.setzkasten-popover, \.setzkasten-selection-bar\) & \{\s*--btn-bg: var\(--setzkasten-popover-control\);/

    # One plain-button selector for every surface that lifts it.
    assert length(String.split(css, ".btn:not(.btn-ghost, .btn-link, .btn-outline,")) == 2

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

  test "tooltip: daisyUI data-tip, placement, and a hidden copy for the description" do
    assigns = %{}

    doc =
      parse(~H"""
      <.tooltip id="t" text="Zuletzt vor 5 Minuten" placement={:bottom}>
        <.button>Abgleichen</.button>
      </.tooltip>
      """)

    assert classes(doc, "#t") == ~w(tooltip tooltip-bottom)
    assert attr(doc, "#t", "data-tip") == "Zuletzt vor 5 Minuten"
    assert attr(doc, "#t", "phx-hook") == "Setzkasten.Components.Overlays.Tooltip"
    assert attr(doc, "#t-text", "hidden") != nil
    assert text(doc, "#t-text") == "Zuletzt vor 5 Minuten"

    assert classes(parse(~H|<.tooltip id="u" text="x"><b>y</b></.tooltip>|), "#u") ==
             ~w(tooltip tooltip-top)
  end

  test "the tooltip hook describes the first focusable element unless the text is its name" do
    hook = colocated_js("Setzkasten.Components.Overlays")
    assert hook =~ ~s|this.js().setAttribute(target, "aria-describedby", ids.join(" "))|
    assert hook =~ "if (name !== text.textContent.trim()) ids.push(text.id)"
  end

  test "tooltips take the selection fill, the sidebar's own colours in the rail" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    assert css =~ ~r/  \.tooltip \{\s*--tt-bg: var\(--color-selected\);/
    assert css =~ ~r/\.tooltip\[data-tip\]::before \{\s*color: var\(--color-selected-content\);/
    assert css =~ ~r/\.setzkasten-sidebar \.tooltip \{\s*--tt-bg: var\(--color-sidebar-content\);/
  end

  test "popover: a native popover in the top layer, toggled by its trigger" do
    assigns = %{}

    doc =
      parse(~H"""
      <.popover id="p" title="Umbenennen" label="Kategorie" variant={:ghost} trigger_class="btn-sm">
        <:trigger>Lebensmittel</:trigger>
        <input id="p-name" autofocus />
      </.popover>
      """)

    assert "setzkasten-popover-root" in classes(doc, "div:has(> #p)")
    assert "inline-block" in classes(doc, "div:has(> #p)")
    assert attr(doc, "#p-trigger", "popovertarget") == "p"
    assert attr(doc, "#p-trigger", "type") == "button"
    assert attr(doc, "#p-trigger", "aria-label") == "Kategorie"
    assert attr(doc, "#p-trigger", "aria-haspopup") == "dialog"
    assert classes(doc, "#p-trigger") == ~w(btn btn-ghost btn-sm)
    assert count(doc, "#p-trigger svg") == 0
    assert attr(doc, "#p", "popover") == "auto"
    assert attr(doc, "#p", "role") == "dialog"
    assert attr(doc, "#p", "aria-labelledby") == "p-title"
    assert text(doc, "#p-title") == "Umbenennen"
    assert attr(doc, "#p", "phx-hook") == "Setzkasten.Components.Overlays.Popover"
    # LiveView would copy an ignored style back as an attribute, which a strict CSP blocks;
    # the hook places the panel through CSSOM again after each patch instead.
    assert attr(doc, "#p", "phx-mounted") == nil
    assert classes(doc, "#p") == ~w(setzkasten-popover shadow-lg)
    assert attr(doc, "#p", "data-show") == nil
  end

  test "popover placement, server state and an anchor elsewhere" do
    assigns = %{}

    doc =
      parse(~H"""
      <.popover id="p" align={:end} position={:top} chevron show on_cancel={JS.push("closed")}>
        <:trigger>x</:trigger>
        y
      </.popover>
      """)

    assert Enum.all?(
             ~w(setzkasten-popover-end setzkasten-popover-top),
             &(&1 in classes(doc, "#p"))
           )

    assert count(doc, "#p-trigger svg.lucide") == 1
    assert attr(doc, "#p", "data-show") == "true"
    assert [%{"event" => "closed"}] = pushes(attr(doc, "#p", "data-cancel"))

    doc = parse(~H|<.popover id="q" anchor="cell-3" show={false}>y</.popover>|)
    assert count(doc, "#q-trigger") == 0
    assert attr(doc, "#q", "data-anchor") == "cell-3"
    assert attr(doc, "#q", "data-show") == "false"
    # Without a trigger the root takes no room (no gap in a flex row, no blank line).
    assert "contents" in classes(doc, "div:has(> #q)")
    refute "inline-block" in classes(doc, "div:has(> #q)")

    assert_raise ArgumentError, ~r/needs a :trigger or an anchor/, fn ->
      parse(~H|<.popover id="r">y</.popover>|)
    end
  end

  test "show and hide popover dispatch to the popover" do
    alias Setzkasten.Components.Overlays

    assert Jason.decode!(Jason.encode!(Overlays.show_popover("p"))) ==
             [["dispatch", %{"to" => "#p", "event" => "setzkasten:show-popover"}]]

    assert Jason.decode!(Jason.encode!(Overlays.hide_popover("p"))) ==
             [["dispatch", %{"to" => "#p", "event" => "setzkasten:hide-popover"}]]
  end

  test "the popover hook syncs server state, runs on_cancel and places without anchor positioning" do
    hook = colocated_js("Setzkasten.Components.Overlays")
    assert hook =~ ~s|if (show === "false" && this.isOpen()) { this.silent = true; this.hide() }|
    # Popover and modal follow a change of show, so a dismissed one does not reopen on any patch.
    assert hook
           |> String.split(
             ~r/if \(show === this.shown\) return\s*this.shown = show\s*if \(show === "true"\) this.show\(\)/
           )
           |> length() == 3

    assert hook =~ ~s|const cancel = this.el.getAttribute("data-cancel")|
    # on_cancel runs synchronously on close, before another popover's open is pushed.
    assert hook =~
             ~r/addEventListener\("beforetoggle", \(e\) => \{\s*if \(e.newState === "open"\) \{[^}]*\}\s*if \(!this.el.hasAttribute\("data-suspended"\)\) this.cancel\(\)/

    assert hook =~
             ~r/\} else \{\s*this.stopTracking\(\)\s*if \(!this.el.hasAttribute\("data-suspended"\)\) this.returnFocus\(\)\s*\}/

    assert hook =~ ~s|CSS.supports("anchor-scope: all")|
    assert hook =~ ~s|(NATIVE && !this.el.hasAttribute("data-anchor"))|
    # A click on the anchor of an open popover closes it and does not reopen it.
    assert hook =~ ~s|if (anchor && anchor.contains(e.target)) this.swallow = e.timeStamp|
    assert hook =~ ~s|document.addEventListener("click", this.onClick, true)|
    # A popover removed while open (:if) fires no toggle; focus goes back all the same.
    assert hook =~
             ~r/destroyed\(\) \{\s*this.stopTracking\(\)\s*document.removeEventListener\("click", this.onClick, true\)\s*this.returnFocus\(\)/

    # Focus goes back after a submit inside, not after a click outside.
    assert hook =~ "if (this.byPointer || !target || !target.isConnected) return"

    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    assert css =~ ~r/\.setzkasten-popover-root \{\s*anchor-scope: --setzkasten-popover;/

    assert css =~
             ~r/\.setzkasten-popover-root > \[popovertarget\] \{\s*anchor-name: --setzkasten-popover;/

    assert css =~ "position-area: block-end span-inline-end;"
    assert css =~ "position-try-fallbacks: flip-block, flip-inline, flip-block flip-inline;"
    # Below sm a bottom sheet, sliding in as the modal's sheet does; reduced motion fades.
    assert css =~
             ~r/@media \(width < 40rem\) \{\s*\.setzkasten-popover\[popover\] \{\s*position-area: none;\s*inset: auto 0 0 0;/

    assert css =~ ~r/\.modal \.modal-box,\s*\.setzkasten-popover\[popover\],/
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

  test "a disclosure's summary may be markup in the :title slot" do
    assigns = %{}

    doc =
      parse(~H"""
      <.disclosure id="d" count={2}>
        <:title>Überzogen <.amount value={-4_210} tone /></:title>
        x
      </.disclosure>
      """)

    assert text(doc, "summary data") == "−42,10\u00A0€"
    assert "text-error-ink" in classes(doc, "summary data")
    assert text(doc, "summary span.tabular-nums") == "2"

    doc =
      parse(~H"""
      <.disclosure id="b" variant={:button}><:title><b>Mehr</b></:title>x</.disclosure>
      """)

    assert text(doc, "summary b") == "Mehr"

    assert text(parse(~H|<.disclosure id="s" summary="Text">x</.disclosure>|), "summary") ==
             "Text"

    assert_raise ArgumentError, ~r/needs a summary/, fn ->
      parse(~H|<.disclosure id="n">x</.disclosure>|)
    end
  end

  test "the page keeps its scrollbar's room, so an open modal shifts nothing" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    assert css =~ ~r/@layer utilities\.setzkasten \{\s*:root \{\s*scrollbar-gutter: stable;/
  end
end
