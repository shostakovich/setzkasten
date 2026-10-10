defmodule Setzkasten.Components.Data do
  @moduledoc """
  Tables, lists, amounts, stats, fact lists, bars, avatars and the chart frame.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias Setzkasten.Format
  import Setzkasten.Components.Icons
  import Setzkasten.Components.Overlays, only: [show_confirm: 5]

  @show_from %{
    nil => nil,
    sm: "hidden sm:table-cell",
    md: "hidden md:table-cell",
    lg: "hidden lg:table-cell",
    xl: "hidden xl:table-cell"
  }

  @hide_from %{nil => nil, sm: "sm:hidden", md: "md:hidden", lg: "lg:hidden", xl: "xl:hidden"}
  @block_from %{
    nil => nil,
    sm: "hidden sm:block",
    md: "hidden md:block",
    lg: "hidden lg:block",
    xl: "hidden xl:block"
  }

  @flat "border-y border-base-content/10 max-sm:-mx-4"

  @doc """
  Class list for a table cell that appears from breakpoint `bp` on (`:sm`, `:md`, `:lg`,
  `:xl`). Use it on `:foot` cells of columns with `show_from`.
  """
  def show_from(bp), do: Map.fetch!(@show_from, bp)

  @doc """
  A data table (`table tabular-nums`, daisyUI md or `:sm`), as Phoenix's `<.table>` with
  streams, plus column priorities, group rows, a total row and an empty row.

  Flat by default: the table sits on the page between `border-y` hairlines and
  runs edge to edge on phones. `flush` drops both for a card's `:list` slot or a modal.

  `:col` attrs: `label`, `align` (`:end` right-aligns with tabular figures), `show_from`
  (`:sm` … `:xl`, hides the column below), `class`. `row_link` turns the first cell into a
  link stretched over the row. `groups` is a list of `%{id, label, rows}`, one `<tbody>` each.
  `:foot` holds the cells of the total row (use `show_from/1` on hidden columns).

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
  attr :row_link, :any, default: nil, doc: "fn row -> path, navigated on click"
  attr :size, :atom, default: :md, values: [:md, :sm]
  attr :zebra, :boolean, default: false
  attr :flush, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  slot :col, required: true do
    attr :label, :string
    attr :align, :atom, values: [:start, :end]
    attr :show_from, :atom, values: [:sm, :md, :lg, :xl]
    attr :class, :any
  end

  slot :foot
  slot :empty

  def table(assigns) do
    assigns = prepare_rows(assigns)

    ~H"""
    <div class={["overflow-x-auto", !@flush && flat(), @class]} {@rest}>
      <table class={["table tabular-nums", @size == :sm && "table-sm", @zebra && "table-zebra"]}>
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
    <tr
      :for={row <- @rows}
      id={@row_id && @row_id.(row)}
      class={@row_link && "relative row-hover"}
    >
      <td :for={{col, i} <- Enum.with_index(@col)} class={col_class(col)}>
        <.link
          :if={i == 0 && @row_link}
          navigate={@row_link.(@row_item.(row))}
          class="font-medium after:absolute after:inset-0"
        >
          {render_slot(col, @row_item.(row))}
        </.link>
        <%= if i > 0 || !@row_link do %>
          {render_slot(col, @row_item.(row))}
        <% end %>
      </td>
    </tr>
    """
  end

  defp flat, do: @flat

  defp col_class(col) do
    [
      col[:align] == :end && "text-end tabular-nums whitespace-nowrap",
      Map.fetch!(@show_from, col[:show_from]),
      col[:class]
    ]
  end

  @doc """
  The values of hidden columns, repeated under the visible ones (`text-sm`, 70 %).
  `hide_from` hides it from that breakpoint; `show_from` shows it only from there.

      <.cell_sub hide_from={:lg}>{h.shares} Stück · <.amount value={h.price} /></.cell_sub>
  """
  attr :hide_from, :atom, default: nil, values: [nil, :sm, :md, :lg, :xl]
  attr :show_from, :atom, default: nil, values: [nil, :sm, :md, :lg, :xl]
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
  """
  attr :flush, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def list(assigns) do
    ~H"""
    <ul class={["list", !@flush && flat(), @class]} data-focus-fallback {@rest}>
      {render_slot(@inner_block)}
    </ul>
    """
  end

  @doc "A group heading inside `<.list>` (e.g. a date)."
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def list_heading(assigns) do
    ~H"""
    <li class={["px-4 pt-4 text-xs font-semibold text-base-content/70", @class]}>
      {render_slot(@inner_block)}
    </li>
    """
  end

  @doc """
  A list row: `:leading` (plush, icon, avatar), title (`title` or the inner block,
  `font-medium`), `:meta` (70 %, truncates), `:trailing` (value, amount, badge) and `:action`
  entries. With `navigate`/`patch`/`href` the title link covers the row and a chevron shows.

  Actions are icon buttons from `md` and fold into a `⋮` menu below (Escape and choosing an
  entry return focus to the `⋮` button). `menu={:always}` uses the `⋮` menu at every width,
  e.g. when the actions are rare or destructive and should not sit on every row. Each `:action` takes
  `label`, `icon`, a target (`navigate`/`patch`/`href`, or `on_click` as event name or
  `%JS{}`), and optionally `confirm` (+ `confirm_text`, `confirm_label`) for the shared
  confirmation dialog, `danger` (red in the menu), `disabled` and `id` (the icon button; the
  menu entry gets `<id>-menu-item`, the `⋮` button of a row with `id` gets `<row id>-menu-toggle`).
  `title` also names the actions for screen readers (`"Bearbeiten: Herbst"`, menu
  `"Aktionen: Herbst"`).

  Below `md` the `:trailing` content (a badge, a value) moves into a second line under the
  title and meta, so the title keeps the width next to the `⋮` menu and the chevron. With
  `trailing_on_phone={:meta}` it goes to the end of the meta line instead (a status that is
  only there now and then, so rows keep two lines), and wraps below it only when the line is
  full, so neither gets cut; it then renders twice and receives where
  (`:meta`, `:column`) for unique ids. `<:trailing class="md:w-40 md:justify-start">` gives the
  trailing column a fixed width, so badges line up from row to row even when most rows have none.

  With `menu={:always}` an action marked `inline` still shows as an icon button from `md`
  (e.g. move up and down), the others only in the `⋮` menu.

      <.list_row title={post.title} navigate={~p"/posts/\#{post}"}>
        <:leading><.icon name="file-text" class="size-5 text-base-content/70" /></:leading>
        <:meta>Geändert am 07.10.2026 · 1.240 Wörter</:meta>
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
  attr :actions_label, :string, default: "Aktionen"
  attr :menu, :atom, default: :responsive, values: [:responsive, :always]
  attr :trailing_on_phone, :atom, default: :line, values: [:line, :meta]
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
        menu_label:
          if(assigns.title,
            do: "#{assigns.actions_label}: #{assigns.title}",
            else: assigns.actions_label
          ),
        wrap?: assigns.trailing != [] and assigns.trailing_on_phone == :line,
        meta_trailing?: assigns.trailing != [] and assigns.trailing_on_phone == :meta,
        inline_actions:
          if(assigns.menu == :always,
            do: Enum.filter(assigns.action, & &1[:inline]),
            else: assigns.action
          ),
        grow_column:
          if(assigns.leading != [], do: "max-md:col-start-2", else: "max-md:col-start-1")
      )

    ~H"""
    <li id={@id} class={["list-row items-center", @wrap? && "max-md:gap-y-1", @class]} {@rest}>
      <div :if={@leading != []} class={["flex items-center", @wrap? && "max-md:row-[1/span_2]"]}>
        {render_slot(@leading)}
      </div>
      <div class="list-col-grow min-w-0">
        <.link
          :if={@link?}
          navigate={@navigate}
          patch={@patch}
          href={@href}
          class="font-medium wrap-anywhere after:absolute after:inset-0"
        >
          {@title}{render_slot(@inner_block)}
        </.link>
        <p :if={!@link?} class="font-medium wrap-anywhere">{@title}{render_slot(@inner_block)}</p>
        <p :if={@meta != [] and !@meta_trailing?} class="text-sm text-base-content/70 truncate">
          {render_slot(@meta)}
        </p>
        <div
          :if={@meta_trailing?}
          class="flex min-w-0 flex-wrap items-center gap-x-2 text-sm text-base-content/70"
        >
          <p :if={@meta != []} class="min-w-0 max-w-full truncate">{render_slot(@meta)}</p>
          <div class="flex shrink-0 items-center gap-2 md:hidden">
            {render_slot(@trailing, :meta)}
          </div>
        </div>
      </div>
      <div
        :for={trailing <- @trailing}
        class={[
          "flex flex-wrap items-center gap-2 md:justify-end md:text-end",
          if(@meta_trailing?,
            do: "max-md:hidden",
            else: ["max-md:row-start-2 max-md:min-w-0", @grow_column]
          ),
          trailing[:class]
        ]}
      >
        {render_slot(trailing, :column)}
      </div>
      <div :if={@inline_actions != []} class="relative z-10 hidden md:flex gap-1">
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
            phx-click={action_click(action, @confirm_id)}
          >
            <.icon name={action[:icon] || "chevron-right"} />
          </button>
        <% end %>
      </div>
      <details
        :if={@action != []}
        class={[
          "dropdown dropdown-end relative z-10 open:z-20",
          @menu == :responsive && "md:hidden",
          @wrap? && "max-md:row-[1/span_2]"
        ]}
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
        <ul class="menu dropdown-content bg-base-100 rounded-box border border-base-content/10 shadow-lg z-10 w-56">
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
                close_menu({:closest, "details"}) |> JS.concat(action_click(action, @confirm_id))
              }
              phx-keydown={close_menu({:closest, "details"})}
              phx-key="Escape"
            >
              <.icon :if={action[:icon]} name={action[:icon]} />{action.label}
            </button>
          </li>
        </ul>
      </details>
      <.icon
        :if={@link?}
        name="chevron-right"
        class={["size-4 text-base-content/70", @wrap? && "max-md:row-[1/span_2]"]}
      />
    </li>
    """
  end

  # As in Navigation: close the row menu and focus its summary (Escape binding on each item).
  defp close_menu(to), do: JS.remove_attribute("open", to: to) |> JS.focus_first(to: to)

  defp action_link?(action), do: Enum.any?([action[:navigate], action[:patch], action[:href]])

  defp action_label(action, nil), do: action.label
  defp action_label(action, title), do: "#{action.label}: #{title}"

  defp action_click(action, confirm_id) do
    js =
      case action[:on_click] do
        %JS{} = js -> js
        event when is_binary(event) -> JS.push(event)
        nil -> %JS{}
      end

    if action[:confirm] do
      show_confirm(%JS{}, confirm_id, action[:confirm], js,
        text: action[:confirm_text],
        label: action[:confirm_label]
      )
    else
      js
    end
  end

  @doc """
  Money in de-DE (`Setzkasten.Format.money/2`) inside `<data value>`, `tabular-nums`, no wrap.
  `tone` colours negative values `error-ink`, positive `success-ink`, zero 70 %.
  `size={:lg}` for totals; inside `<.stat>` the stat sets the size.

      <.amount value={-7420} signed tone />
  """
  attr :value, :any, required: true, doc: "integer minor units (cents) or Decimal"
  attr :currency, :string, default: "EUR"
  attr :signed, :boolean, default: false
  attr :tone, :boolean, default: false
  attr :size, :atom, default: :inherit, values: [:inherit, :lg]
  attr :class, :any, default: nil
  attr :rest, :global

  def amount(assigns) do
    ~H"""
    <data
      value={Format.machine(@value)}
      class={[
        "tabular-nums whitespace-nowrap",
        @tone && tone_class(Format.sign(@value)),
        @size == :lg && "text-lg font-semibold",
        @class
      ]}
      {@rest}
    >{Format.money(@value, currency: @currency, signed: @signed)}</data>
    """
  end

  defp tone_class(-1), do: "text-error-ink"
  defp tone_class(1), do: "text-success-ink"
  defp tone_class(0), do: "text-base-content/70"

  @doc """
  A KPI tile: daisyUI `stat` on base-100 with a hairline and `tabular-nums`.
  `size={:sm}` (`text-2xl`) for tile grids where 32px overflows. `tone` (`:success`/`:error`)
  colours the value with the ink tokens. `stale` adds a badge instead of fading the value;
  `loading` shows a skeleton in place of the value. The inner block replaces `value`.

      <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <.stat label="PV jetzt" value="1.234" unit="W" desc="Akku 82 %" size={:sm} />
      </div>
  """
  attr :label, :string, required: true
  attr :value, :any, default: nil
  attr :unit, :string, default: nil
  attr :desc, :string, default: nil
  attr :tone, :atom, default: nil, values: [nil, :success, :error]
  attr :size, :atom, default: :md, values: [:md, :sm]
  attr :stale, :boolean, default: false
  attr :stale_label, :string, default: "veraltet"
  attr :loading, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def stat(assigns) do
    ~H"""
    <div
      class={["stat bg-base-100 rounded-box border border-base-content/10", @class]}
      aria-busy={@loading && "true"}
      {@rest}
    >
      <div class="stat-title">{@label}</div>
      <div :if={@loading} class="skeleton h-8 w-24 mt-1"></div>
      <div
        :if={!@loading}
        class={[
          "stat-value tabular-nums",
          @size == :sm && "text-2xl",
          @tone == :success && "text-success-ink",
          @tone == :error && "text-error-ink"
        ]}
      >
        {@value}{render_slot(@inner_block)}
        <span :if={@unit} class="text-base font-semibold text-base-content/70">{@unit}</span>
      </div>
      <div :if={@desc || @stale} class="stat-desc flex flex-wrap items-center gap-1 whitespace-normal">
        <span :if={@stale} class="badge badge-sm">
          <span class="status status-warning" aria-hidden="true"></span>{@stale_label}
        </span>
        {@desc}
      </div>
    </div>
    """
  end

  @doc """
  Label → value facts. Values right-aligned with tabular figures.

      <.description_list>
        <:item label="TER">0,22 %</:item>
      </.description_list>
  """
  attr :class, :any, default: nil
  attr :rest, :global

  slot :item, required: true do
    attr :label, :string, required: true
  end

  def description_list(assigns) do
    ~H"""
    <dl class={@class} {@rest}>
      <div
        :for={item <- @item}
        class="flex justify-between gap-4 py-2 border-b border-base-content/10"
      >
        <dt class="text-base-content/70">{item.label}</dt>
        <dd class="min-w-0 text-end tabular-nums font-medium wrap-anywhere">{render_slot(item)}</dd>
      </div>
    </dl>
    """
  end

  @bar_tones %{
    primary: "progress-primary",
    info: "progress-info",
    success: "progress-success",
    warning: "progress-warning",
    error: "progress-error"
  }

  @doc """
  A share or fill level as native `<progress>` with label and value. The pastel tones
  (`:info`, `:success`, `:warning`, `:error`) are below 3:1 against their track in the light
  theme; use them with `show_value`. `target` draws a 2px marker as SVG geometry (no
  inline style, so it works under a strict CSP).

      <.bar label="Aktien weltweit" value={72} target={70} show_value />
  """
  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :max, :any, default: 100
  attr :tone, :atom, default: :primary, values: Map.keys(@bar_tones)
  attr :show_value, :boolean, default: false
  attr :value_label, :string, default: nil, doc: "replaces the computed percentage"
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, doc: "a line below the bar (e.g. the target)"

  def bar(assigns) do
    assigns =
      assign(assigns,
        tone_class: @bar_tones[assigns.tone],
        percent: percent(assigns.value, assigns.max),
        target_percent: assigns.target && percent(assigns.target, assigns.max)
      )

    ~H"""
    <div class={@class} {@rest}>
      <div class="flex justify-between gap-4 text-sm">
        <span>{@label}</span>
        <span :if={@show_value} class="tabular-nums">
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
          :if={@target_percent}
          class="absolute -top-0.5 left-0 h-3 w-full overflow-visible pointer-events-none"
          aria-hidden="true"
        >
          <rect
            x={"#{min(@target_percent, 100)}%"}
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
  Initials or an icon on a theme fill (every fill/content pair ≥ 4.5:1). Square chip
  (`rounded-field`) by default, `shape={:round}` for people. Hidden from screen readers unless
  `label` is set (the name usually sits next to it).

      <.avatar initials="KD" size={:sm} />
      <.avatar icon="user" tone={:base} shape={:round} />
  """
  attr :initials, :string, default: nil
  attr :icon, :string, default: nil
  attr :tone, :atom, default: :primary, values: Map.keys(@avatar_tones)
  attr :size, :atom, default: :md, values: [:sm, :md, :lg]
  attr :shape, :atom, default: :square, values: [:square, :round]
  attr :label, :string, default: nil
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
    >
      <div class={[
        @tone_class,
        @width,
        if(@shape == :round, do: "rounded-full", else: "rounded-field")
      ]}>
        <span :if={@initials} class={@text}>{@initials}</span>
        <.icon :if={@icon && !@initials} name={@icon} class={@icon_size} />
      </div>
    </div>
    """
  end

  @chart_heights %{sm: "h-56", md: "h-64", lg: "h-76"}

  @doc """
  The frame around an app-drawn chart (Chart.js etc.): card with title and `:actions`,
  `role="img"` with `summary` as its name, a `phx-hook` container with `phx-update="ignore"`
  and a `<canvas>`, an optional `:legend`, and `:data` folded into "Werte als Tabelle" (the
  keyboard and touch path to exact values). `loading` shows a skeleton. Without `hook` the
  inner block is drawn instead of the canvas (static SVG charts).

      <.chart_card id="networth" title="Vermögen" hook="NetWorthChart" summary="…">
        <:legend><.legend items={[%{label: "Vermögen", color: 1}]} /></:legend>
        <:data><.table id="networth-data" rows={@points} size={:sm} flush>…</.table></:data>
      </.chart_card>
  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :summary, :string, required: true
  attr :hook, :string, default: nil
  attr :height, :atom, default: :md, values: [:sm, :md, :lg]
  attr :level, :integer, default: 2
  attr :loading, :boolean, default: false
  attr :data_label, :string, default: "Werte als Tabelle"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block
  slot :actions
  slot :legend
  slot :data

  def chart_card(assigns) do
    assigns = assign(assigns, :height_class, @chart_heights[assigns.height])

    ~H"""
    <section
      id={@id}
      class={["card bg-base-100 border border-base-content/10", @class]}
      aria-busy={@loading && "true"}
      {@rest}
    >
      <div class="card-body">
        <div class="flex flex-wrap items-start justify-between gap-2">
          <.dynamic_tag tag_name={"h#{@level}"} class="card-title">{@title}</.dynamic_tag>
          <div :if={@actions != []} class="flex flex-wrap items-center gap-2">
            {render_slot(@actions)}
          </div>
        </div>
        <div :if={@loading} class={@height_class}>
          <div class="skeleton h-full"></div>
        </div>
        <div :if={!@loading} role="img" aria-label={@summary} class={["flex flex-col", @height_class]}>
          {if !@hook, do: render_slot(@inner_block)}
          <div
            :if={@hook}
            id={"#{@id}-chart"}
            phx-hook={@hook}
            phx-update="ignore"
            class="h-full"
          >
            <canvas></canvas>
          </div>
        </div>
        {render_slot(@legend)}
        <details
          :if={@data != []}
          class="collapse collapse-arrow rounded-none border-t border-base-content/10"
        >
          <summary class="collapse-title text-sm font-semibold">{@data_label}</summary>
          <div class="collapse-content overflow-x-auto">{render_slot(@data)}</div>
        </details>
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
    success: "bg-success-ink",
    error: "bg-error-ink",
    primary: "bg-primary",
    neutral: "bg-base-content/70"
  }

  @doc """
  Chart legend: 10px dots with `text-xs` labels. `color` is a series number 1–8 (fill
  `chart-N-fill` with a 1px `chart-N` outline, like the bars; the outline carries the 3:1) or
  `:success`, `:error`, `:primary`, `:neutral`.

      <.legend items={[%{label: "Vermögen", color: 1}, %{label: "Einzahlungen", color: 3}]} />
  """
  attr :items, :list, required: true
  attr :class, :any, default: nil

  def legend(assigns) do
    ~H"""
    <ul class={["flex flex-wrap gap-x-4 gap-y-1 text-xs", @class]}>
      <li :for={item <- @items} class="flex items-center gap-1.5">
        <span
          class={["size-2.5 rounded-full", Map.fetch!(legend_colors(), item.color)]}
          aria-hidden="true"
        ></span>
        {item.label}
      </li>
    </ul>
    """
  end

  defp legend_colors, do: @legend_colors
end
