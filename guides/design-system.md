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
| neutral / -content | `#3d4958` / `#f6f9fc` | `#0b0d12` / `#e9ebef` | `btn-neutral`, tooltip |
| selected / -content | `#3d4958` / `#f6f9fc` | `#d4d8de` / `#202328` | current menu item, selected segmented option and theme toggle option |
| info / -content | `#47d2e8` / `#002934` | `#60d8eb` / `#002631` | info alerts and flashes |
| success / -content | `#54dd7d` / `#092c13` | `#65e287` / `#062911` | success fills |
| warning / -content | `#ffc845` / `#3b1e02` | `#ffcc59` / `#381c01` | warnings |
| error / -content | `#fd7273` / `#34080b` | `#ff8382` / `#34080b` | errors, destructive buttons (dark) |
| success-ink | `#007f38` | `#65e287` | positive amounts, success icons |
| error-ink | `#cc272e` | `#ff8382` | negative amounts, error lines and borders, filled destructive buttons with white text (light) |

`success-ink`, `error-ink` and `selected` are extra tokens (`text-success-ink`, `text-error-ink`, `bg-selected`,
`text-selected-content`): the light fills are pastels and too faint as text or thin lines; `selected` keeps
primary for the main action. A button takes it with the utility `setzkasten-selected`; in the dark sidebar it
inverts to `sidebar-content` with `sidebar` text.

- **Text levels:** `text-base-content` (body, field labels) · `text-base-content/70` (meta, help lines, KPI titles)
  · daisyUI's `/60` (`thead`, `stat-desc`) · nothing lighter. Placeholders and disabled text are exempt.
- **Coloured text:** only `text-primary`, `text-success-ink`, `text-error-ink`. Use `secondary`, `accent`, `info`,
  `success`, `warning`, `error` only as a fill with their `-content` text, never as text, icon or thin mark on
  base-100/200 (both themes, since components use the same classes in each).
- **Hairlines:** `border-base-content/10` (dividers, card edge). Field borders are 50 % base-content; error fields
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

Sidebar tokens (`:sidebar` shell): `sidebar` `#2c394a`/`#14161b`, `sidebar-content` `#f6f9fc`/`#eceff2`,
`sidebar-muted` `#bcc9d7`/`#b7bbc1`, `sidebar-accent` `#80c5ff`/`#6eb6ff`.

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
| field border on base-100 / 200 | 3 | 3.39 / 3.36 | 4.37 / 4.11 |
| neutral control fill on its surface: page / popover (label identifies it) | – | 1.07 / 1.07 | 1.14 / 1.16 |
| selected fill on page / track (base-200) / popover track (dark: base-300) | 3 | 9.16 / 8.58 / 8.58 | 11.01 / 9.66 / 8.35 |
| error border, `btn-error btn-outline` on base-100 | 3 | 5.39 | 6.62 |
| primary as mark (focus, checkbox, toggle track, progress) on base-100 / 200 | 3 | 4.89 / 4.58 | 7.68 / 6.73 |
| checked toggle: knob (primary-content) on track (primary) | 3 | 4.89 | 8.44 |
| neutral bar (base-content 70 %) on its track, base-100 / 200 | 3 | 5.33 / 5.15 | 4.56 / 4.11 |
| alert-soft text on tint (neutral included) | 4.5 | 14.04–15.97 | 11.06–11.75 |
| alert icon on tint: info (`chart-6`) / warning (`chart-2`) | 3 | 3.27 / 3.64 | 8.13 / 8.96 |
| `::selection` text on its fill (primary 25 % in base-100) | 4.5 | 12.66 | 8.19 |
| button hover: primary / error content | 4.5 | 5.78 / 5.49 | 6.93 / 6.14 |
| sidebar content / muted / accent | 4.5 / 4.5 / 3 | 11.10 / 6.96 / 6.34 | 15.68 / 9.39 / 8.44 |

The light pastel fills as marks (status dots, `progress-success|warning|error|info`) are below 3:1; alert icons use
the line colours instead. Use them only next to a word that carries the meaning; a mark that must stand alone uses `primary` or a
chart token. The neutral status dot is base-content 50 % (about 3:1), not daisyUI's 20 % (1.6:1).

