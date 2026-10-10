# Setzkasten design system

Tailwind CSS 4 + daisyUI 5. The catalog (`mix dev`) renders every component listed here. The function
docs are the exact API; this guide gives the rules.

## 1. Principles

| Rule | In practice |
|---|---|
| daisyUI defaults first | Sizes, radii and type steps are daisyUI's or Tailwind's unless a rule below says otherwise. |
| Calm | One accent (`primary`). Colour carries state, not decoration. Pastel fills with dark text. Flat surfaces with hairlines, no texture. |
| Flat | The page is base-100. Sections are structured by headings, spacing and hairlines. Tables, lists and forms sit on the page, full width, edge to edge on phones. Cards only for independent objects: dashboard tiles, KPI groups, titled charts, clickable object grids, dialogs. |
| Floors | Text ≥ 12px · text 4.5:1, marks and boundaries 3:1 (WCAG 2.x) · targets 44px on coarse pointers · prose ≤ 65ch · numbers `tabular-nums`. |
| No JS framework, no inline styles | `<dialog>`, `<details>`, `Phoenix.LiveView.JS`, colocated hooks. Works under a strict CSP. |
| Themes | `zipfel-light` default, `zipfel-dark` on `prefers-color-scheme: dark`; an explicit choice sets `data-theme` on `<html>`. |

## 2. Tokens

### 2.1 Theme colours

| Role | Light | Dark | Used for |
|---|---|---|---|
| base-100 | `#ffffff` | `#2d2f33` | page, cards, fields, menus, modals |
| base-200 | `#f4f8fb` | `#24272a` | zebra rows, group rows, code |
| base-300 | `#e5edf3` | `#1e1f22` | wells, trays, kbd |
| base-content | `#0d1928` | `#e9ebef` | all text |
| primary / -content | `#0077b4` / `#fff` | `#61bdff` / `#001c32` | main action, selection, links, focus |
| secondary / -content | `#f7b385` / `#3e1b0b` | `#f6b88f` / `#381b0e` | rare; no default button uses it |
| accent / -content | `#b7a1f5` / `#22163c` | `#bda8fc` / `#20143a` | reserved; no component uses it |
| neutral / -content | `#3d4958` / `#f6f9fc` | `#181b1e` / `#e9ebef` | `btn-neutral`, tooltip |
| info / -content | `#47d2e8` / `#002934` | `#60d8eb` / `#002631` | info alerts and flashes |
| success / -content | `#54dd7d` / `#092c13` | `#65e287` / `#062911` | success fills |
| warning / -content | `#ffc845` / `#3b1e02` | `#ffcc59` / `#381c01` | warnings |
| error / -content | `#fd7273` / `#34080b` | `#ff8382` / `#34080b` | errors, destructive buttons |
| success-ink | `#007f38` | `#65e287` | positive amounts, success icons |
| error-ink | `#cc272e` | `#ff8382` | negative amounts, error lines and borders |

`success-ink` and `error-ink` are extra tokens (`text-success-ink`, `text-error-ink`): the light fills are pastels
and too faint as text or thin lines.

- **Text levels:** `text-base-content` (body) · `text-base-content/70` (meta, hints) · daisyUI's `/60` (labels,
  `thead`, `stat-title`) · nothing lighter. Placeholders and disabled text are exempt.
- **Coloured text:** only `text-primary`, `text-success-ink`, `text-error-ink`. Use `secondary`, `accent`, `info`,
  `success`, `warning`, `error` only as a fill with their `-content` text, never as text, icon or thin mark on
  base-100/200 (both themes, since components use the same classes in each).
- **Hairlines:** `border-base-content/10` (dividers, card edge). Field borders are 50 % base-content; error fields
  use `error-ink`.
- **Alert tint:** soft alerts mix `--setzkasten-alert-tint` of their tone into the background: 25 % light, 8 % dark.
  Override after the import:

  ```css
  @layer base {
    :where(:root), [data-theme="zipfel-light"] { --setzkasten-alert-tint: 8%; }
  }
  ```

### 2.2 Chart series

Eight series, two tokens each (`bg-chart-N-fill`, `fill-chart-N-fill`, `stroke-chart-N`, `border-chart-N`; CSS
`--color-chart-N-fill`, `--color-chart-N`):

