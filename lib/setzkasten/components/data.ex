defmodule Setzkasten.Components.Data do
  @moduledoc """
  Tables, lists, amounts, stats, fact lists, bars, avatars and the chart frame.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.ColocatedHook
  alias Phoenix.LiveView.JS
  alias Setzkasten.Format
  import Setzkasten.Components.Icons
  import Setzkasten.Click, only: [click_js: 2, entry_click: 2]
  import Setzkasten.Components.Overlays, only: [disclosure: 1]

  @show_from %{
    nil => nil,
    sm: "hidden sm:table-cell",
    md: "hidden md:table-cell",
    lg: "hidden lg:table-cell",
    xl: "hidden xl:table-cell",
    "2xl": "hidden 2xl:table-cell"
  }

  @hide_from %{
    nil => nil,
    sm: "sm:hidden",
    md: "md:hidden",
    lg: "lg:hidden",
    xl: "xl:hidden",
    "2xl": "2xl:hidden"
  }
  @block_from %{
    nil => nil,
    sm: "hidden sm:block",
    md: "hidden md:block",
    lg: "hidden lg:block",
    xl: "hidden xl:block",
    "2xl": "hidden 2xl:block"
  }
  @breakpoints [:sm, :md, :lg, :xl, :"2xl"]

  @flat "border-y border-base-content/10 max-sm:-mx-4"
  # Word joiner and no-break space glue the dot to the part before it; it breaks after.
  @meta_sep "\u2060\u00A0· "

  @doc """
  Class list for a table cell that appears from breakpoint `bp` on (`:sm`, `:md`, `:lg`,
  `:xl`, `:"2xl"`). Use it on `:foot` cells of columns with `show_from`.
  """
  def show_from(bp), do: Map.fetch!(@show_from, bp)

  @doc """
  A data table (`table tabular-nums`), as Phoenix's `<.table>` with streams, plus column
  priorities, group rows, a total row and an empty row. Text is 14px and the cell padding at
  the sides the same in every `size`, so the edges line up:

    * `:md` (default): 45px rows.
    * `:sm`: 8px instead of 12px above and below a cell, about 37px rows, for read-only data
      next to other content; rows grow with their content and are no touch targets.
    * `:dense`: data grids (a register, a budget). Rows are 36px on fine pointers and 44px on
      coarse ones; inputs, selects and buttons in cells are 32px high (44px on coarse
      pointers), so an editable row keeps the row height. Use it for rows that are targets
      (`row_link`, controls) or many rows to scan.

  Flat by default: the table sits on the page between `border-y` hairlines and
  runs edge to edge on phones. `flush` drops both for a card's `:list` slot or a modal.

  `:col` attrs: `label`, `align` (`:end` right-aligns with tabular figures), `show_from`
  (`:sm` … `:"2xl"`, hides the column below), `class`. `row_link` turns the first cell into a
  link stretched over the row; a row for which it returns `nil` has no link and no hover.
  `row_attrs` returns extra attributes for a row's `<tr>` (`aria-current`, `data-*`,
  `hidden`, …) as a map or keyword list, or `nil` for none; its `class` is added to the row's
  own classes, an `id` is dropped (`row_id` and streams own the row ids). A row with
  `aria-current` (the current row, e.g. the one open in a side panel or in edit) or
  `aria-selected="true"` (in a `role="grid"`) takes the `row-selected` fill and a 3px bar at
  its start. The bar belongs to the first cell, so such a table keeps its first column visible.
  Both get the row item, also with streams and `groups`. `groups` is a list of
  `%{id, label, rows}`, one `<tbody>` each. `:foot` holds the cells of the total row (use
  `show_from/1` on hidden columns).

      <.table id="activity" rows={@entries} size={:sm} zebra>
        <:col :let={e} label="Datum">{e.date}</:col>
        <:col :let={e} label="Betrag" align={:end}><.amount value={e.amount} tone /></:col>
        <:empty><.empty_state icon="inbox">Noch keine Buchungen.</.empty_state></:empty>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :any, default: []
  attr :groups, :list, default: nil
  attr :row_id, :any, default: nil
  attr :row_item, :any, default: &Function.identity/1
  attr :row_link, :any, default: nil, doc: "fn row -> path or nil, navigated on click"

  attr :row_attrs, :any,
    default: nil,
    doc: "fn row -> map or keyword list of `<tr>` attributes, or nil"

  attr :size, :atom, default: :md, values: [:md, :sm, :dense]
  attr :zebra, :boolean, default: false
  attr :flush, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  slot :col, required: true do
    attr :label, :string
    attr :align, :atom, values: [:start, :end]
    attr :show_from, :atom, values: @breakpoints
    attr :class, :any
  end

  slot :foot
  slot :empty

  def table(assigns) do
    assigns = prepare_rows(assigns)

    ~H"""
    <div class={["overflow-x-auto", !@flush && flat(), @class]} {@rest}>
      <table class={["table tabular-nums", size_class(@size), @zebra && "table-zebra"]}>
        <thead>
          <tr>
            <th :for={col <- @col} scope="col" class={col_class(col)}>{col[:label]}</th>
          </tr>
        </thead>
        <tbody :if={@groups == nil} id={@id} phx-update={@stream? && "stream"} data-focus-fallback>
          {table_rows(assigns, @rows)}
          <tr :if={@empty != []} id={"#{@id}-empty"} class="hidden only:table-row">
            <td colspan={length(@col)}>{render_slot(@empty)}</td>
          </tr>
        </tbody>
        <tbody :for={group <- @groups || []} id={"#{@id}-#{group.id}"} data-focus-fallback>
          <tr>
            <th scope="colgroup" colspan={length(@col)} class="bg-base-200 text-xs font-semibold">
              {group.label}
            </th>
          </tr>
          {table_rows(assigns, group.rows)}
        </tbody>
        <tfoot :if={@foot != []}>
          <tr class="font-semibold">{render_slot(@foot)}</tr>
        </tfoot>
      </table>
    </div>
    """
  end

  defp prepare_rows(%{rows: %Phoenix.LiveView.LiveStream{}} = assigns) do
    row_item = assigns.row_item

    assign(assigns,
      row_id: assigns.row_id || fn {id, _item} -> id end,
      row_item: fn {_id, item} -> row_item.(item) end,
      stream?: true
    )
  end

  defp prepare_rows(assigns), do: assign(assigns, :stream?, false)

  defp table_rows(assigns, rows) do
    assigns = assign(assigns, :rows, rows)

    ~H"""
    <.table_row
      :for={row <- @rows}
      id={@row_id && @row_id.(row)}
      item={@row_item.(row)}
      col={@col}
      row_link={@row_link}
      row_attrs={@row_attrs}
    />
    """
  end

  attr :id, :any, required: true
  attr :item, :any, required: true
  attr :col, :list, required: true
  attr :row_link, :any, required: true
  attr :row_attrs, :any, required: true

  defp table_row(assigns) do
    {class, attrs} = tr_attrs(assigns.row_attrs, assigns.item)

    assigns =
      assign(assigns,
        path: assigns.row_link && assigns.row_link.(assigns.item),
        class: class,
        attrs: attrs
      )

    ~H"""
    <tr
      id={@id}
      class={[@path && "relative row-hover has-[td:first-child>a:active]:bg-base-200", @class]}
      {@attrs}
    >
      <td :for={{col, i} <- Enum.with_index(@col)} class={col_class(col)}>
        <.link :if={i == 0 && @path} navigate={@path} class={["font-medium", stretched()]}>
          {render_slot(col, @item)}
        </.link>
        <%= if i > 0 || !@path do %>
          {render_slot(col, @item)}
        <% end %>
      </td>
    </tr>
    """
  end

  # `row_attrs` of a row: nil adds nothing, `class` joins the row's classes, the id stays the
  # table's.
  defp tr_attrs(nil, _item), do: {nil, %{}}

  defp tr_attrs(fun, item) do
    {class, attrs} = (fun.(item) || %{}) |> Map.new() |> Map.pop(:class)
    {string_class, attrs} = Map.pop(attrs, "class")
    {[class, string_class], Map.drop(attrs, [:id, "id"])}
  end

  defp flat, do: @flat

  # Not daisyUI's table-sm: its 12px text and narrower padding would not line up with :md.
  defp size_class(:md), do: nil
  defp size_class(:sm), do: "[&_:is(th,td)]:py-2"
  defp size_class(:dense), do: "setzkasten-table-dense"

  defp col_class(col) do
    [
      col[:align] == :end && "text-end tabular-nums whitespace-nowrap",
      Map.fetch!(@show_from, col[:show_from]),
      col[:class]
    ]
  end

  @doc """
  The separator of a meta line (header subtitle, stat note, `cell_sub`, list row meta): a
  middle dot that never starts a line. It is glued to the part before it (word joiner and
  no-break space) and breaks after it, so wrapped meta ends a line with "·". Write it without
  a space before it: `{@count} Wertpapiere<.meta_sep /><.amount value={@cash} />`. For plain
  strings use `join_meta/1`.
  """
  def meta_sep(assigns), do: ~H|{meta_sep_text()}|

  defp meta_sep_text, do: @meta_sep

  @doc """
  Joins the parts of a meta line with the separator of `meta_sep/1`, so the dot never starts a
  line. `nil`, `false` and `""` parts are left out, so an optional part (`cond && part`) leaves
  no dangling dot.

      join_meta(["IE00BK5BQT80", nil, "Langfristig"]) #=> "IE00BK5BQT80\u2060\u00A0· Langfristig"
  """
  def join_meta(parts) when is_list(parts) do
    parts |> Enum.reject(&(&1 in [nil, false, ""])) |> Enum.join(@meta_sep)
  end

  @doc """
  The values of hidden columns, repeated under the visible ones (`text-sm`, 70 %).
  `hide_from` hides it from that breakpoint; `show_from` shows it only from there.

      <.cell_sub hide_from={:lg}>{h.shares} Stück<.meta_sep /><.amount value={h.price} /></.cell_sub>
  """
  attr :hide_from, :atom, default: nil, values: [nil | @breakpoints]
  attr :show_from, :atom, default: nil, values: [nil | @breakpoints]
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def cell_sub(assigns) do
    ~H"""
    <div class={[
      "text-sm font-normal text-base-content/70",
      Map.fetch!(hide_from_classes(), @hide_from),
      Map.fetch!(block_from_classes(), @show_from),
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp hide_from_classes, do: @hide_from
  defp block_from_classes, do: @block_from

  @doc """
  A daisyUI `list`. Flat by default (between `border-y` hairlines, edge to edge on phones);
  `flush` for a card's `:list` slot. Supports streams via `phx-update="stream"` and `id`.

      <.list id="posts" phx-update="stream">
        <.list_row :for={{id, post} <- @streams.posts} id={id} title={post.title} navigate={~p"/posts/\#{post}"}>
          <:meta>Geändert am 07.10.2026</:meta>
        </.list_row>
      </.list>

  `:foot` is a total row ("Summe") under the rows, its value at the end of the rows' trailing
  column. When the rows have `:action`s, give the foot their count (`actions`, the buttons the
  rows show from `md`), `menu` and `actions_class`: it keeps an invisible copy of that column,
  so the value lines up from `md`, on phones with the rows' `trailing_on_phone={:title}`. Its
  `class` goes on the value, as a trailing's does (`md:w-40`). It takes the list's `id` with
  `-foot`, so in a stream LiveView keeps it and adds rows above it.

      <.list>
        <.list_row :for={b <- @bookings} title={b.title}>…<:action label="Löschen" … /></.list_row>
        <:foot label="Summe" actions={1}><.amount value={@total} /></:foot>
      </.list>
  """
  attr :id, :string, default: nil
  attr :flush, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  slot :foot, doc: "a total row whose value lines up with the rows' trailing column" do
    attr :label, :string, required: true
    attr :actions, :integer, doc: "the action buttons the rows show from `md`"
    attr :menu, :atom, values: [:responsive, :always], doc: "as the rows' `menu`"
    attr :actions_class, :any, doc: "as the rows' `actions_class`"
    attr :class, :any, doc: "on the value, as on a row's `:trailing`"
  end

  def list(assigns) do
    ~H"""
    <ul id={@id} class={["list", !@flush && flat(), @class]} data-focus-fallback {@rest}>
      {render_slot(@inner_block)}
      <li
        :for={{foot, i} <- Enum.with_index(@foot)}
        id={@id && foot_id(@id, i)}
        class="list-row items-center rounded-none border-t border-base-content/30 font-semibold"
      >
        <div class="list-col-grow min-w-0">{foot.label}</div>
        <div class={["flex items-center justify-end gap-2 text-end tabular-nums", foot[:class]]}>
          {render_slot(foot)}
        </div>
        <div
          :if={(foot[:actions] || 0) > 0}
          class={["invisible hidden gap-1 md:flex", foot[:actions_class]]}
          aria-hidden="true"
        >
          <span :for={_ <- 1..foot[:actions]//1} class="btn btn-ghost btn-sm btn-square"></span>
        </div>
        <div
          :if={(foot[:actions] || 0) > 0 or foot[:menu] == :always}
          class={["invisible", foot[:menu] != :always && "md:hidden"]}
          aria-hidden="true"
        >
          <span class="btn btn-ghost btn-sm btn-square"></span>
        </div>
      </li>
    </ul>
    """
  end

  defp foot_id(id, 0), do: "#{id}-foot"
  defp foot_id(id, i), do: "#{id}-foot-#{i}"

  @doc "A group heading inside `<.list>` (e.g. a date). Global attrs (`id`, …) land on the `<li>`."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def list_heading(assigns) do
    ~H"""
    <li class={["px-4 pt-4 text-xs font-semibold text-base-content/70", @class]} {@rest}>
      {render_slot(@inner_block)}
    </li>
    """
  end

  @doc """
  A list row: `:leading` (plush, icon, avatar), title (`title` or the inner block,
  `font-medium`), `:meta` (70 %, truncates; each `:meta` is a line of its own), `:trailing`
  (value, amount, badge) and `:action` entries. With `navigate`/`patch`/`href` the title link covers the row, which takes a light
  fill under the pointer (no chevron: the row's title and its hover say it opens). With
  `on_click` instead (an event name with `phx-target={@myself}`, or a `%JS{}` that carries its
  own target: `JS.push("open", target: @myself)`) the
  title is a `<button type="button">` that covers the row the same way, e.g. to open a dialog.
  Keyboard focus rings the whole row. Without `on_click`, `phx-click` and `phx-target` stay on
  the `<li>`.

  Actions are icon buttons from `md` and fold into a `⋮` menu below (Escape and choosing an
  entry return focus to the `⋮` button). `menu={:always}` uses the `⋮` menu at every width,
  e.g. when the actions are rare or destructive and should not sit on every row. Each `:action` takes
  `label`, `icon`, a target (`navigate`/`patch`/`href`, or `on_click` as event name or
  `%JS{}`; `phx-target={@myself}` sends an event name to a live component, a `%JS{}` carries
  its own target), and optionally `confirm` (+ `confirm_text`, `confirm_label`) for the shared
  confirmation dialog, `danger` (red in the menu), `disabled` and `id` (the icon button; the
  menu entry gets `<id>-menu-item`, the `⋮` button of a row with `id` gets `<row id>-menu-toggle`).
  `title` also names the actions for screen readers (`"Bearbeiten: Herbst"`, menu
  `"Aktionen: Herbst"`).

  Below `md` the `:trailing` content (a badge, a value) moves into a second line under the
  title and meta, so the title keeps the width next to the `⋮` menu and the chevron. With
  `trailing_on_phone={:meta}` it goes to the end of the meta line instead (a status that is
  only there now and then, so rows keep two lines), and wraps below it only when the line is
  full, so neither gets cut; it then renders twice and receives where
  (`:meta`, `:column`) for unique ids. With `trailing_on_phone={:title}` a short value (an
  amount, optionally with a small second line such as a percentage) stays at the end of the
  title line, its lines right-aligned to each other, and the meta line takes the full width
  below it (or sits beside the second line), as in a bank statement; it renders twice, with
  `:title` and `:column`. Wrapped below the title (the default), the trailing lines align at
  the start, also where the content carries `text-end` for the column. `<:trailing class="md:w-40 md:justify-start">` gives the
  trailing column a fixed width, so badges line up from row to row even when most rows have none.

  With `menu={:always}` an action marked `inline` still shows as an icon button from `md`
  (e.g. move up and down), the others only in the `⋮` menu. `actions_class` sets the width of
  the icon buttons' column (e.g. `md:w-20 justify-end`), so trailing columns line up across
  lists whose rows have a different number of actions.

      <.list_row title={post.title} navigate={~p"/posts/\#{post}"}>
        <:leading><.icon name="file-text" class="size-5 text-base-content/70" /></:leading>
        <:meta>{join_meta(["Geändert am 07.10.2026", "1.240 Wörter"])}</:meta>
        <:trailing><.badge tone={:success}>Veröffentlicht</.badge></:trailing>
        <:action label="Bearbeiten" icon="pencil" navigate={~p"/posts/\#{post}/edit"} />
        <:action label="Löschen" icon="trash-2" danger confirm="Post löschen?"
                 on_click={JS.push("delete", value: %{id: post.id})} />
      </.list_row>
  """
  attr :id, :string, default: nil
  attr :title, :string, default: nil
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :href, :string, default: nil
  attr :on_click, :any, default: nil, doc: "event name or `%JS{}`; the title becomes a button"

  attr :"phx-target", :any,
    default: nil,
    doc: "for an event name in `on_click`; without `on_click` it stays on the `<li>`"

  attr :actions_label, :string, default: "Aktionen"
  attr :menu, :atom, default: :responsive, values: [:responsive, :always]
  attr :trailing_on_phone, :atom, default: :line, values: [:line, :meta, :title]
  attr :actions_class, :any, default: nil, doc: "the icon buttons' column, e.g. a fixed width"
  attr :confirm_id, :string, default: "confirm-delete"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block
  slot :leading
  slot :meta

  slot :trailing do
    attr :class, :any
  end

  slot :action do
    attr :label, :string, required: true
    attr :icon, :string
    attr :navigate, :string
    attr :patch, :string
    attr :href, :string
    attr :method, :string
    attr :on_click, :any
    attr :"phx-target", :any, doc: "for an event name in `on_click`, e.g. `@myself`"
    attr :confirm, :string
    attr :confirm_text, :string
    attr :confirm_label, :string
    attr :danger, :boolean
    attr :disabled, :boolean, doc: "e.g. Move up on the first row; keeps its place"
    attr :id, :string, doc: "id of the icon button; the menu entry gets `<id>-menu-item`"
    attr :inline, :boolean, doc: "with `menu={:always}`: also an icon button from `md`"
  end

  def list_row(assigns) do
    assigns =
      assign(assigns,
        link?: Enum.any?([assigns.navigate, assigns.patch, assigns.href]),
        title_click: assigns.on_click && click_js(assigns.on_click, assigns[:"phx-target"]),
        menu_label:
          if(assigns.title,
            do: "#{assigns.actions_label}: #{assigns.title}",
            else: assigns.actions_label
          ),
        wrap?: assigns.trailing != [] and assigns.trailing_on_phone == :line,
        meta_lines: meta_lines(assigns),
        meta_trailing?: assigns.trailing != [] and assigns.trailing_on_phone == :meta,
        title_trailing?: assigns.trailing != [] and assigns.trailing_on_phone == :title,
        inline_actions:
          if(assigns.menu == :always,
            do: Enum.filter(assigns.action, & &1[:inline]),
            else: assigns.action
          ),
        grow_column:
          if(assigns.leading != [], do: "max-md:col-start-2", else: "max-md:col-start-1")
      )

    ~H"""
    <li
      id={@id}
      class={[
        "list-row items-center",
        (@link? || @title_click) &&
          "md:hover:bg-base-200 has-[.list-col-grow>:is(a,button):active]:bg-base-200",
        @wrap? && "max-md:gap-y-1",
        @class
      ]}
      phx-target={!@on_click && assigns[:"phx-target"]}
      {@rest}
    >
      <div
        :if={@leading != []}
        class={["flex items-center", @wrap? && "max-md:row-[1/span_2] max-md:self-start"]}
      >
        {render_slot(@leading)}
      </div>
      <div class="list-col-grow min-w-0">
        <%!-- Floats at the end of the title line; the meta line (truncate makes it a block
             formatting context) takes the full width below it, or sits beside a second line. --%>
        <div
          :if={@title_trailing?}
          class="float-end ms-3 flex flex-col items-end text-end tabular-nums md:hidden"
        >
          {render_slot(@trailing, :title)}
        </div>
        <.link
          :if={@link?}
          navigate={@navigate}
          patch={@patch}
          href={@href}
          class={["font-medium wrap-anywhere", stretched()]}
        >
          {@title}{render_slot(@inner_block)}
        </.link>
        <button
          :if={!@link? && @title_click}
          type="button"
          class={["block cursor-pointer text-start font-medium wrap-anywhere", stretched()]}
          phx-click={@title_click}
        >
          {@title}{render_slot(@inner_block)}
        </button>
        <p :if={!@link? && !@title_click} class="font-medium wrap-anywhere">
          {@title}{render_slot(@inner_block)}
        </p>
        <p :for={line <- @meta_lines} class="text-sm text-base-content/70 truncate">
          {render_slot(line)}
        </p>
        <div
          :if={@meta_trailing?}
          class="flex min-w-0 flex-wrap items-center gap-x-2 text-sm text-base-content/70"
        >
          <p :if={@meta != []} class="min-w-0 max-w-full truncate">
            {render_slot(List.last(@meta))}
          </p>
          <div class="flex shrink-0 items-center gap-2 md:hidden">
            {render_slot(@trailing, :meta)}
          </div>
        </div>
      </div>
      <div
        :for={trailing <- @trailing}
        class={[
          "flex flex-wrap items-center gap-2 md:justify-end md:text-end",
          if(@meta_trailing? or @title_trailing?,
            do: "max-md:hidden",
            else: [
              "max-md:row-start-2 max-md:min-w-0 max-md:[&_.text-end]:text-start",
              @grow_column
            ]
          ),
          trailing[:class]
        ]}
      >
        {render_slot(trailing, :column)}
      </div>
      <div
        :if={@inline_actions != []}
        class={["relative z-10 hidden md:flex gap-1", @actions_class]}
      >
        <%= for action <- @inline_actions do %>
          <.link
            :if={action_link?(action)}
            navigate={action[:navigate]}
            patch={action[:patch]}
            href={action[:href]}
            method={action[:method]}
            id={action[:id]}
            class="btn btn-ghost btn-sm btn-square"
            aria-label={action_label(action, @title)}
          >
            <.icon name={action[:icon] || "chevron-right"} />
          </.link>
          <button
            :if={!action_link?(action)}
            type="button"
            id={action[:id]}
            class="btn btn-ghost btn-sm btn-square"
            aria-label={action_label(action, @title)}
            aria-haspopup={action[:confirm] && "dialog"}
            disabled={action[:disabled]}
            phx-click={entry_click(action, @confirm_id)}
          >
            <.icon name={action[:icon] || "chevron-right"} />
          </button>
        <% end %>
      </div>
      <details
        :if={@action != []}
        class={
          [
            "dropdown dropdown-end relative z-10 open:z-20",
            @menu == :responsive && "md:hidden",
            @wrap? && "max-md:row-[1/span_2]",
            # Centred on the title line, beside the amount, at either button height.
            @title_trailing? && "max-md:self-start max-md:translate-y-[calc(0.5lh-50%)]"
          ]
        }
        phx-mounted={JS.ignore_attributes(["open"])}
        phx-click-away={JS.remove_attribute("open")}
        phx-window-keydown={JS.remove_attribute("open")}
        phx-key="Escape"
      >
        <summary
          id={@id && "#{@id}-menu-toggle"}
          class="btn btn-ghost btn-sm btn-square"
          aria-label={@menu_label}
          phx-keydown={close_menu({:closest, "details"})}
          phx-key="Escape"
        >
          <.icon name="ellipsis-vertical" />
        </summary>
        <ul class="menu dropdown-content bg-popover rounded-box border border-base-content/10 shadow-lg z-10 w-56">
          <li
            :for={action <- @action}
            class={[
              action[:disabled] && "menu-disabled",
              @menu == :always && action[:inline] && "md:hidden"
            ]}
          >
            <.link
              :if={action_link?(action)}
              navigate={action[:navigate]}
              patch={action[:patch]}
              href={action[:href]}
              method={action[:method]}
              id={action[:id] && "#{action[:id]}-menu-item"}
              class={action[:danger] && "text-error-ink"}
              phx-click={close_menu({:closest, "details"})}
              phx-keydown={close_menu({:closest, "details"})}
              phx-key="Escape"
            >
              <.icon :if={action[:icon]} name={action[:icon]} />{action.label}
            </.link>
            <button
              :if={!action_link?(action)}
              type="button"
              id={action[:id] && "#{action[:id]}-menu-item"}
              class={action[:danger] && "text-error-ink"}
              disabled={action[:disabled]}
              aria-haspopup={action[:confirm] && "dialog"}
              phx-click={
                close_menu({:closest, "details"}) |> JS.concat(entry_click(action, @confirm_id))
              }
              phx-keydown={close_menu({:closest, "details"})}
              phx-key="Escape"
            >
              <.icon :if={action[:icon]} name={action[:icon]} />{action.label}
            </button>
          </li>
        </ul>
      </details>
    </li>
    """
  end

  # With the trailing content at the end of the meta line, the last line renders beside it.
  defp meta_lines(%{trailing: [_ | _], trailing_on_phone: :meta, meta: meta}),
    do: Enum.drop(meta, -1)

  defp meta_lines(%{meta: meta}), do: meta

  # The row link (table) or the title link or button (list) covers the row; keyboard focus
  # rings the row, not the text.
  # outline-solid: the ::after inherits --tw-outline-style: none from outline-none.
  defp stretched do
    [
      "after:absolute after:inset-0 focus-visible:outline-none",
      "focus-visible:after:outline-2 focus-visible:after:outline-solid",
      "focus-visible:after:-outline-offset-2 focus-visible:after:outline-primary"
    ]
  end

  # As in Navigation: close the row menu and focus its summary (Escape binding on each item).
  defp close_menu(to), do: JS.remove_attribute("open", to: to) |> JS.focus_first(to: to)

  defp action_link?(action), do: Enum.any?([action[:navigate], action[:patch], action[:href]])

  defp action_label(action, nil), do: action.label
  defp action_label(action, title), do: "#{action.label}: #{title}"

  @doc """
  Money in de-DE (`Setzkasten.Format.money/2`) inside `<data value>`, `tabular-nums`, no wrap.
  `tone` colours negative values `error-ink`, positive `success-ink`, zero 70 % (as shown, so
  a value that rounds to zero is zero). `tone={:negative}` colours only what needs attention:
  negative `error-ink`, zero 70 %, positive plain text, for balances in lists where green on
  every positive value would be noise. `decimals` (default 2; `0` for whole-currency KPIs)
  rounds half away from zero; `<data value>` keeps the exact value.
  `size={:lg}` for totals; inside `<.stat>` the stat sets the size. `currency_display={:code}`
  shows the ISO code instead of the symbol ("1,10 USD"), e.g. where several currencies meet.
  `minor_digits` says how many decimal places the integer's minor unit has: 2 by default, 0 for
  yen, 3 for dinar; `decimals` follows it unless given.

      <.amount value={-7420} signed tone />
      <.amount value={@account.balance} tone={:negative} />
      <.amount value={6_327_914} decimals={0} />
      <.amount value={110} currency="USD" currency_display={:code} />
      <.amount value={4850} currency="JPY" minor_digits={0} currency_display={:code} />

  `animate` (needs an `id`): when a LiveView update changes the value, it counts from the old to
  the new value. Never on first render. Inside a `<.stat>` value the stat does this already.

      <.amount id="balance" value={@balance} signed tone animate />
  """
  attr :value, :any, required: true, doc: "integer minor units (cents) or Decimal"
  attr :currency, :string, default: "EUR"
  attr :currency_display, :atom, default: :symbol, values: [:symbol, :code]
  attr :minor_digits, :integer, default: 2, doc: "decimal places of the integer's minor unit"
  attr :decimals, :integer, default: nil, doc: "shown decimal places; `minor_digits` by default"
  attr :signed, :boolean, default: false

  attr :tone, :any,
    default: false,
    values: [false, true, :negative],
    doc: "`true`: by sign; `:negative`: only negative and zero"

  attr :size, :atom, default: :inherit, values: [:inherit, :lg]
  attr :animate, :boolean, default: false, doc: "count on change; needs `id`"
  attr :class, :any, default: nil
  attr :rest, :global

  def amount(%{animate: true, rest: rest}) when not is_map_key(rest, :id) do
    raise ArgumentError, "<.amount animate> needs an id: LiveView hooks run on elements with one"
  end

  def amount(assigns) do
    assigns = assign(assigns, :decimals, assigns.decimals || assigns.minor_digits)

    ~H"""
    <data
      value={Format.machine(@value, minor_digits: @minor_digits)}
      phx-hook={@animate && "Setzkasten.Components.Data.LiveValue"}
      class={[
        "tabular-nums whitespace-nowrap",
        @tone && tone_class(Format.shown_sign(@value, @decimals, @minor_digits), @tone),
        @size == :lg && "text-lg font-semibold",
        @class
      ]}
      {@rest}
    >{Format.money(@value,
      currency: @currency,
      currency_display: @currency_display,
      signed: @signed,
      minor_digits: @minor_digits,
      decimals: @decimals
    )}</data>
    """
  end

  defp tone_class(-1, _tone), do: "text-error-ink"
  defp tone_class(1, true), do: "text-success-ink"
  defp tone_class(1, :negative), do: nil
  defp tone_class(0, _tone), do: "text-base-content/70"

  @doc """
  A KPI tile: daisyUI `stat` on base-100 with a hairline and `tabular-nums`.
  `size={:sm}` (`text-2xl`) for tile grids where 32px overflows. `tone` (`:success`,
  `:warning`, `:error`) colours the value with the ink tokens. `stale` adds a badge instead of fading the value;
  `loading` shows a skeleton in place of the value. The inner block replaces `value`.
  `desc` is a plain line under the value; the `:note` slot takes its place for markup (a
  toned delta, a date with a name) in the same small text.

  `:meter` holds a full-width meter under the value, before the note (a battery level as
  `<.bar label="Ladestand" value={82} hide_label />`): a block of its own, where a note is a
  line of inline text.

  `:figure` is a non-interactive widget at the end of the tile (daisyUI `stat-figure`): a
  plush, an icon, a gauge or a sparkline, centred beside the rows. Below `sm` it moves to the
  end of the label row and value and note take the full width, so a narrow tile keeps room for
  the number. It is hidden from screen readers; give it `label` when it says something the
  value does not (a gauge's verdict), and it becomes an image with that name.

  `navigate`, `patch` or `href` makes the tile a link to the KPI's detail page: the label is the
  link and covers the tile, `:meter` and `:figure` included, which takes a light fill under the
  pointer and on tap; keyboard focus rings the tile.

  With an `id`, a value that a LiveView update changes counts from the old to the new number
  (500 ms, `tabular-nums`); never on first render or a reconnect that brings the same value.
  Numbers in the components' German format ("2,14", "−0,88", "12.521,00 €"); the final text is
  the server's. `animate={false}` for values that change every second. Reduced motion: the new
  value stands at once.

  `setzkasten-stat-grid` on a grid of stats lets the tiles share its rows (subgrid, two rows a
  tile, three once one has a note), so a label on two lines keeps every value of the row level.
  Opt-in, as each tile then spans rows of the grid: leave it off where a stat places itself
  (`row-span-2`) or the grid sizes its rows (`auto-rows-fr`).

      <div class="setzkasten-stat-grid grid grid-cols-2 md:grid-cols-4 gap-4">
        <.stat label="PV jetzt" value="1.234" unit="W" desc="Akku 82 %" size={:sm} />
        <.stat label="Depot" value="63.279" unit="€">
          <:note><.amount value={50_000} signed tone /> heute</:note>
        </.stat>
        <.stat label="PV jetzt" value="486" unit="W" size={:sm}>
          <:figure><.plush name="sunny" size={:lg} /></:figure>
        </.stat>
        <.stat label="Dein Saldo" value="12,50" unit="€" navigate={~p"/salden"} />
      </div>
  """
  attr :id, :string, default: nil, doc: "needed for the change animation"
  attr :label, :string, required: true
  attr :value, :any, default: nil
  attr :unit, :string, default: nil
  attr :desc, :string, default: nil
  attr :tone, :atom, default: nil, values: [nil, :success, :warning, :error]
  attr :size, :atom, default: :md, values: [:md, :sm]
  attr :stale, :boolean, default: false
  attr :stale_label, :string, default: "veraltet"
  attr :loading, :boolean, default: false
  attr :animate, :boolean, default: true, doc: "count on change (with `id`)"
  attr :navigate, :string, default: nil, doc: "makes the tile a link (also `patch`, `href`)"
  attr :patch, :string, default: nil
  attr :href, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block
  slot :note, doc: "markup in place of `desc` (the slot wins)"

  slot :meter, doc: "a full-width meter under the value, e.g. `<.bar hide_label>`"

  slot :figure, doc: "a widget at the end of the tile: plush, icon, gauge, sparkline" do
    attr :label, :string, doc: "makes the figure an image with this name; hidden without"
  end

  def stat(assigns) do
    assigns =
      assign(assigns,
        live: assigns.id && assigns.animate,
        link?: Enum.any?([assigns.navigate, assigns.patch, assigns.href])
      )

    ~H"""
    <div
      id={@id}
      class={[
        "stat bg-base-100 rounded-box border border-base-content/10",
        @link? &&
          [
            "relative hover:bg-base-200 has-[a:active]:bg-base-200",
            "has-[a:focus-visible]:outline-2 has-[a:focus-visible]:outline-primary",
            "has-[a:focus-visible]:outline-offset-2"
          ],
        @class
      ]}
      aria-busy={@loading && "true"}
      {@rest}
    >
      <div class="stat-title">
        <.link
          :if={@link?}
          navigate={@navigate}
          patch={@patch}
          href={@href}
          class="after:absolute after:inset-0 after:z-1 after:rounded-box focus-visible:outline-none"
        >
          {@label}
        </.link>
        {if !@link?, do: @label}
      </div>
      <div
        :if={@loading}
        class={["skeleton h-8 w-full max-w-24 mt-1", @figure != [] && "max-sm:col-span-2"]}
      >
      </div>
      <div
        :if={!@loading}
        id={@live && "#{@id}-value"}
        phx-hook={@live && "Setzkasten.Components.Data.LiveValue"}
        class={[
          "stat-value tabular-nums",
          @figure != [] && "max-sm:col-span-2",
          @size == :sm && "text-2xl",
          @tone == :success && "text-success-ink",
          @tone == :warning && "text-warning-ink",
          @tone == :error && "text-error-ink"
        ]}
      >
        <span :if={@value}>{@value}</span>{render_slot(@inner_block)}
        <span :if={@unit} class="text-base font-semibold text-base-content/70">{@unit}</span>
      </div>
      <div
        :if={@meter != [] || @desc || @note != [] || @stale}
        class={[
          "stat-desc whitespace-normal",
          if(@meter != [],
            do: "mt-1 flex flex-col gap-1.5",
            else: "flex flex-wrap items-center gap-1"
          ),
          @figure != [] && "max-sm:col-span-2"
        ]}
      >
        <div :if={@meter != []}>{render_slot(@meter)}</div>
        <%= if @meter != [] do %>
          <div :if={@desc || @note != [] || @stale} class="flex flex-wrap items-center gap-1">
            {stat_note(assigns)}
          </div>
        <% else %>
          {stat_note(assigns)}
        <% end %>
      </div>
      <div
        :for={figure <- @figure}
        class="stat-figure w-max max-sm:[grid-row:1] max-sm:self-start"
        role={figure[:label] && "img"}
        aria-label={figure[:label]}
        aria-hidden={!figure[:label] && "true"}
      >
        {render_slot(figure)}
      </div>
    </div>
    <script :type={ColocatedHook} name=".LiveValue">
      const NUMBER = /^(.*?)([+\u2212-]?)(\d{1,3}(?:\.\d{3})+|\d+)(?:,(\d+))?(\D*)$/s
      const parse = (text) => {
        const m = NUMBER.exec(text)
        if (!m) return null
        const [, prefix, sign, int, frac = "", suffix] = m
        const units = Number(int.replace(/\./g, "") + frac)
        return {
          prefix, suffix, d: frac.length,
          units: sign && sign !== "+" ? -units : units,
          plus: sign === "+",
          minus: sign && sign !== "+" ? sign : null,
          ungrouped: !int.includes(".") && int.length > 3
        }
      }
      // Mirrors Setzkasten.Format: thousands dot, decimal comma, no sign on zero.
      const format = (units, t) => {
        const digits = String(Math.abs(units)).padStart(t.d + 1, "0")
        let int = t.d ? digits.slice(0, -t.d) : digits
        if (t.grouped) int = int.replace(/\B(?=(\d{3})+$)/g, ".")
        const sign = units === 0 ? "" : units < 0 ? t.minus : t.plus ? "+" : ""
        return t.prefix + sign + int + (t.d ? "," + digits.slice(-t.d) : "") + t.suffix
      }
      const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches
      const ms = (css, name, fallback) => {
        const v = css.getPropertyValue(name).trim()
        return v.endsWith("ms") ? parseFloat(v) : v.endsWith("s") ? parseFloat(v) * 1000 : fallback
      }
      export default {
        mounted() {
          this.node = this.find()
          this.text = this.node && this.node.data
        },
        updated() {
          const node = this.find()
          if (!node) return (this.node = this.text = null)
          const from = this.text && parse(this.shown ?? this.text)
          const to = parse(node.data)
          const changed = node.data !== this.text
          this.node = node
          this.text = node.data
          if (!changed || !from || !to || from.prefix !== to.prefix || from.suffix !== to.suffix) return
          const scale = 10 ** (to.d - from.d)
          const start = Math.round(from.units * scale)
          if (start === to.units) return
          if (!reduced()) this.roll(start, to, {
            ...to,
            plus: to.plus || from.plus,
            minus: to.minus || from.minus || "\u2212",
            grouped: !(to.ungrouped || from.ungrouped)
          })
        },
        destroyed() { this.stop() },
        find() {
          const walker = document.createTreeWalker(this.el, NodeFilter.SHOW_TEXT, {
            acceptNode: (n) =>
              n.parentElement.closest("[phx-hook]") !== this.el ? NodeFilter.FILTER_REJECT
                : /\d/.test(n.data) ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_SKIP
          })
          return walker.nextNode()
        },
        roll(start, to, t) {
          this.stop()
          const css = getComputedStyle(this.el)
          const duration = ms(css, "--setzkasten-duration-count", 500)
          const easing = css.getPropertyValue("--setzkasten-ease-out").trim() || "ease-out"
          // An empty animation carries the eased progress of the motion token.
          const anim = this.el.animate([], { duration, easing })
          this.anim = anim
          const step = () => {
            const p = anim.effect.getComputedTiming().progress
            if (anim !== this.anim) return
            if (p === null || anim.playState === "finished") return this.stop()
            this.shown = format(Math.round(start + (to.units - start) * p), t)
            if (this.node.data !== this.shown) this.node.data = this.shown
            this.frame = requestAnimationFrame(step)
          }
          step()
        },
        stop() {
          cancelAnimationFrame(this.frame)
          if (this.anim) this.anim.cancel()
          this.anim = null
          this.shown = null
          if (this.node && this.text != null && this.node.data !== this.text) this.node.data = this.text
        }
      }
    </script>
    """
  end

  @doc """
  Label → value facts in 14px, as tables. Values right-aligned with tabular figures.

  For a calculation, mark items `strong` (label and value semibold, e.g. the start value) and
  the result `total` (strong, with a stronger hairline above it, `base-content/30`). As soon as
  one item is marked, the other values drop to regular weight, so the marked ones stand out.

      <.description_list>
        <:item label="TER">0,22 %</:item>
      </.description_list>

      <.description_list>
        <:item label="Anfangswert" strong>10.000,00 €</:item>
        <:item label="Einzahlungen">+500,00 €</:item>
        <:item label="Endwert" total>10.812,00 €</:item>
      </.description_list>
  """
  attr :class, :any, default: nil
  attr :rest, :global

  slot :item, required: true do
    attr :label, :string, required: true
    attr :strong, :boolean
    attr :total, :boolean
  end

  def description_list(assigns) do
    assigns = assign(assigns, :marked?, Enum.any?(assigns.item, &(&1[:strong] || &1[:total])))

    ~H"""
    <dl class={["text-sm", @class]} {@rest}>
      <div
        :for={item <- @item}
        class={[
          "flex justify-between gap-4 py-2 border-b border-base-content/10",
          item[:total] && "border-t border-t-base-content/30 -mt-px",
          (item[:strong] || item[:total]) && "font-semibold"
        ]}
      >
        <dt class={!(item[:strong] || item[:total]) && "text-base-content/70"}>{item.label}</dt>
        <dd class={[
          "min-w-0 text-end tabular-nums wrap-anywhere",
          !@marked? && "font-medium"
        ]}>
          {render_slot(item)}
        </dd>
      </div>
    </dl>
    """
  end

  @bar_tones %{
    primary: "progress-primary",
    info: "progress-info",
    success: "progress-success",
    warning: "progress-warning",
    error: "progress-error",
    neutral: "setzkasten-progress-neutral"
  }

  @bar_colors %{
    1 => "text-chart-1-fill [--setzkasten-bar-line:var(--color-chart-1)]",
    2 => "text-chart-2-fill [--setzkasten-bar-line:var(--color-chart-2)]",
    3 => "text-chart-3-fill [--setzkasten-bar-line:var(--color-chart-3)]",
    4 => "text-chart-4-fill [--setzkasten-bar-line:var(--color-chart-4)]",
    5 => "text-chart-5-fill [--setzkasten-bar-line:var(--color-chart-5)]",
    6 => "text-chart-6-fill [--setzkasten-bar-line:var(--color-chart-6)]",
    7 => "text-chart-7-fill [--setzkasten-bar-line:var(--color-chart-7)]",
    8 => "text-chart-8-fill [--setzkasten-bar-line:var(--color-chart-8)]",
    {:seq, 1} => "text-seq-1 [--setzkasten-bar-line:var(--color-seq-1)]",
    {:seq, 2} => "text-seq-2 [--setzkasten-bar-line:var(--color-seq-2)]",
    {:seq, 3} => "text-seq-3 [--setzkasten-bar-line:var(--color-seq-3)]",
    {:seq, 4} => "text-seq-4 [--setzkasten-bar-line:var(--color-seq-4)]",
    {:seq, 5} => "text-seq-5 [--setzkasten-bar-line:var(--color-seq-5)]",
    other: "text-chart-other-fill [--setzkasten-bar-line:var(--color-chart-other)]"
  }

  @doc """
  A share or fill level as native `<progress>` with label and value. The pastel tones
  (`:info`, `:success`, `:warning`, `:error`) are below 3:1 against their track in the light
  theme; use them with `show_value`. `:neutral` is base-content 70 %, a quiet bar for a share
  that is no state; it keeps 3:1 against its track and can stand alone. `target` draws a 2px
  marker at its exact share as SVG geometry (no inline style, so it works under a strict CSP).

  `hide_label` drops the visible label (it stays the progress's accessible name), for a bar
  whose label is said next to it, as a stat's `:meter` under its value.

  `color` (a chart series 1–8, `:other` or a sequential step `{:seq, 1..5}`) draws the bar as
  the chart draws that series:
  `chart-N-fill` with a 1px `chart-N` line, in place of `tone`, so a bar beside a chart keeps
  its series' colour without borrowing a tone's meaning. Series 1–8 and `:other` stand alone:
  their line carries the 3:1. A sequential step has no line of its own (its fill is its line),
  so steps 1–3 in light and 1–2 in dark need `show_value`.

      <.bar label="Aktien weltweit" value={72} target={70} show_value />
      <.bar label="Solar" value={64} color={2} show_value />
  """
  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :max, :any, default: 100
  attr :tone, :atom, default: :primary, values: Map.keys(@bar_tones)

  attr :color, :any,
    default: nil,
    values: [nil | Map.keys(@bar_colors)],
    doc: "a chart series 1–8, `:other` or `{:seq, 1..5}`, in place of `tone`"

  attr :show_value, :boolean, default: false
  attr :hide_label, :boolean, default: false, doc: "no visible label; it stays the bar's name"
  attr :value_label, :string, default: nil, doc: "replaces the computed percentage"
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, doc: "a line below the bar (e.g. the target)"

  def bar(assigns) do
    assigns =
      assign(assigns,
        tone_class:
          if(assigns.color,
            do: ["setzkasten-progress-chart", @bar_colors[assigns.color]],
            else: @bar_tones[assigns.tone]
          ),
        percent: percent(assigns.value, assigns.max),
        target_x: assigns.target && target_x(assigns.target, assigns.max)
      )

    ~H"""
    <div class={@class} {@rest}>
      <div :if={!@hide_label or @show_value} class="flex justify-between gap-4 text-sm">
        <span :if={!@hide_label}>{@label}</span>
        <span :if={@show_value} class="ms-auto tabular-nums">
          {@value_label || Format.number(@percent) <> " %"}
        </span>
      </div>
      <div class="relative flex">
        <progress
          class={["progress w-full", @tone_class]}
          value={min(@value, @max)}
          max={@max}
          aria-label={@label}
        ></progress>
        <svg
          :if={@target_x}
          class="absolute -top-0.5 left-0 h-3 w-full overflow-visible pointer-events-none"
          aria-hidden="true"
        >
          <rect
            x={@target_x}
            width="2"
            height="100%"
            transform="translate(-1 0)"
            class="fill-base-content"
          />
        </svg>
      </div>
      <p :if={@inner_block != []} class="text-xs text-base-content/70">{render_slot(@inner_block)}</p>
    </div>
    """
  end

  defp percent(_value, max) when max == 0, do: 0
  defp percent(value, max), do: round(value / max * 100)

  # The marker's x as an SVG percentage, exact to 0.001 % ("12.5%", "70%").
  defp target_x(_target, max) when max == 0, do: "0%"

  defp target_x(target, max),
    do: (target / max * 100) |> max(0.0) |> min(100.0) |> svg_percent()

  defp stat_note(assigns) do
    ~H"""
    <span :if={@stale} class="badge badge-sm">
      <span class="status status-warning" aria-hidden="true"></span>{@stale_label}
    </span>
    <span :if={@note != []}>{render_slot(@note)}</span>
    {if @note == [], do: @desc}
    """
  end

  defp svg_percent(share) do
    share = Float.round(share * 1.0, 3)
    whole = trunc(share)
    if share == whole, do: "#{whole}%", else: "#{share}%"
  end

  @share_fills %{
    1 => "fill-chart-1-fill",
    2 => "fill-chart-2-fill",
    3 => "fill-chart-3-fill",
    4 => "fill-chart-4-fill",
    5 => "fill-chart-5-fill",
    6 => "fill-chart-6-fill",
    7 => "fill-chart-7-fill",
    8 => "fill-chart-8-fill",
    {:seq, 1} => "fill-seq-1",
    {:seq, 2} => "fill-seq-2",
    {:seq, 3} => "fill-seq-3",
    {:seq, 4} => "fill-seq-4",
    {:seq, 5} => "fill-seq-5",
    other: "fill-chart-other-fill",
    success: "fill-success-ink",
    error: "fill-error-ink",
    primary: "fill-primary",
    neutral: "fill-base-content/70"
  }

  @share_heights %{sm: "h-2", md: "h-3"}
  @share_track "fill-base-content/10"

  @doc """
  A whole split into its shares in one continuous bar: the power of each plug, a portfolio by
  asset class, spending by category. The segments sit flush in one rounded track, as wide as
  their values, in the given order (put the largest first and a grouped rest last), with a 2px
  gap between neighbours that shows the surface, so similar fills stay apart; no outlines.

  `segments` are maps with `label`, `value` (a number), `color` (a chart series 1–8,
  `:other` for the grouped rest, `{:seq, 1..5}` for ordered bins such as particle sizes, or
  `:success`, `:error`, `:primary`, `:neutral`, as in `legend`) and an optional `value_label` ("412 W"; without it the share in percent). `max`
  larger than the sum leaves the rest as empty track; by default the bar is full. A negative
  value counts as 0, and a whole of 0 shows the empty track.

  The values are text: a `legend` with a value per segment under the bar (two columns on
  phones), or with `legend={false}` a list for screen readers only; the bar itself is hidden
  from them. The group is named by `label`, with the whole's `value_label` at its end. Widths
  are SVG geometry, no inline style, and do not animate. A segment narrower than the gap
  vanishes from the bar and stays in the legend. `id` defaults to one derived from `label`
  (pass `id` when two share bars share a label on one page).

      <.share_bar
        label="Steckdosen"
        value_label="756 W"
        segments={[
          %{label: "Waschmaschine", value: 412, color: 1, value_label: "412 W"},
          %{label: "Arbeitsplatz", value: 138, color: 2, value_label: "138 W"},
          %{label: "Sonstige", value: 28, color: :other, value_label: "28 W"}
        ]}
      />
  """
  attr :id, :string, default: nil, doc: "needed when two share bars share a label on one page"
  attr :label, :string, required: true
  attr :value_label, :string, default: nil, doc: "the whole, at the end of the label row"

  attr :segments, :list,
    required: true,
    doc: "maps with `label`, `value`, `color` and an optional `value_label`"

  attr :max, :any, default: nil, doc: "the whole when larger than the sum of the values"
  attr :size, :atom, default: :md, values: [:sm, :md]
  attr :legend, :boolean, default: true, doc: "`false`: the values for screen readers only"
  attr :class, :any, default: nil
  attr :rest, :global

  def share_bar(assigns) do
    total = assigns.segments |> Enum.map(&share_value/1) |> Enum.sum()
    whole = max(total, assigns.max || 0)

    assigns =
      assign(assigns,
        id: assigns.id || "share-bar-#{:erlang.phash2(assigns.label)}",
        height_class: @share_heights[assigns.size],
        parts: share_parts(assigns.segments, total, whole),
        items: Enum.map(assigns.segments, &share_item(&1, whole))
      )

    ~H"""
    <div
      id={@id}
      role="group"
      aria-labelledby={"#{@id}-label"}
      class={["flex flex-col gap-1.5", @class]}
      {@rest}
    >
      <div class="flex justify-between gap-4 text-sm">
        <span id={"#{@id}-label"}>{@label}</span>
        <span :if={@value_label} class="tabular-nums">{@value_label}</span>
      </div>
      <div class={["overflow-hidden rounded-box", @height_class]} aria-hidden="true">
        <svg class="block h-full w-full">
          <svg :for={part <- @parts} x={part.x} width={part.width} overflow="hidden">
            <rect x={part.inset} width="100%" height="100%" class={part.fill} />
          </svg>
        </svg>
      </div>
      <.legend :if={@legend} items={@items} class="mt-0.5" />
      <ul :if={!@legend} class="sr-only">
        <li :for={item <- @items}>{item.label}: {item.value_label}</li>
      </ul>
    </div>
    """
  end

  # Nested viewports in percent, each rect inset by the gap, so nothing measures in pixels.
  defp share_parts(_segments, _total, whole) when whole <= 0,
    do: [%{x: "0%", width: "100%", inset: "0", fill: @share_track}]

  defp share_parts(segments, total, whole) do
    spans =
      segments
      |> Enum.scan({0, 0, nil}, fn segment, {_start, stop, _fill} ->
        {stop, stop + share_value(segment), Map.fetch!(@share_fills, segment.color)}
      end)
      |> Kernel.++([{total, whole, @share_track}])
      |> Enum.reject(fn {start, stop, _fill} -> stop <= start end)

    spans
    |> Enum.with_index()
    |> Enum.map(fn {{start, stop, fill}, index} ->
      x = start / whole * 100

      %{
        x: svg_percent(x),
        width: svg_percent(stop / whole * 100 - x),
        inset: if(index == 0, do: "0", else: "2"),
        fill: fill
      }
    end)
  end

  defp share_item(segment, whole) do
    %{
      label: segment.label,
      color: segment.color,
      value_label: segment[:value_label] || share_percent(share_value(segment), whole)
    }
  end

  defp share_value(segment), do: max(segment.value, 0)

  defp share_percent(_value, whole) when whole <= 0, do: "0 %"
  defp share_percent(value, whole), do: Format.number(round(value / whole * 100)) <> " %"

  @avatar_tones %{
    primary: "bg-primary text-primary-content",
    neutral: "bg-neutral text-neutral-content",
    secondary: "bg-secondary text-secondary-content",
    accent: "bg-accent text-accent-content",
    info: "bg-info text-info-content",
    success: "bg-success text-success-content",
    warning: "bg-warning text-warning-content",
    error: "bg-error text-error-content",
    base: "bg-base-300 text-base-content"
  }

  @avatar_sizes %{
    sm: {"w-8", "text-xs", "size-4"},
    md: {"w-10", "text-sm", "size-5"},
    lg: {"w-12", "text-base", "size-6"}
  }

  @doc """
  Initials or an icon on a quiet base-300 tile, or on a theme fill with `tone` (every
  fill/content pair ≥ 4.5:1; `:primary` e.g. for the signed-in user). Square chip
  (`rounded-field`) by default, `shape={:round}` for people. Hidden from screen readers unless
  `label` is set (the name usually sits next to it). `loading` shows a spinner in the tile
  instead of its content (same size and tone); with reduced motion a still ellipsis. Only an
  avatar with `label` announces it (`aria-busy`); a hidden one leaves that to its row.

      <.avatar initials="KD" size={:sm} />
      <.avatar icon="user" shape={:round} />
      <.avatar initials="JM" tone={:primary} />
      <.avatar initials="DB" loading />
  """
  attr :initials, :string, default: nil
  attr :icon, :string, default: nil
  attr :tone, :atom, default: :base, values: Map.keys(@avatar_tones)
  attr :size, :atom, default: :md, values: [:sm, :md, :lg]
  attr :shape, :atom, default: :square, values: [:square, :round]
  attr :label, :string, default: nil
  attr :loading, :boolean, default: false
  attr :class, :any, default: nil

  def avatar(assigns) do
    {width, text, icon_size} = Map.fetch!(@avatar_sizes, assigns.size)

    assigns =
      assign(assigns,
        tone_class: @avatar_tones[assigns.tone],
        width: width,
        text: text,
        icon_size: icon_size
      )

    ~H"""
    <div
      class={["avatar avatar-placeholder", @class]}
      aria-hidden={if(@label, do: nil, else: "true")}
      role={@label && "img"}
      aria-label={@label}
      aria-busy={@label && @loading && "true"}
    >
      <div class={[
        @tone_class,
        @width,
        if(@shape == :round, do: "rounded-full", else: "rounded-field")
      ]}>
        <span :if={@loading} class={["loading loading-spinner motion-reduce:hidden", @icon_size]}></span>
        <.icon :if={@loading} name="ellipsis" class={[@icon_size, "motion-safe:hidden"]} />
        <span :if={@initials && !@loading} class={@text}>{@initials}</span>
        <.icon :if={@icon && !@initials && !@loading} name={@icon} class={@icon_size} />
      </div>
    </div>
    """
  end

  @chart_heights %{sm: "h-56", md: "h-64", lg: "h-76", auto: nil}

  @doc """
  The frame around an app-drawn chart (Chart.js etc.): card with title and `:actions`,
  `role="img"` with `summary` as its name, a `phx-hook` container with `phx-update="ignore"`
  and a `<canvas>`, an optional `:legend`, and `:data` folded into "Werte als Tabelle" (the
  keyboard and touch path to exact values). `loading` shows a skeleton. Without `hook` the
  inner block is drawn instead of the canvas (static SVG charts).

  The hook element is `relative` and holds only the canvas, as Chart.js's responsive mode
  needs; the card is `min-w-0`, so in a flex row it shrinks below the canvas's last width and
  the chart can follow.

  `hook_attrs` go on the hook element (`<id>-chart`), e.g. the series as `data-*`: after
  mount LiveView patches only the `data-*` of the ignored container and calls the hook's
  `updated()`. `id`, `class`, `phx-hook` and `phx-update` belong to the component. Global
  attrs stay on the card.

  `subtitle` carries the unit or period ("Leistung in Watt", "seit 27.08.2026 · 16 Tage"), so
  the ticks show bare numbers and need no axis title.

  `height` `:sm` 14rem, `:md` 16rem, `:lg` 19rem, or `:auto` for an inner block that sizes
  itself (an SVG at `width: 100%; height: auto`: heat strips, maps, small multiples); its
  `loading` skeleton takes the `:md` height. `:auto` with `hook` raises: a canvas has no
  height of its own to give.

      <.chart_card
        id="networth"
        title="Vermögen"
        hook="NetWorthChart"
        hook_attrs={%{"data-points" => Jason.encode!(@points)}}
        summary="…"
      >
        <:legend><.legend items={[%{label: "Vermögen", color: 1}]} /></:legend>
        <:data><.table id="networth-data" rows={@points} size={:sm} flush>…</.table></:data>
      </.chart_card>
  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :summary, :string, required: true
  attr :hook, :string, default: nil

  attr :hook_attrs, :map,
    default: %{},
    doc: "`data-*` on the hook element, e.g. the series; patched after mount"

  attr :height, :atom, default: :md, values: [:sm, :md, :lg, :auto]
  attr :level, :integer, default: 2
  attr :loading, :boolean, default: false
  attr :data_label, :string, default: "Werte als Tabelle"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block
  slot :actions
  slot :legend
  slot :data

  def chart_card(%{height: :auto, hook: hook}) when is_binary(hook) do
    raise ArgumentError,
          "<.chart_card height={:auto}> needs an inner block, not a hook: a canvas takes its height from the card"
  end

  def chart_card(assigns) do
    height = @chart_heights[assigns.height]
    assigns = assign(assigns, height_class: height, skeleton_class: height || @chart_heights.md)

    ~H"""
    <section
      id={@id}
      class={[
        "setzkasten-chart-card card min-w-0 bg-base-100 border border-base-content/10",
        @class
      ]}
      aria-busy={@loading && "true"}
      {@rest}
    >
      <div class="card-body">
        <div class="flex flex-wrap items-start justify-between gap-2">
          <div class="min-w-0">
            <.dynamic_tag tag_name={"h#{@level}"} class="card-title">{@title}</.dynamic_tag>
            <p :if={@subtitle} class="text-sm text-base-content/70 max-w-prose wrap-anywhere">
              {@subtitle}
            </p>
          </div>
          <div :if={@actions != []} class="flex flex-wrap items-center gap-2">
            {render_slot(@actions)}
          </div>
        </div>
        <div :if={@loading} class={@skeleton_class}>
          <div class="skeleton h-full"></div>
        </div>
        <div :if={!@loading} role="img" aria-label={@summary} class={["flex flex-col", @height_class]}>
          {if !@hook, do: render_slot(@inner_block)}
          <div
            :if={@hook}
            id={"#{@id}-chart"}
            phx-hook={@hook}
            phx-update="ignore"
            class="relative h-full"
            {@hook_attrs}
          >
            <canvas></canvas>
          </div>
        </div>
        {render_slot(@legend)}
        <.disclosure :if={@data != []} id={"#{@id}-data-toggle"} variant={:row} summary={@data_label}>
          {render_slot(@data)}
        </.disclosure>
      </div>
    </section>
    """
  end

  @legend_colors %{
    1 => "bg-chart-1-fill border border-chart-1",
    2 => "bg-chart-2-fill border border-chart-2",
    3 => "bg-chart-3-fill border border-chart-3",
    4 => "bg-chart-4-fill border border-chart-4",
    5 => "bg-chart-5-fill border border-chart-5",
    6 => "bg-chart-6-fill border border-chart-6",
    7 => "bg-chart-7-fill border border-chart-7",
    8 => "bg-chart-8-fill border border-chart-8",
    {:seq, 1} => "bg-seq-1",
    {:seq, 2} => "bg-seq-2",
    {:seq, 3} => "bg-seq-3",
    {:seq, 4} => "bg-seq-4",
    {:seq, 5} => "bg-seq-5",
    other: "bg-chart-other-fill border border-chart-other",
    success: "bg-success-ink",
    error: "bg-error-ink",
    primary: "bg-primary",
    neutral: "bg-base-content/70"
  }

  @legend_strokes %{
    1 => "stroke-chart-1",
    2 => "stroke-chart-2",
    3 => "stroke-chart-3",
    4 => "stroke-chart-4",
    5 => "stroke-chart-5",
    6 => "stroke-chart-6",
    7 => "stroke-chart-7",
    8 => "stroke-chart-8",
    {:seq, 1} => "stroke-seq-1",
    {:seq, 2} => "stroke-seq-2",
    {:seq, 3} => "stroke-seq-3",
    {:seq, 4} => "stroke-seq-4",
    {:seq, 5} => "stroke-seq-5",
    other: "stroke-chart-other",
    success: "stroke-success-ink",
    error: "stroke-error-ink",
    primary: "stroke-primary",
    neutral: "stroke-base-content/70"
  }

  @doc """
  Chart legend: 10px dots with `text-xs` labels. An item's `value_label` ("412 W") shows its
  value at the end of its line: then the items form a grid of up to three columns of at least
  8rem, by the legend's own width (two in a phone card or a half-width card), labels end in an
  ellipsis, values right-aligned with tabular figures. `color` is a series number 1–8 (fill
  `chart-N-fill` with a 1px `chart-N` outline, like the bars; the outline carries the 3:1),
  `:other` (the grouped rest, `chart-other-fill` with a `chart-other` outline), a step of the
  sequential ramp `{:seq, 1..5}` for ordered categories, or `:success`, `:error`, `:primary`,
  `:neutral`. An item's `marker` is `:dot` (default),
  `:line` or `:dashed` (a 16px line in the series' line colour, ≥ 3:1, to key a line or a
  dashed reference line).

      <.legend items={[%{label: "Vermögen", color: 1}, %{label: "Einzahlungen", color: 3}]} />
      <.legend items={[%{label: "Kurs", color: 1, marker: :line},
                       %{label: "Einstand", color: 8, marker: :dashed}]} />
  """
  attr :items, :list, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  def legend(assigns) do
    assigns = assign(assigns, :values?, Enum.any?(assigns.items, &(&1[:value_label] != nil)))

    ~H"""
    <ul
      class={[
        if(@values?,
          do: "setzkasten-legend-grid grid gap-x-6 gap-y-1 text-xs",
          else: "flex flex-wrap gap-x-4 gap-y-1 text-xs"
        ),
        @class
      ]}
      {@rest}
    >
      <li :for={item <- @items} class={["flex items-center gap-1.5", @values? && "min-w-0"]}>
        <.legend_marker marker={Map.get(item, :marker, :dot)} color={item.color} />
        <%= if @values? do %>
          <span class="min-w-0 flex-1 truncate" title={item.label}>{item.label}</span>
          <span class="shrink-0 tabular-nums">{item[:value_label]}</span>
        <% else %>
          {item.label}
        <% end %>
      </li>
    </ul>
    """
  end

  attr :marker, :atom, required: true
  attr :color, :any, required: true

  defp legend_marker(%{marker: :dot} = assigns) do
    ~H"""
    <span
      class={["size-2.5 shrink-0 rounded-full", Map.fetch!(legend_colors(), @color)]}
      aria-hidden="true"
    ></span>
    """
  end

  defp legend_marker(%{marker: marker} = assigns) when marker in [:line, :dashed] do
    ~H"""
    <svg
      class={["h-2.5 w-4 shrink-0", Map.fetch!(legend_strokes(), @color)]}
      viewBox="0 0 16 10"
      aria-hidden="true"
    >
      <line
        x1="0"
        y1="5"
        x2="16"
        y2="5"
        stroke-width="2"
        stroke-dasharray={@marker == :dashed && "4 2"}
      />
    </svg>
    """
  end

  defp legend_colors, do: @legend_colors
  defp legend_strokes, do: @legend_strokes
end