Avoid: `btn-soft`/`badge-soft` with coloured text, coloured text in light fills other than `primary`, `tabs-box`.

### 2.5 Type scale

Figtree (variable, `wght` 300–900, roman and italic; SIL OFL 1.1) as `--font-sans`, then "Figtree Fallback",
a local Arial with `size-adjust` and ascent/descent overrides matched to Figtree, so a late or missing font
does not shift lines. The app serves `priv/static/fonts` at `/setzkasten/fonts` (`Plug.Static`, README) and
preloads the roman file; `font-display: swap`. Code stays in the system mono stack. Antialiased; headings
`text-wrap: balance`, paragraphs `pretty`. Controls, tables and card bodies 14px; prose 16px. Figtree's
default `wght` is 300; the browser maps `font-weight` onto the axis, so unweighted text is 400.

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

### 2.8 Icons

| Set | Use | Render | Sizes |
|---|---|---|---|
| Lucide (stroke, `currentColor`) | actions, chevrons, status | `<.icon name="trash-2">` → inline `<svg class="lucide">` | `size-4` next to `text-sm` (default), `size-5` standalone, `size-6` empty states |
| Plush (WebP, light and dark file) | navigation, categories, settings links | `<.plush name="home">` → `<img class="plush">` | `:sm` 20 · `:md` 24 (dock) · `:lg` 32 (list leading) · `:xl` 48px |

- One icon per meaning across both sets.
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
| `disclosure` | opens at once, content settles 4px, the arrow turns | content fades, arrow flips |
| `flash` | enters 8px from the top edge, leaves upward in 150ms (`hide_flash`) | fades |
| `tabs` | the active line grows from its centre, the old one fades | colour fades |
| checkbox, toggle | tick and knob in 200ms, no delay | tick fades, knob jumps |

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
| `app_shell` | `nav_label` (Hauptnavigation), `skip_label` (Zum Inhalt springen), `expand_label` (Seitenleiste ausklappen), `collapse_label` (Seitenleiste einklappen), `more_label` (Mehr) |

### Actions

- **`button`** – `variant` `:primary` · `:neutral` (default; cancel/secondary) · `:ghost` · `:danger` ·
  `:danger_outline` · `:link`; `size` `:sm | :md | :lg`; `icon` (Lucide, before the label); `icon_only` (needs
  `label`, raises without); `loading` (spinner, a still ellipsis with reduced motion; `aria-busy`, disabled);
  `href`/`navigate`/`patch` render a link; `confirm` (+ `confirm_text`, `confirm_label`, `confirm_id`) asks in the
  shared confirmation dialog, see Overlays; an event name keeps its `phx-value-*` and `phx-target`, a `%JS{}`
  carries its own target (`JS.push("delete", target: @myself)`); `confirm` with `href`/`navigate`/`patch`/`method`
  raises (a link would navigate without asking). `saved` (needs `id`, raises without or on a link): the saved
  moment of 2.10 after `push_saved(socket, id)`; a `phx-disable-with` text becomes the pending label in the same
  stack (LiveView would flatten the stack otherwise).
  40px on fine pointers, 44px on coarse. `:danger` is filled `error-ink` with white text in light (as strong as
  primary), the error fill in dark. In the dark sidebar a `:neutral` button takes a quiet translucent fill, for a
  global action that should not compete with the page's primary.
- **`fab`** – the one main action on phones (`md:hidden`), 16px above the dock (`--setzkasten-dock-offset`) or,
  without one, above the bottom safe edge; `label` becomes `aria-label`.

### Forms

