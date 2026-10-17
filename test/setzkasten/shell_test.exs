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
    assert classes(doc, "main#main") |> Enum.member?("mx-auto")
    assert "mx-auto" in classes(doc, "header .navbar")
    assert attr(doc, ".menu-horizontal a.menu-active", "aria-current") == "page"
    assert count(doc, "nav.dock a") == 2
    assert attr(doc, "nav.dock a.dock-active", "href") == "/a"
    assert text(doc, "nav.dock a:last-child .dock-label") == "B"
  end

  test "the top bar row takes bar_width, independent of the page's width" do
    for layout <- [:topbar, :sidebar] do
      assigns = %{layout: layout}

      doc =
        parse(~H"""
        <.app_shell layout={@layout} width={:narrow} bar_width={:wide}>
          <:brand>App</:brand>
          <:nav key={:a} label="A" icon="list" navigate="/a" /> x
        </.app_shell>
        """)

      assert "max-w-7xl" in classes(doc, "header .navbar")
      assert "max-w-3xl" in classes(doc, "main#main")

      doc =
        parse(~H"""
        <.app_shell layout={@layout} width={:narrow}>
          <:brand>App</:brand>
          <:nav key={:a} label="A" icon="list" navigate="/a" /> x
        </.app_shell>
        """)

      assert "max-w-3xl" in classes(doc, "header .navbar")
    end
  end

  test "full-width pages keep a 16px gutter in bar and column, the others widen it" do
    wide_gutter = ~w(px-4 sm:px-6 lg:px-8)

    for layout <- [:topbar, :sidebar] do
      assigns = %{layout: layout}

      doc =
        parse(~H"""
        <.app_shell layout={@layout} width={:full}>
          <:brand>App</:brand>
          <:nav key={:a} label="A" icon="list" navigate="/a" /> x
        </.app_shell>
        """)

      for selector <- ["main#main", "header .navbar"] do
        assert "px-4" in classes(doc, selector)
        refute Enum.any?(~w(sm:px-6 lg:px-8), &(&1 in classes(doc, selector)))
      end

      doc =
        parse(~H"""
        <.app_shell layout={@layout}>
          <:brand>App</:brand>
          <:nav key={:a} label="A" icon="list" navigate="/a" /> x
        </.app_shell>
        """)

      for selector <- ["main#main", "header .navbar"] do
        assert Enum.all?(wide_gutter, &(&1 in classes(doc, selector)))
      end
    end
  end

  test "a full-width top bar's menu bleeds into the 16px gutter below md" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell dock={false} width={:full}>
        <:brand>App</:brand><:nav key={:a} label="A" navigate="/a" />x
      </.app_shell>
      """)

    nav = classes(doc, "header nav")
    assert Enum.all?(["max-md:-mx-4", "max-md:w-[calc(100%+2rem)]", "max-md:px-4"], &(&1 in nav))
    refute "sm:max-md:-mx-6" in nav
  end

  test "the top-bar menu shows a plush at 24px without growing the bar, an icon at 16px" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell>
        <:brand>App</:brand>
        <:nav key={:a} label="A" plush="cart" navigate="/a" />
        <:nav key={:b} label="B" icon="list" navigate="/b" /> x
      </.app_shell>
      """)

    plush = classes(doc, ".menu-horizontal a[href='/a'] img.plush")
    assert Enum.all?(~w(size-6 -my-[1.5px]), &(&1 in plush))
    assert "size-4" in classes(doc, ".menu-horizontal a[href='/b'] svg")
    assert "size-6" in classes(doc, "nav.dock a[href='/a'] img.plush")
    refute "-my-[1.5px]" in classes(doc, "nav.dock a[href='/a'] img.plush")
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
    assert attr(doc, "nav.dock button", "aria-current") == "true"
  end

  test "topbar dock with more than five entries: four and a more sheet with the rest" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell current={:f} more_label="More">
        <:brand>App</:brand>
        <:nav :for={k <- ~w(a b c d e f)a} key={k} label={"#{k}"} icon="list" navigate={"/#{k}"} /> x
      </.app_shell>
      """)

    assert count(doc, "nav.dock a") == 4
    more = "nav.dock button[aria-haspopup=dialog]"
    assert text(doc, "#{more} .dock-label") == "More"
    assert attr(doc, more, "phx-click") =~ "#app-shell-more"
    assert "dock-active" in classes(doc, more)

    sheet = "dialog#app-shell-more"
    assert "modal-bottom" in classes(doc, sheet)
    assert attr(doc, sheet, "aria-labelledby") == "app-shell-more-title"
    assert text(doc, "#{sheet} h2") == "More"
    assert doc |> find("#{sheet} nav a") |> LazyHTML.attribute("href") == ["/e", "/f"]
    assert attr(doc, "#{sheet} a[href='/f']", "aria-current") == "page"
    assert "menu-active" in classes(doc, "#{sheet} a[href='/f']")
    assert attr(doc, "#{sheet} a[href='/e']", "aria-current") == nil

    doc =
      parse(~H"""
      <.app_shell current={:a}>
        <:brand>App</:brand>
        <:nav :for={k <- ~w(a b c d e)a} key={k} label={"#{k}"} icon="list" navigate={"/#{k}"} /> x
      </.app_shell>
      """)

    assert count(doc, "nav.dock a") == 5
    assert count(doc, "nav.dock button") == 0
    assert count(doc, "dialog") == 0
  end

  test "entries left out of the topbar dock are in the more sheet, with icon and count" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell current={:b}>
        <:brand>App</:brand>
        <:nav key={:b} label="Budget" icon="wallet" navigate="/b" />
        <:nav
          id="nav-s"
          key={:s}
          label="Sensoren"
          plush="cart"
          count={2}
          count_label="neu"
          dock={false}
          navigate="/s"
        />
        <:nav key={:n} label="Neu" icon="plus" on_click="new" /> x
      </.app_shell>
      """)

    assert count(doc, "nav.dock a") == 1
    refute "dock-active" in classes(doc, "nav.dock button")

    sheet = "dialog#app-shell-more"
    assert count(doc, "#{sheet} a[href='/b']") == 0
    assert attr(doc, "#{sheet} #nav-s-more", "aria-label") == "Sensoren, 2 neu"
    assert count(doc, "#{sheet} #nav-s-more img.plush") == 1
    assert text(doc, "#{sheet} #nav-s-more .badge") == "2"
    assert [%{"event" => "new"}] = pushes(attr(doc, "#{sheet} li button", "phx-click"))

    doc =
      parse(~H"""
      <.app_shell dock={false}>
        <:brand>App</:brand>
        <:nav key={:b} label="Budget" icon="wallet" navigate="/b" />
        <:nav key={:s} label="Sensoren" icon="list" dock={false} navigate="/s" /> x
      </.app_shell>
      """)

    assert count(doc, "dialog") == 0
  end

  test "the top-bar more sheet: a parent in the dock stands in, button entries close the sheet" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell current={{:account, 1}}>
        <:brand>App</:brand>
        <:nav key={:accounts} label="Konten" icon="landmark" navigate="/k" />
        <:nav
          key={{:account, 1}}
          label="Giro"
          icon="wallet"
          dock={false}
          parent={:accounts}
          navigate="/k/1"
        />
        <:nav id="add" key={:add} label="Neu" on_click="add" phx-target="#a" /> x
      </.app_shell>
      """)

    assert attr(doc, "nav.dock a[href='/k']", "aria-current") == "true"
    refute "dock-active" in classes(doc, "nav.dock button[aria-haspopup]")

    sheet = "dialog#app-shell-more"
    assert attr(doc, "#{sheet} a[href='/k/1']", "aria-current") == "page"
    assert "menu-active" in classes(doc, "#{sheet} a[href='/k/1']")

    [hide, _push] = attr(doc, "#add-more", "phx-click") |> Jason.decode!()
    assert hide == ["dispatch", %{"event" => "setzkasten:hide-modal", "to" => "#app-shell-more"}]
    assert [%{"event" => "add", "target" => "#a"}] = pushes(attr(doc, "#add-more", "phx-click"))
    refute attr(doc, "#add-menu", "phx-click") =~ "hide-modal"
    # One text column: an entry without media keeps the icon's place.
    assert count(doc, "#add-more > span.size-5[aria-hidden]") == 1
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

  test "long nav labels end in an ellipsis, with the full label as title" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav key={:a} label="Gemeinsames Haushaltskonto" icon="wallet" navigate="/a" /> x
      </.app_shell>
      """)

    label = "aside.lg\\:flex a[href='/a'] span[title]"
    assert attr(doc, label, "title") == "Gemeinsames Haushaltskonto"
    assert Enum.all?(~w(min-w-0 flex-1 truncate), &(&1 in classes(doc, label)))
    assert "flex" in classes(doc, "aside.lg\\:flex a[href='/a']")
    assert attr(doc, "aside.lg\\:flex a[href='/a']", "aria-label") == nil

    assert attr(doc, "dialog#app-shell-sidebar a[href='/a'] span[title]", "title") ==
             "Gemeinsames Haushaltskonto"

    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    assert css =~
             ~r/\.setzkasten-sidebar \.tooltip\[data-tip\]::before \{\s*white-space: nowrap;\s*overflow: hidden;\s*text-overflow: ellipsis;/
  end

  test "amount_tone={:negative} tones nav and section amounts as <.amount tone={:negative}>" do
    for tone <- [:negative, false] do
      assigns = %{tone: tone}

      doc =
        parse(~H"""
        <.app_shell layout={:sidebar} amount_tone={@tone}>
          <:brand>App</:brand>
          <:nav
            key={:g}
            label="Giro"
            amount={-1250}
            section="Konten"
            section_amount={-1000}
            navigate="/g"
          />
          <:nav key={:t} label="Tagesgeld" amount={250} section="Konten" navigate="/t" />
          <:nav key={:z} label="Leer" amount={0} section="Konten" navigate="/z" /> x
        </.app_shell>
        """)

      sidebar = "aside.lg\\:flex"

      {negative, positive} =
        if tone,
          do: {"text-sidebar-negative", "text-sidebar-content"},
          else: {"text-sidebar-muted", "text-sidebar-muted"}

      assert negative in classes(doc, "#{sidebar} a[href='/g'] span.tabular-nums")
      assert text(doc, "#{sidebar} a[href='/g'] span.tabular-nums") == "−12,50\u00A0€"
      assert positive in classes(doc, "#{sidebar} a[href='/t'] span.tabular-nums")
      assert "text-sidebar-muted" in classes(doc, "#{sidebar} a[href='/z'] span.tabular-nums")
      assert negative in classes(doc, "#{sidebar} li.menu-title span.tabular-nums")
      assert text(doc, "#{sidebar} li.menu-title span.tabular-nums") == "−10,00\u00A0€"
      assert attr(doc, "#{sidebar} li.menu-title span.truncate", "title") == "Konten"

      assert Enum.all?(
               ~w(flex-row flex-nowrap),
               &(&1 in classes(doc, "#{sidebar} li.menu-title"))
             )
    end

    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    assert length(String.split(css, "--color-sidebar-negative: var(--color-error-ink);")) == 3
    assert css =~ "--color-sidebar-negative: oklch(81.00% 0.095 22.00);"
  end

  test "a section without section_amount shows no total" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav key={:g} label="Giro" amount={100} section="Konten" navigate="/g" /> x
      </.app_shell>
      """)

    assert count(doc, "aside.lg\\:flex li.menu-title span.tabular-nums") == 0
  end

  test "a count next to an amount is a badge, named in words" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav key={:g} label="Giro" amount={-500} count={3} count_label="offen" navigate="/g" />
        <:nav key={:t} label="Tagesgeld" amount={500} count={0} navigate="/t" />
        <:nav key={:b} label="Buchungen" count={4} navigate="/b" /> x
      </.app_shell>
      """)

    sidebar = "aside.lg\\:flex"
    badge = classes(doc, "#{sidebar} a[href='/g'] .badge")
    assert Enum.all?(~w(badge badge-sm bg-sidebar-accent text-sidebar), &(&1 in badge))
    assert text(doc, "#{sidebar} a[href='/g'] .badge") == "3"
    assert attr(doc, "#{sidebar} a[href='/g']", "aria-label") == "Giro, 3 offen, −5,00\u00A0€"
    assert count(doc, "#{sidebar} a[href='/t'] .badge") == 0
    assert text(doc, "#{sidebar} a[href='/t']") =~ "5,00"
    refute text(doc, "#{sidebar} a[href='/t']") =~ "0 "
    # Without an amount the count stays a quiet number.
    assert count(doc, "#{sidebar} a[href='/b'] .badge") == 0
    assert text(doc, "#{sidebar} a[href='/b'] span.tabular-nums") == "4"
  end

  test "a glyph takes the icon's place, hidden from screen readers" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav key={:g} label="Giro" glyph="🏦" navigate="/g" />
        <:nav key={:i} label="Icon" glyph="I" icon="list" navigate="/i" /> x
      </.app_shell>
      """)

    for place <- ["aside.lg\\:flex", "aside.md\\:flex", "nav.dock"] do
      assert text(doc, "#{place} a[href='/g'] span[aria-hidden]") == "🏦"
    end

    assert count(doc, "aside.lg\\:flex a[href='/i'] span[aria-hidden]") == 0
    assert count(doc, "aside.lg\\:flex a[href='/i'] svg.lucide") == 1
  end

  test "an entry with on_click is a quiet button, out of the rail and the dock" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav key={:g} label="Giro" icon="wallet" section="Konten" navigate="/g" />
        <:nav
          key={:add}
          label="Konto hinzufügen"
          icon="plus"
          section="Konten"
          on_click="add_account"
          phx-target="#accounts"
        />
        <:nav key={:js} label="Neu" icon="plus" on_click={JS.push("new")} rail dock /> x
      </.app_shell>
      """)

    sidebar = "aside.lg\\:flex"
    assert text(doc, "#{sidebar} li:nth-child(3) button") == "Konto hinzufügen"

    assert [%{"event" => "add_account", "target" => "#accounts"}] =
             pushes(attr(doc, "#{sidebar} li:nth-child(3) button", "phx-click"))

    assert "text-sidebar-muted" in classes(doc, "#{sidebar} li:nth-child(3) button")
    # Same section: no gap before it.
    refute "mt-4" in classes(doc, "#{sidebar} li:nth-child(3)")
    assert count(doc, "dialog#app-shell-sidebar li button") == 2

    assert count(doc, "aside.md\\:flex button[aria-label='Konto hinzufügen']") == 0
    entry = "nav.dock button:not([aria-haspopup])"
    assert count(doc, entry) == 1
    assert text(doc, "#{entry} .dock-label") == "Neu"
    assert [%{"event" => "new"}] = pushes(attr(doc, entry, "phx-click"))
    assert attr(doc, "aside.md\\:flex button[aria-label=Neu]", "data-tip") == "Neu"
  end

  test "button entries render as buttons in the topbar menu" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell>
        <:brand>App</:brand>
        <:nav key={:a} label="A" icon="list" navigate="/a" />
        <:nav key={:n} label="Neu" icon="plus" on_click="new" /> x
      </.app_shell>
      """)

    assert text(doc, ".menu-horizontal li button") == "Neu"
    assert count(doc, "nav.dock button:not([aria-haspopup])") == 0
    assert count(doc, "nav.dock a") == 1
    assert text(doc, "dialog#app-shell-more li button") == "Neu"
  end

  test "a long nav label does not widen the sidebar's other entries" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav key={:a} label="Gemeinsames Haushaltskonto mit langem Namen" navigate="/a" /> x
      </.app_shell>
      """)

    # daisyUI's menu and items are wrapping flex columns: every line takes the widest item's
    # full width, past the sidebar's edge.
    assert "flex-nowrap" in classes(doc, "aside.lg\\:flex ul.menu")
    assert "flex-nowrap" in classes(doc, "aside.lg\\:flex li:has(> a[href='/a'])")
  end

  test "an entry's id is suffixed with each place it renders in" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav id="nav-giro" key={:g} label="Giro" icon="wallet" navigate="/g" />
        <:nav id="nav-add" key={:add} label="Neu" icon="plus" on_click="add" rail /> x
      </.app_shell>
      """)

    for place <- ~w(sidebar dialog rail dock) do
      assert attr(doc, "#nav-giro-#{place}", "href") == "/g"
    end

    for place <- ~w(sidebar dialog rail), do: assert(count(doc, "button#nav-add-#{place}") == 1)
    assert count(doc, "#nav-add-dock") == 0

    doc =
      parse(~H"""
      <.app_shell>
        <:brand>App</:brand>
        <:nav id="nav-a" key={:a} label="A" icon="list" navigate="/a" /> x
      </.app_shell>
      """)

    assert attr(doc, "#nav-a-menu", "href") == "/a"
    assert attr(doc, "#nav-a-dock", "href") == "/a"
  end

  test "entries left out of the sidebar dock stay reachable through the more button" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar} current={:g}>
        <:brand>App</:brand>
        <:nav key={:b} label="Budget" icon="wallet" navigate="/b" />
        <:nav key={:g} label="Giro" icon="landmark" dock={false} navigate="/g" /> x
      </.app_shell>
      """)

    assert count(doc, "nav.dock a") == 1
    assert attr(doc, "nav.dock button", "phx-click") =~ "app-shell-sidebar"
    assert "dock-active" in classes(doc, "nav.dock button")
    assert count(doc, "dialog#app-shell-more") == 0

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav key={:b} label="Budget" icon="wallet" navigate="/b" /> x
      </.app_shell>
      """)

    assert count(doc, "nav.dock button") == 0
  end

  test "the dock gives way only to fields that bring up the on-screen keyboard" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    # :read-write leaves out sliders, colour and file inputs, buttons, checkboxes and read-only fields.
    assert css =~
             ~s|body:has(:read-write:not([inputmode="none"], [type="date"], [type="time"], [type="datetime-local"], [type="month"], [type="week"]):focus) .dock {\n    display: none;|
  end

  test "a sidebar nav footer brings the more button, so phones reach it in the sidebar" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav_footer><a href="/sync">Sync</a></:nav_footer>
        <:nav key={:b} label="Budget" icon="wallet" navigate="/b" /> x
      </.app_shell>
      """)

    assert count(doc, "nav.dock a") == 1
    assert attr(doc, "nav.dock button", "phx-click") =~ "#app-shell-sidebar"
    refute "dock-active" in classes(doc, "nav.dock button")
    assert count(doc, "dialog#app-shell-sidebar a[href='/sync']") == 1

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav_footer>Sync</:nav_footer>
        <:nav :for={k <- ~w(a b c d e)a} key={k} label={"#{k}"} icon="list" navigate={"/#{k}"} /> x
      </.app_shell>
      """)

    assert count(doc, "nav.dock a") == 4
    assert count(doc, "nav.dock button") == 1

    doc =
      parse(~H"""
      <.app_shell>
        <:brand>App</:brand>
        <:nav_footer>Sync</:nav_footer>
        <:nav key={:b} label="Budget" icon="wallet" navigate="/b" /> x
      </.app_shell>
      """)

    assert count(doc, "nav.dock button") == 0
  end

  test "a sidebar shell without a dock opens the sidebar from the top bar on phones" do
    assigns = %{}

    for doc <- [
          parse(~H"""
          <.app_shell layout={:sidebar} expand_label="Expand">
            <:brand>App</:brand>
            <:nav key={:g} label="Giro" icon="landmark" dock={false} navigate="/g" />
            <:nav key={:t} label="Tagesgeld" icon="wallet" dock={false} navigate="/t" /> x
          </.app_shell>
          """),
          parse(~H"""
          <.app_shell layout={:sidebar} dock={false} expand_label="Expand">
            <:brand>App</:brand>
            <:nav key={:b} label="Budget" icon="wallet" navigate="/b" /> x
          </.app_shell>
          """)
        ] do
      assert count(doc, "nav.dock") == 0
      button = "header .navbar > button:first-child"
      assert attr(doc, button, "aria-label") == "Expand"
      assert attr(doc, button, "aria-haspopup") == "dialog"
      assert attr(doc, button, "phx-click") =~ "#app-shell-sidebar"
      assert "md:hidden" in classes(doc, button)
      assert count(doc, "#{button} path[d='m14 9 3 3-3 3']") == 1
    end

    for doc <- [
          parse(~H"""
          <.app_shell layout={:sidebar}>
            <:brand>App</:brand>
            <:nav key={:b} label="Budget" icon="wallet" navigate="/b" /> x
          </.app_shell>
          """),
          parse(~H"""
          <.app_shell layout={:sidebar} dock={false}>
            <:brand>App</:brand>
            <:bar>Winter</:bar>
            <:nav key={:b} label="Budget" icon="wallet" navigate="/b" /> x
          </.app_shell>
          """)
        ] do
      assert count(doc, "header button") == 0
    end
  end

  test "every dock item has a 24px icon box, so all labels sit on one line" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav key={:a} label="A" plush="cart" navigate="/a" />
        <:nav key={:b} label="B" icon="list" navigate="/b" />
        <:nav key={:g} label="G" glyph="G" navigate="/g" />
        <:nav key={:c} label="C" icon="list" dock={false} navigate="/c" /> x
      </.app_shell>
      """)

    assert "size-6" in classes(doc, "nav.dock a[href='/a'] img.plush")
    assert Enum.all?(~w(size-5 m-0.5), &(&1 in classes(doc, "nav.dock a[href='/b'] svg")))

    assert Enum.all?(
             ~w(size-5 m-0.5),
             &(&1 in classes(doc, "nav.dock a[href='/g'] span[aria-hidden]"))
           )

    assert Enum.all?(
             ~w(size-5 m-0.5),
             &(&1 in classes(doc, "nav.dock button[aria-haspopup] svg"))
           )

    refute "m-0.5" in classes(doc, "aside.lg\\:flex a[href='/b'] svg")
  end

  test "dock labels stay on one line and end in an ellipsis" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav key={:i} label="Import & Sync" icon="upload" navigate="/i" />
        <:nav key={:a} label="A" icon="list" dock={false} navigate="/a" /> x
      </.app_shell>
      """)

    for item <- ["nav.dock a[href='/i']", "nav.dock button"] do
      assert "min-w-0" in classes(doc, item)

      assert Enum.all?(
               ~w(dock-label max-w-full truncate),
               &(&1 in classes(doc, "#{item} .dock-label"))
             )
    end

    # The truncation is visual only: the link keeps its full text as its name.
    assert text(doc, "nav.dock a[href='/i'] .dock-label") == "Import & Sync"
    assert attr(doc, "nav.dock a[href='/i']", "aria-label") == nil
  end

  test "sidebar pages start at the content edge whatever their width" do
    for width <- [:narrow, :default, :wide] do
      assigns = %{width: width}

      doc =
        parse(~H"""
        <.app_shell layout={:sidebar} width={@width}>
          <:brand>App</:brand>
          <:nav key={:a} label="A" icon="list" navigate="/a" /> Inhalt
        </.app_shell>
        """)

      refute "mx-auto" in classes(doc, "main#main")
      refute "mx-auto" in classes(doc, "header .navbar")
    end
  end

  test "a button entry in the sidebar dialog closes the dialog, then runs its action" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav id="add" key={:add} label="Neu" icon="plus" on_click="add" phx-target="#a" />
        <:nav id="js" key={:js} label="JS" icon="plus" on_click={JS.push("js")} /> x
      </.app_shell>
      """)

    for id <- ~w(add-dialog js-dialog) do
      [hide, push] = attr(doc, "##{id}", "phx-click") |> Jason.decode!()

      assert hide == [
               "dispatch",
               %{"event" => "setzkasten:hide-modal", "to" => "#app-shell-sidebar"}
             ]

      assert ["push", %{"event" => _}] = push
    end

    assert [%{"event" => "add", "target" => "#a"}] = pushes(attr(doc, "#add-dialog", "phx-click"))

    refute attr(doc, "#add-sidebar", "phx-click") =~ "hide-modal"
  end

  test "dock and rail mark an entry's parent while the entry, left out there, is current" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar} current={{:account, 1}}>
        <:brand>App</:brand>
        <:nav key={:budget} label="Budget" icon="wallet" navigate="/b" />
        <:nav key={:accounts} label="Konten" icon="landmark" navigate="/k" />
        <:nav
          key={{:account, 1}}
          label="Giro"
          section="Konten"
          rail={false}
          dock={false}
          parent={:accounts}
          navigate="/k/1"
        /> x
      </.app_shell>
      """)

    assert attr(doc, "nav.dock a[href='/k']", "aria-current") == "true"
    assert "dock-active" in classes(doc, "nav.dock a[href='/k']")
    refute "dock-active" in classes(doc, "nav.dock button[aria-haspopup]")
    assert attr(doc, "nav.dock button[aria-haspopup]", "aria-current") == nil
    assert attr(doc, "nav.dock a[href='/b']", "aria-current") == nil

    rail = "aside.md\\:flex"
    assert attr(doc, "#{rail} a[href='/k']", "aria-current") == "true"
    assert "bg-white/10" in classes(doc, "#{rail} a[href='/k']")

    assert attr(doc, "aside.lg\\:flex a[href='/k/1']", "aria-current") == "page"
    assert attr(doc, "aside.lg\\:flex a[href='/k']", "aria-current") == nil

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar} current={{:account, 1}}>
        <:brand>App</:brand>
        <:nav key={:budget} label="Budget" icon="wallet" navigate="/b" />
        <:nav key={{:account, 1}} label="Giro" rail={false} dock={false} navigate="/k/1" /> x
      </.app_shell>
      """)

    assert "dock-active" in classes(doc, "nav.dock button[aria-haspopup]")
  end

  test "sidebar labels share one text column: entries without media keep the icon's place" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav key={:a} label="A" icon="list" navigate="/a" />
        <:nav key={:g} label="G" glyph="🐷" navigate="/g" />
        <:nav key={:b} label="B" navigate="/b" /> x
      </.app_shell>
      """)

    for place <- ["aside.lg\\:flex", "dialog#app-shell-sidebar"] do
      assert count(doc, "#{place} a[href='/b'] > span.size-5[aria-hidden]:first-child") == 1
      assert count(doc, "#{place} a[href='/a'] > span.size-5") == 0
      assert count(doc, "#{place} a[href='/g'] > span.size-5") == 1
    end

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar}>
        <:brand>App</:brand>
        <:nav key={:b} label="B" navigate="/b" /> x
      </.app_shell>
      """)

    assert count(doc, "aside.lg\\:flex a[href='/b'] > span.size-5") == 0
  end

  test "with more than one area, a segmented switch tops the sidebar, its dialog and the rail" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar} current={:b} current_area={:finanzen}>
        <:brand>App</:brand>
        <:area key={:finanzen} id="area-finanzen" label="Finanzen" icon="wallet" navigate="/b" />
        <:area key={:kasse} label="Kasse" icon="receipt" href="/k" />
        <:nav key={:b} label="Budget" icon="wallet" navigate="/b" /> x
      </.app_shell>
      """)

    for place <- ["aside.lg\\:flex", "dialog#app-shell-sidebar", "aside.md\\:flex"] do
      switch = "#{place} nav[aria-label=Bereich]"
      assert count(doc, "#{switch} a") == 2
      assert "join" in classes(doc, switch)
      assert attr(doc, "#{switch} a[aria-current=page]", "href") == "/b"
      assert "setzkasten-selected" in classes(doc, "#{switch} a[aria-current=page]")
      refute "setzkasten-selected" in classes(doc, "#{switch} a[href='/k']")
      assert attr(doc, "#{switch} a[href='/k']", "data-phx-link") == nil
      assert attr(doc, "#{switch} a[href='/b']", "data-phx-link") == "redirect"
    end

    assert text(doc, "aside.lg\\:flex nav[aria-label=Bereich] a[href='/k']") == "Kasse"

    assert attr(doc, "aside.md\\:flex nav[aria-label=Bereich] a[href='/k']", "data-tip") ==
             "Kasse"

    assert attr(doc, "aside.md\\:flex nav[aria-label=Bereich] a[href='/k']", "aria-label") ==
             "Kasse"

    assert count(doc, "#area-finanzen-sidebar") == 1
    assert count(doc, "#area-finanzen-dialog") == 1
    assert count(doc, "#area-finanzen-rail") == 1
    assert count(doc, "nav.dock a[href='/k']") == 0
  end

  test "one area, or the top-bar layout, shows no area switch" do
    assigns = %{}

    for doc <- [
          parse(~H"""
          <.app_shell layout={:sidebar} current_area={:kasse}>
            <:brand>App</:brand>
            <:area key={:kasse} label="Kasse" icon="receipt" navigate="/k" />
            <:nav key={:b} label="Ausgaben" icon="receipt" navigate="/k" /> x
          </.app_shell>
          """),
          parse(~H"""
          <.app_shell current_area={:finanzen}>
            <:brand>App</:brand>
            <:area key={:finanzen} label="Finanzen" icon="wallet" navigate="/b" />
            <:area key={:kasse} label="Kasse" icon="receipt" navigate="/k" />
            <:nav key={:b} label="Budget" icon="wallet" navigate="/b" /> x
          </.app_shell>
          """)
        ] do
      assert count(doc, "nav[aria-label=Bereich]") == 0
    end
  end

  test "an area without an icon shows its initial in the rail" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar} current_area={:a} area_label="Area">
        <:brand>App</:brand>
        <:area key={:a} label="Finanzen" navigate="/a" />
        <:area key={:b} label="Kasse" navigate="/b" />
        <:nav key={:x} label="X" icon="list" navigate="/x" /> x
      </.app_shell>
      """)

    assert text(doc, "aside.md\\:flex nav[aria-label=Area] a[href='/b']") == "K"
    assert count(doc, "aside.md\\:flex nav[aria-label=Area] a[href='/b'] span[aria-hidden]") == 1
  end

  test "an area plush shows at 20px in the switch and falls back to the icon, then the initial" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar} current_area={:a}>
        <:brand>App</:brand>
        <:area key={:a} label="Finanzen" plush="cart" icon="wallet" navigate="/a" />
        <:area key={:b} label="Kasse" plush="missing" icon="receipt" navigate="/b" />
        <:area key={:c} label="Reisen" plush="missing" navigate="/c" />
        <:nav key={:x} label="X" icon="list" navigate="/x" /> x
      </.app_shell>
      """)

    for place <- ["aside.lg\\:flex", "dialog#app-shell-sidebar", "aside.md\\:flex"] do
      switch = "#{place} nav[aria-label=Bereich]"
      assert "size-5" in classes(doc, "#{switch} a[href='/a'] img.plush")
      assert count(doc, "#{switch} a[href='/a'] svg") == 0
      assert count(doc, "#{switch} a[href='/b'] img") == 0
      assert count(doc, "#{switch} a[href='/b'] svg.lucide") == 1
    end

    assert "size-4" in classes(doc, "aside.lg\\:flex nav[aria-label=Bereich] a[href='/b'] svg")
    assert "size-5" in classes(doc, "aside.md\\:flex nav[aria-label=Bereich] a[href='/b'] svg")
    assert text(doc, "aside.md\\:flex nav[aria-label=Bereich] a[href='/c']") == "R"
  end

  test "with a back link the sidebar shows the page's own navigation, without dock or area switch" do
    assigns = %{}

    doc =
      parse(~H"""
      <.app_shell layout={:sidebar} current={:access} current_area={:finanzen} expand_label="Expand">
        <:brand>App</:brand>
        <:back id="back" label="Zurück zu Finanzen" href="/budget" />
        <:area key={:finanzen} label="Finanzen" icon="wallet" navigate="/b" />
        <:area key={:kasse} label="Kasse" icon="receipt" navigate="/k" />
        <:nav key={:access} label="Zugang" icon="key-round" section="Allgemein" navigate="/s/a" />
        <:nav key={:look} label="Aussehen" icon="sun" section="Allgemein" navigate="/s/l" />
        <:nav key={:group} label="Gruppe" icon="users" section="Kasse" navigate="/s/g" /> x
      </.app_shell>
      """)

    assert count(doc, "nav[aria-label=Bereich]") == 0
    assert count(doc, "nav.dock") == 0
    assert attr(doc, "header .navbar > button:first-child", "aria-label") == "Expand"

    for place <- ["aside.lg\\:flex", "dialog#app-shell-sidebar"] do
      assert text(doc, "#{place} a[href='/budget']") == "Zurück zu Finanzen"
      assert count(doc, "#{place} a[href='/budget'] svg") == 1
      assert text(doc, "#{place} li.menu-title:first-of-type") =~ "Allgemein"
    end

    assert attr(doc, "aside.md\\:flex a[href='/budget']", "data-tip") == "Zurück zu Finanzen"
    assert attr(doc, "aside.md\\:flex a[href='/budget']", "aria-label") == "Zurück zu Finanzen"
    assert count(doc, "#back-sidebar") == 1
    assert count(doc, "#back-dialog") == 1
    assert count(doc, "#back-rail") == 1
  end
end
