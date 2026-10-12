defmodule Setzkasten.ActionsTest do
  use Setzkasten.ComponentCase, async: true

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
end
