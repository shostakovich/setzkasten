defmodule Setzkasten.ShellTest do
  use Setzkasten.ComponentCase, async: true

  test "topbar shell: skip link, menu, dock, main" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell current={:a} width={:narrow}>
        <:brand>App</:brand>
        <:nav key={:a} label="A" icon="list" navigate="/a" />
        <:nav key={:b} label="B" plush="cart" navigate="/b" /> Inhalt
      </.app_shell>
      """)

    assert attr(doc, "a[href='#main']", "class") =~ "sr-only"
    assert classes(doc, "main#main") |> Enum.member?("max-w-3xl")
    assert attr(doc, ".menu-horizontal a.menu-active", "aria-current") == "page"
    assert count(doc, "nav.dock a") == 2
    assert attr(doc, "nav.dock a.dock-active", "href") == "/a"
    assert text(doc, "nav.dock a:last-child .dock-label") == "B"
  end

  test "sidebar dock with more than five entries: four and a more button" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar} current={:f} more_label="More">
        <:brand>App</:brand>
        <:nav :for={k <- ~w(a b c d e f)a} key={k} label={"#{k}"} icon="list" navigate={"/#{k}"} /> x
      </.app_shell>
      """)

    assert count(doc, "nav.dock a") == 4
    assert text(doc, "nav.dock button .dock-label") == "More"
    assert attr(doc, "nav.dock button", "phx-click") =~ "app-shell-sidebar"
    # The current page is behind "more", so the button is the active one.
    assert "dock-active" in classes(doc, "nav.dock button")
  end

  test "brand, nav footer and account know where they render" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand :let={place}><span class="brand" id={"brand-#{place}"}>App</span></:brand>
        <:nav_footer :let={place}><span class="foot" id={"foot-#{place}"}>F</span></:nav_footer>
        <:account :let={place}><span class="acc" id={"acc-#{place}"}>A</span></:account>
        <:nav key={:a} label="A" icon="list" navigate="/a" /> x
      </.app_shell>
      """)

    assert Enum.sort(doc |> find(".brand") |> LazyHTML.attribute("id")) == [
             "brand-bar",
             "brand-dialog",
             "brand-sidebar"
           ]

    assert Enum.sort(doc |> find(".foot") |> LazyHTML.attribute("id")) == [
             "foot-dialog",
             "foot-sidebar"
           ]

    # The account sits in the top bar below xl and at the foot of the full sidebar from xl.
    assert Enum.sort(doc |> find(".acc") |> LazyHTML.attribute("id")) == [
             "acc-bar",
             "acc-sidebar"
           ]

    assert count(doc, "aside.xl\\:flex #acc-sidebar") == 1
    assert "xl:hidden" in classes(doc, "header:has(#acc-bar)")
  end

  test "dock can be dropped; then the menu stays on phones" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell dock={false}>
        <:brand>App</:brand><:nav key={:a} label="A" navigate="/a" />x
      </.app_shell>
      """)

    assert count(doc, "nav.dock") == 0
    refute "hidden" in classes(doc, "header nav")
  end

  test "topbar without nav entries renders no menu" do
    assigns = %{}
    doc = parse(~H|<.app_shell dock={false}><:brand>App</:brand>x</.app_shell>|)
    assert count(doc, "header nav") == 0
    assert count(doc, "nav.dock") == 0
  end

  test "sidebar shell: sidebar, rail with tooltips, overlay dialog, sections and amounts" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar} current={:k}>
        <:brand>Depotblick</:brand>
        <:nav key={:o} label="Übersicht" icon="chart-line" navigate="/" />
        <:nav
          key={:k}
          label="Kinderdepot"
          icon="wallet"
          amount={799_483}
          section="Depots"
          navigate="/k"
        /> x
      </.app_shell>
      """)

    assert count(doc, "aside.xl\\:flex") == 1
    assert attr(doc, "aside.md\\:flex a[aria-current=page]", "data-tip") == "Kinderdepot"
    # Sticky makes a stacking context: without a z-index the rail's tooltips end up below
    # positioned page content such as form fields.
    assert "z-30" in classes(doc, "aside.md\\:flex")

    assert attr(doc, "dialog#app-shell-sidebar", "phx-hook") ==
             "Setzkasten.Components.Overlays.Modal"

    assert text(doc, "aside.xl\\:flex li.menu-title") == "Depots"
    assert text(doc, "aside.xl\\:flex a[aria-current=page]") =~ "7.994,83"
  end

  test "topbar brand shrinks before the account instead of wrapping the bar" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell dock={false}>
        <:brand><span class="truncate">A long brand</span></:brand>
        <:account>acc</:account>
        x
      </.app_shell>
      """)

    brand = classes(doc, ".navbar > div:first-child")
    assert Enum.all?(~w(min-w-0 *:min-w-0 max-md:flex-1), &(&1 in brand))
    assert "shrink-0" in classes(doc, ".navbar > div.ms-auto")
  end

  test "a page bar takes the brand's place, sticks and stays from xl without the account" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand><span class="brand">App</span></:brand>
        <:account :let={place}><span class="acc" id={"acc-#{place}"}>A</span></:account>
        <:bar><span class="page-bar">Posts › Winter</span></:bar>
        <:nav key={:a} label="A" icon="list" navigate="/a" /> x
      </.app_shell>
      """)

    header = classes(doc, "header:has(.page-bar)")
    assert "sticky" in header
    refute "xl:hidden" in header
    assert count(doc, "header .brand") == 0
    assert count(doc, "aside .brand") == 1
    assert "xl:hidden" in classes(doc, "header div:has(> #acc-bar)")
  end
end