- **`input`** – `field`, `type` (HTML types plus `select`, `textarea`, `checkbox`, `toggle`, `radio_group`), `label`,
  `hide_label`, `help`, `prefix`/`suffix` (€, %), `icon`, `numeric` (right-aligned, `tabular-nums`,
  `inputmode="decimal"`), `options`/`prompt`/`multiple`. `class` lands on the field box (`max-w-40` for narrow amounts).
  - Markup: `fieldset` > label > field > errors > help.
  - `help_tone={:warning}`: the help line with `triangle-alert`, text in full base-content (warning is a fill,
    never text); still linked by `aria-describedby`.
  - `inline` (text-like types): field and inner block (the button, `class="join-item"`) in one `join`, stacked
    below `sm`; label sr-only; errors and help below the join. See 4.1.
  - Errors show after `used_input?/1`: `aria-invalid`, border in `error-ink`, lines with `circle-alert` (first
    letter upper case), linked by `aria-describedby`. Ecto messages via `config :setzkasten, translate_error: {Mod, :fun}`.
  - Checkbox and radio rows are labels with 44px height on coarse pointers. A checked toggle fills its track
    (primary) with a `primary-content` knob.
  - With the label for screen readers only (`hide_label`, `inline`) the fieldset has no block padding, so the field
    lines up with buttons beside it (a search field next to a `segmented`).
- **`field_error`, `field_help`** – `input`'s error and help lines for other controls (`live_file_input`, custom
  pickers), inside a `fieldset.fieldset`: `id` + `errors` (messages or Ecto tuples) or `field`; ids
  `<id>-error-<n>` / `<id>-help`, `field_describedby(id, errors, help)` for the control's `aria-describedby`.
  `field_help` takes `tone={:warning}` (as `help_tone`) and global attrs (`aria-live`).
- **`action_bar`** – form footer: primary at the end, cancel before it, destructive in `:secondary` at the start.
  Below `sm`: full width, stacked, primary on top. `sticky` pins it to the bottom (above the dock); on phones it
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
  from `sm`, under the text on phones). Tinted background, base-content text, icon in the tone's line colour
  (`chart-6`, `success-ink`, `chart-2`, `error-ink`). `role="alert"` only for `:error`.
- **`badge`** – `tone` `:neutral | :info | :success | :warning | :error | :primary`; `style` `:dot` (default, neutral
  badge with status dot), `:solid` (alarm states only), `:text` (dot and label without the pill, e.g. in a meta
  line) or `:plain` (pill without dot, labels that are no status); `size` `:sm` (default) | `:md`; `icon`
  (icon-only needs `label`). Never wraps; on phones the label may end in an ellipsis.
- **`empty_state`** – says what goes here and how to get it, with one `:action`. `layout` `:inline` (default, in a
  section, list or card) | `:page` (centred, large plush, heading). `icon` or `plush`, `title`. Data that arrives by
  itself needs no action. A `plush` without an image falls back to `icon`; without one, no figure (no generic
  icon, one icon per meaning).

### Layout

- **`header`** – page title (`h1`, `text-2xl`), `back`/`back_label`, `:subtitle`, `:badge`, `:actions`. Actions wrap
  under the title on narrow screens; a `block` segmented control there gets a full-width row on phones.
- **`section_heading`** – `text-lg` 600, sentence case; `count` as quiet text (70 %, regular weight), `:actions`.
  `mt-8 first:mt-0`: 2rem above, none as first child (top of a page, card, dialog). A heading that opens its own
  `<section aria-labelledby>` is a first child too, so the parent stacks such sections with a gap
  (`flex flex-col gap-8`, `space-y-8` or the grid's gap).
- **`card`** – independent objects only (see Flat). `title`, `subtitle`, `level`, `as`, `:leading`, `:actions`,
  `:list` (flush list or table, no body padding), `:footer` (hairline note). `navigate`/`href` makes the whole card
  clickable. `bleed={:phone}` runs it edge to edge below `sm`. No margin; spacing comes from the parent.
- **`theme_toggle`**, **`theme_script`**, **`theme_meta`** – see section 7.

### Data

- **`table`** – Phoenix's `<.table>` API with streams, plus:
  - `size` `:md` (45px rows) | `:sm` (≈ 37px, read-only data: 8px row padding instead of 12px; text stays 14px
    and the side padding stays as `:md`, so edges line up; not daisyUI's `table-sm`); `zebra`; `flush` (inside a
    card or modal).
  - `:col` attrs `label`, `align={:end}` (right-aligned, `tabular-nums`, no wrap), `show_from` (`:sm`…`:"2xl"`).
    With `layout={:sidebar}` the content is 256px narrower from `lg`, so choose `show_from` one step later
    (`:xl` becomes `:"2xl"`).
  - `groups` (`%{id, label, rows}`, one `<tbody>` with a `th scope="colgroup"` row each), `:foot` (total row; use
    `show_from/1` on hidden columns), `:empty` (works with streams), `row_link` (link stretched over the row;
    keyboard focus rings the whole row, a tap fills it base-200; `nil` for a row without one: no link, no hover).
  - `row_attrs` (fn row → `<tr>` attributes such as `aria-current`, `data-*`, `hidden`, or `nil`; `class` is merged, `id` dropped: the table owns row ids).
  - `<.cell_sub hide_from={:lg}>` repeats hidden columns' values under the name (`hide_from`/`show_from` take the
    same breakpoints).
  - Default: on the page between `border-y` hairlines, edge to edge on phones, horizontal scroll in its wrapper.
