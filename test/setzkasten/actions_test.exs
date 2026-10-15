defmodule Setzkasten.ActionsTest do
  use Setzkasten.ComponentCase, async: true

  test "a button's phx-value-value also renders as its value, which LiveView's client sends" do
    assigns = %{}
    doc = parse(~H|<.button phx-click="pick" phx-value-value="a">A</.button>|)
    assert attr(doc, "button", "value") == "a"
    assert attr(doc, "button", "phx-value-value") == "a"

    doc = parse(~H|<.button phx-click="pick" phx-value-value="a" value="b">A</.button>|)
    assert attr(doc, "button", "value") == "b"

    assert attr(parse(~H|<.button navigate="/a" phx-value-value="a">A</.button>|), "a", "value") ==
             nil

    doc = parse(~H|<.button phx-click="pick" phx-value-value="a" confirm="Sicher?">A</.button>|)
    assert attr(doc, "button", "value") == nil
  end

  test "default button is a neutral btn of type button" do
    assigns = %{}
    doc = parse(~H|<.button>Abbrechen</.button>|)
    assert classes(doc, "button") == ["btn"]
    assert attr(doc, "button", "type") == "button"
  end

  test "variants and sizes map to fixed daisyUI classes, class is appended" do
    for {variant, expected} <- [
          primary: ~w(btn-primary),
          ghost: ~w(btn-ghost),
          danger: ~w(btn-error),
          danger_outline: ~w(btn-error btn-outline),
          link: ~w(btn-link)
        ] do
      assigns = %{variant: variant}
      doc = parse(~H|<.button variant={@variant} size={:sm} class="w-full">x</.button>|)
      assert classes(doc, "button") == ["btn"] ++ expected ++ ["btn-sm", "w-full"]
    end
  end

  test "icon-only buttons are square and named" do
    assigns = %{}
    doc = parse(~H|<.button icon="trash-2" icon_only label="Löschen" />|)
    assert "btn-square" in classes(doc, "button")
    assert attr(doc, "button", "aria-label") == "Löschen"
    assert count(doc, "svg.lucide") == 1
  end

  test "icon-only without label raises" do
    assigns = %{}
    assert_raise ArgumentError, fn -> parse(~H|<.button icon="x" icon_only />|) end
  end

  test "loading disables and shows a spinner instead of the icon" do
    assigns = %{}
    doc = parse(~H|<.button icon="plus" loading>Speichert</.button>|)
    assert attr(doc, "button", "disabled") != nil
    assert attr(doc, "button", "aria-busy") == "true"
    assert classes(doc, ".loading") == ~w(loading loading-spinner loading-sm motion-reduce:hidden)
    assert classes(doc, "svg.lucide") == ~w(lucide size-4 motion-safe:hidden)
  end

  test "navigate renders a link styled as button" do
    assigns = %{}
    doc = parse(~H|<.button navigate="/depots" size={:sm}>Alle</.button>|)
    assert attr(doc, "a", "href") == "/depots"
    assert attr(doc, "a", "data-phx-link") == "redirect"
    assert classes(doc, "a") == ["btn", "btn-sm"]
  end

  test "confirm on a link raises instead of navigating without asking" do
    assigns = %{}

    for attrs <- [
          %{href: "/x"},
          %{navigate: "/x"},
          %{patch: "/x"},
          %{href: "/x", method: "delete"}
        ] do
      assigns = Map.put(assigns, :attrs, attrs)

      assert_raise ArgumentError, ~r/<.button confirm> cannot ask before a link/, fn ->
        rendered_to_string(~H|<.button confirm="Löschen?" {@attrs}>x</.button>|)
      end
    end
  end

  test "confirm moves the click into the shared dialog" do
    assigns = %{}

    doc =
      parse(~H"""
      <.button confirm="Löschen?" phx-click="delete" phx-value-id="7">Löschen</.button>
      """)

    click = attr(doc, "button", "phx-click")
    assert attr(doc, "button", "aria-haspopup") == "dialog"
    assert attr(doc, "button", "phx-value-id") == nil
    assert click =~ "setzkasten:show-modal"
    assert click =~ "#confirm-delete-confirm"
    assert click =~ "Löschen?"
    assert [%{"event" => "delete", "value" => %{"id" => "7"}}] = pushes(click)
  end

  test "confirm keeps phx-value-* values as strings, like the browser sends them" do
    assigns = %{}

    doc =
      parse(
        ~H|<.button confirm="Wiederherstellen?" phx-click="restore" phx-value-number={3}>x</.button>|
      )

    assert [%{"value" => %{"number" => "3"}}] = pushes(attr(doc, "button", "phx-click"))
  end

  test "confirm parks a button's value as the client sends it, over a phx-value-value" do
    assigns = %{}
    doc = parse(~H|<.button value="42" phx-click="pick" confirm="Sicher?">x</.button>|)

    assert [%{"event" => "pick", "value" => %{"value" => "42"}}] =
             pushes(attr(doc, "button", "phx-click"))

    doc =
      parse(
        ~H|<.button value="b" phx-value-value="a" phx-value-id="7" phx-click="pick" confirm="?">x</.button>|
      )

    assert [%{"value" => %{"value" => "b", "id" => "7"}}] =
             pushes(attr(doc, "button", "phx-click"))
  end

  test "confirm carries phx-target into the parked push" do
    assigns = %{myself: %Phoenix.LiveComponent.CID{cid: 3}}

    doc =
      parse(~H"""
      <.button confirm="Löschen?" phx-click="delete" phx-target={@myself} phx-value-id="7">
        Löschen
      </.button>
      """)

    assert [%{"event" => "delete", "target" => 3}] = pushes(attr(doc, "button", "phx-click"))
    assert attr(doc, "button", "phx-target") == nil
  end

  test "confirm leaves a %JS{} click and its phx-target alone" do
    assigns = %{}

    doc =
      parse(~H"""
      <.button confirm="Löschen?" phx-click={JS.push("delete")} phx-target="#form">x</.button>
      """)

    assert [push] = pushes(attr(doc, "button", "phx-click"))
    refute Map.has_key?(push, "target")
    assert attr(doc, "button", "phx-target") == "#form"
  end

  test "fab is a floating primary circle, phones only" do
    assigns = %{}
    doc = parse(~H|<.fab navigate="/neu" label="Ausgabe" />|)
    c = classes(doc, "a")
    assert Enum.all?(~w(btn-primary btn-circle fixed md:hidden), &(&1 in c))
    # setzkasten.css hides it while a dialog is open.
    assert "setzkasten-fab" in c
    # 16px above the dock, or above the bottom safe edge without one.
    assert "bottom-[calc(max(var(--setzkasten-dock-offset,0px),env(safe-area-inset-bottom))+1rem)]" in c
    assert "end-[calc(1rem+env(safe-area-inset-right))]" in c
    assert attr(doc, "a", "aria-label") == "Ausgabe"
  end

  test "saved stacks idle, pending and saved labels in one grid cell under the hook" do
    assigns = %{}

    doc =
      parse(~H"""
      <.button
        type="submit"
        id="save"
        variant={:primary}
        icon="check"
        saved
        phx-disable-with="Speichert …"
      >
        Speichern
      </.button>
      """)

    assert attr(doc, "button", "phx-hook") == "Setzkasten.Components.Actions.Saved"
    assert attr(doc, "button", "data-saved-label") == "Gespeichert"
    assert attr(doc, "button", "phx-disable-with") == nil
    assert "setzkasten-saved" in classes(doc, "button")
    assert text(doc, ".setzkasten-saved-idle") == "Speichern"
    assert text(doc, ".setzkasten-saved-pending") == "Speichert …"
    assert text(doc, ".setzkasten-saved-done") == "Gespeichert"
    assert count(doc, ".setzkasten-saved-stack > *") == 3
    assert count(doc, ".setzkasten-saved-done svg.lucide") == 1
  end

  test "saved label is overridable and the pending layer is optional" do
    assigns = %{}
    doc = parse(~H|<.button id="s" saved saved_label="Saved">Save</.button>|)
    assert text(doc, ".setzkasten-saved-done") == "Saved"
    assert attr(doc, "button", "data-saved-label") == "Saved"
    assert count(doc, ".setzkasten-saved-pending") == 0
  end

  test "saved needs an id and a button" do
    assigns = %{}
    assert_raise ArgumentError, ~r/needs an id/, fn -> parse(~H|<.button saved>x</.button>|) end

    assert_raise ArgumentError, ~r/not a link/, fn ->
      parse(~H|<.button id="s" saved navigate="/x">x</.button>|)
    end
  end

  test "a button without saved keeps the plain markup" do
    assigns = %{}
    doc = parse(~H|<.button phx-disable-with="…">Speichern</.button>|)
    assert attr(doc, "button", "phx-hook") == nil
    assert attr(doc, "button", "phx-disable-with") == "…"
    assert count(doc, ".setzkasten-saved-stack") == 0
  end

  test "a button with an icon keeps it while phx-disable-with shows its text" do
    assigns = %{}

    doc =
      parse(~H"""
      <.button type="submit" icon="check" phx-disable-with="Speichert …">Speichern</.button>
      """)

    assert attr(doc, "button", "phx-disable-with") == nil
    assert "setzkasten-pending" in classes(doc, "button")
    assert count(doc, ".setzkasten-saved-idle svg.lucide") == 1
    assert text(doc, ".setzkasten-saved-idle") == "Speichern"
    assert text(doc, ".setzkasten-saved-pending") == "Speichert …"
    assert count(doc, ".setzkasten-saved-done") == 0

    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    assert css =~
             ":is(.setzkasten-saved, .setzkasten-pending):is(.phx-submit-loading, .phx-click-loading)"
  end

  test "a clicked pending button looks disabled until the reply" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    assert css =~
             ~r/\.btn\.setzkasten-pending\.phx-click-loading \{\s*pointer-events: none;\s*--btn-border: #0000;\s*--btn-noise: none;\s*--btn-fg: color-mix\(in oklch, var\(--color-base-content\) 20%, #0000\);\s*&:not\(\.btn-link, \.btn-ghost\) \{\s*background-color: color-mix\(in oklab, var\(--color-base-content\) 10%, transparent\);/
  end

  test "an empty or bare phx-disable-with keeps the icon and label, nil drops it" do
    assigns = %{}

    for doc <- [
          parse(~H|<.button icon="check" phx-click="go" phx-disable-with="">Los</.button>|),
          parse(~H|<.button icon="check" phx-click="go" phx-disable-with>Los</.button>|)
        ] do
      assert attr(doc, "button", "phx-disable-with") == nil
      assert "setzkasten-pending" in classes(doc, "button")
      assert count(doc, ".setzkasten-saved-idle svg.lucide") == 1
      assert count(doc, ".setzkasten-saved-pending") == 0
      assert text(doc, "button") == "Los"
    end

    doc = parse(~H|<.button icon="check" phx-click="go" phx-disable-with={nil}>Los</.button>|)
    assert attr(doc, "button", "phx-disable-with") == nil
    refute "setzkasten-pending" in classes(doc, "button")
    assert count(doc, ".setzkasten-saved-stack") == 0
  end

  test "an icon-only button takes no phx-disable-with text" do
    assigns = %{}

    assert_raise ArgumentError, ~r/<.button icon_only> takes no phx-disable-with text/, fn ->
      parse(~H"""
      <.button
        icon="trash-2"
        icon_only
        label="Löschen"
        phx-click="delete"
        phx-disable-with="Löscht …"
      />
      """)
    end

    doc =
      parse(~H"""
      <.button icon="trash-2" icon_only label="Löschen" phx-click="delete" phx-disable-with="" />
      """)

    assert attr(doc, "button", "aria-label") == "Löschen"
    assert count(doc, ".setzkasten-saved-idle svg.lucide") == 1
  end

  test "push_saved pushes the saved event for the button id" do
    socket = %Phoenix.LiveView.Socket{}
    socket = push_saved(socket, "save")

    assert socket.private.live_temp.push_events == [["setzkasten:saved", %{id: "save"}]]
  end

  test "confirm on a submit button asks first, then submits the button's form" do
    assigns = %{}

    doc =
      parse(~H"""
      <.button
        type="submit"
        id="replace"
        name="mode"
        value="replace"
        form="import"
        confirm="Alle ersetzen?"
        confirm_label="Ersetzen"
      >Ersetzen</.button>
      """)

    assert attr(doc, "button", "type") == "submit"
    assert attr(doc, "button", "name") == "mode"
    assert attr(doc, "button", "form") == "import"
    assert attr(doc, "button", "aria-haspopup") == "dialog"
    assert attr(doc, "button", "phx-hook") == "Setzkasten.Components.Actions.ConfirmSubmit"
    assert pushes(attr(doc, "button", "phx-click")) == []

    ops = Jason.decode!(attr(doc, "button", "phx-click"))

    assert ["set_attr", %{"attr" => ["data-confirm-action", action]}] =
             Enum.find(ops, &match?(["set_attr", %{"attr" => ["data-confirm-action", _]}], &1))

    assert Jason.decode!(action) == [
             ["dispatch", %{"event" => "setzkasten:confirm-submit", "to" => "#replace"}]
           ]

    hook = colocated_js("Setzkasten.Components.Actions")
    assert hook =~ ~s|this.el.addEventListener("click", (e) => e.preventDefault())|
    assert hook =~ "this.el.form.requestSubmit(this.el)"
  end

  test "a confirmed submit button with phx-click pushes it before submitting" do
    assigns = %{}

    doc =
      parse(~H"""
      <.button type="submit" id="s" confirm="?" phx-click="mark" phx-value-id="7">x</.button>
      """)

    [_, %{"attr" => [_, action]}] =
      doc
      |> attr("button", "phx-click")
      |> Jason.decode!()
      |> Enum.filter(&match?(["set_attr", %{"attr" => ["data-confirm-action", _]}], &1))
      |> hd()

    assert [["push", %{"event" => "mark", "value" => %{"id" => "7"}}], ["dispatch", _]] =
             Jason.decode!(action)
  end

  test "confirm without a click to park, or beside a hook of its own, raises" do
    assigns = %{}

    assert_raise ArgumentError, ~r/needs a phx-click/, fn ->
      parse(~H|<.button confirm="Löschen?">Löschen</.button>|)
    end

    assert_raise ArgumentError, ~r/takes no phx-hook/, fn ->
      parse(~H|<.button type="submit" id="s" confirm="Senden?" phx-hook="Mine">Senden</.button>|)
    end
  end

  test "a confirmed submit button needs an id and cannot also be saved" do
    assigns = %{}

    assert_raise ArgumentError, ~r/needs an id/, fn ->
      parse(~H|<.button type="submit" confirm="?">x</.button>|)
    end

    assert_raise ArgumentError, ~r/confirm or saved/, fn ->
      parse(~H|<.button type="submit" id="s" confirm="?" saved>x</.button>|)
    end

    # A plain button keeps the click move, without the submit hook.
    doc = parse(~H|<.button id="d" confirm="?" phx-click="delete">x</.button>|)
    assert attr(doc, "button", "phx-hook") == nil
  end

  test "selection bar: count, clear button and actions in a group, a live region for the count" do
    assigns = %{}

    doc =
      parse(~H"""
      <.selection_bar id="sel" count={3} on_clear="clear" phx-target="#list" label="%{count} Buchungen">
        <.button id="approve" size={:sm}>Bestätigen</.button>
      </.selection_bar>
      """)

    assert attr(doc, "#sel-status", "role") == "status"
    assert "sr-only" in classes(doc, "#sel-status")
    assert text(doc, "#sel-status") == "3 Buchungen"
    bar = "#sel .setzkasten-selection-bar"
    assert attr(doc, bar, "hidden") == nil
    assert attr(doc, "#{bar} [role=group]", "aria-labelledby") == "sel-count"
    assert text(doc, "#sel-count") == "3 Buchungen"
    assert attr(doc, "#sel-count", "aria-hidden") == "true"
    assert attr(doc, "#{bar} button[aria-label='Auswahl aufheben']", "type") == "button"

    assert [%{"event" => "clear", "target" => "#list"}] =
             pushes(attr(doc, "#{bar} button[aria-label='Auswahl aufheben']", "phx-click"))

    assert count(doc, "#{bar} #approve") == 1
    # A spacer lets the last rows scroll above the bar.
    assert count(doc, "#sel > div.h-20[aria-hidden]") == 1
  end

  test "selection bar at 0: hidden, the live region kept and empty" do
    assigns = %{}
    doc = parse(~H|<.selection_bar id="sel" count={0} on_clear={JS.push("clear")} />|)
    assert attr(doc, "#sel .setzkasten-selection-bar", "hidden") != nil
    assert text(doc, "#sel-status") == ""
    assert count(doc, "#sel > div.h-20") == 0
    assert text(doc, "#sel-count") == "0 ausgewählt"
  end

  test "a selection bar that hides with focus inside moves focus to the page" do
    assigns = %{}
    doc = parse(~H|<.selection_bar id="sel" count={0} on_clear="clear" />|)
    assert attr(doc, "#sel", "phx-hook") == "Setzkasten.Components.Actions.SelectionBar"

    hook = colocated_js("Setzkasten.Components.Actions")
    assert hook =~ "beforeUpdate() { this.focused = this.el.contains(document.activeElement) }"

    assert hook =~
             ~s|if (!this.focused \|\| !this.el.querySelector(".setzkasten-selection-bar").hidden) return|

    assert hook =~
             ~s|this.el.closest("[data-focus-fallback]") \|\| document.getElementById("main")|
  end

  test "selection bar keeps to the content area, above the dock and the safe area" do
    assigns = %{}
    doc = parse(~H|<.selection_bar id="sel" count={1} on_clear="clear" />|)
    bar = classes(doc, "#sel .setzkasten-selection-bar")

    assert Enum.all?(
             [
               "fixed",
               "start-(--setzkasten-shell-start,0px)",
               "end-0",
               "bottom-[calc(max(var(--setzkasten-dock-offset,0px),env(safe-area-inset-bottom))+1rem)]",
               "pe-[calc(1rem+env(safe-area-inset-right))]"
             ],
             &(&1 in bar)
           )

    doc = parse(~H|<.app_shell layout={:sidebar}><:brand>A</:brand>x</.app_shell>|)
    shell = classes(doc, "#app-shell")
    assert "lg:[--setzkasten-shell-start:16rem]" in shell

    assert "lg:sidebar-collapsed:[--setzkasten-shell-start:calc(4.25rem+env(safe-area-inset-left))]" in shell

    assert "md:[--setzkasten-shell-start:calc(4.25rem+env(safe-area-inset-left))]" in shell

    refute Enum.any?(
             classes(parse(~H|<.app_shell><:brand>A</:brand>x</.app_shell>|), "#app-shell"),
             &(&1 =~ "shell-start")
           )

    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    assert css =~
             ~r/\.setzkasten-selection-bar \.dropdown > \.dropdown-content \{\s*top: auto;\s*bottom: 100%;/

    assert css =~
             ":root:has(.modal[open], .setzkasten-selection-bar:not([hidden])) .setzkasten-fab {"

    assert css =~
             ~r/@starting-style \{\s*\.setzkasten-selection-bar \{\s*opacity: 0;\s*translate: 0 0.5rem;/
  end

  test "a confirmed click parks phx-value-* as a plain button sends them" do
    assigns = %{}

    doc =
      parse(~H"""
      <.button
        confirm="?"
        phx-click="delete"
        phx-value-id={7}
        phx-value-reconciled={false}
        phx-value-note={nil}
        phx-value-all={true}
      >x</.button>
      """)

    assert [%{"event" => "delete", "value" => value}] = pushes(attr(doc, "button", "phx-click"))
    assert value == %{"id" => "7", "all" => ""}

    plain =
      parse(~H"""
      <.button phx-click="delete" phx-value-reconciled={false} phx-value-all={true}>x</.button>
      """)

    assert attr(plain, "button", "phx-value-reconciled") == nil
    assert attr(plain, "button", "phx-value-all") == ""
  end

  test "small buttons set their label in 13px, segmented options too" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    assert css =~ ~r/\.btn-sm \{\s*--fontsize: 0.8125rem;/

    assigns = %{}

    doc =
      parse(~H|<.segmented label="Zeitraum" size={:sm} options={[{"1M", "1m"}]} value="1m" />|)

    assert "btn-sm" in classes(doc, ".join-item")
  end
end
