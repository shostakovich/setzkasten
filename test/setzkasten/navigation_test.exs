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

    assert classes(doc, "a[aria-current=page]") ==
             ~w(join-item btn btn-sm pointer-coarse:min-w-11 setzkasten-selected)

    assert attr(doc, "a[aria-current=page]", "data-phx-link") == "patch"
  end

  test "segmented patch links replace the history entry unless asked not to" do
    assigns = %{options: [{"1M", "1m", "/?r=1m"}, {"1J", "1y", "/?r=1y"}]}
    doc = parse(~H|<.segmented label="Zeitraum" value="1m" options={@options} />|)
    assert doc |> find("a") |> LazyHTML.attribute("data-phx-link-state") == ~w(replace replace)

    doc = parse(~H|<.segmented label="Zeitraum" value="1m" options={@options} replace={false} />|)
    assert doc |> find("a") |> LazyHTML.attribute("data-phx-link-state") == ~w(push push)
  end

  test "segmented button mode uses aria-pressed and sends the option as value" do
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
    # LiveView's client sends a button's value property over phx-value-value.
    assert attr(doc, "button[aria-pressed=true]", "value") == "list"
    assert attr(doc, "button[aria-pressed=false]", "phx-click") == "view"

    doc =
      parse(~H"""
      <.segmented
        mode={:button}
        label="Netto"
        value={false}
        phx-click="net"
        options={[{"Ja", true}, {"Nein", false}]}
      />
      """)

    assert attr(doc, "button[aria-pressed=true]", "value") == "false"
    assert attr(doc, "button[aria-pressed=true]", "phx-value-value") == "false"

    doc =
      parse(~H"""
      <.segmented
        mode={:radio}
        name="net"
        label="Netto"
        value={false}
        options={[{"Ja", true}, {"Nein", false}]}
      />
      """)

    assert attr(doc, "input[checked]", "value") == "false"
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

    assert text(doc, "legend.fieldset-legend") == "Aufteilung"
    assert attr(doc, "input[value=shares]", "checked") != nil
    assert attr(doc, "input[value=shares]", "name") == "e[split]"
  end

  test "segmented checkbox mode is a checkbox group sent as name[]" do
    assigns = %{form: to_form(%{"days" => ["mon", "wed"]}, as: :plan)}

    doc =
      parse(~H"""
      <.segmented
        mode={:checkbox}
        label="Wochentage"
        field={@form[:days]}
        options={[%{label: "Mo", long_label: "Montag", value: "mon"}, {"Di", "tue"}, {"Mi", "wed"}]}
      />
      """)

    assert text(doc, "fieldset > legend.fieldset-legend") == "Wochentage"
    boxes = find(doc, "fieldset > .join > label.join-item input[type=checkbox].sr-only")
    assert LazyHTML.attribute(boxes, "name") == List.duplicate("plan[days][]", 3)

    assert doc |> find("input[type=checkbox][checked]") |> LazyHTML.attribute("value") ==
             ~w(mon wed)

    assert attr(doc, "input[value=mon]", "aria-label") == "Montag"
    assert "has-checked:setzkasten-selected" in classes(doc, "label:has(input[value=tue])")
    # Outside the join, so daisyUI's join still finds its first and last item.
    assert attr(doc, "fieldset > input[type=hidden]", "name") == "plan[days][]"
    assert attr(doc, "input[type=hidden]", "value") == ""
    assert count(doc, ".join input[type=hidden]") == 0

    for name <- ["days", "days[]"] do
      assigns = %{name: name}

      doc =
        parse(~H"""
        <.segmented mode={:checkbox} label="Tage" name={@name} value={[:tue]} options={[{"Di", "tue"}]} />
        """)

      assert attr(doc, "input[type=checkbox]", "name") == "days[]"
      assert attr(doc, "input[type=checkbox]", "checked") != nil
    end
  end

  test "segmented form modes are fields: visible label, errors after use, help, described group" do
    form =
      to_form(%{"split" => "x"}, as: :e, errors: [split: {"is invalid", []}], action: :validate)

    assigns = %{form: form}

    doc =
      parse(~H"""
      <.segmented
        mode={:radio}
        label="Aufteilung"
        field={@form[:split]}
        help="Gilt für alle Beteiligten"
        options={[{"Gleich", "equal"}, {"Anteile", "shares"}]}
      />
      """)

    group = "fieldset#e_split"
    assert attr(doc, group, "role") == "radiogroup"
    assert attr(doc, group, "aria-invalid") == "true"
    assert attr(doc, group, "aria-describedby") == "e_split-error-0 e_split-help"
    assert text(doc, "#e_split-error-0") == "Is invalid"
    assert text(doc, "#e_split-help") == "Gilt für alle Beteiligten"
    assert attr(doc, "input[value=equal]", "aria-invalid") == nil

    unused = to_form(%{}, as: :e, errors: [split: {"is invalid", []}])
    assigns = %{form: unused}

    doc =
      parse(~H"""
      <.segmented
        mode={:radio}
        label="Aufteilung"
        field={@form[:split]}
        hide_label
        options={[{"Gleich", "equal"}]}
      />
      """)

    assert count(doc, "[id$=-error-0]") == 0
    assert attr(doc, "fieldset", "aria-invalid") == nil
    assert classes(doc, "legend") == ["sr-only"]

    doc =
      parse(~H"""
      <.segmented
        mode={:checkbox}
        id="days"
        name="days"
        label="Tage"
        errors={["Mindestens ein Tag"]}
        options={[{"Mo", "mon"}, {"Di", "tue"}]}
      />
      """)

    assert attr(doc, "fieldset#days", "role") == nil
    assert attr(doc, "fieldset#days", "aria-invalid") == nil

    assert doc |> find("input[type=checkbox]") |> LazyHTML.attribute("aria-invalid") ==
             ~w(true true)

    assert attr(doc, "fieldset#days", "aria-describedby") == "days-error-0"
  end

  test "segmented takes its errors from field over errors, as input does" do
    form =
      to_form(%{"split" => "x"}, as: :e, errors: [split: {"is invalid", []}], action: :validate)

    assigns = %{form: form}

    doc =
      parse(~H"""
      <.segmented
        mode={:radio}
        label="Aufteilung"
        field={@form[:split]}
        errors={["Bitte wählen"]}
        options={[{"Gleich", "equal"}]}
      />
      """)

    assert count(doc, "[id^=e_split-error-]") == 1
    assert text(doc, "#e_split-error-0") == "Is invalid"
  end

  test "segmented form modes without field or id take their id from name" do
    assigns = %{}

    doc =
      parse(~H"""
      <.segmented
        mode={:checkbox}
        name="plan[days][]"
        label="Tage"
        errors={["Mindestens ein Tag"]}
        help="Mehrere möglich"
        options={[{"Mo", "mon"}]}
      />
      <.segmented
        mode={:radio}
        name="split"
        label="Aufteilung"
        help="Gilt für alle"
        options={[{"A", "a"}]}
      />
      """)

    assert attr(doc, "fieldset#plan_days", "aria-describedby") ==
             "plan_days-error-0 plan_days-help"

    assert text(doc, "#plan_days-error-0") == "Mindestens ein Tag"
    assert attr(doc, "fieldset#split", "aria-describedby") == "split-help"
    assert count(doc, "[id=-help]") == 0
  end

  test "segmented options carry a long accessible name, in every mode" do
    options = [
      %{label: "1 M", long_label: "1 Monat", value: "1m", path: "/?r=1m"},
      {"Max", "max", "/?r=max"}
    ]

    assigns = %{options: options}

    doc = parse(~H|<.segmented label="Zeitraum" value="1m" options={@options} />|)
    assert attr(doc, "a[href='/?r=1m']", "aria-label") == "1 Monat"
    assert attr(doc, "a[href='/?r=1m']", "title") == nil
    assert attr(doc, "a[href='/?r=max']", "aria-label") == nil

    doc = parse(~H|<.segmented mode={:button} label="Zeitraum" options={@options} />|)
    assert attr(doc, "button[phx-value-value='1m']", "aria-label") == "1 Monat"

    doc = parse(~H|<.segmented mode={:radio} name="r" label="Zeitraum" options={@options} />|)
    assert attr(doc, "input[value='1m']", "aria-label") == "1 Monat"
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

  test "the first tab's label lines up with the content edge, a tab's padding before it" do
    assigns = %{}
    doc = parse(~H|<.tabs label="x">
  <:tab navigate="/a">A</:tab>
</.tabs>|)
    nav = classes(doc, "nav")
    assert Enum.all?(~w(-ms-3 max-sm:-mx-4 max-sm:ps-1 max-sm:scroll-ps-1), &(&1 in nav))
  end

  test "tabs scroll edge to edge on phones, snap, and reveal the active tab" do
    assigns = %{}

    doc =
      parse(~H"""
      <.tabs label="Bereiche">
        <:tab navigate="/a">A</:tab>
        <:tab navigate="/b" active>B</:tab>
      </.tabs>
      """)

    nav = classes(doc, "nav")

    assert Enum.all?(
             ~w(setzkasten-scroller snap-x scroll-pe-4 max-sm:-mx-4 max-sm:pe-4),
             &(&1 in nav)
           )

    assert attr(doc, "nav", "phx-hook") == "Setzkasten.Components.Navigation.ScrollActive"
    assert attr(doc, "nav", "id") =~ ~r/^tabs-\d+$/
    assert attr(parse(~H|<.tabs id="t" label="x">
  <:tab navigate="/a">A</:tab>
</.tabs>|), "nav", "id") == "t"

    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    assert css =~ "animation-timeline: scroll(self inline)"

    assert css =~
             ~r/@media \(pointer: coarse\) \{\s*\.setzkasten-scroller \{\s*scrollbar-width: none/
  end

  test "small segmented options and breadcrumb links are 44px wide on touch screens" do
    assigns = %{}

    doc =
      parse(~H|<.segmented mode={:button} label="Z" size={:sm} options={[{"1M", "1m"}]} />|)

    assert "pointer-coarse:min-w-11" in classes(doc, "button")

    refute "pointer-coarse:min-w-11" in classes(
             parse(~H|<.segmented mode={:button} label="Z" options={[{"1M", "1m"}]} />|),
             "button"
           )

    doc =
      parse(~H"""
      <.breadcrumbs>
        <:crumb navigate="/a">A</:crumb>
        <:crumb navigate="/b">B</:crumb>
        <:crumb>C</:crumb>
      </.breadcrumbs>
      """)

    assert Enum.all?(
             doc
             |> find("a")
             |> Enum.map(
               &("pointer-coarse:min-w-11" in String.split(
                   LazyHTML.attribute(&1, "class")
                   |> hd()
                 ))
             )
           )
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

    assert classes(doc, "a[href='/b']") == ~w(tab shrink-0 snap-start whitespace-nowrap ms-auto)
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
    assert attr(doc, "details", "phx-hook") == "Setzkasten.Components.Navigation.Dropdown"

    assert colocated_js("Setzkasten.Components.Navigation") =~
             ~s[if (e.key === "Escape" && this.el.open) e.preventDefault()]

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
        <:item id="undo" on_click="undo" disabled class="sm:hidden">Rückgängig</:item>
        <:item id="drop" on_click="delete" danger confirm="Löschen?">Löschen</:item>
      </.dropdown>
      """)

    assert attr(doc, "#undo", "disabled") != nil
    assert Enum.all?(~w(menu-disabled sm:hidden), &(&1 in classes(doc, "li:has(#undo)")))
    assert attr(doc, "#drop", "aria-haspopup") == "dialog"
    assert attr(doc, "#drop", "phx-click") =~ "confirm-delete"
  end

  test "dropdown items push an event name to their phx-target" do
    assigns = %{myself: %Phoenix.LiveComponent.CID{cid: 3}}

    doc =
      parse(~H"""
      <.dropdown id="more" label="Mehr">
        <:trigger>…</:trigger>
        <:item id="undo" on_click="undo" phx-target={@myself}>Rückgängig</:item>
        <:item id="drop" on_click="delete" phx-target={@myself} confirm="Löschen?">Löschen</:item>
      </.dropdown>
      """)

    assert [%{"event" => "undo", "target" => 3}] = pushes(attr(doc, "#undo", "phx-click"))
    assert [%{"event" => "delete", "target" => 3}] = pushes(attr(doc, "#drop", "phx-click"))
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
    # daisyUI makes breadcrumb items flex containers, which ignore text-overflow.
    assert Enum.all?(~w(block truncate), &(&1 in classes(doc, "h1")))
    # Below sm only the nearest parent stays, with a back chevron instead of the separator.
    assert "max-sm:hidden" in classes(doc, "li:has(a[href='/'])")
    assert "max-sm:before:hidden" in classes(doc, "li:has(a[href='/posts'])")
    assert count(doc, "a[href='/posts'] svg") == 1
    # On phones the parent's name is for screen readers, the current page stays visible.
    assert "max-sm:sr-only" in classes(doc, "a[href='/posts'] span")
    refute "max-sm:sr-only" in classes(doc, "li:has(h1)")
    assert "max-sm:before:hidden" in classes(doc, "li:has(h1)")
  end

  test "breadcrumbs with the current page only" do
    assigns = %{}
    doc = parse(~H|<.breadcrumbs heading={false}>
  <:crumb>Neu</:crumb>
</.breadcrumbs>|)
    assert text(doc, "span[aria-current=page]") == "Neu"
    refute "max-sm:sr-only" in classes(doc, "li")
  end

  test "segmented block stretches options to equal widths, in every mode" do
    options = [{"1M", "1m", "/?r=1m"}, {"1J", "1y", "/?r=1y"}]
    assigns = %{options: options}

    doc = parse(~H|<.segmented label="Zeitraum" options={@options} size={:sm} block />|)
    assert classes(doc, "nav") == ~w(join flex w-full setzkasten-segmented-block)

    assert classes(doc, "a[href='/?r=1m']") ==
             ~w(join-item btn btn-sm pointer-coarse:min-w-11 min-w-0 flex-1 max-sm:px-2)

    doc = parse(~H|<.segmented mode={:button} label="Zeitraum" options={@options} block />|)
    assert classes(doc, "[role=group]") == ~w(join flex w-full setzkasten-segmented-block)
    assert "flex-1" in classes(doc, "button")

    doc =
      parse(~H|<.segmented mode={:radio} name="r" label="Zeitraum" options={@options} block />|)

    assert classes(doc, "fieldset") == ~w(fieldset min-w-0 w-full setzkasten-segmented-block)
    assert classes(doc, "fieldset > .join") == ~w(join flex w-full)
    assert "flex-1" in classes(doc, "label")

    doc = parse(~H|<.segmented label="Zeitraum" options={@options} />|)
    assert classes(doc, "nav") == ["join"]
  end

  test "segmented block on phones only, with room in the header's actions" do
    options = [{"1M", "1m", "/?r=1m"}, {"1J", "1y", "/?r=1y"}]
    assigns = %{options: options}

    doc =
      parse(~H"""
      <.header>
        Übersicht
        <:actions><.segmented label="Zeitraum" options={@options} block={:phone} /></:actions>
      </.header>
      """)

    assert classes(doc, "nav") ==
             ~w(join max-sm:flex max-sm:w-full setzkasten-segmented-block)

    assert Enum.all?(~w(max-sm:min-w-0 max-sm:flex-1), &(&1 in classes(doc, "a[href='/?r=1m']")))
    refute "flex-1" in classes(doc, "a[href='/?r=1m']")

    assert "max-sm:has-[>.setzkasten-segmented-block]:w-full" in classes(
             doc,
             "header > div:last-child"
           )
  end

  test "touch screens: 44px file inputs, menu labels centred in their box" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    [coarse] = Regex.run(~r/@media \(pointer: coarse\) \{\s*\.btn,.*?\n  \}/s, css)
    assert coarse =~ ".file-input,"
    assert coarse =~ ".menu :where(li > a, li > button, li > summary, li > label),"

    assert coarse =~
             ~r/\.menu :where\(li > a, li > button, li > summary, li > label\) \{\s*align-content: center;/
  end

  test "dropdown items show a plush at 24px, icons and empty items keep its box at text height" do
    assigns = %{}

    doc =
      parse(~H"""
      <.dropdown id="areas">
        <:trigger>Bereich</:trigger>
        <:item navigate="/a" plush="cart" icon="wallet">A</:item>
        <:item navigate="/b" icon="list">B</:item>
        <:item navigate="/c">C</:item>
      </.dropdown>
      """)

    plush = classes(doc, "a[href='/a'] img.plush")
    assert Enum.all?(~w(size-6 -my-0.5), &(&1 in plush))
    assert count(doc, "a[href='/a'] svg") == 0
    assert classes(doc, "a[href='/b'] svg.lucide") == ~w(lucide size-4 mx-1)
    assert classes(doc, "a[href='/c'] > span[aria-hidden=true]") == ~w(w-6 h-4 shrink-0)
  end

  test "a dropdown item's plush without an image falls back to its icon" do
    assigns = %{}

    doc =
      parse(~H"""
      <.dropdown id="areas">
        <:trigger>Bereich</:trigger>
        <:item navigate="/a" plush="missing" icon="wallet">A</:item>
        <:item on_click="b">B</:item>
      </.dropdown>
      """)

    assert count(doc, "a[href='/a'] img") == 0
    assert classes(doc, "a[href='/a'] svg.lucide") == ~w(lucide size-4)
    assert count(doc, "li:last-child button > span") == 0
  end

  test "a dropdown without a plush shows icons only where given" do
    assigns = %{}

    doc =
      parse(~H"""
      <.dropdown id="sites">
        <:trigger>Website</:trigger>
        <:item navigate="/a" icon="building-2">A</:item>
        <:item navigate="/b"><.avatar initials="KM" size={:sm} />B</:item>
        <:item navigate="/c" plush="missing">C</:item>
      </.dropdown>
      """)

    assert classes(doc, "a[href='/a'] svg.lucide") == ~w(lucide size-4)
    assert count(doc, "a[href='/b'] > span") == 0
    assert count(doc, "a[href='/b'] > *") == 1
    assert count(doc, "a[href='/c'] > *") == 0
    assert count(doc, "li img") == 0
  end

  test "an active button item is marked like an active link" do
    assigns = %{}

    doc =
      parse(~H"""
      <.dropdown id="sort">
        <:trigger>Sortieren</:trigger>
        <:item on_click="sort" active>Datum</:item>
        <:item on_click="sort">Betrag</:item>
      </.dropdown>
      """)

    assert attr(doc, "li:first-child button", "aria-current") == "true"
    assert "menu-active" in classes(doc, "li:first-child button")
    assert attr(doc, "li:last-child button", "aria-current") == nil
    refute "menu-active" in classes(doc, "li:last-child button")
  end
end