- `chart-N-fill`: bars, areas, slices, dots, legend swatches.
- `chart-N`: lines, markers, outlines; ≥ 3:1 on base-100/200.

| Series | Light fill | Light line | Dark fill = line |
|---|---|---|---|
| 1 primary | `#0077b4` | `#0077b4` | `#61bdff` |
| 2 warning | `#ffc845` | `#ac7300` | `#ffcc5a` |
| 3 success | `#54dd7d` | `#007f38` | `#65e287` |
| 4 error | `#fd7273` | `#cc272e` | `#ff8382` |
| 5 accent | `#b7a1f5` | `#876dc8` | `#bda8fc` |
| 6 info | `#47d2e8` | `#079298` | `#60d8eb` |
| 7 secondary | `#f7b385` | `#c3610d` | `#f6b88f` |
| 8 neutral | `#3d4958` | `#3d4958` | `#9aa6b4` |

- Bars, areas, slices: `chart-N-fill` with a 1px `chart-N` outline (the outline carries the 3:1). SVG:
  `class="fill-chart-2-fill stroke-chart-2" stroke-width="1"`, plus `vector-effect="non-scaling-stroke"` in a
  stretched viewBox.
- Chart.js: `backgroundColor` = `--color-chart-N-fill`, `borderColor` = `--color-chart-N`, `borderWidth: 1`.
- Semantic series: warnings 2, income 3, overspend 4. Categorical series in order from 1; more than 8: group the rest.
- Read tokens with `getComputedStyle(document.documentElement)`; redraw on theme change (observe `data-theme`,
  listen to `prefers-color-scheme`). Chart text ≥ 12px.

Sidebar tokens (`:sidebar` shell): `sidebar` `#2c394a`/`#1a1c20`, `sidebar-content` `#f6f9fc`/`#eceff2`,
`sidebar-muted` `#bcc9d7`/`#b7bbc1`, `sidebar-accent` `#80c5ff`/`#6eb6ff`.

### 2.3 Structure tokens

| Token | Value | Note |
|---|---|---|
| `--radius-box` | 0.5rem | cards, alerts, modals, tables |
| `--radius-field` | 0.25rem | buttons, inputs, tabs, menu items |
| `--radius-selector` | 0.5rem | checkbox, badge, toggle |
| `--size-field` / `--size-selector` | 0.25rem | button/input md 40px, checkbox md 24px |
| `--border` | 1px | |
| `--depth` | 1 | buttons only; cards and tables stay flat |
| `--noise` | 0 | |

Radii via `rounded-box`, `rounded-field`, `rounded-selector`; `rounded-full` for avatars and dots only. Shadows:
cards none; dropdowns, popovers and FAB `shadow-lg`; modals daisyUI's.

### 2.4 Contrast

| Pair | Need | Light | Dark |
|---|---|---|---|
| base-content on base-100 / 200 / 300 | 4.5 | 17.69 / 16.57 / 14.95 | 11.24 / 12.58 / 13.81 |
| primary-content on primary | 4.5 | 4.89 | 8.44 |
| secondary-content on secondary | 4.5 | 8.59 | 9.14 |
| accent-content on accent | 4.5 | 7.56 | 8.32 |
| neutral-content on neutral | 4.5 | 8.67 | 14.49 |
| info-content on info | 4.5 | 8.53 | 9.47 |
| success-content on success | 4.5 | 8.70 | 9.59 |
| warning-content on warning | 4.5 | 9.91 | 10.51 |
| error-content on error | 4.5 | 6.61 | 7.44 |
| base-content/60 on base-100 / 200 | 4.5 | 4.66 / 4.58 | 5.12 / 5.51 |
| base-content/70 (secondary text, menu titles) on base-100 / 200 / 300 | 4.5 | 6.56 / 6.37 / 6.03 | 6.39 / 6.91 / 7.42 |
| text-primary on base-100 / 200 | 4.5 | 4.89 / 4.58 | 6.53 / 7.32 |
| text-success-ink on base-100 / 200 | 4.5 | 5.13 / 4.81 | 8.16 / 9.14 |
| text-error-ink on base-100 / 200 | 4.5 | 5.39 / 5.05 | 5.63 / 6.31 |
| field border on base-100 / 200 | 3 | 3.39 / 3.36 | 4.03 / 4.27 |
| error border, `btn-error btn-outline` on base-100 | 3 | 5.39 | 5.63 |
| primary as mark (focus, checkbox, menu-active, progress) on base-100 / 200 | 3 | 4.89 / 4.58 | 6.53 / 7.32 |
| alert-soft text on tint | 4.5 | 14.04–15.97 | 9.52–9.89 |
| button hover: primary / error content | 4.5 | 5.78 / 5.49 | 6.93 / 6.14 |
| sidebar content / muted / accent | 4.5 / 4.5 / 3 | 11.10 / 6.96 / 6.34 | 14.78 / 8.85 / 7.96 |

