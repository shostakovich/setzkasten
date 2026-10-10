defmodule Setzkasten.CatalogTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint Setzkasten.Dev.Endpoint

  paths =
    Enum.map(Setzkasten.Dev.CatalogLive.pages(), fn {slug, _} -> "/" <> slug end) ++
      Enum.map(Setzkasten.Dev.ScreenLive.screens(), fn {slug, _} -> "/screens/" <> slug end)

  for path <- paths do
    test "catalog page #{path} renders" do
      {:ok, view, html} = live(build_conn(), unquote(path))
      assert html =~ ~s(id="main")
      refute html =~ ~s(style=")
      assert render(view) =~ "</main>"
    end
  end

  test "delete events from the dialog reach the view" do
    {:ok, view, _} = live(build_conn(), "/overlays")
    assert render(view) =~ "Bisher gelöscht (Demo): 0"
    render_hook(view, "delete", %{"title" => "X"})
    assert render(view) =~ "Bisher gelöscht (Demo): 1"
  end

  test "form pattern validates on change" do
    {:ok, view, html} = live(build_conn(), "/forms")
    assert html =~ "2 Felder sind noch nicht richtig"

    html =
      view
      |> form("#expense-form", expense: %{title: "Einkauf", amount: "12,00"})
      |> render_change()

    refute html =~ "Felder sind noch nicht richtig"
  end
end
