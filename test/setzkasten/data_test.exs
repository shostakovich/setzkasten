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
    assert classes(doc, "table") == ~w(table tabular-nums table-sm table-zebra)
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

    assert classes(doc, "tbody tr") == ~w(relative row-hover)
    assert attr(doc, "tbody tr:first-child td:first-child a", "href") == "/w/1"
    assert count(doc, "td:last-child a") == 0
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
    assert classes(doc, ".avatar > div") == ~w(bg-primary text-primary-content w-8 rounded-field)
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
end