The light pastel fills as marks (status dots, `progress-success|warning|error|info`, info/warning alert icons) are
below 3:1. Use them only next to a word that carries the meaning; a mark that must stand alone uses `primary` or a
chart token.

Avoid: `btn-soft`/`badge-soft` with coloured text, coloured text in light fills other than `primary`, `tabs-box`.

### 2.5 Type scale

System font stack. Controls, tables and card bodies 14px; prose 16px.

| Role | Class | Size / line | Weight |
|---|---|---|---|
| Page title (`<.header>`) | `text-2xl` | 24 / 32px | 600 |
| KPI value (`<.stat>`) | `stat-value` / `text-2xl` (`size={:sm}`) | 32px / 24px | 800 |
| Card title | `card-title` | 18 / 28px | 600 |
| Section heading | `text-base` | 16 / 24px | 600 |
| Body prose | `text-base` | 16 / 24px | 400 |
| Controls, tables, menus, alerts | `text-sm` | 14 / 20px | 400; buttons 600 |
| Meta, help, table sub lines | `text-sm text-base-content/70` | 14 / 20px | 400 |
| Field labels | `fieldset-legend` | 12 / 16px | 600 |
| Small badges, captions, dock labels, chart ticks | `text-xs` | 12 / 16px | 400–600 |

Not used (below 12px): `btn-xs`, `input-xs`, `table-xs`, `badge-xs`, `kbd-xs`.

### 2.6 Spacing

Tailwind's 4px scale; steps in use `1` `1.5` `2` `3` `4` `6` `8` `12`.

| Gap | Value |
|---|---|
| Inside a card | `card-body`: padding 24px, gap 8px |
| Between form fields | `gap-4` |
| Between cards, grid gutter | `gap-4 md:gap-6` |
| Above a section heading | `mt-8` |
| Page padding | `px-4 sm:px-6 lg:px-8`, `py-6` |

### 2.7 Breakpoints and widths

`sm` 640 · `md` 768 · `lg` 1024 · `xl` 1280 · `2xl` 1536px.

| Width | Class | For |
|---|---|---|
| `:narrow` | `max-w-3xl` | forms, settings, single-column pages |
| `:default` | `max-w-5xl` | most pages |
| `:wide` | `max-w-7xl` | wide tables, dashboards |
| `:full` | none | grids, editors |
| auth | `max-w-md` | sign-in pages |
| prose | `max-w-prose` | every paragraph of running text |

### 2.8 Icons

| Set | Use | Render | Sizes |
|---|---|---|---|
| Lucide (stroke, `currentColor`) | actions, chevrons, status | `<.icon name="trash-2">` → inline `<svg class="lucide">` | `size-4` next to `text-sm` (default), `size-5` standalone, `size-6` empty states |
| Plush (WebP, light and dark file) | navigation, categories, settings links | `<.plush name="home">` → `<img class="plush">` | `:sm` 20 · `:md` 24 (dock) · `:lg` 32 (list leading) · `:xl` 48px |

- One icon per meaning across both sets.
- Chevrons and arrows: Lucide, never `←`/`›` glyphs. Spinners: daisyUI `loading`.
- Icon-only buttons: `btn-square` + `aria-label`.

## 3. Components

`use Setzkasten` imports all component modules; each can be imported alone. Every component appends `class` to its
base classes; most accept global attrs. Visible default strings are German and can be overridden by attrs.

### Actions

- **`button`** – `variant` `:primary` · `:neutral` (default; cancel/secondary) · `:ghost` · `:danger` ·
  `:danger_outline` · `:link`; `size` `:sm | :md | :lg`; `icon` (Lucide, before the label); `icon_only` (needs
  `label`, raises without); `loading` (spinner, `aria-busy`, disabled); `href`/`navigate`/`patch` render a link;
  `confirm` (+ `confirm_text`, `confirm_label`, `confirm_id`) asks in the shared confirmation dialog, see Overlays.
  40px on fine pointers, 44px on coarse.
