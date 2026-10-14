defmodule Setzkasten.DataTest do
  use Setzkasten.ComponentCase, async: true

  @rows [%{id: 1, name: "SAP", value: 120_905}, %{id: 2, name: "Gold", value: -500}]

  test "table is flat, tabular and aligns numeric columns" do
    assigns = %{rows: @rows}

    doc =
      parse(~H"""
      <.table id="t" rows={@rows} row_id={&"row-#{&1.id}"}>
        <:col :let={r} label="Name">{r.name}</:col>
        <:col :let={r} label="Wert" align={:end} show_from={:md}><.amount value={r.value} /></:col>
      </.table>
      """)

    assert classes(doc, "div") |> Enum.take(4) ==
             ~w(overflow-x-auto border-y border-base-content/10 max-sm:-mx-4)

    assert classes(doc, "table") == ~w(table tabular-nums)
    assert attr(doc, "th:first-child", "scope") == "col"

    assert classes(doc, "th:last-child") ==
             ~w(text-end tabular-nums whitespace-nowrap hidden md:table-cell)

    assert count(doc, "tbody#t tr[id^=row-]") == 2
  end

  test "flush, size and zebra" do
    assigns = %{rows: @rows}

    doc =
      parse(~H"""
      <.table id="t" rows={@rows} flush size={:sm} zebra>
        <:col :let={r}>{r.name}</:col>
      </.table>
      """)

    assert classes(doc, "div") == ["overflow-x-auto"]
    # :sm keeps 14px text and the side padding of :md; only the rows get tighter.
    assert classes(doc, "table") == [
             "table",
             "tabular-nums",
             "[&_:is(th,td)]:py-2",
             "table-zebra"
           ]
  end

  test "row link stretches over the row" do
    assigns = %{rows: @rows}

    doc =
      parse(~H"""
      <.table id="t" rows={@rows} row_link={&"/w/#{&1.id}"}>
        <:col :let={r} label="Name">{r.name}</:col>
        <:col :let={r} label="Wert">{r.value}</:col>
      </.table>
      """)

    assert classes(doc, "tbody tr") ==
             ~w(relative row-hover has-[td:first-child>a:active]:bg-base-200)

    assert attr(doc, "tbody tr:first-child td:first-child a", "href") == "/w/1"
    link = classes(doc, "tbody tr:first-child td:first-child a")

    assert Enum.all?(
             ~w(after:absolute after:inset-0 focus-visible:outline-none focus-visible:after:outline-2
                focus-visible:after:-outline-offset-2 focus-visible:after:outline-primary),
             &(&1 in link)
           )

    assert count(doc, "td:last-child a") == 0
  end

  test "a row whose link is nil has no link and no hover" do
    assigns = %{rows: @rows}

    doc =
      parse(~H"""
      <.table id="t" rows={@rows} row_id={&"row-#{&1.id}"} row_link={&(&1.id == 1 && "/w/1")}>
        <:col :let={r} label="Name">{r.name}</:col>
      </.table>
      """)

    assert classes(doc, "#row-1") ==
             ~w(relative row-hover has-[td:first-child>a:active]:bg-base-200)

    assert classes(doc, "#row-2") == []
    assert count(doc, "#row-2 a") == 0
    assert text(doc, "#row-2 td") == "Gold"
    refute LazyHTML.to_html(doc) =~ ~s(href="#")
  end

  test "row attrs land on the tr and merge their class" do
    attrs = fn r ->
      if r.id == 1,
        do: %{"aria-current": "true", class: "font-semibold", "data-kind": "stock"},
        else: [hidden: true]
    end

    assigns = %{rows: @rows, attrs: attrs, groups: [%{id: "a", label: "A", rows: @rows}]}

    doc =
      parse(~H"""
      <.table id="t" rows={@rows} row_id={&"row-#{&1.id}"} row_link={&"/w/#{&1.id}"} row_attrs={@attrs}>
        <:col :let={r}>{r.name}</:col>
      </.table>
      """)

    assert classes(doc, "#row-1") ==
             ~w(relative row-hover has-[td:first-child>a:active]:bg-base-200 font-semibold)

    assert attr(doc, "#row-1", "aria-current") == "true"
    assert attr(doc, "#row-1", "data-kind") == "stock"
    assert attr(doc, "#row-2", "hidden") != nil

    doc =
      parse(~H"""
      <.table id="g" groups={@groups} row_attrs={@attrs}>
        <:col :let={r}>{r.name}</:col>
      </.table>
      """)

    assert count(doc, "tbody#g-a tr[aria-current=true]") == 1

    stream = Phoenix.LiveView.LiveStream.new(:items, 0, @rows, [])
    assigns = %{stream: stream, attrs: attrs}

    doc =
      parse(~H"""
      <.table id="s" rows={@stream} row_attrs={@attrs}>
        <:col :let={r}>{r.name}</:col>
      </.table>
      """)

    assert attr(doc, "tr[id^=items-][aria-current]", "data-kind") == "stock"
  end

  test "row_attrs may return nil, a string class, and never replaces the row id" do
    attrs = fn
      %{id: 1} -> %{"class" => "font-semibold", "id" => "other", "data-kind" => "stock"}
      _ -> nil
    end

    assigns = %{rows: @rows, attrs: attrs}

    doc =
      parse(~H"""
      <.table id="t" rows={@rows} row_id={&"row-#{&1.id}"} row_attrs={@attrs}>
        <:col :let={r}>{r.name}</:col>
      </.table>
      """)

    assert classes(doc, "#row-1") == ~w(font-semibold)
    assert attr(doc, "#row-1", "data-kind") == "stock"
    assert count(doc, "#other") == 0
    assert count(doc, "#row-2") == 1
    assert attr(doc, "#row-2", "class") in [nil, ""]

    doc =
      parse(~H"""
      <.table id="k" rows={@rows} row_id={&"k-#{&1.id}"} row_attrs={&[id: "x-#{&1.id}"]}>
        <:col :let={r}>{r.name}</:col>
      </.table>
      """)

    assert count(doc, "#k-1") == 1
    assert count(doc, "#x-1") == 0
  end

  test "groups become tbodies with colgroup rows; foot and empty rows" do
    assigns = %{groups: [%{id: "a", label: "Depot A", rows: @rows}]}

    doc =
      parse(~H"""
      <.table id="t" groups={@groups}>
        <:col :let={r} label="Name">{r.name}</:col>
        <:col :let={r} label="Wert">{r.value}</:col>
        <:foot>
          <th scope="row">Gesamt</th><td>1</td>
        </:foot>
      </.table>
      """)

    assert attr(doc, "tbody#t-a th", "scope") == "colgroup"
    assert attr(doc, "tbody#t-a th", "colspan") == "2"
    assert text(doc, "tfoot tr.font-semibold th") == "Gesamt"

    doc =
      parse(~H"""
      <.table id="e" rows={[]}>
        <:col :let={r}>{r}</:col><:empty>Leer</:empty>
      </.table>
      """)

    assert "only:table-row" in classes(doc, "#e-empty")
  end

  test "table supports streams" do
    stream = Phoenix.LiveView.LiveStream.new(:items, 0, @rows, [])
    assigns = %{stream: stream}

    doc = parse(~H|<.table id="s" rows={@stream}>
  <:col :let={r}>{r.name}</:col>
</.table>|)
    assert attr(doc, "tbody", "phx-update") == "stream"
    assert count(doc, "tbody tr[id^=items-]") == 2
  end

  test "cell_sub hides and shows by breakpoint" do
    assigns = %{}
    doc = parse(~H|<.cell_sub hide_from={:lg}>x</.cell_sub>|)
    assert "lg:hidden" in classes(doc, "div")
    doc = parse(~H|<.cell_sub show_from={:lg}>x</.cell_sub>|)
    assert Enum.all?(~w(hidden lg:block), &(&1 in classes(doc, "div")))
  end

  test "show_from and hide_from accept 2xl" do
    assigns = %{rows: @rows}

    doc =
      parse(~H"""
      <.table id="t" rows={@rows}>
        <:col :let={r} label="Name">{r.name}</:col>
        <:col :let={r} label="Wert" show_from={:"2xl"}>{r.value}</:col>
      </.table>
      """)

    assert Enum.all?(~w(hidden 2xl:table-cell), &(&1 in classes(doc, "th:last-child")))
    assert show_from(:"2xl") == "hidden 2xl:table-cell"
    assert "2xl:hidden" in classes(parse(~H|<.cell_sub hide_from={:"2xl"}>x</.cell_sub>|), "div")

    assert Enum.all?(
             ~w(hidden 2xl:block),
             &(&1 in classes(parse(~H|<.cell_sub show_from={:"2xl"}>x</.cell_sub>|), "div"))
           )
  end

  test "list row with link, hover, meta and folded actions" do
    assigns = %{}

    doc =
      parse(~H"""
      <.list>
        <.list_row title="Herbst" navigate="/p/1">
          <:meta>Meta</:meta>
          <:action label="Bearbeiten" icon="pencil" navigate="/p/1/edit" />
          <:action label="Löschen" icon="trash-2" danger confirm="Löschen?" on_click="delete" />
        </.list_row>
      </.list>
      """)

    assert "border-y" in classes(doc, "ul.list")
    assert "after:inset-0" in classes(doc, ".list-col-grow a")
    assert text(doc, ".list-col-grow a") == "Herbst"
    assert count(doc, "div.hidden.md\\:flex .btn-square") == 2
    assert attr(doc, "div.md\\:flex a", "aria-label") == "Bearbeiten: Herbst"
    assert attr(doc, "div.md\\:flex button", "aria-haspopup") == "dialog"
    assert attr(doc, "details summary", "aria-label") == "Aktionen: Herbst"
    assert "text-error-ink" in classes(doc, "details li:last-child button")
    assert attr(doc, "details", "phx-click-away") =~ "remove_attr"
    # No chevron: the hover fill and the title say the row opens.
    assert count(doc, "li > svg.lucide") == 0
    assert "md:hover:bg-base-200" in classes(doc, "li.list-row")
    assert "has-[.list-col-grow>:is(a,button):active]:bg-base-200" in classes(doc, "li.list-row")
    # An open menu lies above the menus of the rows below it.
    assert "open:z-20" in classes(doc, "details")
  end

  test "list row with menu={:always} folds the actions on every width" do
    assigns = %{}

    doc =
      parse(~H"""
      <.list_row title="Herbst" menu={:always}>
        <:action label="Löschen" icon="trash-2" danger on_click="delete" />
      </.list_row>
      """)

    assert count(doc, "div.md\\:flex") == 0
    refute "md:hidden" in classes(doc, "details")
  end

  test "list row with menu={:always} keeps inline actions as buttons from md" do
    assigns = %{}

    doc =
      parse(~H"""
      <.list_row title="Herbst" menu={:always}>
        <:action label="Nach oben" icon="chevron-left" on_click="up" inline />
        <:action label="Löschen" icon="trash-2" danger on_click="delete" />
      </.list_row>
      """)

    assert count(doc, "div.md\\:flex button") == 1
    assert attr(doc, "div.md\\:flex button", "aria-label") == "Nach oben: Herbst"
    # In the menu the inline action is only there for phones.
    assert "md:hidden" in classes(doc, "details li:first-child")
    refute "md:hidden" in classes(doc, "details li:last-child")
  end

  test "list row puts trailing content at the end of the meta line on phones" do
    assigns = %{}

    doc =
      parse(~H"""
      <.list_row title="T" navigate="/p/1" trailing_on_phone={:meta}>
        <:meta>07.10.2026</:meta>
        <:trailing :let={place} class="md:w-40 md:justify-start">
          <.badge id={"status-#{place}"}>Entwurf</.badge>
        </:trailing>
      </.list_row>
      """)

    refute "max-md:gap-y-1" in classes(doc, "li")
    assert "md:hidden" in classes(doc, ".list-col-grow div:has(> #status-meta)")
    column = classes(doc, "li > div:has(> #status-column)")
    assert Enum.all?(~w(max-md:hidden md:w-40 md:justify-start), &(&1 in column))
    refute "max-md:row-start-2" in column
  end

  test "list row moves trailing content under the title on phones" do
    assigns = %{}

    doc =
      parse(~H"""
      <.list>
        <.list_row title="Ein ziemlich langer Titel" navigate="/p/1">
          <:leading><.icon name="info" /></:leading>
          <:meta>07.10.2026</:meta>
          <:trailing>
            <.badge tone={:success}>Veröffentlicht</.badge>
          </:trailing>
          <:action label="Löschen" icon="trash-2" on_click="delete" />
        </.list_row>
      </.list>
      """)

    assert "max-md:gap-y-1" in classes(doc, "li.list-row")
    trailing = classes(doc, "li.list-row > div:has(> .badge)")
    assert Enum.all?(~w(max-md:row-start-2 max-md:col-start-2 md:justify-end), &(&1 in trailing))
    assert "max-md:row-[1/span_2]" in classes(doc, "li.list-row > div:first-child")
    # The media stays with the first line when the trailing content wraps below.
    assert "max-md:self-start" in classes(doc, "li.list-row > div:first-child")
    assert "max-md:row-[1/span_2]" in classes(doc, "li.list-row > details")

    without_leading =
      parse(~H"""
      <.list_row title="T">
        <:trailing>
          <.badge>Entwurf</.badge>
        </:trailing>
      </.list_row>
      """)

    assert "max-md:col-start-1" in classes(without_leading, "li > div:has(> .badge)")

    plain = parse(~H|<.list_row title="T">
  <:meta>M</:meta>
</.list_row>|)
    refute "max-md:gap-y-1" in classes(plain, "li")
  end

  test "list row action ids and disabled actions" do
    assigns = %{}

    doc =
      parse(~H"""
      <.list_row id="page-1" title="Über mich">
        <:action id="move-up-1" label="Nach oben" icon="chevron-left" on_click="up" disabled />
        <:action id="delete-1" label="Löschen" icon="trash-2" on_click="delete" />
      </.list_row>
      """)

    assert attr(doc, "#move-up-1", "disabled") != nil
    assert attr(doc, "#delete-1", "disabled") == nil
    assert "menu-disabled" in classes(doc, "details li:has(#move-up-1-menu-item)")
    assert attr(doc, "#move-up-1-menu-item", "disabled") != nil
    assert count(doc, "#delete-1-menu-item") == 1
    assert attr(doc, "details summary", "id") == "page-1-menu-toggle"
  end

  test "list row actions push an event name to their phx-target" do
    assigns = %{myself: %Phoenix.LiveComponent.CID{cid: 3}}

    doc =
      parse(~H"""
      <.list>
        <.list_row title="Herbst">
          <:action
            label="Löschen"
            icon="trash-2"
            id="drop"
            confirm="Löschen?"
            on_click="delete"
            phx-target={@myself}
          />
        </.list_row>
      </.list>
      """)

    for selector <- ["#drop", "#drop-menu-item"] do
      assert [%{"event" => "delete", "target" => 3}] = pushes(attr(doc, selector, "phx-click"))
    end
  end

  test "list row action confirm with its own label" do
    assigns = %{}

    doc =
      parse(~H"""
      <.list_row title="Entwurf">
        <:action
          label="Verwerfen"
          icon="x"
          confirm="Verwerfen?"
          confirm_label="Verwerfen"
          on_click="discard"
        />
      </.list_row>
      """)

    click = attr(doc, "div.md\\:flex button", "phx-click")
    assert click =~ "#confirm-delete-confirm-label"
    assert click =~ "Verwerfen"
  end

  test "list heading" do
    assigns = %{}
    assert text(parse(~H|<.list_heading>Heute</.list_heading>|), "li.text-xs") == "Heute"
  end

  test "amount formats, tones and exposes a machine value" do
    assigns = %{}
    doc = parse(~H|<.amount value={-7420} tone />|)
    assert attr(doc, "data", "value") == "-74.20"
    assert text(doc, "data") == "−74,20 €"
    assert "text-error-ink" in classes(doc, "data")
    assert "text-success-ink" in classes(parse(~H|<.amount value={1} tone />|), "data")
    assert "text-lg" in classes(parse(~H|<.amount value={1} size={:lg} />|), "data")
  end

  test "amount with whole currency units keeps the exact machine value" do
    assigns = %{}
    doc = parse(~H|<.amount value={-123_456} decimals={0} tone />|)
    assert text(doc, "data") == "−1.235\u00A0€"
    assert attr(doc, "data", "value") == "-1234.56"
    assert "text-error-ink" in classes(doc, "data")

    doc = parse(~H|<.amount value={-40} decimals={0} signed tone />|)
    assert text(doc, "data") == "0\u00A0€"
    assert "text-base-content/70" in classes(doc, "data")
  end

  test "stat tile with unit, tone, stale and loading" do
    assigns = %{}
    doc = parse(~H|<.stat label="Saldo" value="−42" unit="€" tone={:error} size={:sm} stale />|)
    assert text(doc, ".stat-title") == "Saldo"

    assert Enum.all?(
             ~w(stat-value tabular-nums text-2xl text-error-ink),
             &(&1 in classes(doc, ".stat-value"))
           )

    assert text(doc, ".stat-desc .badge") == "veraltet"
    assert count(parse(~H|<.stat label="x" loading />|), ".skeleton") == 1
  end

  test "stat note slot takes the place of desc" do
    assigns = %{}

    doc =
      parse(~H"""
      <.stat label="Depot" value="63.279" desc="ignoriert">
        <:note><.amount value={50_000} signed tone /> heute</:note>
      </.stat>
      """)

    assert text(doc, ".stat-desc") =~ "heute"
    refute text(doc, ".stat-desc") =~ "ignoriert"
    assert "text-success-ink" in classes(doc, ".stat-desc data")
    assert text(parse(~H|<.stat label="x" value="1" desc="Akku" />|), ".stat-desc") == "Akku"
  end

  test "description list" do
    assigns = %{}
    doc = parse(~H|<.description_list>
  <:item label="TER">0,22 %</:item>
</.description_list>|)
    assert text(doc, "dt") == "TER"
    assert "tabular-nums" in classes(doc, "dd")
  end

  test "bar draws a native progress and an SVG target marker without inline style" do
    assigns = %{}
    html = rendered_to_string(~H|<.bar label="Aktien" value={72} target={70} show_value />|)
    doc = LazyHTML.from_fragment(html)
    assert attr(doc, "progress", "value") == "72"
    assert attr(doc, "progress", "aria-label") == "Aktien"
    assert attr(doc, "rect", "x") == "70%"
    assert text(doc, "span.tabular-nums") == "72 %"
    refute html =~ "style="
  end

  test "bar draws the target at its exact share" do
    assigns = %{}
    assert attr(parse(~H|<.bar label="A" value={10} target={12.5} />|), "rect", "x") == "12.5%"

    assert attr(parse(~H|<.bar label="A" value={1} max={3} target={1} />|), "rect", "x") ==
             "33.333%"

    assert attr(parse(~H|<.bar label="A" value={1} target={130} />|), "rect", "x") == "100%"
    assert attr(parse(~H|<.bar label="A" value={1} target={-4} />|), "rect", "x") == "0%"
  end

  test "neutral bar stands alone in base-content" do
    assigns = %{}
    html = rendered_to_string(~H|<.bar label="Anteil" value={40} tone={:neutral} target={50} />|)
    doc = LazyHTML.from_fragment(html)
    assert classes(doc, "progress") == ~w(progress w-full setzkasten-progress-neutral)
    refute html =~ "style="

    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    assert css =~
             ~r/\.progress\.setzkasten-progress-neutral \{\s*color: color-mix\(in oklab, var\(--color-base-content\) 70%, transparent\);/
  end

  test "bar caps the bar at max but shows the real share" do
    assigns = %{}
    doc = parse(~H|<.bar label="Budget" value={112} tone={:error} show_value />|)
    assert attr(doc, "progress", "value") == "100"
    assert "progress-error" in classes(doc, "progress")
    assert text(doc, "span.tabular-nums") == "112 %"
  end

  test "avatar" do
    assigns = %{}
    doc = parse(~H|<.avatar initials="KD" size={:sm} />|)
    assert attr(doc, ".avatar", "aria-hidden") == "true"
    assert classes(doc, ".avatar > div") == ~w(bg-base-300 text-base-content w-8 rounded-field)
    doc = parse(~H|<.avatar initials="KD" tone={:primary} />|)
    assert "bg-primary" in classes(doc, ".avatar > div")
    doc = parse(~H|<.avatar icon="user" shape={:round} label="Person" />|)
    assert attr(doc, ".avatar", "role") == "img"
    assert "rounded-full" in classes(doc, ".avatar > div")
  end

  test "chart card frame with hook, summary and data disclosure" do
    assigns = %{}

    doc =
      parse(~H"""
      <.chart_card id="nw" title="Vermögen" hook="NetWorth" summary="steigt">
        <:data>
          <p>Werte</p>
        </:data>
      </.chart_card>
      """)

    assert attr(doc, "[role=img]", "aria-label") == "steigt"
    assert attr(doc, "#nw-chart", "phx-hook") == "NetWorth"
    assert attr(doc, "#nw-chart", "phx-update") == "ignore"
    assert text(doc, "summary") == "Werte als Tabelle"

    assert count(parse(~H|<.chart_card id="x" title="t" summary="s" loading />|), ".skeleton") ==
             1
  end

  test "legend uses chart tokens" do
    assigns = %{}
    doc = parse(~H|<.legend items={[%{label: "A", color: 1}, %{label: "B", color: :error}]} />|)
    assert "bg-chart-1-fill" in classes(doc, "li:first-child span")
    assert "border-chart-1" in classes(doc, "li:first-child span")
    assert "bg-error-ink" in classes(doc, "li:last-child span")
  end

  test "legend takes global attrs and line markers in the series' line colour" do
    assigns = %{}

    doc =
      parse(~H"""
      <.legend
        id="lg"
        items={[
          %{label: "Kurs", color: 1, marker: :line},
          %{label: "Einstand", color: :neutral, marker: :dashed},
          %{label: "Punkt", color: 2}
        ]}
      />
      """)

    assert attr(doc, "ul", "id") == "lg"
    assert "stroke-chart-1" in classes(doc, "li:nth-child(1) svg")
    assert attr(doc, "li:nth-child(1) line", "stroke-dasharray") == nil
    assert "stroke-base-content/70" in classes(doc, "li:nth-child(2) svg")
    assert attr(doc, "li:nth-child(2) line", "stroke-dasharray") == "4 2"
    assert attr(doc, "li:nth-child(2) svg", "aria-hidden") == "true"
    assert "rounded-full" in classes(doc, "li:nth-child(3) span")
  end

  test "lists and table bodies are focus fallbacks for removed rows" do
    assigns = %{}

    list = parse(~H|<.list id="l"><.list_row title="A" /></.list>|)
    assert attr(list, "ul.list", "data-focus-fallback") != nil

    table =
      parse(~H"""
      <.table id="t" rows={[%{id: 1}]}>
        <:col :let={r} label="Id">{r.id}</:col>
      </.table>
      """)

    assert attr(table, "tbody#t", "data-focus-fallback") != nil
  end

  test "list row menu returns focus to its toggle" do
    assigns = %{}

    doc =
      parse(~H"""
      <.list_row id="r1" title="Herbst" navigate="/p/1">
        <:action label="Bearbeiten" icon="pencil" patch="/p/1/edit" />
        <:action label="Löschen" icon="trash-2" confirm="Löschen?" on_click="delete" />
      </.list_row>
      """)

    assert attr(doc, "details summary", "phx-keydown") =~ "focus_first"
    assert attr(doc, "details li a", "phx-keydown") =~ "focus_first"
    closest = ~s(["focus_first",{"to":{"closest":"details"}}])
    assert attr(doc, "details li a", "phx-click") =~ closest
    assert attr(doc, "details li button", "phx-click") =~ closest
    assert attr(doc, "details li button", "phx-click") =~ "confirm-delete"
  end

  test "list row titles and description list values break long strings" do
    assigns = %{}
    row = parse(~H|<.list_row title="a-very-long-hostname.example.com" navigate="/p/1" />|)
    assert "wrap-anywhere" in classes(row, ".list-col-grow a")
    plain = parse(~H|<.list_row title="a-very-long-hostname.example.com" />|)
    assert "wrap-anywhere" in classes(plain, ".list-col-grow p")
    doc = parse(~H|<.description_list>
  <:item label="Host">x</:item>
</.description_list>|)
    assert Enum.all?(~w(min-w-0 wrap-anywhere), &(&1 in classes(doc, "dd")))
  end

  test "a list row without on_click keeps phx-click and phx-target on the li" do
    assigns = %{myself: %Phoenix.LiveComponent.CID{cid: 3}}

    doc =
      parse(~H"""
      <.list><.list_row title="Herbst" phx-click="select" phx-target={@myself} /></.list>
      """)

    assert attr(doc, "li.list-row", "phx-click") == "select"
    assert attr(doc, "li.list-row", "phx-target") == "3"
  end

  test "list row with on_click renders the title as a button over the row" do
    assigns = %{myself: %Phoenix.LiveComponent.CID{cid: 3}}

    doc =
      parse(~H"""
      <.list>
        <.list_row title="Herbst" on_click="open" phx-target={@myself}>
          <:meta>Meta</:meta>
        </.list_row>
      </.list>
      """)

    assert attr(doc, ".list-col-grow button", "type") == "button"
    assert text(doc, ".list-col-grow button") == "Herbst"

    assert [%{"event" => "open", "target" => 3}] =
             pushes(attr(doc, ".list-col-grow button", "phx-click"))

    button = classes(doc, ".list-col-grow button")
    assert Enum.all?(~w(after:absolute after:inset-0 text-start), &(&1 in button))
    assert "focus-visible:after:outline-primary" in button
    assert "md:hover:bg-base-200" in classes(doc, "li.list-row")
    assert attr(doc, "li.list-row", "phx-target") == nil
    assert count(doc, ".list-col-grow p.font-medium") == 0

    doc = parse(~H|<.list_row title="Herbst" on_click={JS.push("open")} />|)
    assert [%{"event" => "open"}] = pushes(attr(doc, ".list-col-grow button", "phx-click"))
  end

  test "list row link rings the whole row on keyboard focus" do
    assigns = %{}
    doc = parse(~H|<.list_row title="Herbst" navigate="/p/1" />|)
    assert "focus-visible:after:outline-primary" in classes(doc, ".list-col-grow a")
    assert count(doc, ".list-col-grow button") == 0
  end

  test "list heading takes global attrs" do
    assigns = %{}
    doc = parse(~H|<.list_heading id="d-1" aria-live="polite">Heute</.list_heading>|)
    assert attr(doc, "li", "id") == "d-1"
    assert attr(doc, "li", "aria-live") == "polite"
  end

  test "amount can show the ISO code instead of the symbol" do
    assigns = %{}
    doc = parse(~H|<.amount value={110} currency="USD" currency_display={:code} />|)
    assert text(doc, "data") == "1,10 USD"
    assert text(parse(~H|<.amount value={110} currency="USD" />|), "data") == "1,10 $"
  end

  test "avatar shows a spinner while loading, keeping size and tone" do
    assigns = %{}
    doc = parse(~H|<.avatar initials="KD" tone={:success} size={:lg} loading label="Kim" />|)
    assert attr(doc, ".avatar", "aria-busy") == "true"
    assert attr(doc, ".avatar", "role") == "img"
    assert classes(doc, ".avatar > div") == ~w(bg-success text-success-content w-12 rounded-field)
    assert classes(doc, ".loading") == ~w(loading loading-spinner motion-reduce:hidden size-6)
    assert "motion-safe:hidden" in classes(doc, "svg.lucide")
    assert text(doc, ".avatar") == ""

    doc = parse(~H|<.avatar initials="KD" />|)
    assert attr(doc, ".avatar", "aria-busy") == nil
    assert count(doc, ".loading") == 0

    # Hidden from screen readers without a label, so no busy state that nobody hears.
    doc = parse(~H|<.avatar initials="KD" loading />|)
    assert attr(doc, ".avatar", "aria-hidden") == "true"
    assert attr(doc, ".avatar", "aria-busy") == nil
    assert count(doc, ".loading") == 1
  end

  test "list row keeps a short trailing value on the title line on phones" do
    assigns = %{}

    doc =
      parse(~H"""
      <.list_row title="Depot A" navigate="/p/1" trailing_on_phone={:title}>
        <:leading><.icon name="info" /></:leading>
        <:meta>2 Wertpapiere</:meta>
        <:trailing :let={place}>
          <.amount id={"value-#{place}"} value={949_047} />
          <span>+1,7 %</span>
        </:trailing>
      </.list_row>
      """)

    title = classes(doc, ".list-col-grow > div:has(> #value-title)")
    assert Enum.all?(~w(float-end flex-col items-end text-end md:hidden), &(&1 in title))
    # The float comes before the title, so the meta line takes the width below it.
    assert attr(doc, ".list-col-grow > :first-child #value-title", "id") == "value-title"
    column = classes(doc, "li > div:has(> #value-column)")
    assert "max-md:hidden" in column
    refute "max-md:row-start-2" in column
    refute "max-md:gap-y-1" in classes(doc, "li")
  end

  test "wrapped trailing lines align at the start on phones" do
    assigns = %{}

    doc =
      parse(~H"""
      <.list_row title="T">
        <:trailing>
          <div class="text-end">1 €<br />2 %</div>
        </:trailing>
      </.list_row>
      """)

    assert "max-md:[&_.text-end]:text-start" in classes(doc, "li > div:has(> .text-end)")
  end

  test "meta separator never starts a line" do
    assigns = %{}
    html = rendered_to_string(~H|<p>2 Wertpapiere<.meta_sep />Konto</p>|)
    assert html == "<p>2 Wertpapiere\u2060\u00A0· Konto</p>"
    assert join_meta(["Referenzkonto", nil, "", "EUR"]) == "Referenzkonto\u2060\u00A0· EUR"
    # The same separator as <.meta_sep />.
    assert join_meta(["2 Wertpapiere", "Konto"]) == "2 Wertpapiere\u2060\u00A0· Konto"
    assert join_meta(["Referenzkonto", nil]) == "Referenzkonto"
    assert join_meta(["Referenzkonto", false && "geteilt"]) == "Referenzkonto"
  end

  test "description list emphasises strong items and the total" do
    assigns = %{}

    doc =
      parse(~H"""
      <.description_list>
        <:item label="Anfangswert" strong>10 €</:item>
        <:item label="Einzahlungen">5 €</:item>
        <:item label="Endwert" total>15 €</:item>
      </.description_list>
      """)

    [start, line, total] =
      doc |> find("dl > div") |> LazyHTML.attribute("class") |> Enum.map(&String.split/1)

    assert "font-semibold" in start
    refute "font-semibold" in line
    assert Enum.all?(~w(font-semibold border-t border-t-base-content/30), &(&1 in total))
    # Marked items stand out because the others drop to regular weight.
    refute doc |> find("dd") |> LazyHTML.attribute("class") |> Enum.any?(&(&1 =~ "font-medium"))

    plain = parse(~H|<.description_list>
  <:item label="TER">0,22 %</:item>
</.description_list>|)
    assert "font-medium" in classes(plain, "dd")
    # Facts are data: 14px like tables.
    assert "text-sm" in classes(plain, "dl")
  end

  test "a stat with an id carries the change hook on its value; without one, none" do
    assigns = %{}
    doc = parse(~H|<.stat id="pv" label="PV" value="1.234" unit="W" />|)
    assert attr(doc, ".stat", "id") == "pv"
    assert attr(doc, "#pv-value", "phx-hook") == "Setzkasten.Components.Data.LiveValue"
    assert text(doc, "#pv-value > span:first-child") == "1.234"

    assert count(parse(~H|<.stat label="PV" value="1" />|), "[phx-hook]") == 0

    assert count(parse(~H|<.stat id="pv" label="PV" value="1" animate={false} />|), "[phx-hook]") ==
             0
  end

  test "an animated amount needs an id and carries the change hook" do
    assigns = %{}
    doc = parse(~H|<.amount id="b" value={-7420} signed tone animate />|)
    assert attr(doc, "data", "phx-hook") == "Setzkasten.Components.Data.LiveValue"
    assert attr(parse(~H|<.amount value={1} />|), "data", "phx-hook") == nil

    assert_raise ArgumentError, ~r/needs an id/, fn ->
      parse(~H|<.amount value={1} animate />|)
    end
  end

  test "the change hook reads the motion tokens and has no glow" do
    hook = colocated_js("Setzkasten.Components.Data")
    assert hook =~ "--setzkasten-duration-count"
    refute hook =~ "glow"
    assert hook =~ "prefers-reduced-motion: reduce"

    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    assert css =~ "--setzkasten-duration-count: 500ms"
    refute css =~ "glow"
  end
end
