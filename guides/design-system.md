# Setzkasten design system

Tailwind CSS 4 + daisyUI 5. The catalog (`mix dev`) renders every component listed here. The function
docs are the exact API; this guide gives the rules.

## 1. Principles

| Rule | In practice |
|---|---|
| daisyUI defaults first | Sizes, radii and type steps are daisyUI's or Tailwind's unless a rule below says otherwise. |
| Calm | One accent (`primary`), at most one solid primary block per screen; selection is the neutral `selected`. Colour carries state, not decoration. Pastel fills with dark text. Flat surfaces with hairlines, no texture. |
| Flat | The page is base-100. Sections are structured by headings, spacing and hairlines. Tables, lists and forms sit on the page, full width, edge to edge on phones. Cards only for independent objects: dashboard tiles, KPI groups, titled charts, clickable object grids, dialogs. |
| Floors | Text ≥ 12px · text 4.5:1, marks and boundaries 3:1 (WCAG 2.x) · targets 44px on coarse pointers · prose ≤ 65ch · numbers `tabular-nums`. |
| No JS framework, no inline styles | `<dialog>`, `<details>`, `Phoenix.LiveView.JS`, colocated hooks. Works under a strict CSP. |
| Themes | `zipfel-light` default, `zipfel-dark` on `prefers-color-scheme: dark`; an explicit choice sets `data-theme` on `<html>`. |

## 2. Tokens

### 2.1 Theme colours