- **`list`, `list_heading`, `list_row`** – collections. Same flat default as tables; `flush` in a card.
  `list_heading` takes global attrs (`id`).
  - `list_row`: `title`, `:leading` (plush, icon, avatar), `:meta` (truncates), `:trailing` (value, badge; moves to
    a second line below `md`, its lines aligned at the start; with `trailing_on_phone={:meta}` to the end of the
    meta line; with `trailing_on_phone={:title}` a short value (amount, optional small second line such as a
    percentage) stays at the end of the title line, lines right-aligned, and the meta line takes the full width
    below (bank statement; use it where the trailing is an amount); `:meta` and `:title` render it twice with
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
  glued to the part before it, so a "·" never starts a line. `join_meta(parts)` for strings (drops `nil` and `""`,
  so an optional part leaves no dangling dot); `<.meta_sep />` between markup, written without a space before it.
- **`amount`** – money in de-DE (thousands dot, decimal comma, U+2212 minus, no-break space) in `<data value>`.
  `value` in minor units or `Decimal`; `currency` (default `"EUR"`); `signed`; `tone` (negative `error-ink`,
  positive `success-ink`, zero 70 %, by the shown value); `decimals` (default 2, `0` for whole-currency KPIs;
  `<data value>` stays exact); `currency_display={:code}` shows the ISO code ("1,10 USD") where currencies mix;
  `size={:lg}` for totals; `animate` (needs `id`) for a rolling number (2.10).
- **`stat`** – KPI tile: `label`, `value`, `unit`, `desc` (or the `:note` slot for markup, e.g. a toned
  `amount`; the slot wins), `tone` (`:success | :error`), `size` `:md` (32px) |
  `:sm` (24px, tile grids), `stale` (badge, never faded text), `loading` (skeleton); with `id`, a rolling
  number on change (2.10), `animate={false}` opts out. Grid:
  `grid grid-cols-2 md:grid-cols-4 gap-4`.
- **`description_list`** – label → value facts in 14px like tables; values right-aligned, `tabular-nums`. A calculation marks `:item`s
  `strong` (start value) and `total` (result, stronger `base-content/30` hairline above); once one is marked, the
  other values are regular weight.
- **`bar`** – native `<progress>` with `label` and value: `value`, `max`, `tone`, `show_value`, `value_label`,
  `target` (2px marker at the exact share, drawn as SVG geometry, no inline style). Pastel tones need `show_value`;
  `:neutral` (base-content 70 %, a share that is no state) stands alone like `:primary`.
- **`avatar`** – `initials` or `icon`; `tone` (`:base` default, base-300 tile; or a theme role, `:primary` for the
  signed-in user); `size` `:sm` 32 · `:md` 40 · `:lg` 48px;
  `shape` `:square` (default) | `:round`. `aria-hidden` unless `label` is set. `loading`: spinner in the tile (same
  size and tone), a still ellipsis with reduced motion; `aria-busy` only with `label` (a hidden avatar can't announce it).
- **`chart_card`, `legend`** – the frame around an app-drawn chart: card, `role="img"` with `summary`, a `hook`
  container with `phx-update="ignore"` and a `<canvas>` (without `hook` the inner block, e.g. static SVG). `height`
  `:sm` 14rem · `:md` 16rem · `:lg` 19rem; slots `:actions`, `:legend`, `:data` (folded "Werte als Tabelle", the
  keyboard path to exact values); `loading` skeleton. `<.legend>` (global attrs): `items` with `label`, `color` 1–8 or
  `:success | :error | :primary | :neutral`, and `marker` `:dot` (default, fill + outline) | `:line` | `:dashed`
  (a 16px stroke in the line colour, ≥ 3:1, for line series and reference lines). Chart setup stays in the app.

### Navigation

- **`segmented`** – one choice out of a few, a `join` of buttons, selected = `setzkasten-selected` (`selected` fill). `mode` `:patch` (links,
  `aria-current`) | `:button` (`phx-click` with `phx-value-value`, `aria-pressed`) | `:radio` (form field). `label`,
  `size` `:sm | :md`; options as tuples or maps with `icon` and `long_label` (`aria-label` for a short label,
  "1 M" → "1 Monat"; it contains the visible text; no tooltip). `block`: full width, options of equal width,
  tighter padding below `sm` (five short options fit 360px); `block={:phone}` only below `sm`, e.g. a period in
  the header's `:actions`, which then gives it a full-width row under the title on phones.
- **`tabs`** – sibling views of one object; links only, `aria-current="page"` on the active `:tab`. No client-side
  tab panels. Tabs that do not fit scroll sideways (`setzkasten-scroller`, as the top-bar menu): edge to edge on
  phones, snapping to the start, the end edge faded while more follows (a scroll-driven animation; no fade where
  unsupported or when all fits), no scrollbar on touch screens and a thin one with a mouse. A colocated hook
  scrolls an off-screen active tab into view; `id` defaults to one derived from `label`: pass `id` when two tabs
  components share a label on one page.
- **`breadcrumbs`** – where a detail page sits: `:crumb` (`navigate`/`patch`/`href`; the last is the current
  page, an `<h1>` unless `heading={false}`, cut with an ellipsis). Below `sm` a back chevron to the nearest
  parent and the current page. Goes into the `:bar` of `app_shell`, followed by the page's status badge (a dot on
  phones; a neutral badge only for screen readers there).
- **`dropdown`** – menu behind a button (`<details>`). `:trigger`, `:header`, `:item` (`navigate`/`patch`/`href`/
  `method` or `on_click` (+ `phx-target` for an event name), `icon`, `active`, `danger`, `divider`, `id`, `disabled`, `confirm`
  (+ `confirm_text`, `confirm_label`) for the shared confirmation dialog, `class`), `align`, `position` (`:top` opens upwards),
  `variant`, `chevron`, `trigger_class`. The menu sets its own text colour and weight (readable in the sidebar).
  Closes on outside click, Escape and item choice; Escape and item choice return focus to the trigger; survives
  LiveView patches.

### Overlays

- **`modal`** – native `<dialog>`. `placement` `:center` (bottom sheet on phones) | `:end` | `:start` (side panel, with a ✕
  unless `close_button={false}`). Open with `show_modal(id)` or `show={true}`; close with `hide_modal(id)`, Escape, backdrop or
  `<form method="dialog">`. `on_cancel` runs after every close except `show={false}`.
- **`confirm_dialog`** – one per layout. Every irreversible delete asks here; archiving does not ask. `confirm` on
  `<.button>` and on list row actions, or `show_confirm(id, question, action, text: …, label: …)`, writes the
  question into it and puts the destructive command on its confirm button. Cancel, Escape and the backdrop only
  close. Focus starts on Cancel. On phones a bottom sheet with full-width buttons, destructive on top. No
  `data-confirm`, no `window.confirm`.
  - Focus return: to the trigger, or to its menu's summary when the menu closed. If the confirmed action removes the
    trigger, focus goes to the next (else previous) row of the closest `[data-focus-fallback]` (set on `<.list>` and
    `<.table>` bodies; add it to other collections), else to that element, else to `<main>`. Same for `modal`.
- **`disclosure`** – `<details>`; `variant` `:collapse` (default) | `:button` (compact "more options" trigger with
  `icon`); `open`; `count` (a quiet number after the summary, as in `section_heading`, never "(3)"). Open state
  survives patches.

### Shell

- **`app_shell`** – skip link, navigation, `<main id="main">`.
  - `layout={:sidebar}`: dark sidebar 16rem (`w-64`) from `lg` with the account and a collapse button
    (`panel-left-close`) at its foot, icon rail `md`–`lg`, top bar with brand and account below `lg`, dock below
    `md` (not on pages with a `:bar`). Collapsed, rail and top bar also show from `lg`; the rail's one
    `panel-left-open` button, at its foot, decides at click time: in place from `lg`, as a dialog below (also the
    dock's "Mehr"). The dialog has no ✕: its foot button, Escape or the scrim close it. The state is
    `localStorage["setzkasten:sidebar"]`, set as `data-sidebar="collapsed"` on `<html>` by `<.theme_script>` before
    paint; the `sidebar-collapsed:` variant keys off it. Ghost and neutral buttons in the sidebar take its colours.
  - `layout={:topbar}` (default): navbar from `md`, dock below. `dock={false}` keeps the menu in the navbar on phones.
  - `width` `:narrow | :default | :wide | :full` (2.7); `current` marks the active `:nav` entry.
  - `:nav` entries: `key`, `label`, `navigate`/`href`, `icon` or `plush` (falls back to `icon` without an image),
    `count`, `amount`, `section`, `dock`
    (the first five go into the dock; with `layout={:sidebar}` and more, four plus a `more_label` button that opens
    the sidebar), `rail` (`false`: left out of the icon rail, kept everywhere else; object lists such as
    accounts can stay out of the rail). An entry without `section` after a section leaves it with the section gap
    (`mt-4`), no title. The rail keeps a gap where the section changes, also across left-out entries.
  - `count`: a quiet number in the sidebar, a neutral badge in the navbar, a `badge-sm` on the icon in the rail
    (`sidebar-accent` fill, `primary` is 2.4:1 on the light sidebar) and the dock (`primary`; `neutral` is
    1.2:1 on dark base-100); rail and dock show no badge at 0. The link's `aria-label` says it in words:
    "Buchungen, 2 neu" with `count_label="neu"`.
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
  - Dock: daisyUI `dock` (64px + safe area), hidden while a text field has focus. Sticky action bars sit above it
    via `--setzkasten-dock-offset`.

## 4. Patterns

### 4.1 Forms

- One column on phones; `grid gap-4 md:grid-cols-2` for short fields; text areas full width.
- Labels above, help below, errors last; `required` in HTML.
- On submit with errors: an `<.alert tone={:error}>` at the top with the count, focus on the first invalid field
  (`JS.focus(to: "[aria-invalid=true]")`).
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
| table rows | 45px (`:md`) | 45px |
| list rows | ≥ 53px | ≥ 53px |
| dock items | ≈ 48px | ≈ 48px |
| standalone text links | – | 44px: use `btn btn-ghost btn-sm` or `btn-link` |

Inline links in sentences are exempt (WCAG 2.5.8).

## 7. Theme switching

- No `data-theme`: the system decides. Explicit choice: `data-theme="zipfel-light|zipfel-dark"`.
- Tailwind's `dark:` matches both ways into dark mode.
- `<.theme_toggle>`: icon-only square segments, `sun-moon` (System), `sun` (Hell), `moon` (Dunkel); the
  `labels` are the accessible names and `title` tooltips. All toggles on a page stay in sync.
  The choice reveals as a circle from the icon (2.10); the origin goes in custom properties on `<html>` via
  CSSOM, which a strict `style-src` allows.
  - `store={:local}` (default): `localStorage["setzkasten:theme"]`; add `<.theme_script nonce={…}>` to the root
    layout's `<head>` so it applies before paint.
  - `store={:server}`: sends `on_change` with `%{"theme" => …}`; the app saves it and renders `data-theme`.
- `<.theme_meta />`: the two `theme-color` meta tags (`#ffffff` / `#202328`) by `prefers-color-scheme`. With an
  explicit choice, `<.theme_script>` (on load) and `<.theme_toggle>` (on change) put a `theme-color` meta without
  `media` first, in the chosen theme's colour; "System" removes it. Place `<.theme_meta />` before `<.theme_script>`.
