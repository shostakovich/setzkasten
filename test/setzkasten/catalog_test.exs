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

  test "the actions page shows the shopping screen in one phone frame" do
    {:ok, view, _} = live(build_conn(), "/actions")
    assert has_element?(view, ~s|#composer iframe[src="/screens/shopping"][width="390"]|)
    refute has_element?(view, ~s|#composer iframe[src="/screens/shopping"]:not([width="390"])|)
  end

  test "the budget screen moves an account within its group" do
    {:ok, view, _} = live(build_conn(), "/screens/budget")
    nav = "#app-shell-sidebar-sort"

    view
    |> element(nav)
    |> render_hook("sort_account", %{
      "section" => "Budgetkonten",
      "id" => "ruecklage",
      "index" => 0
    })

    ids =
      view
      |> render()
      |> LazyHTML.from_document()
      |> LazyHTML.query("#{nav} li[data-sort-section=Budgetkonten]")
      |> LazyHTML.attribute("data-sort-id")

    assert ids == ~w(ruecklage giro karte)
  end

  test "the settings screen confirms a save on its button instead of a flash" do
    {:ok, view, _} = live(build_conn(), "/screens/settings")
    html = view |> element("#settings-form") |> render_submit()
    assert_push_event(view, "setzkasten:saved", %{id: "settings-save"})
    refute html =~ "Einstellungen gespeichert"
  end

  test "the shopping screen checks an item off with an undo toast and adds an entry" do
    {:ok, view, _} = live(build_conn(), "/screens/shopping")
    assert has_element?(view, "#add-entry-bar #add-entry")
    assert has_element?(view, "#shopping[phx-update=stream] #item-1 img.plush.size-8")

    html = view |> element("#item-1 button") |> render_click()
    refute has_element?(view, "#item-1")
    assert has_element?(view, "#recent li:first-child#recent-1")
    assert html =~ "Bananen abgehakt"
    assert has_element?(view, "#flash-group [role=status] button", "Rückgängig")

    render_click(view, "uncheck", %{"id" => "1"})
    assert has_element?(view, "#shopping li:first-child#item-1")
    refute has_element?(view, "#recent-1")

    html = view |> form("#add-entry", entry: %{name: "Milch"}) |> render_submit()
    assert html =~ "Milch hinzugefügt"
    assert has_element?(view, "#flash-group [role=status] button", "Angabe")
    assert has_element?(view, "#shopping li", "Milch")
  end

  test "the shopping screen puts a recent item back and checks one off from elsewhere" do
    {:ok, view, _} = live(build_conn(), "/screens/shopping")
    assert has_element?(view, "#recent li.list-row", "Butter")

    view |> element("#recent-13 button") |> render_click()
    assert has_element?(view, "#shopping #item-13", "Butter")
    refute has_element?(view, "#recent-13")

    view |> element("button", "Auf anderem Gerät abhaken") |> render_click()
    refute has_element?(view, "#item-1")
    assert has_element?(view, "#recent-1")
  end

  test "the shopping screen ignores a second undo and details of an unknown entry" do
    {:ok, view, _} = live(build_conn(), "/screens/shopping")
    view |> element("#item-1 button") |> render_click()
    render_click(view, "uncheck", %{"id" => "1"})
    render_click(view, "uncheck", %{"id" => "1"})
    render_click(view, "check", %{"id" => "1"})
    render_click(view, "check", %{"id" => "1"})
    assert has_element?(view, "#recent-1")

    html = render_click(view, "entry_detail", %{"id" => "new-0"})
    refute html =~ "Hier öffnet die App die Angaben"
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
