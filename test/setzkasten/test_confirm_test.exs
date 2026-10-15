defmodule Setzkasten.Test.ConfirmTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Setzkasten.Test.Confirm

  @endpoint Setzkasten.Dev.Endpoint

  defmodule ValueLive do
    use Phoenix.LiveView
    use Setzkasten

    def mount(_params, _session, socket), do: {:ok, assign(socket, params: nil)}

    def render(assigns) do
      ~H"""
      <.button id="plain" value="x" confirm="Löschen?" phx-click="delete">Löschen</.button>
      <.button id="mirrored" phx-value-value="y" confirm="Löschen?" phx-click="delete">
        Löschen
      </.button>
      <.confirm_dialog />
      <p id="params">{@params}</p>
      """
    end

    def handle_event("delete", params, socket),
      do:
        {:noreply,
         assign(socket, params: Enum.map_join(params, ",", fn {k, v} -> "#{k}=#{v}" end))}
  end

  test "asked returns the dialog's texts and the parked push" do
    {:ok, view, _} = live(build_conn(), "/screens/posts")
    [id] = Enum.take(for(post <- Setzkasten.Dev.Data.posts(), do: post.id), 1)

    asked = asked(view, "#post-#{id}-delete")
    assert asked.question =~ "löschen?"
    assert asked.text == "Der Post und seine Bilder verschwinden von der Website."
    assert asked.label == nil
    assert [["push", %{"event" => "delete", "value" => %{"id" => ^id}}]] = asked.action
  end

  test "confirm_click runs a confirmed button's push" do
    {:ok, view, _} = live(build_conn(), "/overlays")

    html =
      confirm_click(view, "#delete-demo", "Ausgabe „Wocheneinkauf“ löschen?")

    assert html =~ "Bisher gelöscht (Demo): 1"
  end

  test "confirm_click runs a list row action and a dropdown item" do
    {:ok, view, _} = live(build_conn(), "/screens/posts")
    [first, second | _] = for post <- Setzkasten.Dev.Data.posts(), do: post.id

    confirm_click(view, "#post-#{first}-delete")
    refute has_element?(view, "#post-#{first}")
    confirm_click(view, "#post-#{second}-delete-menu-item")
    refute has_element?(view, "#post-#{second}")
  end

  test "confirm_click skips what only changes the page in the browser" do
    {:ok, view, _} = live(build_conn(), "/overlays")

    assert [
             ["push", %{"event" => "delete"}],
             ["dispatch", %{"event" => "setzkasten:hide-popover"}]
           ] =
             asked(view, "#pop-rename-delete").action

    assert confirm_click(view, "#pop-rename-delete") =~ "Bisher gelöscht (Demo): 1"
  end

  test "confirm_click sends a button's value as the browser does after confirming" do
    {:ok, view, _} = live_isolated(build_conn(), ValueLive)

    confirm_click(view, "#plain")
    assert view |> element("#params") |> render() =~ ~r/>value=x<\/p>/

    confirm_click(view, "#mirrored")
    assert view |> element("#params") |> render() =~ ~r/>value=y<\/p>/
  end

  test "confirm_click keeps a push's target, so a LiveComponent gets it" do
    {:ok, view, _} = live(build_conn(), "/overlays")
    confirm_click(view, "#target-demo > button")
    assert render(view) =~ "In der Komponente gelöscht: 1"
    assert render(view) =~ "Bisher gelöscht (Demo): 0"

    confirm_click(view, "#target-demo-menu button", "Löschen?")
    assert render(view) =~ "In der Komponente gelöscht: 2"
  end

  test "confirm_click submits a confirmed submit button's form with the button" do
    {:ok, view, _} = live(build_conn(), "/overlays")

    assert asked(view, "#import-replace").action == [
             ["dispatch", %{"event" => "setzkasten:confirm-submit", "to" => "#import-replace"}]
           ]

    html =
      confirm_click(view, "#import-replace", nil,
        with: %{import: %{file: "umsaetze-september.ofx"}}
      )

    assert html =~ "„umsaetze-september.ofx“ ersetzt (Demo)"
  end

  test "confirm_click submits for a confirmed submit button without a name" do
    {:ok, view, _} = live(build_conn(), "/overlays")
    assert confirm_click(view, "#close-account") =~ "Konto geschlossen (Demo)."
  end

  test "confirm_click and LiveViewTest's form data set a combobox's value" do
    {:ok, view, _} = live(build_conn(), "/overlays")
    html = confirm_click(view, "#close-account", nil, with: %{close: %{target: "giro"}})
    assert html =~ "Konto geschlossen (Demo), Rest auf „giro“."

    html = view |> form("#close-account-form", close: %{target: "tagesgeld"}) |> render_submit()
    assert html =~ "Konto geschlossen (Demo), Rest auf „tagesgeld“."
  end

  test "asked fails for a trigger that sends its event without asking" do
    {:ok, view, _} = live(build_conn(), "/delights")

    assert_raise ExUnit.AssertionError, ~r/sends its event itself/, fn ->
      asked(view, "#live-up")
    end

    {:ok, view, _} = live(build_conn(), "/overlays")

    assert_raise ExUnit.AssertionError, fn ->
      confirm_click(view, "#import-replace", "Etwas anderes?")
    end

    refute render(view) =~ "ersetzt (Demo)"
  end

  test "close_modal closes natively and sends the modal's on_cancel" do
    {:ok, view, _} = live(build_conn(), "/overlays")
    assert close_modal(view, "#booking-cancel", "booking") =~ "Dialog geschlossen (Demo)."
  end
end
