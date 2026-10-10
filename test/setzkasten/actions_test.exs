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
    assert count(doc, ".loading-spinner") == 1
    assert count(doc, "svg") == 0
  end

  test "navigate renders a link styled as button" do
    assigns = %{}
    doc = parse(~H|<.button navigate="/depots" size={:sm}>Alle</.button>|)
    assert attr(doc, "a", "href") == "/depots"
    assert attr(doc, "a", "data-phx-link") == "redirect"
    assert classes(doc, "a") == ["btn", "btn-sm"]
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
    [_, %{"attr" => [_, action]}] = click |> Jason.decode!() |> Enum.at(0)
    assert [["push", %{"event" => "delete", "value" => %{"id" => "7"}}]] = Jason.decode!(action)
  end

  test "confirm keeps phx-value-* values as strings, like the browser sends them" do
    assigns = %{}

    doc =
      parse(
        ~H|<.button confirm="Wiederherstellen?" phx-click="restore" phx-value-number={3}>x</.button>|
      )

    [_, %{"attr" => [_, action]}] =
      doc |> attr("button", "phx-click") |> Jason.decode!() |> Enum.at(0)

    assert [["push", %{"value" => %{"number" => "3"}}]] = Jason.decode!(action)
  end

  test "fab is a floating primary circle, phones only" do
    assigns = %{}
    doc = parse(~H|<.fab navigate="/neu" label="Ausgabe" />|)
    c = classes(doc, "a")
    assert Enum.all?(~w(btn-primary btn-circle fixed md:hidden), &(&1 in c))
    assert attr(doc, "a", "aria-label") == "Ausgabe"
  end
end