| Role | Light | Dark | Used for |
|---|---|---|---|
| base-100 | `#ffffff` | `#202328` | page, cards, fields; menus and modals in light |
| base-200 | `#f4f8fb` | `#2a2d32` | zebra rows, group rows, code, neutral buttons, tiles; menus and modals in dark |
| base-300 | `#e5edf3` | `#34373c` | wells, trays, kbd |
| base-content | `#0d1928` | `#e9ebef` | all text |
| primary / -content | `#0077b4` / `#fff` | `#61bdff` / `#001c32` | main action, links, focus, checked controls (checkbox, toggle, radio, progress) |
| secondary / -content | `#f7b385` / `#3e1b0b` | `#f6b88f` / `#381b0e` | rare; no default button uses it |
| accent / -content | `#b7a1f5` / `#22163c` | `#bda8fc` / `#20143a` | reserved; no component uses it |
| neutral / -content | `#3d4958` / `#f6f9fc` | `#0b0d12` / `#e9ebef` | `btn-neutral` |
| selected / -content | `#3d4958` / `#f6f9fc` (neutral) | `#d4d8de` / `#202328` | current menu item, selected segmented option and theme toggle option, tooltips (daisyUI's neutral is 1.2:1 on the dark page; in the sidebar `sidebar-content` with `sidebar` text) |
| row-selected | `#e6f4ff` | `#2a3846` | the selected or current row of a table or grid, with a 3px `selected` bar at its start |
| info / -content | `#47d2e8` / `#002934` | `#60d8eb` / `#002631` | info alerts and flashes |
| success / -content | `#54dd7d` / `#092c13` | `#65e287` / `#062911` | success fills |
| warning / -content | `#ffc845` / `#3b1e02` | `#ffcc5a` / `#381c01` | warnings |
| error / -content | `#fd7273` / `#34080b` | `#ff8382` / `#34080b` | errors, destructive buttons (dark) |
| success-ink | `#007f38` | `#65e287` (success) | positive amounts, success icons |
| error-ink | `#cc272e` | `#ff8382` (error) | negative amounts, error lines and borders, filled destructive buttons with white text (light) |
| info-ink | `#037a7f` | `#60d8eb` (info) | info text, icons and marks |
| warning-ink | `#956300` | `#ffcc5a` (warning) | warning text, icons and marks such as ratings |

The inks (`success-ink`, `error-ink`, `info-ink`, `warning-ink`), `selected` and `row-selected` are extra tokens
(`text-success-ink`, `text-warning-ink`, `bg-selected`, `text-selected-content`, `bg-row-selected`, …): the light
fills are pastels and too faint as text or thin lines; `selected` keeps primary for the main action. A button takes it
with the utility `setzkasten-selected`; in the dark sidebar it inverts to `sidebar-content` with `sidebar` text. A
token that equals a role follows it with `var()`: in dark the inks are their roles (`success`, `error`, `info`,
`warning`) and `sidebar-negative` is `error-ink`; in light `selected` is `neutral` (and `neutral-content`); the chart
lines 2, 3, 4 and 6 are the inks. An app that overrides such a role restates nothing else.

- **Text levels:** `text-base-content` (body, field labels) · `text-base-content/70` (meta, help lines, KPI titles)
  · daisyUI's `/60` (`thead`, `stat-desc`) · nothing lighter. Placeholders and disabled text are exempt.
- **Coloured text:** only `text-primary` and the inks (`text-success-ink`, `text-error-ink`, `text-info-ink`,
  `text-warning-ink`); every ink holds 4.5:1 on base-100/200, so it serves text, icons and marks. Use `secondary`,
  `accent`, `info`, `success`, `warning`, `error` only as a fill with their `-content` text, never as text, icon or
  thin mark on base-100/200 (both themes, since components use the same classes in each).
- **Hairlines:** `border-base-content/10` (dividers, card edge). Field borders are 50 % base-content, as are the
  borders of a plain `checkbox` or `radio` (`checkbox-primary` and other variants keep their colour); error fields
  (`input-error`, `select-error`, `textarea-error`, `file-input-error`) use `error-ink`.
- **Dark elevation:** in dark, base-200/300 are lighter than base-100 (daisyUI: darker), so neutral buttons and tiles
  stand out from the page instead of reading as holes. Dropdown menus and modal boxes take the extra token
  `popover` (`bg-popover`): base-100 in light, base-200 in dark, where the modal box also gets a
  `base-content/10` hairline (`--setzkasten-popover-border`). On that surface neutral controls (neutral `btn`,
  unselected `segmented` options, the file input's button) take `--setzkasten-popover-control`: base-200 in light
  (unchanged), base-300 in dark, the same one-step lift as on the page.
- **Browser surfaces:** `accent-color` and the caret are primary; `::selection` is primary 25 % in base-100 with
  base-content text.
- **Alert tint:** soft alerts mix `--setzkasten-alert-tint` of their tone into the background: 25 % light, 8 % dark.
  Neutral alerts take `--setzkasten-alert-neutral-tint` of base-content: 5 % light, 8 % dark.
  At 8 % the tones look alike on dark grey, so dark draws the border with `--setzkasten-alert-border` 40 %
  (light 10 %, daisyUI's).
  Neutral buttons in a soft alert (its `:actions`) take `--setzkasten-alert-control` (base-100 in light, base-300
  in dark: a step lighter than the tint) and the field border, 50 % base-content; base-200, their fill elsewhere,
  is 1.01:1 on the dark tint and 1.08:1 on the light one. Hover mixes 7 % base-content into the fill.
  Override after the import:

  ```css
  @layer base {
    :where(:root), [data-theme="zipfel-light"] { --setzkasten-alert-tint: 8%; }
  }
  ```

### 2.2 Chart series

Eight series, two tokens each (`bg-chart-N-fill`, `fill-chart-N-fill`, `stroke-chart-N`, `border-chart-N`; CSS
`--color-chart-N-fill`, `--color-chart-N`), plus `chart-other-fill` and `chart-other` for the grouped rest:

- `chart-N-fill`: bars, areas, slices, dots, legend swatches.
- `chart-N`: lines, markers, outlines; ≥ 3:1 on base-100/200. Series 2, 3, 4 and 6 draw them in the inks.

| Series | Light fill | Light line | Dark fill = line |
|---|---|---|---|
| 1 primary | `#0077b4` | `#0077b4` | `#61bdff` |
| 2 warning | `#ffc845` | `#956300` (warning-ink) | `#ffcc5a` |
| 3 success | `#54dd7d` | `#007f38` (success-ink) | `#65e287` |
| 4 error | `#fd7273` | `#cc272e` (error-ink) | `#ff8382` |
| 5 accent | `#b7a1f5` | `#876dc8` | `#bda8fc` |
| 6 info | `#47d2e8` | `#037a7f` (info-ink) | `#60d8eb` |
| 7 secondary | `#f7b385` | `#c3610c` | `#f6b88f` |
| 8 neutral | `#3d4958` | `#3d4958` | `#9aa6b4` |
| other (grouped rest) | `#ccd2d9` | `#7b8187` | `#767b80` |

- Bars, areas, slices: `chart-N-fill` with a 1px `chart-N` outline (the outline carries the 3:1). SVG:
  `class="fill-chart-2-fill stroke-chart-2" stroke-width="1"`, plus `vector-effect="non-scaling-stroke"` in a
  stretched viewBox.
- Ordered categories (particle size bins, heat-map steps, ranges) take the sequential ramp, never categorical or
  semantic colours: honey and red read as warning and bad. Five steps of one hue, `seq-1` (low, near the surface) to
  `seq-5` (high, far from it), in light from pale to deep blue, in dark from dim to bright (`bg-seq-N`, `fill-seq-N`,
  `stroke-seq-N`; `--color-seq-N`; `color: {:seq, N}` in `legend`, `bar` and `share_bar`). Fill = line; neighbours
  differ by 1.4:1 or more, the low end stays visible on the surface (2.4). Fewer than five bins: spread them
  (1, 3, 5 or 1, 2, 4, 5), keep the low end low.

  | Step | Light | Dark |
  |---|---|---|
  | seq-1 | `#aed3f3` | `#2a4b66` |
  | seq-2 | `#80b4e1` | `#356890` |
  | seq-3 | `#4d92ca` | `#4b89bb` |
  | seq-4 | `#1e71ac` | `#6dabdf` |
  | seq-5 | `#0b517f` | `#a2d0f9` |

- Stacked share bars (`share_bar`): fills only, no line. Outlines would cut one bar into pieces; a 2px gap that shows
  the surface separates neighbours (and the filled part from the empty rest, base-content 10 %). The bar carries no
  meaning alone: its values are text in the legend (or a list for screen readers), so its pastel fills need no 3:1,
  as 2.4 allows pastels next to the words that carry the meaning. Largest first, the grouped rest (`:other`) last.
- Chart.js: `backgroundColor` = `--color-chart-N-fill`, `borderColor` = `--color-chart-N`, `borderWidth: 1`.
- Semantic series: warnings 2, income 3, overspend 4. Categorical series take the numbers in order from 1 and skip
  those the chart already uses semantically: with warnings in 2 and nothing else semantic, the categories take 1, 3,
  4, 5 and so on. More categories than free series: group the rest into one series ("Sonstige") in `chart-other`, a
  calm grey lighter than series 8 in light and dimmer in dark; `legend` takes it as `color: :other`.
- Units and periods go in the chart card's `subtitle` ("Leistung in Watt", "seit 27.08.2026 · 16 Tage"); ticks show
  bare numbers, no axis titles.
- At most 5–6 value ticks on an axis, at round steps; a phone shows fewer (3–4), so labels never crowd or overlap.
- Read tokens with `getComputedStyle(document.documentElement)`; redraw on theme change (observe `data-theme`,
  listen to `prefers-color-scheme`). Chart text ≥ 12px.

Sidebar tokens (`:sidebar` shell): `sidebar` `#2c394a`/`#14161b`, `sidebar-content` `#f6f9fc`/`#eceff2`,
`sidebar-muted` `#bcc9d7`/`#b7bbc1`, `sidebar-accent` `#80c5ff`/`#6eb6ff`, `sidebar-negative` `#f8a9a5`/`#ff8382`
(`error-ink` in dark; negative amounts with `amount_tone`; light is lighter than `error-ink` so it also holds on
the white 10 % of the current and hovered entry).

### 2.3 Structure tokens

| Token | Value | Note |
|---|---|---|
| `--radius-box` | 0.75rem | cards, alerts, modals, tables |
| `--radius-field` | 0.5rem | buttons, inputs, tabs, menu items, square avatars |
| `--radius-selector` | 0.5rem | checkbox, badge, toggle |
| `--size-field` / `--size-selector` | 0.25rem | button/input md 40px, checkbox md 24px |
| `--border` | 1px | |
| `--depth` | 0 | flat buttons, no 3D edge (daisyUI: 1) |
| `--noise` | 0 | |

Radii via `rounded-box`, `rounded-field`, `rounded-selector`; `rounded-full` for avatars and dots only. Shadows:
cards none; dropdowns, popovers, toasts and FAB `shadow-lg`; modals daisyUI's.

### 2.4 Contrast

| Pair | Need | Light | Dark |
|---|---|---|---|
| base-content on base-100 / 200 / 300 | 4.5 | 17.69 / 16.57 / 14.95 | 13.20 / 11.58 / 10.01 |
| primary-content on primary | 4.5 | 4.89 | 8.44 |
| secondary-content on secondary | 4.5 | 8.59 | 9.14 |
| accent-content on accent | 4.5 | 7.56 | 8.32 |
| neutral-content on neutral | 4.5 | 8.67 | 16.28 |
| selected-content on selected | 4.5 | 8.67 | 11.01 |
| info-content on info | 4.5 | 8.53 | 9.47 |
| success-content on success | 4.5 | 8.70 | 9.59 |
| warning-content on warning | 4.5 | 9.91 | 10.51 |
| error-content on error | 4.5 | 6.61 | 7.44 |
| base-content/60 on base-100 / 200 | 4.5 | 4.66 / 4.58 | 5.66 / 5.21 |
| base-content/70 (secondary text, help, KPI and menu titles) on base-100 / 200 / 300 | 4.5 | 6.56 / 6.37 / 6.03 | 7.17 / 6.51 / 5.82 |
| text-primary on base-100 / 200 | 4.5 | 4.89 / 4.58 | 7.68 / 6.73 |
| text-success-ink on base-100 / 200 | 4.5 | 5.13 / 4.81 | 9.59 / 8.41 |
| text-error-ink on base-100 / 200 | 4.5 | 5.39 / 5.05 | 6.62 / 5.80 |
| text-info-ink / text-warning-ink on base-100 / 200 | 4.5 | 5.13 / 4.80, 5.17 / 4.84 | 9.40 / 8.24, 10.53 / 9.24 |
| field, plain checkbox and radio border (50 %) on base-100 / 200 (page and popover) | 3 | 3.39 / 3.32 | 4.38 / 4.11 |
| neutral control fill on its surface: page / popover (label identifies it) | – | 1.07 / 1.07 | 1.14 / 1.16 |
| selected fill on page / track (base-200) / popover track (dark: base-300) | 3 | 9.16 / 8.58 / 8.58 | 11.01 / 9.66 / 8.35 |
| row-selected fill on base-100 / base-200 (zebra, group rows; hue and the bar tell them apart) | – | 1.12 / 1.05 | 1.32 / 1.16 |
| row-selected bar (`selected`, 3px) on row-selected / base-100 | 3 | 8.18 / 9.16 | 8.33 / 10.99 |
| on row-selected: base-content / 70 % / success-ink / error-ink | 4.5 | 15.80 / 6.23 / 4.58 / 4.81 | 10.01 / 5.81 / 7.28 / 5.02 |
| text-primary on row-selected (below 4.5: keep links in rows base-content, as `row_link` does) | 4.5 | 4.36 | 5.82 |
| error border, `btn-error btn-outline` on base-100 | 3 | 5.39 | 6.62 |
| primary as mark (focus, checkbox, toggle track, progress) on base-100 / 200 | 3 | 4.89 / 4.58 | 7.68 / 6.73 |
| checked toggle: knob (primary-content) on track (primary) | 3 | 4.89 | 8.44 |
| neutral bar (base-content 70 %) on its track, base-100 / 200 | 3 | 5.33 / 5.15 | 4.56 / 4.11 |
| alert-soft text on tint (neutral included) | 4.5 | 14.04–15.97 | 11.06–11.75 |
| alert icon on tint: info (`info-ink`) / warning (`warning-ink`) | 3 | 4.46 / 4.66 | 8.13 / 8.96 |
| neutral button in a soft alert: border (50 % base-content) on the tint, info / success / warning / error / neutral | 3 | 3.28 / 3.29 / 3.32 / 3.22 / 3.30 | 4.06 / 4.05 / 4.04 / 4.12 / 3.99 |
| neutral button in a soft alert: fill (`alert-control`) on the tint (border identifies it) | – | 1.11–1.26 | 1.10–1.16 |
| neutral button in a soft alert: text on its fill | 4.5 | 17.70 | 10.04 |
| `::selection` text on its fill (primary 25 % in base-100) | 4.5 | 12.66 | 8.19 |
| button hover: primary / error content | 4.5 | 5.78 / 5.49 | 6.93 / 6.14 |
| sidebar content / muted / accent | 4.5 / 4.5 / 3 | 11.10 / 6.96 / 6.34 | 15.68 / 9.39 / 8.44 |
| sidebar-negative on the sidebar / on its current or hovered entry (white 10 %) | 4.5 | 6.25 / 4.60 | 7.60 / 5.76 |
| chart-other line (the grouped rest) on base-100 / 200 | 3 | 3.94 / 3.69 | 3.69 / 3.23 |
| sequential ramp seq-1 … seq-5 on base-100 / 200 (neighbours ≥ 1.40) | – | 1.57 / 1.47 … 8.41 / 7.87 | 1.72 / 1.51 … 9.70 / 8.51 |

The light pastel fills as marks (status dots, `progress-success|warning|error|info`) are below 3:1; alert icons use
the inks instead. Use them only next to a word that carries the meaning; a mark that must stand alone uses `primary`,
an ink or a chart token. The neutral status dot is base-content 50 % (about 3:1), not daisyUI's 20 % (1.6:1).

Avoid: `btn-soft`/`badge-soft` with coloured text, coloured text in light fills other than `primary`, `tabs-box`.

### 2.5 Type scale

Figtree (variable, `wght` 300–900, roman and italic; SIL OFL 1.1) as `--font-sans`, then "Figtree Fallback",
a local Arial with `size-adjust` and ascent/descent overrides matched to Figtree, so a late or missing font
does not shift lines. The app serves `priv/static/fonts` at `/setzkasten/fonts` (`Plug.Static`, README) and
preloads the roman file; `font-display: swap`. Code stays in the system mono stack. Antialiased; headings
`text-wrap: balance`, paragraphs `pretty`. Controls, tables and card bodies 14px; prose 16px. Figtree's
default `wght` is 300; the browser maps `font-weight` onto the axis, so unweighted text is 400.

The minus sign (U+2212, in every `amount` and formatted number) comes from a second "Figtree" face with
`unicode-range: U+2212` (`SetzkastenMinus-Variable.woff2` and `-Italic-`, 0.7 KB each, loaded only on pages that
show one): Figtree's own minus is a 0.38em bar with 0.12em side bearings, which next to tabular figures reads as a
short dash with a wide gap ("- 1.150,00"). The replacement is Figtree's plus without its vertical bar, so it
matches the plus at every weight: 0.45em wide at 400 (0.45–0.47em over the axis), at the plus bar's height and
stroke, 0.085em side bearings (an en dash is 0.55em and sits at the same height). The gap to a digit is that
bearing plus the digit's own (tabular `1` 0.15em, `0` 0.04em), the same as after a plus. The files are derived
from Figtree under the OFL; `dev/fonts/build_minus.py` (fontTools) rebuilds them.

| Role | Class | Size / line | Weight |
|---|---|---|---|
| Page title (`<.header>`) | `text-2xl` | 24 / 32px | 600, −0.01em |
| KPI value (`<.stat>`) | `stat-value` / `text-2xl` (`size={:sm}`) | 32px / 24px | 600, −0.02em |
| KPI title | `stat-title` | 14 / 20px | 500, base-content/70 |
| Section heading | `text-lg` | 18 / 28px | 600 |
| Card title | `card-title` | 16 / 24px | 600 |
| Body prose | `text-base` | 16 / 24px | 400 |
| Controls, tables, menus, alerts | `text-sm` | 14 / 20px | 400; buttons 600 |
| Meta, help, table sub lines | `text-sm text-base-content/70` | 14 / 20px | 400; error lines the same size |
| Field labels | `fieldset-legend` | 14 / 20px | 500 |
| Small buttons, `segmented size={:sm}` | `btn-sm` | 13px (daisyUI: 12) | 600 |
| Small badges, captions, dock labels, chart ticks | `text-xs` | 12 / 16px | 400–600 |

Not used (below 12px): `btn-xs`, `input-xs`, `table-xs`, `badge-xs`, `kbd-xs`.

### 2.6 Spacing

Tailwind's 4px scale; steps in use `1` `1.5` `2` `3` `4` `6` `8` `12`.

| Gap | Value |
|---|---|
| Inside a card | `card-body`: padding 24px, gap 8px |
| Between form fields | `gap-4` |
| Between cards, grid gutter | `gap-4 md:gap-6` |
| Above a section heading | `mt-8`; none as the first child (page, card, dialog, its own `<section>`) |
| Between wrapped sections | `gap-8` on the parent (`flex flex-col gap-8`, `space-y-8` or the grid's gap) |
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

`app_shell` aligns the capped widths to the start in the sidebar layout and centres them in the top-bar layout (3,
Shell). Its top bar row follows the page's `width` unless `bar_width` gives it one of its own: an app whose pages
differ in width (`:narrow` forms, `:default` dashboards) sets `bar_width` once in its layout, so the header keeps
its width from page to page and its menu does not scroll on narrow pages.

### 2.8 Icons

| Set | Use | Render | Sizes |
|---|---|---|---|
| Lucide (stroke, `currentColor`) | actions, chevrons, status | `<.icon name="trash-2">` → inline `<svg class="lucide">` | `size-4` next to `text-sm` (default), `size-5` standalone, `size-6` empty states |
| Plush (WebP, light and dark file) | navigation, categories, settings links | `<.plush name="home">` → `<img class="plush">` | `:sm` 20 (sidebar) · `:md` 24 (dock, top-bar menu: smaller artwork does not read) · `:lg` 32 (list leading) · `:xl` 48px |

- One icon per meaning across both sets.
- A plush with a dark file renders two `<img>`, one per theme: an `id` stays on the light one, the dark one
  takes `<id>-dark`; other attrs go on both.
- A `size-*` class replaces the size class of both sets (`icon` and `plush`), e.g. a plush that scales with its
  container; a plush keeps `width`/`height` from `size` for its box before CSS.
- Chevrons and arrows: Lucide, never `←`/`›` glyphs. Spinners: daisyUI `loading`.
- Icon-only buttons: `btn-square` + `aria-label`.

### 2.9 Motion

Motion shows a state change, acknowledges an action or keeps continuity; nothing moves for decoration or as a
page-load sequence. Pure CSS in `setzkasten.css`, replacing daisyUI's timings.

| Token | Value | Use |
|---|---|---|
| `--setzkasten-ease-out` | `cubic-bezier(0.16, 1, 0.3, 1)` | entrances, state changes |
| `--setzkasten-ease-in` | `cubic-bezier(0.4, 0, 1, 1)` | exits |
| `--setzkasten-ease-in-out` | `cubic-bezier(0.65, 0, 0.35, 1)` | theme reveal |
| `--setzkasten-duration-press` | 100ms | press, tick fade |
| `--setzkasten-duration-exit` | 150ms | every exit, button colours |
| `--setzkasten-duration` | 200ms | menus, disclosures, toasts, tabs, checkbox, toggle |
| `--setzkasten-duration-overlay` | 250ms | dialog entrance |
| `--setzkasten-duration-reveal` | 700ms | theme reveal |
| `--setzkasten-duration-count` | 500ms | rolling numbers |

| What | Motion | Reduced motion |
|---|---|---|
| `modal`, `confirm_dialog` | scrim fades; a centred box rises 8px from 97 %, a sheet or side panel slides in opaque from its edge; the exit stays in the top layer (`overlay`) | box fades, no movement |
| `fab` | steps back (fade, 80 %) while any dialog is open | fades |
| buttons | `:active` scales to 97 % | colour only |
| `dropdown` | unfolds from the trigger's corner (96 %, 4px), fades out on close | fades |
| `popover` | as `dropdown`, from the trigger's corner; a bottom sheet on phones slides up over a fading scrim; the exit stays in the top layer | fades |
| `disclosure` | opens at once, content settles 4px, the arrow turns | content fades, arrow flips |
| `selection_bar` | rises 8px into place and fades in (200ms); leaves at once with the selection | fades in |
| `flash` | enters 8px from the top edge, leaves upward in 150ms (`hide_flash`) | fades |
| `tabs` | the active line grows from its centre, the old one fades | colour fades |
| checkbox, toggle | tick and knob in 200ms, no delay | tick fades, knob jumps |
| `tooltip` | daisyUI's: fades in with a 4px shift in 200ms, out after 75ms | appears and disappears at once |

Not animated: the sidebar collapse (it changes the layout in three places; following it would mean animating
widths), list and table rows (instant hover and press colour in dense lists). A disclosure or menu rendered open
fades its content in once. Animate transform, opacity and colour only, never width, height or position.

### 2.10 Delight

Three brief moments that confirm something the user did or needs to notice. Never on page load, never in a loop,
never two on one element at once, one per action. The catalog's Delights page shows each with these rules.

| Moment | How | Motion | Reduced motion |
|---|---|---|---|
| Saved | `<.button id=… saved>`; the server calls `push_saved(socket, id)` after a successful save | check draws in 250ms, label "Gespeichert" for 1.5 s, then back; same width (labels share one grid cell); polite live region | crossfade only |
| Theme reveal | every `<.theme_toggle>` | the new theme grows from the chosen icon as a circle with a 24px soft edge, 700ms ease-in-out (View Transitions) | instant, as without View Transitions or when the shown scheme stays the same |
| Rolling number | `<.stat id=…>` (on by default with an `id`), `<.amount id=… animate>` | a value changed by an update counts from old to new in 500ms, `tabular-nums` | instant |

| Moment | Fits | Does not fit |
|---|---|---|
| Saved | a form that stays on the page after saving: settings, detail forms, inline edits | a save that navigates away (the next page shows the result), a create that adds a row (the row is the confirmation), errors (alert or field errors) |
| Theme reveal | the explicit choice in the toggle | theme changes that come from the system or another tab: those switch instantly |
| Rolling number | KPIs and balances that change through the user's action or a meaningful event (a booking, a new reading every few seconds) | first render, reconnects with the same value, streams that tick every second (throttle on the server or `animate={false}`), table cells and long lists |

- **Saved replaces the success flash.** Use one or the other, never both; failures still use the flash or an
  alert.
- **One switch per number.** Inside a `<.stat>` value the stat animates its number; an `<.amount animate>` there
  animates itself and the stat leaves it alone.
- Numbers in the components' German format ("2,14", "−0,88", "12.521,00 €", "94,4 %"); the last frame is
  the server's text, unchanged. Text the hook cannot read as a number (or with a different unit) just updates.

## 3. Components

`use Setzkasten` imports all component modules; each can be imported alone. Every component appends `class` to its
base classes; most accept global attrs. Text in components wraps long unbroken strings (host names, URLs) instead
of widening the page (`wrap-anywhere`; `fieldset-legend` and `card-title` via the CSS patch).

Visible and accessible default strings are German; each has an attr:

| Component | Attrs (default) |
|---|---|
| `header` | `back_label` (Zurück) |
| `list_row` | `actions_label` (Aktionen) |
| `stat` | `stale_label` (veraltet) |
| `chart_card` | `data_label` (Werte als Tabelle) |
| `alert`, `flash`, `modal` | `close_label` (Schließen) |
| `flash_group` | `close_label`, `client_error` (Keine Verbindung), `server_error` (Etwas ist schiefgelaufen), `reconnecting` (Verbindung wird wiederhergestellt) |
| `confirm_dialog` | `title` (Wirklich löschen?), `text` (Das lässt sich nicht rückgängig machen.), `confirm_label` (Löschen), `cancel_label` (Abbrechen), `close_label` |
| `theme_toggle` | `label` (Farbschema), `labels` (System / Hell / Dunkel) |
| `button` | `saved_label` (Gespeichert) |
| `selection_bar` | `label` (%{count} ausgewählt), `clear_label` (Auswahl aufheben) |
| `combobox` | `create_label` („%{text}“ anlegen), `empty_label` (Keine Treffer) |
| `file_drop` | `drop_label` (Hierher ziehen oder auswählen), `button_label` (Datei auswählen; Dateien auswählen for several), `no_file_label` (Keine Datei ausgewählt; Keine Dateien ausgewählt), `error_labels` (`too_large` Die Datei ist zu groß. · `too_many_files` Zu viele Dateien. · `not_accepted` Dieser Dateityp passt nicht. · `external_client_failure` Die Datei ließ sich nicht hochladen.) |
| `app_shell` | `nav_label` (Hauptnavigation), `skip_label` (Zum Inhalt springen), `expand_label` (Seitenleiste ausklappen), `collapse_label` (Seitenleiste einklappen), `more_label` (Mehr) |

### Actions

- **`button`** – `variant` `:primary` · `:neutral` (default; cancel/secondary) · `:ghost` · `:danger` ·
  `:danger_outline` · `:link`; `size` `:sm | :md | :lg`; `icon` (Lucide, before the label); `icon_only` (needs
  `label`, raises without); `loading` (spinner, a still ellipsis with reduced motion; `aria-busy`, disabled);
  `href`/`navigate`/`patch` render a link; `confirm` (+ `confirm_text`, `confirm_label`, `confirm_id`) asks in the
  shared confirmation dialog, see Overlays; an event name keeps its `phx-value-*`, its `value` (as `"value"`, over
  a `phx-value-value`, as LiveView's client sends it) and `phx-target`, a `%JS{}`
  carries its own target (`JS.push("delete", target: @myself)`). Without `confirm` a `phx-value-value` also renders
  as the button's `value`, which LiveView's client sends in its place; `confirm` with `href`/`navigate`/`patch`/`method`
  raises (a link would navigate without asking), as does `confirm` without `phx-click` on a button that does not
  submit. On `type="submit"` (needs `id`, not with `saved`) `confirm` asks
  before the form is sent: a colocated hook keeps the click and Enter in a field from submitting, the dialog's
  confirm button submits the button's form (also via `form="…"`) with the button as submitter (`name`/`value`
  go along, `phx-click` runs first if set); Cancel sends nothing; a `phx-hook` of its own raises. It needs a connected LiveView: before
  the hook mounts (dead render, slow connect) a click submits without asking. Its `id` is a plain CSS identifier (no
  `.` or `:`), as for every id the overlay helpers address. `saved` (needs `id`, raises without or on a link): the saved
  moment of 2.10 after `push_saved(socket, id)`; a `phx-disable-with` text becomes the pending label in the same
  stack (LiveView would flatten the stack otherwise). A button with an `icon` keeps it through `phx-disable-with`
  in the same kind of stack.
  40px on fine pointers, 44px on coarse. `:danger` is filled `error-ink` with white text in light (as strong as
  primary), the error fill in dark. In the dark sidebar a `:neutral` button takes a quiet translucent fill, for a
  global action that should not compete with the page's primary.
- **`fab`** – the one main action on phones (`md:hidden`), 16px above the dock (`--setzkasten-dock-offset`) or,
  without one, above the bottom safe edge; `label` becomes `aria-label`.

- **`selection_bar`** – the actions for a multi-selection (checked table rows): `id`, `count`, `label` (`%{count}`
  is the number; pass a plural form from Gettext), `on_clear` (event name + `phx-target`, or `%JS{}`),
  `clear_label`, inner block with the actions (`size={:sm}` ghost buttons, dropdowns, popovers).
  - Render it always: at 0 it is `hidden` (focus inside moves to the closest `[data-focus-fallback]`, else
    `<main>`); an always present `sr-only` `role="status"` announces each count
    politely (the visible count is `aria-hidden`, so browse mode reads it once; it names the `role="group"`).
  - Fixed at the bottom of the content area: from the shell's `--setzkasten-shell-start` (sidebar 16rem, rail
    4.25rem + left inset, also collapsed; 0 in the top-bar layout), 16px above the dock offset or the bottom safe
    area, the right inset kept. A pill on the popover surface (hairline, `shadow-lg`, `rounded-box`) centred in
    that area, wrapping on phones. A spacer (80px) at its place lets the last rows scroll above it.
  - Dropdowns inside open upwards (CSS); popovers flip above by themselves. The `fab` steps back while it shows.

### Forms

- **`input`** – `field`, `type` (HTML types plus `select`, `textarea`, `checkbox`, `toggle`, `radio_group`), `label`,
  `hide_label`, `help`, `prefix`/`suffix` (€, %), `icon`, `numeric` (right-aligned, `tabular-nums`,
  `inputmode="decimal"`), `options`/`prompt`/`multiple`. `class` lands on the field box (`max-w-40` for narrow amounts).
  - Markup: `fieldset` > label > field > errors > help.
  - `radio_group` options: `{label, value}` or maps with `:description`, a 70 % line under the label (what the choice
    brings: "Nächster Termin 19.11.2026"); the radio sits on the first line, the label alone is its name and the
    description its `aria-describedby`.
  - `help_tone={:warning}`: the help line with `triangle-alert`, text in full base-content (warning is a fill,
    never text); still linked by `aria-describedby`.
  - `inline` (text-like types): field and inner block (the button, `class="join-item"`) in one `join`, stacked
    below `sm`; label sr-only; errors and help below the join. See 4.1.
  - Errors show after `used_input?/1`: `aria-invalid`, border in `error-ink`, lines with `circle-alert` (first
    letter upper case), linked by `aria-describedby`. Ecto messages via `config :setzkasten, translate_error: {Mod, :fun}`.
  - `radio_group` is a `fieldset` with `role="radiogroup"`, which carries `aria-invalid` with errors.
  - Checkbox and radio rows are labels with 44px height on coarse pointers. A toggle is a checkbox with
    `role="switch"` (announced as a switch, on or off from its native checked state). A checked toggle fills its track
    (primary) with a `primary-content` knob. `bare` (checkbox, toggle): no field padding or row height, for a control
    beside a heading (a card's `:actions`); on touch screens a hit area centred on the label (`::after`), at least
    44px each way, also with `hide_label`, keeps the target without growing the row.
  - The fieldset's 8px of room sit above it, none below its last line, so in an `items-end` row a field with a
    visible label ends where a button or `segmented` beside it ends (a date range with "Anwenden"); stacked fields
    keep daisyUI's spacing. With the label for screen readers only (`hide_label`, `inline`) the fieldset has no block
    padding, so the field lines up with buttons beside it (a search field next to a `segmented`).
- **`combobox`** – a searchable select (ARIA combobox + listbox) for long lists (payees, categories): `field` or
  `id` with `name`/`value`, `label`, `hide_label`, `help`, `errors`, `placeholder`, `class` on the field box, global `disabled`,
  `required`, `form`, `autofocus`. `options`: `{label, value}`, maps (`:label`, `:value`, `:key` as extra search
  text, anything else for the `:option` slot) and `{group, options}` groups. Markup as `input`, with a
  `label.input` box and a `chevron-down`; a hidden text field (`hidden`, not `type="hidden"`, which LiveView never
  marks used) carries the value, so errors show after `used_input?/1` as for `input`.
  - Behaviour (colocated hook): the list opens on focus, click, typing and ArrowDown and filters in the browser
    (case, accents, "ß"/"ss" and emoji ignored); ArrowUp/Down move the highlight (`aria-activedescendant`, a
    primary ring), Enter and Tab take it (Enter on a text that matches nothing does not submit the form), Escape closes only the list and restores the text (it stops the event,
    so a surrounding popover or dialog stays). Leaving restores the chosen option's text; an empty text clears
    the value. The chosen option has a check. Typing is kept out of `phx-change`; a choice fires `input` on the
    hidden field, so `phx-change` sees it.
  - `allow_create`: an entry `create_label` for typed text that matches no option exactly. Without `create_field`
    the text becomes the value (name fields); with it the value is cleared and the text goes to `create_field`
    (id fields: the server tells new from existing).
  - Shared options: `combobox_options` (`id`, `options`, `:option` slot) renders the list once in a hidden `<div>`
    (a `<template>`'s content is out of LiveView's reach, so its options would never update);
    comboboxes with `options_from={id}` copy it in while open (fresh option ids per listbox, the chosen one
    marked), so a split row with many parts does not repeat the payee and category lists. `options` then only
    names the chosen value.
  - The list is a manual popover in the top layer, anchored below the field box (as wide, at least 16rem, at most
    19rem high), flipping above when there is no room; the hook places it without anchor positioning. Options
    36px, 44px on coarse pointers.
- **`file_drop`** – a drop zone around `live_file_input` (`phx-drop-target`): `upload`, `label`, `hide_label`,
  `help`, `drop_label`, inner block below the zone (chosen entries, progress, a remove button), global `accept`,
  `required`, `disabled`, `capture` on the input. Markup as `input`: label, zone (a `<label>` for the input, so a
  click or tap anywhere opens the file dialog; dashed 50 % base-content border, `rounded-box`, upload icon), inner
  block, errors, help. The file input is the control (Tab, Enter/Space, `aria-invalid`, `aria-describedby`) but
  `sr-only`: the browser draws its own button and "no file" text in the browser's language. In its place the zone
  shows a neutral `btn` with `button_label` (a primary focus ring while the input has keyboard focus,
  `btn-disabled` with `disabled`) and the chosen files' names (`client_name`, comma-separated) or `no_file_label`
  in 70 %; drop text, button and names are `aria-hidden`, so the input keeps `label` as its name. While a file is
  dragged over it (`phx-drop-target-active`) the border turns solid primary over a primary 8 % tint. Errors: the
  upload's own (`upload_errors/1,2`), named by `error_labels`, or `errors` instead; `aria-invalid` and an
  `error-ink` zone border.
- **`field_error`, `field_help`** – `input`'s error and help lines for other controls (`live_file_input`, custom
  pickers), inside a `fieldset.fieldset`: `id` + `errors` (messages or Ecto tuples) or `field`; ids
  `<id>-error-<n>` / `<id>-help`, `field_describedby(id, errors, help)` for the control's `aria-describedby`.
  `field_help` takes `tone={:warning}` (as `help_tone`) and global attrs (`aria-live`).
- **`action_bar`** – form footer: primary at the end, cancel before it, destructive in `:secondary` at the start.
  Its hairline sits 24px below the content and 16px above the buttons: a footer set apart from the last field,
  also sticky (24px; in a grid or flex column 8px on top of the forms' `gap-4`; a margin utility in `class` wins). Below `sm`: full width, stacked, primary on top. `sticky` pins it to the bottom (above the dock); on phones it
  spans `main`'s side gutters with a full-width hairline, from `sm` bar and hairline align with the content edge; 12px above and below the buttons on phones, 16px from `sm`, plus
  the bottom safe area without a dock. Below `sm` only cancel and primary stay pinned, side by side; `:secondary`
  follows in a normal row after the bar. `:secondary` renders once (its buttons may carry ids); in a sticky bar it
  comes last in the DOM and tab order, and `class` (spacing like `mt-6`) also lands on the pinned row. In a `modal` (as the box's last element) it takes the box's surface (`bg-popover`) and
  covers the box's bottom padding: 16px above and below the buttons; sticky, it pins to the box's bottom edge
  without the dock offset.

### Feedback

- **`flash`, `flash_group`** – Phoenix's flash API, as a toast at the top (the bottom belongs to dock and action bar),
  72px + safe area from the top, below a sticky page bar (61px on phones). Full width within the 16px gutter on
  phones, 384px at the end from `sm`; `shadow-lg`, as it floats over content. `flash_group` also shows the connection-lost messages. `role="alert"` for errors, `status` for info.
- **`alert`** – `tone` `:info | :success | :warning | :error | :neutral`, `title`, `icon` (`false` hides it),
  `busy` (spinner for the icon, a still ellipsis with reduced motion), `on_close`, `:actions` slot (end of the row
  while the alert's content box is at least 32rem wide, about 34rem with its padding, under the text when narrower: a container query on the alert, so a
  narrow side column on a wide screen also stacks; an alert with actions takes its width from its parent). Tinted background, base-content text, icon in the tone's ink
  (`info-ink`, `success-ink`, `warning-ink`, `error-ink`). Neutral buttons in `:actions` get a lighter fill and a 50 %
  border on the tint (2.1). `role="alert"` only for `:error`.
- **`badge`** – `tone` `:neutral | :info | :success | :warning | :error | :primary`; `style` `:dot` (default, neutral
  badge with status dot), `:solid` (alarm states only), `:text` (dot and label without the pill, e.g. in a meta
  line) or `:plain` (pill without dot, labels that are no status); `size` `:sm` (default) | `:md`; `icon`
  (icon-only needs `label`). Never wraps; on phones the label may end in an ellipsis.
- **`empty_state`** – says what goes here and how to get it, with one `:action`. `layout` `:inline` (default, in a
  section, list or card) | `:page` (centred, large plush, heading). `icon` or `plush`, `title`. Data that arrives by
  itself needs no action. A `plush` without an image falls back to `icon`; without one, no figure (no generic
  icon, one icon per meaning).

### Layout

- **`header`** – page title (`h1`, `text-2xl`), `back` (navigate) or `back_patch` or `back_href` (a full page
  load, e.g. across a re-authentication plug)/`back_label`, `:subtitle`, `:badge`, `:actions`. Actions wrap
  under the title on narrow screens; a `block` segmented control there gets a full-width row on phones.
- **`section_heading`** – `text-lg` 600, sentence case; `count` as quiet text (70 %, regular weight), `:actions`.
  `mt-8 first:mt-0`: 2rem above, none as first child (top of a page, card, dialog). A heading that opens its own
  `<section aria-labelledby>` is a first child too, so the parent stacks such sections with a gap
  (`flex flex-col gap-8`, `space-y-8` or the grid's gap). `size={:sm}`: 14px 600 with `mt-4`, for compact
  surfaces such as a popover, where `text-lg` would outrank the surface's own title.
- **`card`** – independent objects only (see Flat). `title`, `subtitle`, `level`, `as`, `:leading`, `:actions`,
  `:list` (flush list or table, no body padding), `:footer` (hairline note); the list header and the footer follow
  daisyUI's `--card-p` as the body does, set on the card (`max-sm:[--card-p:1rem]` for tighter phone cards;
  daisyUI's `card-sm` and `card-lg` set it on the body only and leave them at 24px). `navigate`/`href` makes
  the whole card clickable. `bleed={:phone}` runs it edge to edge below `sm`. No margin; spacing comes from the parent.
- **`theme_toggle`**, **`theme_script`**, **`theme_meta`** – see section 7.

### Data

- **`table`** – Phoenix's `<.table>` API with streams, plus:
  - `size`: text 14px and the side padding (16px) are the same in every size, so edges line up (none is
    daisyUI's `table-sm`). `zebra`; `flush` (inside a card or modal).

    | Size | Rows | Use |
    |---|---|---|
    | `:md` (default) | 45px | most tables |
    | `:sm` | ≈ 37px (8px cell padding instead of 12px), grow with content | read-only data next to other content; no row targets |
    | `:dense` | 36px on fine pointers, 44px on coarse (fixed cell height, no block padding) | data grids: many rows to scan, row links, editable cells. Inputs, selects and buttons in cells are 32px (44px on coarse pointers), so a row in edit keeps its height; give cell inputs `hide_label` |
  - `:col` attrs `label`, `align={:end}` (right-aligned, `tabular-nums`, no wrap), `show_from` (`:sm`…`:"2xl"`).
    With `layout={:sidebar}` the content is 256px narrower from `lg`, so choose `show_from` one step later
    (`:xl` becomes `:"2xl"`).
  - `groups` (`%{id, label, rows}`, one `<tbody>` with a `th scope="colgroup"` row each), `:foot` (total row; use
    `show_from/1` on hidden columns), `:empty` (works with streams), `row_link` (link stretched over the row;
    keyboard focus rings the whole row, a tap fills it base-200; `nil` for a row without one: no link, no hover).
  - `row_attrs` (fn row → `<tr>` attributes such as `aria-current`, `data-*`, `hidden`, or `nil`; `class` is merged, `id` dropped: the table owns row ids).
  - Selected row: a `<tr>` with `aria-current` (not `"false"`; the current row: open in a side panel, in edit) or
    `aria-selected="true"` (rows of a `role="grid"`) takes the `row-selected` fill and a 3px `selected` bar on its
    leading edge (inset shadow of the first cell, so such a table keeps its first column visible on phones: no
    `show_from` on it); it wins over zebra and hover. A multi-selection by checkboxes
    keeps its state in the checkboxes; a grid of its own uses `bg-row-selected` and the same bar.
    Don't tint rows with primary to flag them (new, needs attention): in light the tint reads as `row-selected`
    (a pale blue). Mark such rows with a badge, an icon, weight or a bar of another colour.
  - A hand-written `<table class="table">` (a data grid the component does not fit) takes the same rules: rows
    with `aria-current` or `aria-selected="true"` get the selected fill and bar, and the utility
    `setzkasten-table-dense` on the `<table>` gives the `:dense` size (36px rows, 44px on coarse pointers, 32px
    controls in cells).
  - `<.cell_sub hide_from={:lg}>` repeats hidden columns' values under the name (`hide_from`/`show_from` take the
    same breakpoints).
  - Default: on the page between `border-y` hairlines, edge to edge on phones, horizontal scroll in its wrapper.
- **`list`, `list_heading`, `list_row`** – collections. Same flat default as tables; `flush` in a card.
  `list_heading` takes global attrs (`id`). `list` `:foot` is a total row (`label`, the value as its inner block,
  semibold over a `base-content/30` hairline): its value ends where the rows' trailing column ends; with row actions
  pass their count (`actions`, the buttons from `md`), `menu` and `actions_class`, and it keeps an invisible copy of
  that column, from `md` and on phones with the rows' `trailing_on_phone={:title}`. It takes the list's `id` with
  `-foot`, so a stream keeps it and adds rows above it.
  - `list_row`: `title`, `:leading` (plush, icon, avatar), `:meta` (truncates; one line per `:meta`), `:trailing` (value, badge; moves to
    a second line below `md`, its lines aligned at the start; with `trailing_on_phone={:meta}` to the end of the
    meta line; with `trailing_on_phone={:title}` a short value (amount, optional small second line such as a
    percentage) stays at the end of the title line, lines right-aligned, the `⋮` menu centred on that line beside
    it, and the meta line takes the full width below (bank statement; use it where the trailing is an amount); `:meta` and `:title` render it twice with
    `:let={place}`; `class` e.g. `md:w-40 md:justify-start` for a fixed status column),
    `navigate`/`patch`/`href` (the title link covers the row; a light fill under the pointer and on tap, no chevron), or
    `on_click` (event name + `phx-target`, or a `%JS{}` with its own `target:`; the title is a `<button type="button">` covering the row
    the same way, e.g. to open a dialog). Keyboard focus rings the whole row.
    Dividers run the full width of a flat list. When the trailing line wraps below `md`, the leading media stays
    with the first line.
  - `:action` entries (`label`, `icon`, target or `on_click` (+ `phx-target` for an event name), `confirm`, `danger`,
    `disabled`): icon buttons from `md`, a `⋮` menu below; `menu={:always}` uses the menu at every width (rare or destructive actions), with
    `inline` actions (e.g. move up/down) still as icon buttons from `md`; `actions_class` (e.g. `md:w-20
    justify-end`) fixes that column's width so trailing columns line up across lists.
    Accessible names include the row title ("Bearbeiten: …").
- **`meta_sep`, `join_meta/1`** – the " · " of meta lines (header subtitle, stat note, `cell_sub`, list row meta):
  glued to the part before it, so a "·" never starts a line. `join_meta(parts)` for strings (drops `nil`, `false` and `""`,
  so an optional part leaves no dangling dot); `<.meta_sep />` between markup, written without a space before it.
- **`amount`** – money in de-DE (thousands dot, decimal comma, U+2212 minus, no-break space) in `<data value>`.
  `value` in minor units or `Decimal`; `currency` (default `"EUR"`); `signed`; `tone` (negative `error-ink`,
  positive `success-ink`, zero 70 %, by the shown value; `tone={:negative}` for balances in lists: negative
  `error-ink`, zero 70 %, positive plain, since green on every positive balance is noise, not state); `decimals` (default 2, `0` for whole-currency KPIs;
  `<data value>` stays exact); `currency_display={:code}` shows the ISO code ("1,10 USD") where currencies mix; `minor_digits` (0 for yen, 3 for dinar,
  default 2) for an integer in another currency's minor unit;
  `size={:lg}` for totals; `animate` (needs `id`) for a rolling number (2.10).
- **`Setzkasten.Format`** – the components' German formats for the app's own text: `money/2`, `number/2`,
  `machine/2`, and dates and times: `date/2` ("14.10.2026"; `weekday: :short` "Mi, 14.10.2026", `year: false`
  "14.10."), `datetime/2` ("14.10.2026, 18:05") and `time/2` ("18:05"). They take the app's local time and do no
  time zone math; a `DateTime` passed to `date/2` gives the date it carries.
- **`stat`** – KPI tile: `label`, `value`, `unit`, `desc` (or the `:note` slot for markup, e.g. a toned
  `amount`; the slot wins), `tone` (`:success | :warning | :error`, the value in that ink), `size` `:md` (32px) |
  `:sm` (24px, tile grids), `stale` (badge, never faded text), `loading` (skeleton); with `id`, a rolling
  number on change (2.10), `animate={false}` opts out. Grid:
  `setzkasten-stat-grid grid grid-cols-2 md:grid-cols-4 gap-4`; a stat stretched by a taller neighbour keeps its
  rows at the top. With `setzkasten-stat-grid` on a grid of stats the tiles share its rows (subgrid; a third row once
  a stat has a note), so a German label that hyphenates onto two lines ("Eigenverbrauchs-quote") keeps every value
  of the row level; also with `size={:sm}`, `:figure` and `:note`. Opt-in, as every tile then spans two or three
  rows: leave it off where a stat places itself (`row-span-*`) or the grid sizes its rows (`auto-rows-*`).
  `navigate`/`patch`/`href`: the tile links to the KPI's detail page (the label is the link and covers the tile; a
  light fill under the pointer and on tap, a focus ring around the tile).
  `:meter`: a full-width meter under the value, before the note (a battery level as `<.bar hide_label>`), in the
  same row as the note, so grids keep their shared rows. `:figure`: a non-interactive widget at the tile's end (daisyUI `stat-figure`: plush, icon, gauge, sparkline),
  centred beside the rows; below `sm` at the end of the label row, value and note across the full width.
  `aria-hidden`, or with `label` an image of that name (a gauge's verdict). Outside the value, so the rolling
  number ignores it; it stays while `loading`.
- **`description_list`** – label → value facts in 14px like tables; values right-aligned, `tabular-nums`. A calculation marks `:item`s
  `strong` (start value) and `total` (result, stronger `base-content/30` hairline above); once one is marked, the
  other values are regular weight.
- **`bar`** – native `<progress>` with `label` and value: `value`, `max`, `tone`, `show_value`, `value_label`,
  `target` (2px marker at the exact share, drawn as SVG geometry, no inline style), `hide_label` (no visible label,
  it stays the progress's name; for a bar whose label is said next to it, a stat's `:meter`). Pastel tones need `show_value`;
  `:neutral` (base-content 70 %, a share that is no state) stands alone like `:primary`. `color` (series 1–8,
  `:other` or `{:seq, N}`) in place of `tone`: the series fill with its 1px line, as in the chart beside it (2.2);
  series 1–8 and `:other` stand alone (the line carries 3:1), a sequential step has no line of its own, so steps 1–3
  in light and 1–2 in dark need `show_value`.
- **`avatar`** – `initials` or `icon`; `tone` (`:base` default, base-300 tile; or a theme role, `:primary` for the
  signed-in user); `size` `:sm` 32 · `:md` 40 · `:lg` 48px;
  `shape` `:square` (default) | `:round`. `aria-hidden` unless `label` is set. `loading`: spinner in the tile (same
  size and tone), a still ellipsis with reduced motion; `aria-busy` only with `label` (a hidden avatar can't announce it).
- **`chart_card`, `legend`** – the frame around an app-drawn chart: card, `title`, `subtitle` (unit or period, as in
  `card`: 70 %, under the title, `:actions` at the end of the title row), `role="img"` with `summary`, a `hook`
  container with `phx-update="ignore"` and a `<canvas>` (without `hook` the inner block, e.g. static SVG); the
  container is `relative` with only the canvas, as Chart.js's responsive mode needs, and the card `min-w-0`, so a
  chart in a flex row shrinks with it.
  `hook_attrs` go on that container (`<id>-chart`), e.g. the series as `data-*`: after mount LiveView patches only
  the `data-*` of an ignored container and calls the hook's `updated()`; `id`, `class`, `phx-hook` and `phx-update`
  belong to the component; global attrs stay on the card. daisyUI's card rules for
  `figure` (centred flex, clipped) and `p` (grows) stay off the content, so an SVG in a figure and a legend of
  paragraphs keep their own layout. `height` `:sm` 14rem ·
  `:md` 16rem · `:lg` 19rem · `:auto` (an inner block that sizes itself, SVG at `width: 100%; height: auto`: heat
  strips, maps, small multiples; skeleton at `:md`; with `hook` it raises, as a canvas takes its height from the
  card); slots `:actions`, `:legend`, `:data` (folded "Werte als Tabelle", the
  keyboard path to exact values); `loading` skeleton. `<.legend>` (global attrs): `items` with `label`, `color` 1–8, `:other`
  (the grouped rest), `{:seq, 1..5}` (ordered categories) or `:success | :error | :primary | :neutral`, and `marker` `:dot` (default, fill + outline) | `:line` | `:dashed`
  (a 16px stroke in the line colour, ≥ 3:1, for line series and reference lines), and `value_label` ("412 W"): with
  values the items form a grid of up to three columns of at least 8rem, by the legend's own width, not the viewport
  (two in a phone card or a half-width card), labels end in an ellipsis with the full
  text as `title`, values right-aligned in `tabular-nums`. Chart setup stays in the app.
- **`share_bar`** – a whole split into its shares in one continuous bar (plug power, an asset split, spending by
  category): `label` (names the group; the whole's `value_label` at the end of its row), `segments` (`label`,
  `value` a number, `color` as in `legend` (`{:seq, N}` for ordered bins), optional `value_label`, else the share in percent), `max` (a larger
  whole leaves the rest as empty track; default: full), `size` `:sm` 8px | `:md` 12px, `legend` (default; `false`
  keeps the values for screen readers only). Segments keep the given order, flush in one `rounded-box` track, a 2px
  surface gap between neighbours (2.2); a segment narrower than the gap vanishes from the bar and stays in the
  legend. A negative value counts as 0; a whole of 0 shows the empty track. Geometry is SVG (nested viewports in
  percent, no inline style), no width animation; the bar is `aria-hidden`, the values are text. `id` defaults to one
  derived from `label`; pass `id` when two share bars share a label on one page.

### Navigation

- **`segmented`** – one choice out of a few, a `join` of buttons, selected = `setzkasten-selected` (`selected` fill). `mode` `:patch` (links,
  `aria-current`; `replace` by default: a filter of the page adds no history entry per choice, `replace={false}`
  adds them) | `:button` (`phx-click` with the option as the button's `value`, which LiveView sends over
  `phx-value-value`; `aria-pressed`) | `:radio` (form field) | `:checkbox` (any number chosen, e.g. weekdays: a
  checkbox group named by `label`, sent as `name[]`, `value` a list; a hidden empty value goes along so an empty
  choice clears the field, Ecto's `cast/4` drops it). Option values go out as strings: `false` as `"false"`, `nil`
  as `""`. The form modes are fields like `input`: `fieldset.fieldset` > legend (`label`, visible; `hide_label` for
  screen readers only, then without block padding) > options > errors (`field` after `used_input?/1`, which replaces `errors` as in `input`, or `errors`)
  > `help`, linked from the group by `aria-describedby`; with errors a radio group (`role="radiogroup"`) carries
  `aria-invalid`, in a checkbox group each checkbox does (a plain group has no invalid state); the `id` that names
  the error and help lines comes from `field`, else from `name` as Phoenix forms ids (`expense[days][]` →
  `expense_days`). `label`, `size` `:sm | :md`; options as tuples or maps with `icon` and `long_label` (`aria-label` for a short label,
  "1 M" → "1 Monat"; it contains the visible text; no tooltip). `block`: full width, options of equal width,
  tighter padding below `sm` (five short options fit 360px); `block={:phone}` only below `sm`, e.g. a period in
  the header's `:actions`, which then gives it a full-width row under the title on phones.
- **`tabs`** – sibling views of one object; links only, `aria-current="page"` on the active `:tab`. No client-side
  tab panels. The first label lines up with the content edge (the page title): the strip starts one tab padding
  (12px) early, `-ms-3`, as `header` pulls in its back link, so every tab keeps its full hit area. Tabs that do not fit scroll sideways (`setzkasten-scroller`, as the top-bar menu): edge to edge on
  phones, snapping to the start, the end edge faded while more follows (a scroll-driven animation; no fade where
  unsupported or when all fits), no scrollbar on touch screens and a thin one with a mouse. A colocated hook
  scrolls an off-screen active tab into view; `id` defaults to one derived from `label`: pass `id` when two tabs
  components share a label on one page.
- **`breadcrumbs`** – where a detail page sits: `:crumb` (`navigate`/`patch`/`href`; the last is the current
  page, an `<h1>` unless `heading={false}`, cut with an ellipsis). Below `sm` a back chevron to the nearest
  parent and the current page. Goes into the `:bar` of `app_shell`, followed by the page's status badge (a dot on
  phones; a neutral badge only for screen readers there).
- **`dropdown`** – menu behind a button (`<details>`). `:trigger`, `:header`, `:item` (`navigate`/`patch`/`href`/
  `method` or `on_click` (+ `phx-target` for an event name), `icon`, `active` (links and buttons), `danger`, `divider`, `id`, `disabled`, `confirm`
  (+ `confirm_text`, `confirm_label`) for the shared confirmation dialog, `class`), `align`, `position` (`:top` opens upwards),
  `variant`, `chevron`, `trigger_class`. The menu sets its own text colour and weight (readable in the sidebar).
  Closes on outside click, Escape and item choice; Escape and item choice return focus to the trigger; Escape in the
  open menu leaves a `<dialog>` around it open; survives LiveView patches.

### Overlays

Ids that `show_modal`, `hide_modal`, `show_confirm`, `show_popover` and `hide_popover` address become `#id` selectors:
plain CSS identifiers, without `.` or `:`.

- **`modal`** – native `<dialog>`. `placement` `:center` (bottom sheet on phones; its content and a sticky
  `action_bar` stay above the bottom safe area, a transparent bottom border outside the scrolling area) | `:end` |
  `:start` (side panel, with a ✕ unless `close_button={false}`; transparent top and bottom borders keep it clear of
  the safe areas). Open with `show_modal(id)` or `show={true}`; close
  with `hide_modal(id)`, Escape, backdrop or `<form method="dialog">`. `on_cancel` runs after every close except
  `show={false}`. `show` acts when it changes, so a modal the user closed stays closed while the server's `show` is
  still `true`.
  While it is open the page does not scroll and does not shift: `:root` keeps the scrollbar's room
  (`scrollbar-gutter: stable`; daisyUI reserves it only where CSS `if()` works). Where scrollbars take room (Windows,
  macOS set to always show them) a page too short to scroll has an empty strip of that width at its end; overlay
  scrollbars (phones, macOS default) take none.
- **`confirm_dialog`** – one per layout, inside the LiveView (the app layout, not the root layout: its confirm
  button pushes the parked event, and `Setzkasten.Test.Confirm` looks for it there). Every irreversible delete asks here; archiving does not ask. `confirm` on
  `<.button>` (also a submit button: the confirmation sends its form) and on list row actions, or `show_confirm(id, question, action, text: …, label: …)`, writes the
  question into it and puts the destructive command on its confirm button. Cancel, Escape and the backdrop only
  close. Focus starts on Cancel. On phones a bottom sheet with full-width buttons, destructive on top. No
  `data-confirm`, no `window.confirm`.
  - Tests: `Setzkasten.Test.Confirm` (`asked/3`, `confirm_click/4`, `close_modal/3`) reads the parked command and
    runs it as the confirm button would, so app tests do not depend on the dialog's internals.
  - Focus return: to the trigger, or to its menu's summary when the menu closed (its popover's trigger or anchor
    when the confirmed action hid the popover). If the confirmed action removes the
    trigger, focus goes to the next (else previous) row of the closest `[data-focus-fallback]` (set on `<.list>` and
    `<.table>` bodies; add it to other collections), else to that element, else to `<main>`. Same for `modal`.
- **`popover`** – free content at what it belongs to, mostly a small form (move money, rename, a colour); a menu is
  `dropdown`. `id`, `:trigger` (a `btn`, `variant` `:neutral` | `:ghost`, `trigger_class`, `label`, `chevron`
  default off), `title` (heading and accessible name of the `role="dialog"` panel), `align` `:start` | `:end`,
  `position` `:bottom` | `:top`, `class` on the panel (16–22rem wide by default).
  - Mechanics: HTML Popover API (`popover="auto"`, `popovertarget`), so the panel is in the top layer and escapes
    scrolling tables, `overflow` wrappers and transforms. Click outside, Escape, `hide_popover(id)` and
    `show={false}` close it, so does a click on its trigger or `anchor` while it is open; Escape and `hide_popover` return focus to where it was (also after a submit inside),
    a click outside leaves it where the click put it. The open state is the browser's, so patches keep it.
    Give the first field `autofocus`.
  - Placement: CSS anchor positioning (`anchor-scope` per popover, `position-area`, flipping when there is no
    room, 4px from the trigger); a colocated hook places it (and follows scrolling) where the browser lacks
    `anchor-scope`, and always for `anchor` (the id of an element elsewhere, e.g. a table cell whose click opens
    one shared popover from the server; `:trigger` may then be left out, one of them is required).
  - Server: `show` (`true` opens, `false` closes without `on_cancel`; as for `modal`, on a change only), `show_popover(id)`; `on_cancel` runs after
    every other close, e.g. to clear the server's popover state. A modal opened meanwhile (`confirm` on a button
    inside) closes the popover without `on_cancel`; it opens again, its fields as they were, when the modal closes,
    unless the confirmed action hid it (`hide_popover`, `show={false}`).
  - Phones (below `sm`): a bottom sheet over a scrim, like `modal`, with the bottom safe area. An anchored panel
    next to a thumb-sized cell would cover it or leave too little room for a form and the keyboard.
  - Surface: `bg-popover`, hairline, `shadow-lg`, `rounded-box`, 16px padding, 14px text.
- **`disclosure`** – `<details>`; `summary` text or the `:title` slot for markup (a toned amount); `variant` `:collapse` (default) | `:row` (a
  quiet 14px row with only a hairline above, in a card or under a chart; `chart_card`'s data table uses it) | `:button` (compact "more options" trigger with
  `icon`); `open`; `count` (a quiet number after the summary, as in `section_heading`, never "(3)"; in the
  `:button` variant a neutral `badge-sm`, set apart from the label). Open state survives patches.
- **`tooltip`** – daisyUI `tooltip` with `data-tip` around one element (`id`, `text`, `placement` `:top` | `:bottom`
  | `:left` | `:right`), `selected` fill, 14px, on hover and keyboard focus. Screen readers: a colocated hook sets
  `aria-describedby` on the first control inside to a `hidden` copy of the text (hidden elements still
  count for a description; browse mode does not read it twice). When the text only repeats that element's name
  (an icon button with `label`), it adds no description. Wrap a focusable element; a tooltip on something that
  takes no focus is mouse-only. Not for what users must know: touch screens show it at best on a tap, so use it
  for hints, an icon's name or a full text behind an ellipsis, never for errors, values or the only label.

### Shell

- **`app_shell`** – skip link, navigation, `<main id="main">`.
  - `layout={:sidebar}`: dark sidebar 16rem (`w-64`) from `lg` with the account and a collapse button
    (`panel-left-close`) at its foot, icon rail `md`–`lg`, top bar with brand and account below `lg`, dock below
    `md` (not on pages with a `:bar`). Without a dock (`dock={false}`, or every entry left out of it) the top bar
    starts with a `panel-left-open` button (`expand_label`) below `md` that opens the sidebar dialog. Collapsed,
    rail and top bar also show from `lg`; the rail's one `panel-left-open` button, at its foot, decides at click
    time: in place from `lg`, as a dialog below (also the dock's "Mehr"). The dialog has no ✕: its foot button, Escape or the scrim close it. The state is
    `localStorage["setzkasten:sidebar"]`, set as `data-sidebar="collapsed"` on `<html>` by `<.theme_script>` before
    paint; the `sidebar-collapsed:` variant keys off it. Ghost and neutral buttons in the sidebar take its colours.
  - `layout={:topbar}` (default): navbar from `md`, dock below. `dock={false}` keeps the menu in the navbar on phones.
  - `width` `:narrow | :default | :wide | :full` (2.7); `bar_width` (same values, default `width`) for the top bar
    row alone, so the header stays put across pages of different widths; `current` marks the active `:nav` entry.
  - Alignment: with `layout={:sidebar}` the page column (and the top bar row above it) starts at the content edge,
    sidebar or rail plus the page padding, so a narrow form and a wide table start at the same x and the column
    does not jump between pages. With `layout={:topbar}` the navbar row has the same width class as `main` and both
    are centred: a start-aligned column under a full-width bar would leave the right half empty. No option: the
    layout decides.
  - `:nav` entries: `key`, `label`, `navigate`/`href`, `icon` or `plush` (falls back to `icon` without an image)
    or `glyph` (an emoji or initial in the icon's place, `aria-hidden`), `count`, `amount`, `section`,
    `section_amount` (on the section's first entry: the total next to its title), `dock`
    (the first five go into the dock; with more, or entries left out of the dock, at most four plus a `more_label`
    button: with `layout={:sidebar}` it opens the sidebar, with `:topbar` a sheet (`modal`) with the entries the
    dock leaves out, as in the top-bar menu with icon, label, count badge and `aria-current`; the button is
    `dock-active` and `aria-current="true"` while the current page is one of them and no `parent` of it stands in;
    with `:sidebar` a `:nav_footer` also brings the button, as the sidebar is its only place on phones), `rail`
    (`false`: left out of the icon rail, kept everywhere else; object lists such as accounts can stay out of the
    rail), `parent` (the key of the entry that stands in for this one where it is left out: while it is current,
    dock and rail mark the parent, `aria-current="true"`, instead of "Mehr" or nothing; sidebar, dialog, top-bar menu
    and sheet mark the entry itself). An entry without `section` after a section leaves it with the section gap
    (`mt-4`), no title. The rail keeps a gap where the section changes, also across left-out entries.
  - `count`: a quiet number in the sidebar, a neutral badge in the navbar and the top-bar sheet, a `badge-sm` on the
    icon in the rail (`sidebar-accent` fill, `primary` is 2.4:1 on the light sidebar) and the dock (`primary`;
    `neutral` is 1.2:1 on dark base-100); rail and dock show no badge at 0. The link's `aria-label` says it in words:
    "Buchungen, 2 neu" with `count_label="neu"`. Next to an `amount` a positive count is a `badge-sm`
    (`sidebar-accent` fill) before the number, so it does not read as part of it; at 0 nothing shows.
  - One text column in the sidebar, its dialog and the top-bar sheet: once any entry has an icon, plush or glyph, an entry without one
    keeps that 20px place empty, so its label lines up with the others (x 48px, not at the section titles' 20px).
    A sidebar without any media starts every label at the section titles' edge. No option: a label that jumps left
    reads as a section title.
  - Long labels and section titles end in an ellipsis in the sidebar and its dialog, the full text as `title`;
    the rail's tooltips stay on one line and end in an ellipsis at 20rem. The accessible name is unchanged.
  - `amount_tone={:negative}` (on the shell): entry and section amounts toned as `<.amount tone={:negative}>`:
    negative in `sidebar-negative`, zero muted, positive in `sidebar-content`; off by default (all muted).
  - An entry with `on_click` (event name + `phx-target`, or `%JS{}`) is a `<button>`: a quiet action (muted text,
    full on hover) in its place, e.g. "Konto hinzufügen" as the last entry of the accounts' section instead of in
    `:nav_footer` after unrelated entries. It stays out of the rail and the dock unless `rail` or `dock` is `true`
    (an action is no place to go to); in the top-bar menu it is a menu button. In the sidebar dialog (rail and dock
    "Mehr") and the top-bar sheet it closes the dialog first, focus back on the button that opened it, then runs
    `on_click`; a link closes it by replacing the view.
  - An entry renders once per place, so its `id` is suffixed: `<id>-sidebar`, `-dialog`, `-rail`, `-menu` (top-bar
    menu), `-more` (top-bar sheet), `-dock`; without `id` no ids.
  - Slots `:brand` (required), `:nav_footer`, `:account`, `:bar`, `:bar_actions`, `:fab`. `:bar` (detail pages:
    breadcrumbs and status) replaces the brand in the top bar, sticks to the top and with `:sidebar` also shows from
    `lg`. `:bar_actions` (the page's own actions, e.g. a `⋮` dropdown) follow it. Below `sm` a page with a bar
    leaves the `:account` (global actions, account menu) out of the top bar, so its actions sit at the right edge.
    In the sidebar layout `:brand`, `:nav_footer` and `:account` render more than once and receive where
    (`:sidebar`, `:dialog`, `:bar`) for unique ids (`:let={place}`); a menu in the account at the sidebar's
    foot opens with `position={:top}`.
    The brand shrinks before the account, so the bar stays one row; long brand text needs `truncate`.
  - The top-bar menu scrolls like `tabs` when it does not fit (e.g. six entries at 768px); with `dock={false}` it
    runs edge to edge on phones.
  - Safe areas (`viewport-fit=cover`): the shell keeps clear of the left and right insets (the rail grows by the
    left one), the top bar of the top inset.
  - Dock: daisyUI `dock` (64px + safe area); every item's icon takes a 24px box (a plush's size; a Lucide icon and
    "Mehr" keep 2px around their 20px), so all labels sit on one line. On touch screens it gives way to the on-screen keyboard while a field
    that takes typing has focus (`:read-write`: text-like inputs, text areas, editable content); sliders, colour,
    date and time pickers, buttons, file inputs, read-only fields and `inputmode="none"` keep it. Labels stay on
    one line and end in an ellipsis (the link keeps the full label as its name). Sticky action bars sit above it
    via `--setzkasten-dock-offset`.

## 4. Patterns

### 4.1 Forms

- One column on phones; `grid gap-4 md:grid-cols-2` for short fields; text areas full width.
- Labels above, help below, errors last; `required` in HTML.
- On submit with errors: an `<.alert tone={:error}>` at the top with the count, focus on the first invalid field:
  `phx-hook="Setzkasten.Components.Forms.FocusInvalid"` on the `<.form>` (with an `id`) does it once the reply is in,
  on every failed submit (`JS.focus(to: "[aria-invalid=true]")` would focus each match in turn and end on the last).
- Inline form (field + button): `<.input field={…} label="…" inline>` with
  `<.button type="submit" variant={:primary} class="join-item">` inside; the label is sr-only, so a heading above
  says what the field is for.
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
| Dropdown, row menu | `<details>` + `phx-click-away` + Escape via `phx-window-keydown`; `JS.ignore_attributes(["open"])`; Escape and item choice `JS.focus_first` the summary |
| Popover | HTML Popover API + CSS anchor positioning; colocated hook for server state and as placement fallback |
| Disclosure | `<details>` |
| Tabs, segmented ranges | links with `patch`, server state |
| Flash | `JS.push("lv:clear-flash")` + `JS.hide` |
| Confirm | `<.confirm_dialog>` + `show_confirm/3` |
| Sidebar overlay | `<.modal placement={:start} close_button={false}>` |
| Sidebar collapse | `data-sidebar` on `<html>` + colocated hook (`localStorage`), `<.theme_script>` before paint |
| Theme | `<.theme_script>` + colocated hook, or server-rendered `data-theme` |
| Submit lock | `phx-disable-with` |
| Saved, rolling numbers, theme reveal | colocated hooks; `push_saved/2`; View Transitions |
| Infinite scroll | streams + `phx-viewport-bottom` |
| Charts | app hooks reading the chart tokens |

Spinners use `motion-safe:`.

## 6. Touch targets

The pointer decides, not the viewport.

| Element | Fine pointer | Coarse pointer |
|---|---|---|
| `btn`, `input`, `select`, `file-input`, `tab` | 40px | 44px |
| `btn-sm`, `btn-square`, `segmented` `size={:sm}` | 32px | 44 × 44px (at least) |
| breadcrumb links | text | 44 × 44px (at least) |
| menu items, summaries | ≈ 33px | 44px, label centred |
| checkbox, radio, toggle | 24px control | 44px label row |
| table rows | 45px (`:md`), 36px (`:dense`) | 45px (`:md`), 44px (`:dense`) |
| list rows | ≥ 53px | ≥ 53px |
| dock items | ≈ 48px | ≈ 48px |
| standalone text links | – | 44px: use `btn btn-ghost btn-sm` or `btn-link` |

Inline links in sentences are exempt (WCAG 2.5.8).

## 7. Theme switching

- No `data-theme`: the system decides. Explicit choice: `data-theme="zipfel-light|zipfel-dark"`.
- Tailwind's `dark:` matches both ways into dark mode.
- `<.theme_toggle>`: icon-only square segments, `sun-moon` (System), `sun` (Hell), `moon` (Dunkel); the
  `labels` are the accessible names and `title` tooltips. All toggles on a page stay in sync, each with its own `id`
  (the id names its radios and menu). `compact`: one ghost
  icon button showing the current scheme (by `data-theme` on `<html>`, so right from the first paint), opening a small
  menu (`bg-popover`) with the three choices as radios, for a crowded top bar or a phone, where three segments are
  the heaviest element. Same store, sync, `theme-color` and reveal (from the chosen item); a pointer choice closes
  the menu, also on the checked item, arrow keys switch while it stays open, Escape closes it (not a `<dialog>`
  around it) and returns focus to the button. A `value` other than `"light"` or `"dark"` (`nil` from a user without a choice) counts as system.
  The choice reveals as a circle from the icon (2.10); the origin goes in custom properties on `<html>` via
  CSSOM, which a strict `style-src` allows.
  - `store={:local}` (default): `localStorage["setzkasten:theme"]`; add `<.theme_script nonce={…}>` to the root
    layout's `<head>` so it applies before paint.
  - `store={:server}`: sends `on_change` with `%{"theme" => …}`; the app saves it and renders `data-theme`.
- `<.theme_meta />`: the two `theme-color` meta tags (`#ffffff` / `#202328`) by `prefers-color-scheme`. With an
  explicit choice, `<.theme_script>` (on load) and `<.theme_toggle>` (on change) put a `theme-color` meta without
  `media` first, in the chosen theme's colour; "System" removes it. Place `<.theme_meta />` before `<.theme_script>`.
