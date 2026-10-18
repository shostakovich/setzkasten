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
      conn = get(build_conn(), unquote(path))
      assert Plug.Conn.get_resp_header(conn, "content-security-policy") == ["style-src 'self'"]
      {:ok, view, html} = live(conn)
      assert html =~ ~s(id="main")
      refute html =~ ~s(style=")
      assert render(view) =~ "</main>"
    end
  end

  test "the settings screen confirms a save on its button instead of a flash" do
    {:ok, view, _} = live(build_conn(), "/screens/settings")
    html = view |> element("#settings-form") |> render_submit()
    assert_push_event(view, "setzkasten:saved", %{id: "settings-save"})
    refute html =~ "Einstellungen gespeichert"
  end

  test "the feedback page triggers a toast with an action" do
    {:ok, view, _} = live(build_conn(), "/feedback")
    view |> element("#toast-action-demo") |> render_click()
    assert has_element?(view, "#flash-group [role=status] button", "Rückgängig")
    render_click(view, "toast", %{"kind" => "undone"})
    assert has_element?(view, "#flash-group [role=status]", "Bananen wieder auf der Liste")
    refute has_element?(view, "#flash-group [role=status] button")
  end

  test "the delights page changes its live values up and down" do
    {:ok, view, html} = live(build_conn(), "/delights")
    assert html =~ "63.279"
    assert view |> element("#live-up") |> render_click() =~ "63.412"
    assert view |> element("#live-down") |> render_click() =~ "63.279"
    view |> element("#delight-save-form") |> render_submit()
    assert_push_event(view, "setzkasten:saved", %{id: "demo-save"})
  end

  test "delete events from the dialog reach the view" do
    {:ok, view, _} = live(build_conn(), "/overlays")
    assert render(view) =~ "Bisher gelöscht (Demo): 0"
    render_hook(view, "delete", %{"title" => "X"})
    assert render(view) =~ "Bisher gelöscht (Demo): 1"
  end

  test "a confirmed submit button sends its form with its name and value" do
    {:ok, view, _} = live(build_conn(), "/overlays")

    html =
      view
      |> form("#import-form")
      |> put_submitter("#import-replace")
      |> render_submit()

    assert html =~ "ersetzt (Demo)"
  end

  test "a confirm inside a live component parks a push that targets the component's cid" do
    {:ok, view, html} = live(build_conn(), "/overlays")
    doc = LazyHTML.from_document(html)
    [cid] = doc |> LazyHTML.query("#target-demo") |> LazyHTML.attribute("data-phx-component")
    [click] = doc |> LazyHTML.query("#target-demo > button") |> LazyHTML.attribute("phx-click")
    assert [%{"event" => "delete", "target" => target}] = Setzkasten.ComponentCase.pushes(click)
    assert to_string(target) == cid

    view |> with_target("#target-demo") |> render_click("delete", %{})
    assert render(view) =~ "In der Komponente gelöscht: 1"
    assert render(view) =~ "Bisher gelöscht (Demo): 0"
  end

  test "holdings screen filters by depot, marks an account and switches the allocation" do
    {:ok, view, html} = live(build_conn(), "/screens/holdings")
    doc = LazyHTML.from_document(html)

    assert text(doc, "header p") =~
             "2\u00A0Depots\u2060\u00A0· 5\u00A0Wertpapiere\u2060\u00A0· 3\u00A0Konten"

    assert count(doc, "tbody[id^=holdings-]") == 3
    assert count(doc, "#holdings-konten #account-tagesgeld") == 1
    assert total_label(doc) == "Gesamt"
    assert text(doc, "#allocation-rows") =~ "Ohne Angabe"

    doc =
      view |> render_patch("/screens/holdings?d=kinder&k=verrechnung") |> LazyHTML.from_fragment()

    assert count(doc, "tbody[id^=holdings-]") == 1
    assert total_label(doc) == "Kinderdepot"

    assert doc |> LazyHTML.query("#account-verrechnung") |> LazyHTML.attribute("aria-current") ==
             ["true"]

    assert count(doc, "#cost-rows tr[id]") == 2

    doc = view |> render_patch("/screens/holdings?a=anlage") |> LazyHTML.from_fragment()
    assert text(doc, "#allocation-rows") =~ "unter Ziel"
  end

  defp text(doc, selector),
    do: doc |> LazyHTML.query(selector) |> LazyHTML.text() |> String.trim()

  # The holdings table comes before the costs table.
  defp total_label(doc),
    do: doc |> LazyHTML.query("tfoot th") |> Enum.map(&LazyHTML.text/1) |> hd() |> String.trim()

  defp count(doc, selector), do: doc |> LazyHTML.query(selector) |> Enum.count()

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
