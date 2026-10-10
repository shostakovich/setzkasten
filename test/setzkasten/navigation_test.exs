defmodule Setzkasten.NavigationTest do
  use Setzkasten.ComponentCase, async: true

  test "segmented patch mode marks the current link" do
    assigns = %{}

    doc =
      parse(~H"""
      <.segmented
        label="Zeitraum"
        value="1y"
        size={:sm}
        options={[{"1M", "1m", "/?r=1m"}, {"1J", "1y", "/?r=1y"}]}
      />
      """)

    assert attr(doc, "nav", "aria-label") == "Zeitraum"
    assert classes(doc, "a[aria-current=page]") == ~w(join-item btn btn-sm btn-primary)
    assert attr(doc, "a[aria-current=page]", "data-phx-link") == "patch"
  end

  test "segmented button mode uses aria-pressed and phx-value-value" do
    assigns = %{}

    doc =
      parse(~H"""
      <.segmented
        mode={:button}
        label="Ansicht"
        value="list"
        phx-click="view"
        options={[{"Liste", "list"}, {"Karten", "cards"}]}
      />
      """)

    assert attr(doc, "[role=group]", "aria-label") == "Ansicht"
    assert attr(doc, "button[aria-pressed=true]", "phx-value-value") == "list"
    assert attr(doc, "button[aria-pressed=false]", "phx-click") == "view"
  end

  test "segmented radio mode reads the form field" do
    assigns = %{form: to_form(%{"split" => "shares"}, as: :e)}

    doc =
      parse(~H"""
      <.segmented
        mode={:radio}
        label="Aufteilung"
        field={@form[:split]}
        options={[{"Gleich", "equal"}, {"Anteile", "shares"}]}
      />
      """)

    assert text(doc, "legend.sr-only") == "Aufteilung"
    assert attr(doc, "input[value=shares]", "checked") != nil
    assert attr(doc, "input[value=shares]", "name") == "e[split]"
  end

  test "tabs mark the active tab with aria-current only" do
    assigns = %{}

    doc =
      parse(~H"""
      <.tabs label="Bereiche">
        <:tab navigate="/a" active>A</:tab>
        <:tab navigate="/b">B</:tab>
      </.tabs>
      """)

    assert Enum.all?(~w(tabs tabs-border overflow-x-auto), &(&1 in classes(doc, "nav")))
    assert text(doc, "a[aria-current=page]") == "A"
    refute rendered_to_string(~H|<.tabs label="x">
  <:tab navigate="/a" active>A</:tab>
</.tabs>|) =~ "tab-active"
  end

  test "a tab takes extra classes" do
    assigns = %{}

    doc =
      parse(~H"""
      <.tabs label="Bereiche">
        <:tab navigate="/a">A</:tab>
        <:tab navigate="/b" class="ms-auto">B</:tab>
      </.tabs>
      """)

    assert classes(doc, "a[href='/b']") == ~w(tab shrink-0 whitespace-nowrap ms-auto)
  end

  test "dropdown header line and trigger classes" do
    assigns = %{}

    doc =
      parse(~H"""
      <.dropdown id="acc" label="Konto" chevron={false} variant={:ghost} trigger_class="btn-square">
        <:trigger>RC</:trigger>
        <:header>kim@example.com</:header>
        <:item navigate="/s">Einstellungen</:item>
      </.dropdown>
      """)

    assert classes(doc, "summary") == ~w(btn btn-ghost btn-square)
    assert text(doc, "ul > li.menu-title:first-child") == "kim@example.com"
    assert count(doc, "summary svg") == 0
  end

  test "dropdown is a details menu that closes on outside click and escape" do
    assigns = %{}

    doc =
      parse(~H"""
      <.dropdown id="acc" label="Konto" align={:end}>
        <:trigger>RC</:trigger>
        <:item navigate="/s" icon="settings" active>Einstellungen</:item>
        <:item on_click="logout" danger>Abmelden</:item>
      </.dropdown>
      """)

    assert classes(doc, "details") == ~w(dropdown dropdown-end)
    assert attr(doc, "details", "phx-key") == "Escape"
    assert attr(doc, "summary", "aria-label") == "Konto"
    assert attr(doc, "a.menu-active", "aria-current") == "page"
    assert attr(doc, "button.text-error-ink", "phx-click") =~ "logout"
    assert count(doc, "[role=menu]") == 0
  end

  test "dropdown opens upwards, divides items and keeps its own text colour" do
    assigns = %{}

    doc =
      parse(~H"""
      <.dropdown id="acc" label="Konto" position={:top}>
        <:trigger>RC</:trigger>
        <:item navigate="/a">A</:item>
        <:item navigate="/" divider>Alle</:item>
      </.dropdown>
      """)

    assert "dropdown-top" in classes(doc, "details")
    assert Enum.all?(~w(text-base-content font-normal mb-1), &(&1 in classes(doc, "ul")))
    assert classes(doc, "li:first-child") == []
    assert "border-t" in classes(doc, "li:has(a[href='/'])")
  end

  test "dropdown returns focus to its trigger on Escape and after choosing an item" do
    assigns = %{}

    doc =
      parse(~H"""
      <.dropdown id="acc" label="Konto">
        <:trigger>RC</:trigger>
        <:header>kim@example.com</:header>
        <:item patch="/s">Einstellungen</:item>
        <:item on_click="logout">Abmelden</:item>
      </.dropdown>
      """)

    assert attr(doc, "summary", "phx-keydown") =~ "focus_first"
    assert attr(doc, "li button", "phx-keydown") =~ "focus_first"
    assert attr(doc, "li button", "phx-key") == "Escape"
    assert attr(doc, "details", "phx-window-keydown") =~ "remove_attr"
    assert attr(doc, "li a", "phx-click") =~ ~s(["focus_first",{"to":"#acc"}])
    assert attr(doc, "li button", "phx-click") =~ ~s(["focus_first",{"to":"#acc"}])
    assert attr(doc, "li button", "phx-click") =~ "logout"
    assert "menu-title" in classes(doc, "li:first-child")
  end

  test "dropdown items with id, disabled and a confirmation" do
    assigns = %{}

    doc =
      parse(~H"""
      <.dropdown id="more" label="Mehr">
        <:trigger>…</:trigger>
        <:item id="undo" on_click="undo" disabled>Rückgängig</:item>
        <:item id="drop" on_click="delete" danger confirm="Löschen?">Löschen</:item>
      </.dropdown>
      """)

    assert attr(doc, "#undo", "disabled") != nil
    assert "menu-disabled" in classes(doc, "li:has(#undo)")
    assert attr(doc, "#drop", "aria-haspopup") == "dialog"
    assert attr(doc, "#drop", "phx-click") =~ "confirm-delete"
  end

  test "breadcrumbs: parents as links, the current page as heading, back link on phones" do
    assigns = %{}

    doc =
      parse(~H"""
      <.breadcrumbs label="Pfad">
        <:crumb navigate="/">Start</:crumb>
        <:crumb navigate="/posts">Posts</:crumb>
        <:crumb>Winterprojekte</:crumb>
      </.breadcrumbs>
      """)

    assert attr(doc, "nav", "aria-label") == "Pfad"
    assert count(doc, "nav a") == 2
    assert text(doc, "h1[aria-current=page]") == "Winterprojekte"
    # Below sm only the nearest parent stays, with a back chevron instead of the separator.
    assert "max-sm:hidden" in classes(doc, "li:has(a[href='/'])")
    assert "max-sm:before:hidden" in classes(doc, "li:has(a[href='/posts'])")
    assert count(doc, "a[href='/posts'] svg") == 1
    assert "max-sm:sr-only" in classes(doc, "li:has(h1)")
  end

  test "breadcrumbs with the current page only keep it visible on phones" do
    assigns = %{}
    doc = parse(~H|<.breadcrumbs heading={false}>
  <:crumb>Neu</:crumb>
</.breadcrumbs>|)
    assert text(doc, "span[aria-current=page]") == "Neu"
    refute "max-sm:sr-only" in classes(doc, "li")
  end
end