- **`fab`** – the one main action on phones, above the dock (`md:hidden`); `label` becomes `aria-label`.

### Forms

- **`input`** – `field`, `type` (HTML types plus `select`, `textarea`, `checkbox`, `toggle`, `radio_group`), `label`,
  `hide_label`, `help`, `prefix`/`suffix` (€, %), `icon`, `numeric` (right-aligned, `tabular-nums`,
  `inputmode="decimal"`), `options`/`prompt`/`multiple`. `class` lands on the field box (`max-w-40` for narrow amounts).
  - Markup: `fieldset` > label > field > help > errors.
  - Errors show after `used_input?/1`: `aria-invalid`, border in `error-ink`, lines with `circle-alert`, linked by
    `aria-describedby`. Ecto messages via `config :setzkasten, translate_error: {Mod, :fun}`.
  - Checkbox and radio rows are labels with 44px height on coarse pointers.
- **`action_bar`** – form footer: primary at the end, cancel before it, destructive in `:secondary` at the start.
  Below `sm`: full width, stacked, primary on top. `sticky` pins it to the bottom (above the dock); primary and cancel
  then stay side by side.

### Feedback

- **`flash`, `flash_group`** – Phoenix's flash API, as a toast at the top (the bottom belongs to dock and action bar).
  `flash_group` also shows the connection-lost messages. `role="alert"` for errors, `status` for info.
- **`alert`** – `tone` `:info | :success | :warning | :error | :neutral`, `title`, `icon` (`false` hides it),
  `busy`, `on_close`, `:actions` slot (end of the row from `sm`, under the text on phones). Tinted background,
  base-content text, icon in `error-ink`/`success-ink` for error/success. `role="alert"` only for `:error`.
- **`badge`** – `tone` `:neutral | :info | :success | :warning | :error | :primary`; `style` `:dot` (default, neutral
  badge with status dot) or `:solid` (alarm states only); `size` `:sm` (default) | `:md`; `icon` (icon-only needs
  `label`).
- **`empty_state`** – says what goes here and how to get it, with one `:action`. `layout` `:inline` (default, in a
  section, list or card) | `:page` (centred, large plush, heading). `icon` or `plush`, `title`. Data that arrives by
  itself needs no action.

### Layout

- **`header`** – page title (`h1`, `text-2xl`), `back`/`back_label`, `:subtitle`, `:badge`, `:actions`. Actions wrap
  under the title on narrow screens.
- **`section_heading`** – `text-base` 600, sentence case; `count` badge, `:actions`; `mt-8` above unless first child.
- **`card`** – independent objects only (see Flat). `title`, `subtitle`, `level`, `as`, `:leading`, `:actions`,
  `:list` (flush list or table, no body padding), `:footer` (hairline note). `navigate`/`href` makes the whole card
  clickable. `bleed={:phone}` runs it edge to edge below `sm`. No margin; spacing comes from the parent.
- **`theme_toggle`**, **`theme_script`**, **`theme_meta`** – see section 7.

### Data

- **`table`** – Phoenix's `<.table>` API with streams, plus:
  - `size` `:md` (45px rows) | `:sm` (≈ 34px, read-only data); `zebra`; `flush` (inside a card or modal).
  - `:col` attrs `label`, `align={:end}` (right-aligned, `tabular-nums`, no wrap), `show_from` (`:sm`…`:xl`).
  - `groups` (`%{id, label, rows}`, one `<tbody>` with a `th scope="colgroup"` row each), `:foot` (total row; use
    `show_from/1` on hidden columns), `:empty` (works with streams), `row_link` (link stretched over the row).
  - `<.cell_sub hide_from={:lg}>` repeats hidden columns' values under the name.
  - Default: on the page between `border-y` hairlines, edge to edge on phones, horizontal scroll in its wrapper.
- **`list`, `list_heading`, `list_row`** – collections. Same flat default as tables; `flush` in a card.
  - `list_row`: `title`, `:leading` (plush, icon, avatar), `:meta` (truncates), `:trailing` (value, badge; moves to
    a second line below `md`), `navigate`/`patch`/`href` (row link plus chevron).
  - `:action` entries (`label`, `icon`, target or `on_click`, `confirm`, `danger`, `disabled`): icon buttons from
    `md`, a `⋮` menu below. Accessible names include the row title ("Bearbeiten: …").
