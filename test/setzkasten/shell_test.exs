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

  test "a nav plush without an image falls back to the entry's icon" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell>
        <:brand>App</:brand>
        <:nav key={:a} label="A" plush="missing" icon="list" navigate="/a" />
        <:nav key={:b} label="B" plush="cart" icon="list" navigate="/b" /> Inhalt
      </.app_shell>
      """)

    assert count(doc, "nav.dock a:first-child svg.lucide") == 1
    assert count(doc, "nav.dock a:first-child img") == 0
    assert count(doc, "nav.dock a:last-child img.plush") == 1
    assert count(doc, "nav.dock a:last-child svg") == 0
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

    # The account sits in the top bar below lg and at the foot of the full sidebar from lg.
    assert Enum.sort(doc |> find(".acc") |> LazyHTML.attribute("id")) == [
             "acc-bar",
             "acc-sidebar"
           ]

    assert count(doc, "aside.lg\\:flex #acc-sidebar") == 1
    assert "lg:hidden" in classes(doc, "header:has(#acc-bar)")
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
    nav = classes(doc, "header nav")
    refute "hidden" in nav
    # Edge to edge on phones: out into the navbar's gutter, as wide as the bar.
    assert Enum.all?(~w(setzkasten-scroller snap-x max-sm:-mx-4 max-sm:px-4), &(&1 in nav))
    assert attr(doc, "header nav", "phx-hook") == "Setzkasten.Components.Navigation.ScrollActive"
    assert classes(doc, "header nav li") == ["snap-start"]
  end

  test "the shell keeps to the safe areas of viewport-fit=cover" do
    assigns = %{}
    doc = parse(~H|<.app_shell><:brand>App</:brand>x</.app_shell>|)

    assert Enum.all?(
             ["pl-[env(safe-area-inset-left)]", "pr-[env(safe-area-inset-right)]"],
             &(&1 in classes(doc, "#app-shell"))
           )

    assert "pt-[env(safe-area-inset-top)]" in classes(doc, "header")

    doc = parse(~H|<.app_shell layout={:sidebar}><:brand>App</:brand>x</.app_shell>|)
    assert "max-md:pl-[env(safe-area-inset-left)]" in classes(doc, "#app-shell")
    assert "ps-[env(safe-area-inset-left)]" in classes(doc, "aside.md\\:flex")
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

    assert count(doc, "aside.lg\\:flex") == 1
    assert attr(doc, "aside.md\\:flex a[aria-current=page]", "data-tip") == "Kinderdepot"
    # Sticky makes a stacking context: without a z-index the rail's tooltips end up below
    # positioned page content such as form fields.
    assert "z-30" in classes(doc, "aside.md\\:flex")

    assert attr(doc, "dialog#app-shell-sidebar", "phx-hook") ==
             "Setzkasten.Components.Overlays.Modal"

    assert text(doc, "aside.lg\\:flex li.menu-title") == "Depots"
    assert text(doc, "aside.lg\\:flex a[aria-current=page]") =~ "7.994,83"
  end

  test "sidebar: 16rem from lg, collapsible to the rail, overlay below lg without a ✕" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar} collapse_label="Collapse" expand_label="Expand">
        <:brand>App</:brand>
        <:account :let={place}><span id={"acc-#{place}"}>A</span></:account>
        <:nav key={:a} label="A" icon="list" navigate="/a" /> x
      </.app_shell>
      """)

    for aside <- ["#app-shell-sidebar-full", "#app-shell-rail"] do
      assert attr(doc, aside, "phx-hook") == "Setzkasten.Components.Shell.Sidebar"
    end

    full = classes(doc, "aside#app-shell-sidebar-full")
    assert Enum.all?(~w(hidden lg:flex lg:sidebar-collapsed:hidden w-64), &(&1 in full))
    rail = classes(doc, "aside.md\\:flex")
    assert Enum.all?(~w(lg:hidden lg:sidebar-collapsed:flex), &(&1 in rail))
    assert Enum.all?(~w(lg:hidden lg:sidebar-collapsed:block), &(&1 in classes(doc, "header")))
    assert "w-64" in classes(doc, "dialog#app-shell-sidebar .modal-box")

    collapse = "aside#app-shell-sidebar-full [data-sidebar-toggle=collapse]"
    assert count(doc, "#{collapse}:has(path[d='m16 15-3-3 3-3'])") == 1
    assert attr(doc, collapse, "aria-label") == "Collapse"
    assert attr(doc, collapse, "aria-expanded") == "true"
    assert attr(doc, collapse, "aria-controls") == "app-shell-sidebar-full"

    assert count(
             doc,
             "aside#app-shell-sidebar-full div:has(> #acc-sidebar) + [data-sidebar-toggle=collapse]"
           ) == 1

    # One expand button at the rail's foot; the hook expands in place from lg, opens the dialog below.
    assert count(doc, "aside.md\\:flex button") == 1
    expand = "aside.md\\:flex [data-sidebar-toggle=expand]"
    assert attr(doc, expand, "aria-label") == "Expand"
    assert attr(doc, expand, "aria-expanded") == "false"
    assert attr(doc, expand, "aria-controls") == "app-shell-sidebar-full"
    assert attr(doc, expand, "data-sidebar-dialog") == "app-shell-sidebar"
    assert attr(doc, expand, "phx-mounted") =~ "aria-haspopup"
    assert "mt-auto" in classes(doc, expand)
    refute Enum.any?(~w(lg:hidden max-lg:hidden), &(&1 in classes(doc, expand)))
    assert count(doc, "aside.md\\:flex path[d='m14 9 3 3-3 3']") == 1

    assert count(doc, "dialog#app-shell-sidebar path[d='M18 6 6 18']") == 0
    assert count(doc, "dialog#app-shell-sidebar [data-sidebar-toggle]") == 0
    close = "dialog#app-shell-sidebar form[method=dialog]:not(.modal-backdrop) button"
    assert attr(doc, close, "aria-label") == "Collapse"
    assert count(doc, "#{close} path[d='m16 15-3-3 3-3']") == 1
  end

  test "an entry without a section after a section stands apart" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav key={:o} label="Übersicht" icon="list" navigate="/o" />
        <:nav key={:k} label="Kinderdepot" icon="wallet" section="Depots" navigate="/k" />
        <:nav key={:s} label="Einstellungen" icon="settings" navigate="/s" /> x
      </.app_shell>
      """)

    sidebar = "aside.lg\\:flex"
    assert "mt-4" in classes(doc, "#{sidebar} li:has(> a[href='/s'])")
    refute "mt-4" in classes(doc, "#{sidebar} li:has(> a[href='/o'])")
    refute "mt-4" in classes(doc, "#{sidebar} li:has(> a[href='/k'])")
    assert count(doc, "#{sidebar} li.menu-title") == 1
  end

  test "a nav count is named in words and shows as a badge in the rail and the dock" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav key={:b} label="Buchungen" icon="list" count={2} count_label="neu" navigate="/b" />
        <:nav key={:p} label="Posts" icon="file-text" count={12} navigate="/p" />
        <:nav key={:s} label="Start" icon="house" navigate="/s" /> x
      </.app_shell>
      """)

    for place <- ["aside.lg\\:flex", "aside.md\\:flex", "nav.dock"] do
      assert attr(doc, "#{place} a[href='/b']", "aria-label") == "Buchungen, 2 neu"
      assert attr(doc, "#{place} a[href='/p']", "aria-label") == "Posts, 12"
    end

    # Without a count the link keeps its visible text as name; the rail names it by label.
    assert attr(doc, "aside.lg\\:flex a[href='/s']", "aria-label") == nil
    assert attr(doc, "aside.md\\:flex a[href='/s']", "aria-label") == "Start"

    rail = classes(doc, "aside.md\\:flex a[href='/b'] .indicator-item")
    assert Enum.all?(~w(badge badge-sm bg-sidebar-accent text-sidebar), &(&1 in rail))
    assert text(doc, "aside.md\\:flex a[href='/b'] .indicator-item") == "2"
    assert "badge-primary" in classes(doc, "nav.dock a[href='/b'] .indicator-item")
    assert count(doc, "a[href='/s'] .indicator") == 0
    # The full sidebar keeps the plain number.
    assert count(doc, "aside.lg\\:flex .indicator") == 0
  end

  test "a nav count of 0 shows no badge in the rail and the dock" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav key={:b} label="Buchungen" icon="list" count={0} count_label="neu" navigate="/b" /> x
      </.app_shell>
      """)

    assert count(doc, "a[href='/b'] .indicator") == 0
    assert count(doc, "nav.dock a[href='/b'] svg.lucide") == 1
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

  test "a page bar takes the brand's place, sticks and stays from lg without the account" do
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
    refute "lg:hidden" in header
    assert count(doc, "header .brand") == 0
    assert count(doc, "aside .brand") == 1
    assert "lg:hidden" in classes(doc, "header div:has(> #acc-bar)")
    # Detail pages go back through the bar, without the dock.
    assert count(doc, "nav.dock") == 0
  end

  test "on phones a page bar leaves out the account, its actions take the right edge" do
    for layout <- [:sidebar, :topbar] do
      assigns = %{layout: layout}

      doc =
        parse(~H"""
        <.app_shell layout={@layout}>
          <:brand>App</:brand>
          <:account><span id="acc">A</span></:account>
          <:bar><span class="page-bar">Winter</span></:bar>
          <:bar_actions><button id="more">⋮</button></:bar_actions>
          x
        </.app_shell>
        """)

      assert "max-sm:hidden" in classes(doc, "header div:has(> #acc)")
      refute "max-sm:hidden" in classes(doc, "header div:has(> #more)")
      refute "setzkasten-page-bar" in classes(doc, "header div:has(> #more)")
    end

    assigns = %{}

    without_bar =
      parse(~H"""
      <.app_shell>
        <:brand>App</:brand><:account><span id="acc">A</span></:account>x
      </.app_shell>
      """)

    refute "max-sm:hidden" in classes(without_bar, "header div:has(> #acc)")
  end

  test "a sidebar section title gets room above, unless it is the first entry" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav key={:a} label="A" icon="list" navigate="/a" section="Erste" />
        <:nav key={:b} label="B" icon="list" navigate="/b" section="Zweite" /> x
      </.app_shell>
      """)

    [first, second] = doc |> find("aside.lg\\:flex li.menu-title") |> LazyHTML.attribute("class")
    refute "mt-4" in String.split(first)
    assert "mt-4" in String.split(second)
  end

  test "an entry with rail={false} stays out of the icon rail, groups keep their gap" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav key={:o} label="Übersicht" icon="list" navigate="/o" />
        <:nav key={:b} label="Bestand" icon="list" navigate="/b" />
        <:nav key={:k} label="Kinderdepot" icon="wallet" section="Depots" navigate="/k" rail={false} />
        <:nav key={:s} label="Einstellungen" icon="settings" navigate="/s" /> x
      </.app_shell>
      """)

    rail = "aside.md\\:flex"
    assert count(doc, "#{rail} a[href='/k']") == 0
    assert count(doc, "#{rail} a") == 3
    # The left-out section still separates the groups around it.
    assert "mt-3" in classes(doc, "#{rail} a[href='/s']")
    refute "mt-3" in classes(doc, "#{rail} a[href='/o']")
    refute "mt-3" in classes(doc, "#{rail} a[href='/b']")
    # Everywhere else the entry stays.
    assert count(doc, "aside.lg\\:flex a[href='/k']") == 1
    assert count(doc, "dialog#app-shell-sidebar a[href='/k']") == 1
    assert count(doc, "nav.dock a[href='/k']") == 1
  end
end