- **`amount`** – money in de-DE (thousands dot, decimal comma, U+2212 minus, no-break space) in `<data value>`.
  `value` in minor units or `Decimal`; `currency` (default `"EUR"`); `signed`; `tone` (negative `error-ink`,
  positive `success-ink`, zero 70 %); `size={:lg}` for totals.
- **`stat`** – KPI tile: `label`, `value`, `unit`, `desc`, `tone` (`:success | :error`), `size` `:md` (32px) |
  `:sm` (24px, tile grids), `stale` (badge, never faded text), `loading` (skeleton). Grid:
  `grid grid-cols-2 md:grid-cols-4 gap-4`.
- **`description_list`** – label → value facts; values right-aligned, `tabular-nums`.
- **`bar`** – native `<progress>` with `label` and value: `value`, `max`, `tone`, `show_value`, `value_label`,
  `target` (2px marker drawn as SVG, no inline style). Pastel tones need `show_value`.
- **`avatar`** – `initials` or `icon`; `tone` (theme role or `:base`); `size` `:sm` 32 · `:md` 40 · `:lg` 48px;
  `shape` `:square` (default) | `:round`. `aria-hidden` unless `label` is set.
- **`chart_card`, `legend`** – the frame around an app-drawn chart: card, `role="img"` with `summary`, a `hook`
  container with `phx-update="ignore"` and a `<canvas>` (without `hook` the inner block, e.g. static SVG). `height`
  `:sm` 14rem · `:md` 16rem · `:lg` 19rem; slots `:actions`, `:legend`, `:data` (folded "Werte als Tabelle", the
  keyboard path to exact values); `loading` skeleton. `<.legend>`: `items` with `label` and `color` 1–8 or
  `:success | :error | :primary | :neutral`. Chart setup stays in the app.

### Navigation

- **`segmented`** – one choice out of a few, a `join` of buttons, selected = `btn-primary`. `mode` `:patch` (links,
  `aria-current`) | `:button` (`phx-click` with `phx-value-value`, `aria-pressed`) | `:radio` (form field). `label`,
  `size` `:sm | :md`; options as tuples or maps with `icon`.
- **`tabs`** – sibling views of one object; links only, `aria-current="page"` on the active `:tab`. Scrolls
  horizontally on phones. No client-side tab panels.
- **`dropdown`** – menu behind a button (`<details>`). `:trigger`, `:header`, `:item` (`navigate`/`patch`/`href`/
  `method` or `on_click`, `icon`, `active`, `danger`), `align`, `variant`, `chevron`, `trigger_class`. Closes on
  outside click, Escape and item choice; survives LiveView patches.

### Overlays

- **`modal`** – native `<dialog>`. `placement` `:center` (bottom sheet on phones) | `:end` | `:start` (side panel).
  Open with `show_modal(id)` or `show={true}`; close with `hide_modal(id)`, Escape, backdrop or
  `<form method="dialog">`. `on_cancel` runs after every close except `show={false}`.
- **`confirm_dialog`** – one per layout. Every irreversible delete asks here; archiving does not ask. `confirm` on
  `<.button>` and on list row actions, or `show_confirm(id, question, action, text: …, label: …)`, writes the
  question into it and puts the destructive command on its confirm button. Cancel, Escape and the backdrop only
  close. Focus starts on Cancel. No `data-confirm`, no `window.confirm`.
- **`disclosure`** – `<details>`; `variant` `:collapse` (default) | `:button` (compact "more options" trigger with
  `icon`); `open`. Open state survives patches.

### Shell

- **`app_shell`** – skip link, navigation, `<main id="main">`.
  - `layout={:sidebar}`: dark sidebar 18.5rem from `xl`, icon rail `md`–`xl` (expands as a dialog), top bar plus
    dock below `md`.
  - `layout={:topbar}` (default): navbar from `md`, dock below. `dock={false}` keeps the menu in the navbar on phones.
  - `width` `:narrow | :default | :wide | :full` (2.7); `current` marks the active `:nav` entry.
  - `:nav` entries: `key`, `label`, `navigate`/`href`, `icon` or `plush`, `count`, `amount`, `section`, `dock`
    (the first five go into the dock).
  - Slots `:brand` (required), `:nav_footer`, `:account`, `:fab`.
  - Dock: daisyUI `dock` (64px + safe area), hidden while a text field has focus. Sticky action bars sit above it
    via `--setzkasten-dock-offset`.

## 4. Patterns

### 4.1 Forms

- One column on phones; `grid gap-4 md:grid-cols-2` for short fields; text areas full width.
- Labels above, help below, errors last; `required` in HTML.
- On submit with errors: an `<.alert tone={:error}>` at the top with the count, focus on the first invalid field
  (`JS.focus(to: "[aria-invalid=true]")`).
- Inline form (field + button): `join max-sm:join-vertical`, `input join-item` with sr-only label,
  `<.button variant={:primary} class="join-item">`.
- Submit: `<.button variant={:primary} phx-disable-with="Speichert …">` inside `<.action_bar>`.
- Money: `suffix="€"`, `numeric`.

### 4.2 Lists

`<.list>` for collections, `<.list_heading>` for groups (e.g. dates). Load more with a stream +
`phx-viewport-bottom` or a "Mehr laden" button.

### 4.3 Responsive numeric tables

| Column | Visible from | Below that |
|---|---|---|
| Name (link, secondary id from `lg`) | always | carries the sub line |
| Key figure | always | – |
| Second figure | `sm` | under the key figure |
| Third-level figures | `md` | dropped |
| Details (quantity, price) | `lg` | sub line under the name |

- At most two always-visible columns: name and key figure.
- Every hidden value repeats in a sub line or is secondary.
- Numbers and their headers right-aligned, `tabular-nums`, no wrap; dates too.
- Group rows `th scope="colgroup"`; totals in `<tfoot>`; the name link is the row's navigation.

### 4.4 Empty, loading, stale

- Empty: `<.empty_state>` with one next step.
- Loading: skeletons in the final layout for async cards; `loading` on buttons; no full-page spinners.
- Stale live data: badge + timestamp, never reduced opacity.

## 5. Behaviour without a JS framework

| Need | Mechanism |
|---|---|
| Modal, sheet, side panel | `<dialog>` + `showModal()` via `JS.dispatch`; `<form method="dialog">` |
| Dropdown, row menu | `<details>` + `phx-click-away` + Escape via `phx-window-keydown`; `JS.ignore_attributes(["open"])` |
| Disclosure | `<details>` |
| Tabs, segmented ranges | links with `patch`, server state |
| Flash | `JS.push("lv:clear-flash")` + `JS.hide` |
| Confirm | `<.confirm_dialog>` + `show_confirm/3` |
| Sidebar overlay | `<.modal placement={:start}>` |
| Theme | `<.theme_script>` + colocated hook, or server-rendered `data-theme` |
| Submit lock | `phx-disable-with` |
| Infinite scroll | streams + `phx-viewport-bottom` |
| Charts | app hooks reading the chart tokens |

Spinners use `motion-safe:`.

## 6. Touch targets

The pointer decides, not the viewport.

| Element | Fine pointer | Coarse pointer |
|---|---|---|
| `btn`, `input`, `select`, `tab` | 40px | 44px |
| `btn-sm`, `btn-square` | 32px | 44 × 44px |
| menu items, summaries | ≈ 33px | 44px |
| checkbox, radio, toggle | 24px control | 44px label row |
| table rows | 45px (`:md`) | 45px |
| list rows | ≥ 53px | ≥ 53px |
| dock items | ≈ 48px | ≈ 48px |
| standalone text links | – | 44px: use `btn btn-ghost btn-sm` or `btn-link` |

Inline links in sentences are exempt (WCAG 2.5.8).

## 7. Theme switching

- No `data-theme`: the system decides. Explicit choice: `data-theme="zipfel-light|zipfel-dark"`.
- Tailwind's `dark:` matches both ways into dark mode.
- `<.theme_toggle>`: System / Hell / Dunkel; `compact` shows icons only. All toggles on a page stay in sync.
  - `store={:local}` (default): `localStorage["setzkasten:theme"]`; add `<.theme_script nonce={…}>` to the root
    layout's `<head>` so it applies before paint.
  - `store={:server}`: sends `on_change` with `%{"theme" => …}`; the app saves it and renders `data-theme`.
- `<.theme_meta />`: the two `theme-color` meta tags (`#ffffff` / `#2d2f33`).
