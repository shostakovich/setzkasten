# Setzkasten design system

Shared HEEx component library for a handful of Phoenix admin backends: a home-automation dashboard, a CMS
admin, a portfolio tracker, a budgeting app and a shared-expenses app. Tailwind CSS v4.3.3 + daisyUI 5.5.20, the versions `phx_new` 1.8.15 pins.
Status: implemented in `setzkasten` 0.1 (2026-10-10). Palette C and decisions E1–E6 are settled
(2026-10-10). The catalog dev app (`mix dev`, http://localhost:4110) renders every component described here.

Sources: daisyUI/Tailwind/Phoenix defaults from shipped source; a component inventory and a design and
accessibility audit of those apps; palette candidate C. Every deviation from daisyUI's defaults names its reason
here (WCAG, data density or an audit finding).

## 1. Principles

| Rule | Meaning in practice |
|---|---|
| daisyUI default first | Every size, radius and type step is daisyUI's or Tailwind's unless the deviation log gives a reason (recorded decision, WCAG, data density, concrete audit finding). |
| Shared only | A component is in the library if at least two apps need it with the same intent. Domain UI (ProseMirror editor, budget grid, energy flow, chart internals, split editor) stays in the apps. |
| Calm | One accent (primary), colour carries state, not decoration; pastel fills with dark ink, coloured text only through `primary` and the `-ink` tokens; `--noise: 0`; flat surfaces with hairlines; no texture, no look switch. |
| Floors | Text ≥ 12px; text 4.5:1, marks and boundaries 3:1 (WCAG 2.x); targets 44px on coarse pointers; prose ≤ 75ch; aligned numbers `tabular-nums`. |
| No Bootstrap JS, no inline styles | Native `<dialog>`/`<details>`, `Phoenix.LiveView.JS`, small hooks. Works under a strict CSP (two of the apps forbid inline `style`). |
| Light/dark via themes | `zipfel-light` default, `zipfel-dark` on `prefers-color-scheme: dark`; an explicit choice sets `data-theme` on `<html>`. |
| Flat (E1b) | The page is base-100. Sections are structured by headings, spacing and hairlines; tables, lists and forms sit on the page without a card, full width, edge to edge on phones. Cards only for independent objects: dashboard tiles, KPI groups, titled charts, clickable object grids, dialogs. |

## 2. Tokens

### 2.1 Theme colours (`priv/static/setzkasten.css`)

Palette C „Hell und weich" (chosen 2026-10-10 from three candidates): light surfaces with dark text,
one clear blue as the accent, every other role a pastel fill with dark ink; in dark mode the same idea glows on a soft
grey. Two light values are a step darker than the candidate for contrast (marked ¹).

| Role | Light | Dark | Used for |
|---|---|---|---|
| base-100 | `#ffffff` | `#2d2f33` | page background (E1b), cards, fields, menus, modals |
| base-200 | `#f4f8fb` | `#24272a` | zebra rows, group rows, code and wells on the page |
| base-300 | `#e5edf3` | `#1e1f22` | wells, trays, kbd |
| base-content | `#0d1928` ¹ (C: `#1e2b3b`) | `#e9ebef` | all text |
| primary / -content | blue `#0077b4` ¹ (C: `#007ab9`) / `#fff` | `#61bdff` / `#001c32` | main action, selection, links, focus |
| secondary / -content | apricot `#f7b385` / `#3e1b0b` | `#f6b88f` / `#381b0e` | rarely; no default button uses it |
| accent / -content | lavender `#b7a1f5` / `#22163c` | `#bda8fc` / `#20143a` | reserved; no component uses it |
| neutral / -content | slate `#3d4958` / `#f6f9fc` | `#181b1e` / `#e9ebef` | `btn-neutral`, tooltip |
| info / -content | cyan `#47d2e8` / `#002934` | `#60d8eb` / `#002631` | info alerts and flashes |
| success / -content | green `#54dd7d` / `#092c13` | `#65e287` / `#062911` | done, success fills |
| warning / -content | yellow `#ffc845` / `#3b1e02` | `#ffcc59` / `#381c01` | warnings |
| error / -content | coral `#fd7273` / `#34080b` | `#ff8382` / `#34080b` | errors, destructive buttons |
| success-ink | `#007f38` | `#65e287` (= success) | positive amounts, gains, success icons |
| error-ink | `#cc272e` | `#ff8382` (= error) | negative amounts, error lines, error borders and outlines |

`success-ink` and `error-ink` are not daisyUI slots; `setzkasten.css` sets them in both theme blocks and registers them
with `@theme` (`text-success-ink`, `text-error-ink`). They exist because the light fills are pastels: as text or as
a thin line on white they reach only 1.5–2.7:1. `base-content` light went from C's `#1e2b3b` to `#0d1928` so that
daisyUI's built-in 60 % text (labels, table heads, stat titles) reaches 4.5:1 (4.00 → 4.66:1); primary went from
`#007ab9` to `#0077b4` so links reach 4.5:1 on the page background base-200 as well (4.39 → 4.58:1).

**Text levels.** `text-base-content` (body) · `text-base-content/70` (meta, hints, secondary; 6.0–7.4:1) ·
daisyUI's internal `/60` (labels, `thead`, `stat-title`; 4.58–5.51:1) · nothing lighter for text. Placeholders and
disabled text are exempt (WCAG 1.4.3 inactive components).

**Coloured text.** Only `text-primary`, `text-success-ink` and `text-error-ink` (≥ 4.58:1 on base-100 and base-200
in both themes). `secondary`, `accent`, `info`, `success`, `warning` and `error` are fills in light mode: use them
only as a background with their `-content` text, never as text, icon or thin mark on base-100/200 (1.5–2.7:1). In
dark mode they pass as text (5.6–9.0:1), but library code uses the same classes in both themes, so the rule holds
for both.

**Hairlines.** `border-base-content/10` (dividers, card edge). Decorative, no contrast requirement. Field
boundaries are 50 % base-content (patched, 3.39 / 4.03:1); error fields draw their border in `error-ink` (patched).

### 2.2 Extra palette colours and charts

Chart series are the colour roles, in a fixed order, with two tokens each, registered with `@theme`
(`bg-chart-1-fill`, `fill-chart-1-fill`, `stroke-chart-1`, `border-chart-1` …; `--color-chart-N-fill` and
`--color-chart-N` for JS) and set per theme in the theme blocks:

- `chart-N-fill` is the role colour itself: bars, areas, pie slices, dots, legend swatches.
- `chart-N` is the line and outline colour, ≥ 3:1 on base-100 and base-200 (WCAG 1.4.11). In light mode it is
  the role colour where that passes (primary, neutral), the role's ink (success, error) or a darker tone of the
  same hue (warning, accent, info, secondary); in dark mode it is the role colour itself, which passes as a mark.

Equal-lightness series of their own (L 0.60/0.74, until 2026-10) looked washed out in light mode; the roles
are the colours the apps already use. Dark `neutral` is darker than the page (1.29:1), so series 8 uses a
lighter neutral `oklch(72% 0.025 254)` in dark mode, for fill and line.

| Series | Light fill · vs base-100 / 200 | Light line/outline · vs base-100 / 200 | Dark fill = line · vs base-100 / 200 |
|---|---|---|---|
| 1 primary | `#0077b4` 4.89 / 4.58 | `#0077b4` (primary) 4.89 / 4.58 | `#61bdff` 6.53 / 7.32 |
| 2 warning | `#ffc845` 1.54 / 1.45 | `#ac7300` 4.03 / 3.78 | `#ffcc5a` 8.96 / 10.04 |
| 3 success | `#54dd7d` 1.75 / 1.64 | `#007f38` (success-ink) 5.13 / 4.81 | `#65e287` 8.16 / 9.14 |
| 4 error | `#fd7273` 2.68 / 2.51 | `#cc272e` (error-ink) 5.39 / 5.05 | `#ff8382` 5.63 / 6.31 |
| 5 accent | `#b7a1f5` 2.23 / 2.09 | `#876dc8` 4.16 / 3.89 | `#bda8fc` 6.49 / 7.27 |
| 6 info | `#47d2e8` 1.80 / 1.69 | `#079298` 3.77 / 3.53 | `#60d8eb` 7.99 / 8.95 |
| 7 secondary | `#f7b385` 1.79 / 1.67 | `#c3610d` 4.17 / 3.91 | `#f6b88f` 7.77 / 8.70 |
| 8 neutral | `#3d4958` 9.16 / 8.58 | `#3d4958` (neutral) 9.16 / 8.58 | `#9aa6b4` 5.42 / 6.07 |

Base surfaces: light `#ffffff` / `#f4f8fb`, dark `#2d2f33` / `#24272a`. The chart-6 line stays at hue 200°
(info is 210°) so it keeps apart from the chart-1 line (ΔE_OK 0.10 instead of 0.09).

Rules: series are drawn on cards or the page (base-100/200).

- Bars, areas and slices are filled with `chart-N-fill` and get a 1px outline in `chart-N`. The outline carries the
  3:1 for the pastel fills (WCAG 1.4.11 counts the boundary); in dark mode it equals the fill and disappears, so
  apps can draw it always. SVG: `class="fill-chart-2-fill stroke-chart-2" stroke-width="1"` (plus
  `vector-effect="non-scaling-stroke"` in a stretched viewBox).
- Lines, markers and thin strokes use `chart-N`.
- Legend swatches show fill and outline (`<.legend>` does this for series 1–8).
- Chart.js: `backgroundColor` = `--color-chart-N-fill`, `borderColor` = `--color-chart-N`, `borderWidth: 1` for bars
  (lines: `borderColor` only).
- Semantic series: solar/PV and warnings series 2 (warning), income series 3 (success), overspend series 4 (error).
  Categorical series use 1… in order. More than 8 series: group the rest as "Andere".

Charts read tokens with `getComputedStyle(document.documentElement)` and redraw on theme change (a
`MutationObserver` on `data-theme` plus a `matchMedia` listener), replacing per-app colour probes and redraws
that only followed `prefers-color-scheme`. Chart text ≥ 12px. The dark app sidebar has its own tokens: `sidebar` `#2c394a`/`#1a1c20`,
`sidebar-content` `#f6f9fc`/`#eceff2`, `sidebar-muted` `#bcc9d7`/`#b7bbc1`, `sidebar-accent` `#80c5ff`/`#6eb6ff`
(all ≥ 6.3:1 on the sidebar, see 2.4).

### 2.3 Structure tokens

| Token | Value | Note |
|---|---|---|
| `--radius-box` | 0.5rem | cards, alerts, modals, tables, list rows |
| `--radius-field` | 0.25rem | buttons, inputs, tabs, menu items |
| `--radius-selector` | 0.5rem | checkbox, badge, toggle |
| `--size-field` / `--size-selector` | 0.25rem | btn/input md 40px, checkbox md 24px |
| `--border` | 1px | |
| `--depth` | 1 | daisyUI default: a 3px shadow tinted with the button colour and a faint inner edge. It is the only "depth" in the system; cards and tables stay flat. |
| `--noise` | 0 | no texture; the felt look is gone |

### 2.4 Contrast (WCAG 2.x, computed)

Method: hex → relative luminance; `color-mix(in oklab, X n%, transparent)` composited in sRGB over the surface;
tints (`alert-soft`) mixed in OKLab like daisyUI. Base-200 columns matter for zebra and group rows and for anything
on a base-200 well.

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
| base-content/60 on base-100 / base-200 | 4.5 | 4.66 / 4.58 | 5.12 / 5.51 |
| base-content/70 on base-100 / 200 / 300 | 4.5 | 6.56 / 6.37 / 6.03 | 6.39 / 6.91 / 7.42 |
| text-primary on base-100 / base-200 | 4.5 | 4.89 / 4.58 | 6.53 / 7.32 |
| text-success-ink on base-100 / base-200 | 4.5 | 5.13 / 4.81 | 8.16 / 9.14 |
| text-error-ink on base-100 / base-200 | 4.5 | 5.39 / 5.05 | 5.63 / 6.31 |
| secondary / accent / info / success / warning / error **as text** on base-100 | 4.5 | 1.79 / 2.23 / 1.80 / 1.75 / 1.54 / 2.68 – not used | 7.77 / 6.49 / 7.99 / 8.16 / 8.96 / 5.63 |
| field border (base-content 50 %, patched) on base-100 / base-200 | 3 | 3.39 / 3.36 | 4.03 / 4.27 |
| error field border and `btn-error btn-outline` (error-ink, patched) on base-100 | 3 | 5.39 | 5.63 |
| toggle border (base-content 50 %, daisyUI default) | 3 | 3.39 | 4.03 |
| focus ring base-content (fields, neutral buttons) | 3 | 17.69 | 11.24 |
| focus ring `btn-error` (error-ink, patched) | 3 | 5.39 | 5.63 |
| primary as mark (focus ring, checkbox, menu-active, progress) on base-100 / base-200 | 3 | 4.89 / 4.58 | 6.53 / 7.32 |
| success / warning / info / error fill as mark on base-100 (status dot, progress, toggle) | 3 | 1.75 / 1.54 / 1.80 / 2.68 – see note | 8.16 / 8.96 / 7.99 / 5.63 |
| progress bar vs its 20 % track: primary / error / warning / success / info | 3 | 3.70 / 2.22 / 1.41 / 1.55 / 1.59 | 4.40 / 3.97 / 5.49 / 5.14 / 5.05 |
| tabs-border underline (base-content) | 3 | 17.69 | 11.24 |
| alert-soft: base-content text on error / warning / success / info tint (light 25 %, dark 8 %) | 4.5 | 14.04 / 15.97 / 15.53 / 15.42 | 9.89 / 9.52 / 9.52 / 9.56 |
| alert-soft: icon on its tint, error-ink / success-ink / info / warning | 3 | 4.27 / 4.50 / 1.57 / 1.39 | 4.96 / 6.92 / 6.80 / 7.59 |
| alert-soft: tint vs base-100 / base-200 (visibility, not a WCAG pair; rough floor 1.1) | – | 1.11–1.26 / 1.04–1.18 | 1.14–1.18 / 1.27–1.32 |
| btn hover (fill + 7 % black): primary / error content | 4.5 | 5.78 / 5.49 | 6.93 / 6.14 |
| sidebar: content / muted / accent on sidebar | 4.5 / 4.5 / 3 | 11.10 / 6.96 / 6.34 | 14.78 / 8.85 / 7.96 |
| sidebar: active marker (accent) on the active row (`bg-white/10`) | 3 | 4.65 | 5.91 |

Note on the light fills as marks: status dots in badges (E5a), `progress-success|warning|error|info` and the
info/warning icons in soft alerts fall below 3:1 in light mode. The library keeps them only where a word next to
them carries the meaning (badge label, alert text, `<.bar show_value>`), so they are supplementary (WCAG 1.4.11
applies to graphics needed to understand the content). A bar or chart that must carry meaning on its own uses
primary or the chart tokens (pastel fills with their `chart-N` outline, 2.2). Tint visibility (decision E3,
2026-10-10): daisyUI's 8 % `alert-soft` tint of a pastel is barely visible against white (1.03–1.08:1,
ΔE_OK 1.7–2.7), so the light theme mixes 25 % (1.11–1.26:1 against base-100, text still at 14–16:1); dark keeps
8 %, which already reads on the grey page. The amount is the token `--setzkasten-alert-tint` (README, "Alert tint").

Not used by the library because they fail: `btn-soft`/`badge-soft` with coloured text in light mode (secondary 1.71,
error 2.49, warning 1.50, success 1.68, info 1.73 on their tints); coloured text in any light fill colour except
primary (use the `-ink` tokens); daisyUI's default field border (1.56:1); `tabs-box` active state (base-100 on
base-200, 1.07:1); daisyUI's menu focus (10 % tint, ≈1.2:1).

### 2.5 Type scale

Tailwind's scale, system font stack (Tailwind 4.3 `--font-sans`). daisyUI sets controls, tables and card bodies to
14px; body prose is 16px.

| Role | Class | Size / line | Weight |
|---|---|---|---|
| Page title (`<.header>`) | `text-2xl` | 24 / 32px | 600 |
| KPI value (`<.stat>`) | `stat-value` (daisyUI) / `text-2xl` in tile grids | 32px / 24px | 800 (daisyUI) |
| Card title | `card-title` (daisyUI) = `text-lg` | 18 / 28px | 600 |
| Section heading (`<.section_heading>`) | `text-base` | 16 / 24px | 600 (decision E2) |
| Body prose | `text-base` | 16 / 24px | 400 |
| Controls, tables, card body, menus, alerts | `text-sm` (daisyUI md) | 14 / 20px | 400; buttons 600 |
| Meta lines, help text, table sub lines | `text-sm text-base-content/70` | 14 / 20px | 400 |
| Field labels | `fieldset-legend` (daisyUI) = `text-xs` | 12 / 16px | 600 |
| Badges sm, stat-title, captions, dock labels, chart ticks | `text-xs` | 12 / 16px | 400–600 |

Floor 12px: `btn-xs`, `input-xs`, `table-xs`, `badge-xs`, `kbd-xs` (10–11px in daisyUI) are not used by the library;
`dock-label` is patched to 12px. Ad-hoc sizes from the apps map to the nearest step: .6875/.7/.75rem → `text-xs`,
.8125/.875rem → `text-sm`, .9375rem/1rem → `text-base`, 1.125rem → `text-lg`, 1.375/1.5rem → `text-2xl`.
Numbers in tables, amounts, stats and live values: `tabular-nums` (built into those components).

### 2.6 Spacing

Tailwind's 4px scale. Steps in use: `1` 4 · `1.5` 6 (daisyUI's own gap) · `2` 8 · `3` 12 · `4` 16 · `6` 24 · `8` 32 ·
`12` 48px. Old off-scale values (felt only had .25/.5/1/1.5/3rem) mostly exist on Tailwind's scale (.375 = `1.5`,
.75 = `3`, 1.25 = `5`); 0.85, 0.4, 3px, 1.375rem round to the nearest step.

| Gap | Value |
|---|---|
| Inside a card | daisyUI `card-body`: padding 24px, gap 8px |
| Between form fields | `gap-4` (16px) |
| Between cards in a stack, grid gutter | `gap-4 md:gap-6` (16 / 24px) |
| Between page sections | `mt-8` (32px) above a section heading |
| Page padding | `px-4 sm:px-6 lg:px-8`, `py-6` |

### 2.7 Radii, shadows

Radii come from the three theme tokens via `rounded-box`, `rounded-field`, `rounded-selector`; `rounded-full` for
avatars and dots only. Shadows: cards none (hairline instead); dropdowns and popovers `shadow-lg`; modals daisyUI's
own; FAB `shadow-lg`. Nothing else.

### 2.8 Breakpoints and widths

Tailwind: `sm` 640 · `md` 768 · `lg` 1024 · `xl` 1280 · `2xl` 1536px. Shell switches: dock below `md`; sidebar rail
`md`–`xl`; full sidebar from `xl` (1280px, in CSS instead of JS).

| Width | Class | Replaces |
|---|---|---|
| `:narrow` | `max-w-3xl` (48rem) | expenses app container 48rem, CMS settings and form pages 48rem, home-automation main column 760px |
| `:default` | `max-w-5xl` (64rem) | home-automation wide pages 1040px, felt `.container` 1080px |
| `:wide` | `max-w-7xl` (80rem) | portfolio tracker 1200px |
| `:full` | none | budget grid, CMS editor |
| auth | `max-w-md` (28rem) | CMS 28rem, budget and portfolio apps 26rem |
| prose | `max-w-prose` (65ch) | every paragraph of running text; over-long lines were an audit finding in all five apps |

Header and main use the same width.

### 2.9 Icons

| Set | Use | Render | Sizes |
|---|---|---|---|
| Lucide (stroke, 24 grid, 2px, `currentColor`) | actions, chevrons, status glyphs | `<.icon name="trash-2">` → inline `<svg class="lucide size-4">` | `size-4` 16px next to `text-sm` (default), `size-5` 20px standalone, `size-6` 24px in empty states |
| Plush (raster WebP, light and dark files) | navigation, categories, weather, settings links | `<.plush name="home">` → `<img class="plush">` | `size-5` 20px base, `size-6` 24px dock, `size-8` 32px list leading, `size-12`+ heroes (1.25 / 1.5 / 2rem) |

Class names are `lucide` and `plush`, never `icon` (felt and app stylesheets already style `.icon`). One icon
per meaning across sets (one app used plush `archive` for export and stroke `archive` for archive). Plush keeps its aspect ratio (`object-contain`, width and height attributes).

## 3. Components

`use Setzkasten` imports all component modules (`Setzkasten.Components.Icons`, `Actions`, `Forms`, `Feedback`,
`Layout`, `Data`, `Navigation`, `Overlays`, `Shell`); each can also be imported alone. The function docs
(`mix docs`) are the exact API; this section gives the design intent. Every component accepts `class` (appended,
never replacing the base classes, unlike Phoenix's `<.button>`) and most accept `rest` (`:global`). Visible default
strings are German ("Abbrechen", "Schließen", …) and can be overridden by attrs. Counts are call sites from the
component inventory (component + hand-built markup).

| # | Component | Home automation | CMS | Portfolio | Budget | Expenses | Apps |
|---|---|---|---|---|---|---|---|
| 1 | `button` | 11 + 23 raw | 19 + 26 | 8 + 13 | 4 + 2 | 46 | 5 |
| 2 | `icon` (Lucide) | 5 inline SVG | 49 | 14 | 37 (mockup) | 26 | 5 |
| 3 | `plush` | 55 files | – | – | – | 12 | 2 |
| 4 | `input` (+ select, textarea, checkbox, toggle, radios) | 13 | 46 | 6 + raw | 2 | 20 | 5 |
| 5 | `flash`, `flash_group` | 4 / 1 | 4 | 4 / 2 | 4 / 2 | 2 page alerts | 5 |
| 6 | `alert` | 7 | 6 | 1 | mockup | 7 | 5 |
| 7 | `header` (page header) | 9 | 19 | 8 | 2 | (14 in card headers) | 4–5 |
| 8 | `card` | 25 + 12 | list_card 9, grid 5 | 13 + 11 | 5 | 31 | 5 |
| 9 | `section_heading` | 12 + 6 | 9 | 3 | – | 2 | 4 |
| 10 | `empty_state` | 14 | 4 + 5 | 10 | 2 | 10 | 5 |
| 11 | `badge` | 2 | 17 | 6 | pills (mockup) | 3 | 5 |
| 12 | `table` | – | 0 | 4 | register (mockup) | 7 | 3 |
| 13 | `list`, `list_row` | 3 | 9 + 9 | 8 | 1 (26 mockup) | 9 | 5 |
| 14 | `amount` | – | – | 12 (tone, gain) | mockup | 18 (eur, sign_class) | 3 |
| 15 | `stat` | 11 + 12 | – | 4 + 1 | mockup | 1 | 4 |
| 16 | `segmented` | 7 | 4 | 2 | 1 | 1 | 5 |
| 17 | `tabs` | 1 | section nav, 13 pages | 2 | mockup | – | 4 (borderline, see 3.17) |
| 18 | `dropdown` | – | 2 implementations | 2 | mockup | – | 3 |
| 19 | `modal` | 1 + sheet | overlay 4 | – | mockup modal, offcanvas | – | 3 |
| 20 | `disclosure` | 3 | 2 | 2 | – | 2 | 4 |
| 21 | `action_bar` | 2 | 4 + 9 | – | – | 5 | 3 |
| 22 | `description_list` | 7 | – | 2 | – | 1 | 3 (borderline, see 3.22) |
| 23 | `chart_card`, `legend` | 12, legends 6 | – | 2 | – | – | 2 (borderline, see 3.23) |
| 24 | `bar` | 2 + plug bar | – | 2 + 1 | (target bars stay in app) | – | 2 |
| 25 | `avatar` | – | initials avatar | chips 6, avatar 1 | – | – | 2 |
| 26 | `theme_toggle` | – | – | – | 1 | 1 | 2, and every app gets it |
| 27 | `app_shell` | top nav + tabbar | topbar + section tabs | sidebar + rail + tabbar | sidebar (target) | top pills + tabbar | 5 |
| 28 | `fab` | – | – | – | mockup | 1 | 2 |

Not in the library (single app or different intent): budget grid, register, month strip (budgeting app); energy
flow, CO₂ gauge, colour picker, SVG solar charts (home automation); ProseMirror editor, header image picker (CMS);
split editor, balance bars, grouped infinite list (shared expenses); pagination (CMS only; the expenses app loads
more by scrolling, a different answer).

### 3.1 `button`

| Attr | Type | Default | Values |
|---|---|---|---|
| `variant` | atom | `:neutral` | `:primary` `btn-primary` · `:neutral` `btn` · `:ghost` `btn-ghost` · `:danger` `btn-error` · `:danger_outline` `btn-error btn-outline` · `:link` `btn-link` |
| `size` | atom | `:md` | `:sm` `btn-sm` · `:md` · `:lg` `btn-lg` |
| `icon` | string | nil | Lucide name, rendered before the label |
| `icon_only` | boolean | false | `btn-square`; requires `label` (raises without) |
| `label` | string | nil | accessible name for icon-only buttons (`aria-label`) |
| `loading` | boolean | false | `loading loading-spinner loading-sm` replaces the icon, `aria-busy`, disabled |
| `href` / `navigate` / `patch` | string | nil | renders `<.link class="btn …">` |
| `confirm` | string | nil | question for the shared confirmation dialog (E6b, see 3.19); the button's `phx-click` (a `%JS{}` or an event name plus `phx-value-*`) moves to the dialog's confirm button |
| `confirm_text`, `confirm_id` | string | nil, `"confirm-delete"` | sentence under the question; id of the dialog |
| `type`, `disabled`, `rest` | | `"button"` | `phx-disable-with` passes through |

States: default, hover, focus-visible (2px outline in the button colour, offset 2px), active, disabled (daisyUI),
loading. 40px on fine pointers, 44px on coarse (theme patch). Variants are fixed atoms (the apps' free
`variant` strings produced `btn-light` and bare `.btn` in the same role). Secondary/cancel =
`:neutral`; the felt `btn-light` and taupe `btn-outline-secondary` map to it.

### 3.2 `icon`

`<.icon name="plus" class="size-5" />` · attrs `name` (string, required), `label` (string, nil → `aria-hidden="true"`;
set → `role="img"` + `<title>`). Default `size-4`; a `size-*` class replaces it. SVG files are compiled into function
clauses at build time, so no sprite request and no inline style.

The package ships only the icons its components draw (`Setzkasten.Lucide`: chevron-left/right/down, x,
ellipsis-vertical, circle-alert, triangle-alert, info, circle-check, trash-2, monitor, sun, moon, panel-left; from
lucide-static 1.48.0). An app copies the Lucide SVG files it uses into a directory and compiles them with
`use Setzkasten.Icons, path: "assets/vendor/lucide"`, then sets `config :setzkasten, icons: MyAppWeb.Icons`. Lookup
order: app module, then the built-in set; an unknown name raises. Other markup (an app's own SVG) can go into the
inner block of buttons and slots.

### 3.3 `plush`

`<.plush name="home" size={:md} />` · attrs `name` (string), `size` (`:sm` 20 · `:md` 24 · `:lg` 32 · `:xl` 48px),
`alt` (string, default `""` = decorative because a label sits next to it). The app configures the image source
(`config :setzkasten, plush: MyAppWeb.Plush`, a module implementing `Setzkasten.Plush`: `src(name, :light | :dark)`),
or passes `src`/`dark_src` directly. With a dark file the
component renders two `<img>` (`dark:hidden` / `hidden dark:inline-block`) so an explicit theme choice also swaps the
image (a `<picture media>` would only follow the system). Unknown name (no light source) → nothing, in every environment:
plush names often come from data. Sprite sheets are not supported (cells would need inline `background-position`);
export single files.

### 3.4 `input`

| Attr | Type | Default | Notes |
|---|---|---|---|
| `field` | `Phoenix.HTML.FormField` | – | sets id, name, value, errors |
| `type` | string | `"text"` | text, email, password, number, date, datetime-local, search, tel, url, hidden, `select`, `textarea`, `checkbox`, `toggle`, `radio_group` |
| `label` | string | nil | `<label for class="fieldset-legend">` (12px/600) |
| `hide_label` | boolean | false | label `sr-only` (inline forms, search) |
| `help` | string | nil | `<p class="label">` (12px, 60 %), linked by `aria-describedby` |
| `prefix` / `suffix` | string | nil | rendered inside `label.input` as `<span class="label">` (€, %, „Anteile") |
| `icon` | string | nil | Lucide icon at the start of the field (search) |
| `numeric` | boolean | false | `text-end tabular-nums` on the value, `inputmode="decimal"` unless given |
| `class` | | | lands on the field box (`max-w-40` for narrow amounts) |
| `options`, `prompt`, `multiple` | | | select, radio_group |
| `errors` | list | from field | shown only after `used_input?/1` |
| `rest` | global | | `inputmode`, `autocomplete`, `required`, `phx-debounce` … |

Markup: `fieldset.fieldset` > label > `input.input.w-full` (or `label.input.w-full` with prefix/suffix) > help >
errors. Error state: `input-error`/`select-error`/`textarea-error` (border in `error-ink` via theme patch, 5.39:1;
daisyUI's own error fill is a pastel at 2.68:1), `aria-invalid`, error lines `text-error-ink` with a `circle-alert`
icon, ids in `aria-describedby`. Checkbox: `<label class="flex
items-center gap-3 text-sm pointer-coarse:min-h-11">` + `checkbox checkbox-primary` (24px; unchecked border in primary
reaches 3:1, daisyUI's neutral border is 1.56:1). Toggle: `toggle toggle-primary`. Radio group: `fieldset` +
`legend.fieldset-legend` + `radio radio-primary` rows. iOS zoom: daisyUI raises field text to 16px on focus on iOS.
Translation of Ecto errors stays in the app: `config :setzkasten, translate_error: {MyAppWeb.CoreComponents,
:translate_error}`; without it `%{count}`-style bindings are filled in untranslated.

### 3.5 `flash`, `flash_group`

Phoenix's API (`kind` `:info | :error`, `title`, `flash`), rendered as `<.alert>` inside `toast toast-top
toast-center sm:toast-end z-50` (top, because the dock and sticky action bars occupy the bottom).
`:info` → `alert-info` (fixes a copied `:info → alert-success` mapping in three apps). `flash_group` stacks all flashes in one
toast container. Dismiss: a real
`btn btn-ghost btn-sm btn-square` with `aria-label="Schließen"`, `JS.push("lv:clear-flash")`; `role="alert"` for
`:error`, `role="status"` for `:info`. `flash_group` adds the disconnected/reconnecting flashes from the generator.

### 3.6 `alert`

`<.alert tone={:warning} icon="triangle-alert" title="…">body<:actions>…</:actions></.alert>` · `tone` `:info |
:success | :warning | :error | :neutral` (default `:info`), `icon` (Lucide, default per tone), `title`, `busy`
(spinner instead of icon, for async work), `role` derived from tone: `alert` for `:error`, `status`
for all others (a persistent warning on a page should not interrupt a screen reader). `icon={false}` hides the icon.
With `:actions` the buttons sit at the end from `sm`; on phones they move under the text, aligned with it (not
daisyUI's centred `alert-vertical`). The title is a `p.font-semibold`, not a heading. Style per decision E3a
(2026-10-10): `alert alert-soft alert-<tone> text-base-content`, text in base-content (14–16:1 light, 9.5–9.9:1 dark).
Icon colour: `:error` `text-error-ink`, `:success` `text-success-ink`, `:info`/`:warning` the tone colour (light only
1.6 / 1.4:1, supplementary to the text; see the note in 2.4), `:neutral` base-content. Tint: 25 % of the tone in the
light theme, 8 % in dark (decision E3, see 2.4).

### 3.7 `header`

`<.header back={~p"/…"} back_label="Bestand">Titel <:subtitle>…</:subtitle> <:badge>…</:badge> <:actions>…</:actions></.header>`
· `back` (path, nil), `back_label` (string), `level` (default 1). Renders `<header class="flex flex-wrap items-center
gap-x-4 gap-y-2 pb-6">`, a title block `min-w-0 grow basis-64` with `h1.text-2xl.font-semibold` (the 16rem basis makes
the actions wrap below the title on narrow screens), subtitle `text-sm text-base-content/70 max-w-prose`, actions
wrap below the title on phones. Back link: `btn btn-ghost btn-sm` with `chevron-left` (44px on coarse; a plain text back
link was 21px). A "title in the first card header" becomes `<.header>` + cards.

### 3.8 `card`

| Attr / slot | Type | Default | Notes |
|---|---|---|---|
| `title` | string | nil | `h2.card-title` (18px/600) |
| `level` | integer | 2 | heading level |
| `subtitle` | string | nil | `text-sm text-base-content/70` |
| `as` | string | `"section"` | |
| `bleed` | atom | `:none` | `:phone` = edge to edge below `sm`: `max-sm:-mx-4 max-sm:rounded-none max-sm:border-x-0` (matches the page gutter `px-4`) |
| `navigate` / `href` | string | nil | clickable card: the title link covers the card |
| `:actions` slot | | | right side of the header row (buttons, segmented, legend, tabs) |
| `:inner_block` | | | `card-body` (24px, 14px text) |
| `:list` slot | | | flush list or table (`flush` attr) without body padding; the header then uses `px-6 pt-6 pb-2` instead of `card-body`, so the list starts close under the title |
| `:footer` slot | | | `border-t border-base-content/10 px-6 py-3 text-sm text-base-content/70` (footnotes such as data sources) |

When to use a card (decision E1b, flat): only for independent objects
(dashboard tiles, KPI groups, a chart with its own title, clickable object grids such as a CMS's sites,
dialogs); tables, lists and forms sit on the base-100 page without a card, structured by `<.section_heading>`,
spacing and hairlines (`border-y border-base-content/10`, full width, edge to edge on phones).

Base: `card bg-base-100 border border-base-content/10`. No margin (spacing comes from the parent stack; a
built-in `mb-3` doubled the gaps). Clickable card: title link with a stretched `after:absolute
after:inset-0`, focus outline on the card via `has-[a:focus-visible]:outline-2`.

### 3.9 `section_heading`

`<.section_heading count={12}>Depots<:actions>…</:actions></.section_heading>` · `count` (integer, nil; shown as
`badge badge-sm`), `level` (default 2), `id`; `mt-8` above, none as first child. Style per decision E2a (2026-10-10): `text-base font-semibold`,
sentence case. Replaces uppercase eyebrows and the apps' own `.section-title`-style
classes.

### 3.10 `empty_state`

`<.empty_state icon="inbox" title="Noch keine Depots">Text<:action>…</:action></.empty_state>` · `icon` (Lucide) or
`plush`, `title` (optional), `layout` `:inline` (inside a card or list, `py-6`, left-aligned) | `:page` (centred,
`py-12`, plush `size-12`). Inline title: `p.font-semibold` in the surrounding text size (part of a section that already
has a heading); page title: a heading (`level`, default 2) in `text-lg font-semibold`. Text
`text-sm text-base-content/70 max-w-prose`; says what goes here and how to get it
(one action). Replaces 18 variants across the five apps.

### 3.11 `badge`

`<.badge tone={:success}>Veröffentlicht</.badge>` · `tone` `:neutral | :info | :success | :warning | :error |
:primary` (default `:neutral`), `style` `:dot` (default: `badge` on base-100 with a `status status-<tone>` dot, text
base-content) | `:solid` (`badge-<tone>`, for the few loud cases such as an overspent budget pill), `size` `:sm` (default; 20px,
12px text) | `:md` (24px, 14px), `icon`. Decision E5a (2026-10-10): `:dot` is the standard, `:solid` only
for alarm states. In light mode the pastel dots reach 1.5–1.8:1 (error 2.7:1); the label carries the state, the dot is
supplementary. `:solid` badges are pastel fills with dark `-content` text (6.6–9.9:1). Icon-only badges need `label`. Soft badges are not offered (coloured text on tint 1.5–2.5:1 in light).

### 3.12 `table`

| Attr / slot | Type | Default | Notes |
|---|---|---|---|
| `id`, `rows`, `row_id`, `row_item` | | | as Phoenix's `<.table>`, streams supported |
| `groups` | list of `%{id, label, rows}` | nil | one `<tbody>` per group with a `th scope="colgroup"` row (`bg-base-200 text-xs font-semibold`) |
| `size` | atom | `:md` | `:md` daisyUI table (14px, 12 × 16px cells, 45px rows) · `:sm` `table-sm` (12px, 8 × 12px, ≈ 34px rows) |
| `zebra` | boolean | false | `table-zebra` |
| `flush` | boolean | false | drops the page hairlines and phone bleed (card `:list` slot, modals) |
| `row_link` | `fn row -> path` | nil | link in the first cell, stretched over the row |
| `:col` slot | | | `label`, `align` (`:start`/`:end`; `:end` adds `text-end tabular-nums whitespace-nowrap`), `show_from` (`:sm`/`:md`/`:lg`/`:xl` → `hidden <bp>:table-cell`), `class` |
| `:foot` slot | | | cells of the `<tfoot>` row, `font-semibold`, full base-content (theme patch; daisyUI draws it at 60 % like the head); `show_from/1` gives the classes for hidden columns |
| `:empty` slot | | | rendered as a full-width row with `<.empty_state layout={:inline}>` |
| helper `<.cell_sub hide_from={:lg}>` | | | the values of hidden columns, repeated under the name (`text-sm text-base-content/70 <bp>:hidden`); `show_from` for the reverse (ISIN from `lg`) |

Wrapper `overflow-x-auto` directly on the page between `border-y` hairlines, edge to edge on phones (E1b); `flush`
inside a card or modal. The empty row uses `hidden only:table-row`, so `:empty` also works with streams. Whole table `tabular-nums`. Header cells keep daisyUI's
14px/600 at 60 %. See 4.3 for the reference layout.

### 3.13 `list`, `list_row`

`<.list>` = `ul.list` (daisyUI, 14px, hairlines), on the page between `border-y` hairlines and edge to edge on phones,
`flush` inside a card. `<.list_heading>` is a group heading row (dates). `<.list_row title={…} navigate={…}>` slots
`:leading` (plush, icon, avatar), title (`title` attr or the inner block, `font-medium`), `:meta`
(`text-sm text-base-content/70`, truncates), `:trailing` (value, `<.amount>`, badge), `:action` entries (`label`,
`icon`, `navigate`/`patch`/`href`/`method` or `on_click` as event or `%JS{}`, `confirm`, `confirm_text`, `danger`):
from `md` inline as ghost `btn-square`, below `md` folded into a `⋮` menu, as in the CMS's list rows. Actions
are structured entries rather than free markup so one action can render as button and as menu item; their accessible
names include the row `title` ("Bearbeiten: Herbst im Garten"). With `navigate`/`href` the title link stretches over the row and a
`chevron-right` shows at the end on every width. Row padding daisyUI `list-row` 16px →
≥ 53px rows. `confirm` on actions opens the shared confirmation dialog (3.19, E6b); in the `⋮` menu the delete item
is `text-error-ink`.

### 3.14 `amount`

`<.amount value={-12345} currency="EUR" signed tone />` · `value` (integer minor units or `Decimal`), `currency`
(default `"EUR"`), `signed` (show `+`), `tone` (`true`: negative `text-error-ink`, positive `text-success-ink`, zero
`text-base-content/70`), `size` `:inherit | :lg` (`text-lg font-semibold`, totals); KPI-sized
money goes into `<.stat>`, which owns that type step. Format: de-DE, thousands dot, decimal comma, U+2212 minus,
NBSP before the unit; output in `<data value>` with `tabular-nums whitespace-nowrap`. One
implementation replaces `tone/1`, `.is-neg`, `sign_class`, `.app-neg`.

### 3.15 `stat`

`<.stat label="Vermögen" value={…} unit="€" desc="seit Jahresbeginn" tone={nil} size={:md} />` · daisyUI `stat`,
`stat-title` (12px, 60 %), `stat-value` + `tabular-nums`, `stat-desc`; `size` `:md` (32px/800, daisyUI) | `:sm`
(`text-2xl`, for tile grids where 32px overflows: 375px phone, 2 columns → ≈ 123px value width); unit
`text-base font-semibold text-base-content/70` after the value; `stale` boolean (adds a "veraltet" badge instead of
fading the value; faded text had dropped to 2.1:1); `loading` shows a skeleton; `tone` `:success | :error`
colours the value with the ink tokens; the inner block can replace `value`. Tile: `stat bg-base-100 rounded-box border
border-base-content/10` in a `grid grid-cols-2 md:grid-cols-4 gap-4`.

### 3.16 `segmented`

`<.segmented id="range" mode={:patch} value={@range} options={[{"1M", ~p"…"}, …]} label="Zeitraum" />` · `mode`
`:patch` (links, `aria-current="page"`) | `:button` (`phx-click`, `aria-pressed`) | `:radio` (form field: sr-only radios inside
`label.join-item.btn.has-checked:btn-primary` in a `fieldset`, focus ring via `has-focus-visible:`; unlike an `input.btn`
with `aria-label` this can hold icons). `:patch` options are `{label, path}` or `{label, value, path}`; `:button`
sends the `phx-click` from `rest` with `phx-value-value`; options may be maps with `icon`. `size` `:sm | :md`. Markup `join` of `btn`;
selected = `btn-primary` (4.89:1 white on primary, primary 4.89:1 against base-100; "Auswahl = Primary", recorded as
„Auswahl = Denim“). Replaces five techniques
(nav-pills, btn-check, aria-pressed buttons, btn-group links, autosubmit).

### 3.17 `tabs` — borderline, verdict: in

Same intent in four apps: switch between sibling views of one object (CMS site sections, portfolio
card tabs, home-automation light modes, a budget mockup). `<.tabs label="Bereiche"><:tab navigate={…} active>Seiten</:tab></.tabs>`
→ `<nav aria-label>` + `tabs tabs-border`, `aria-current="page"` (daisyUI styles it as active, no `tab-active`), scrolls horizontally on phones
(`overflow-x-auto flex-nowrap`), 44px on coarse. Navigation only, server-rendered; no client-side tab panels
(no `role="tablist"`), so no JS.

### 3.18 `dropdown`

`<.dropdown id="account" label="Konto" align={:end}><:trigger>…</:trigger><:item navigate={…}>…</:item></.dropdown>`
· `<details class="dropdown">` + `<summary class="btn">` + `ul.menu.dropdown-content.bg-base-100.rounded-box
.shadow-lg.w-56`; `variant={:ghost}`, `chevron`; `:item` attrs `navigate`/`patch`/`href`/`method` or `on_click`,
`icon`, `active`, `danger`. Closes on outside click (`phx-click-away`), Escape (`phx-window-keydown`), and after an item
click (`JS.remove_attribute("open")`); `JS.ignore_attributes(["open"])` keeps it open across LiveView patches.
Disclosure semantics (`aria-expanded` from `<details>`), no `role="menu"`. One implementation for the four copies.

### 3.19 `modal`

`<.modal id="booking" title="…" show={@show} on_cancel={JS.patch(…)} placement={:center}>…<:actions>…</:actions></.modal>`
· native `<dialog class="modal">` + `modal-box`; `placement` `:center` (`modal-bottom sm:modal-middle`, a sheet on
phones) | `:end` / `:start` (side panel, replaces an offcanvas, with a close button). Open with `show_modal(id)` =
`JS.dispatch("setzkasten:show-modal")`, handled by the colocated hook `Setzkasten.Components.Overlays.Modal`, or
`show={true}` from the server. Close: `hide_modal(id)`, `<form method="dialog">` button, backdrop form, Escape
(native), each followed by `on_cancel`; `show={false}` from the server closes without `on_cancel`. Focus moves into the
dialog and back natively.

**Confirmation (decision E6b, 2026-10-10).** Every irreversible delete asks in a styled dialog; archiving does
not ask. No `data-confirm`, no `window.confirm`. One shared `<.confirm_dialog id="confirm-delete">` per layout
(`modal` + `modal-box`, title, one sentence what is lost, „Abbrechen" `btn` + „Löschen" `btn btn-error` with
`trash-2`). A `confirm` attr on `<.button>` and on `<.list_row>` actions renders the trigger with
`aria-haspopup="dialog"` and a `phx-click` built by `show_confirm(id, question, action)`: `JS.set_attribute`
stores the encoded destructive command (`action`, e.g. `JS.push("delete", value: %{id: id})`) in the confirm
button's `data-confirm-action`, whose `phx-click` is `JS.exec("data-confirm-action")`; `JS.dispatch("setzkasten:show-modal")`
carries the question and the optional sentence, which the modal hook writes into title and text (both
`phx-update="ignore"`, defaults from the component's attrs). So the destructive command runs from the dialog's
confirm button; Cancel, Escape and the backdrop only close. Focus
starts on „Abbrechen"; on phones the dialog is a bottom sheet.

### 3.20 `disclosure`

`<.disclosure id summary="Weitere Aufteilungsoptionen" open>…</.disclosure>` · `<details class="collapse
collapse-arrow">` with `summary.collapse-title` (≥ 44px on coarse; summaries in three apps
were 21px), `JS.ignore_attributes(["open"])`. `variant={:button}` renders the summary as a `btn` (with
`icon`) for compact "more options" triggers. An inline delete confirmation (`summary.btn`) moves to the
shared confirmation dialog (E6b).

### 3.21 `action_bar`

`<.action_bar sticky><:secondary>…</:secondary>…primary buttons…</.action_bar>` · form footer: primary right, cancel
left of it, destructive far left; `sticky` pins it to the bottom (`sticky bg-base-100 border-t`, above the
dock on phones via the shell's `--setzkasten-dock-offset`). Below `sm` the buttons are full width and stacked, primary on
top and destructive at the bottom (`flex-col-reverse`: the main action closest to the content and the thumb, the
dangerous one furthest away). A sticky bar keeps primary and cancel side by side and puts the secondary actions on a
second row, so it covers less of the screen. Replaces three styles in two apps.

### 3.22 `description_list` — borderline, verdict: in

Same intent in three apps (label → value facts: home automation 7, portfolio 2, expenses 1).
`<.description_list><:item label="TER">0,20 %</:item></.description_list>` → `dl` with rows `flex justify-between gap-4
py-2 border-b border-base-content/10`, `dt` `text-base-content/70`, `dd` `text-end tabular-nums font-medium`. Fixes the
5/7 vs 6/6 column drift and missing tabular figures.

### 3.23 `chart_card`, `legend` — borderline, verdict: in (frame only)

Two apps, same intent (a titled card holding a Chart.js canvas): home automation 12, portfolio 2. The library owns the
frame, not the chart: `<.chart_card id="networth" title="…" hook="NetWorthChart" height={:md} summary="…">` (without `hook` the inner
block is drawn instead of the canvas, for static SVG charts)
→ card + `div[role=img][aria-label=summary]` > `div[phx-hook][phx-update=ignore]` > `canvas`; `height` `:sm` `h-56`
(14rem) · `:md` `h-64` · `:lg` `h-76` (19rem); slots `:actions` (period segmented), `:legend` (header or footer),
`:data` (a `<.disclosure summary="Werte als Tabelle">` with a `<.table size={:sm}>`, the keyboard and touch path to
exact values); skeleton (`skeleton h-full`) until the hook reports data. `<.legend items={[%{label,
color: 1..8 | :success …}]}>`: 10px dots (series: `chart-N-fill` with a 1px `chart-N` outline, ≥ 3:1) +
`text-xs` labels. Chart.js setup, tooltips and series logic stay in
the apps.

### 3.24 `bar`

`<.bar value={42} max={100} tone={:primary} label="Aktien" show_value target={60} />` · native
`<progress class="progress progress-<tone>">` (primary bar vs track 3.70 / 4.40:1; in light the pastel tones
success/warning/error/info fall to 1.4–2.2:1, so they need `show_value`) with label and `tabular-nums` value above; `value_label`
overrides the percentage; values above `max` fill the bar and still show the real share; `target` draws a 2px
base-content marker as an SVG `<rect x="60%">` over the bar. Geometry attributes are not styles, so this works for
any value under a strict CSP, without inline `style` and without generating 101 `left-[n%]` classes. The inner block
adds a caption line ("Ziel 70 %"). Covers bar lists and allocation bars; budget target bars stay in the
app's budget grid.

### 3.25 `avatar`

`<.avatar initials="DK" tone={:primary} size={:sm} />` or `icon` · `avatar avatar-placeholder`, sizes `:sm` 32 / `:md` 40 / `:lg` 48px,
`rounded-field`
(square chip) or `shape={:round}`; `tone` one of the theme roles (fill + `-content`, all ≥ 4.5:1); text
≥ 12px; `aria-hidden` when the name is next to it.

### 3.26 `theme_toggle`

`<.theme_toggle value={@theme} />` · `value` `"system" | "light" | "dark"`; segmented markup: sr-only radios in
`label.join-item.btn.btn-sm.has-checked:btn-primary` with a `has-focus-visible:` outline, `monitor`/`sun`/`moon` icons
and labels (`compact` shows icons only). The colocated hook `Setzkasten.Components.Layout.ThemeToggle` sets or removes
`data-theme` right away and keeps all toggles on a page in sync. Two storage modes: `store={:local}` (writes
`localStorage["setzkasten:theme"]`; `<.theme_script nonce={…}>` in the root layout applies it before paint) or
`store={:server}` (a form sending `on_change` with `%{"theme" => …}`; the app saves it per person and renders
`data-theme`). `<.theme_meta />` renders the two `theme-color` tags.
"System" removes `data-theme`.

### 3.27 `app_shell`

| Attr / slot | Notes |
|---|---|
| `layout` | `:sidebar` (portfolio, budget) · `:topbar` (home automation, expenses, CMS) |
| `current` | key of the active nav item (`aria-current="page"`) |
| `width` | `:narrow | :default | :wide | :full` (2.8) |
| `:brand` | logo or mascot |
| `:nav` slot | `key`, `label`, `navigate`/`href`, `icon` or `plush`, `count`, `amount` (sidebar balances, minor units), `section` (sidebar group title), `dock` (false keeps it out of the dock) |
| `:nav_footer` | sidebar bottom (settings, collapse toggle) |
| `:account` | account menu (dropdown) |
| `dock` attr | `true` (default): the first five `:nav` items (without `dock={false}`) form the phone dock; `false`: no dock, the topbar menu stays on phones and scrolls |
| `:fab` | phone floating action (`<.fab>`); bottom padding for it only when present |

`:sidebar`: from `xl` a `w-74` (18.5rem) `bg-sidebar text-sidebar-content` column with
`menu` items; active item `bg-white/10` + 3px `sidebar-accent` marker (4.65 / 5.91:1); `md`–`xl` an icon rail `w-17` (4.25rem)
with labels as tooltips and an expand button that opens the full sidebar as an overlay: a `<.modal placement={:start}>`, so
the browser provides scrim, inert page, Escape and focus return without a sidebar hook. A persistent collapse of the
desktop sidebar is not part of the shell (only one app had it). Below `md`: top
bar with brand + account, `dock` at the bottom. `:topbar`: from `md` a `navbar bg-base-100 border-b
border-base-content/10` with `menu menu-horizontal`; below `md` the dock. Both: skip link to `#main`, `<main
id="main">` with the width class and bottom padding for the dock (and the FAB, when present) on phones. With a dock the shell
sets `--setzkasten-dock-offset` below `md`; sticky action bars sit above it.

### 3.28 `fab`

`<.fab navigate={…} icon="plus" label="Ausgabe" />` · `btn btn-primary btn-lg btn-circle shadow-lg`, fixed above the
dock (`bottom: calc(4rem + env(safe-area-inset-bottom) + 1rem)`), phones only (`md:hidden`), label as `aria-label`.

## 4. Patterns

### 4.1 Forms

- One column on phones; `grid gap-4 md:grid-cols-2` for short fields; full width for text areas. Narrow numeric
  fields with `class="max-w-40"` on the input, not wrapper classes.
- Labels above fields (`fieldset-legend`), help below, errors last; required fields `required` in HTML.
- Errors per field after `phx-change`/submit (`used_input?`); on submit with errors also an `<.alert tone={:error}>`
  at the top listing the count, focus moved to the first invalid field (`JS.focus(to: "[aria-invalid=true]")`).
- Inline form (field + button: categories, participants, securities, settings): `join max-sm:join-vertical` with a plain
  `input join-item` (sr-only label) and `<.button variant={:primary} class="join-item">`; stacks below `sm`.
- Submit: `<.button variant={:primary} phx-disable-with="Speichert …">`; footer via `<.action_bar>`.
- Money fields: `inputmode="decimal"`, `suffix="€"`, `text-end tabular-nums`.

### 4.2 Lists

`<.list>` on the page between `border-y` hairlines (E1b) for collections (posts, securities,
expenses). Group headings within a list: `<.list_heading>`, `text-xs font-semibold text-base-content/70 px-4 pt-4`
(expense date groups). Loading more: stream + `phx-viewport-bottom` or `<.button>` "Mehr laden";
no shared pagination component.

### 4.3 Responsive numeric table — reference: portfolio holdings

The portfolio tracker's holdings table already did it right; the library generalises it.

| Column | Priority | Visible from | Below that |
|---|---|---|---|
| Wertpapier (name link, ISIN from `lg`) | 1 | always | carries the sub line |
| Wert | 1 | always | gain repeated under the value below `sm` |
| Gewinn | 2 | `sm` | under Wert |
| Einstand | 3 | `md` | dropped |
| Anteil | 3 | `md` | dropped |
| Stück, Kurs | 4 | `lg` | "12 Stück · 81,20 €" under the name |

Rules: at most two always-visible columns, a name and the key figure; every hidden value either repeats in a sub
line or is secondary; numbers right-aligned with right-aligned headers, `tabular-nums`, `whitespace-nowrap`; group
rows `th scope="colgroup"`; totals in `<tfoot>`; the name link is the row's navigation (44px on coarse via the row
height, 45px). Breakpoints shift from Bootstrap's 576/768/992 to 640/768/1024. Dates in columns are numbers too
(`tabular-nums`).

### 4.4 Empty, loading, stale

Empty: `<.empty_state>` teaches the next step (one action) except for data that arrives by itself (sensors:
"erscheint, sobald …" is fine). Loading: `skeleton` blocks in the final layout for async cards; the button
`loading` state for actions; no full-page spinners. Stale live data: badge + timestamp, never opacity on text.

### 4.5 Navigation shells

| App | Layout | Phone | Tablet | Desktop |
|---|---|---|---|---|
| Portfolio, budget | `:sidebar` | top bar + dock (3–4 items) | rail | sidebar 18.5rem |
| Home automation | `:topbar` | dock (6 plush items) | top nav | top nav |
| Shared expenses | `:topbar` | dock (4 plush items) + FAB on home | top nav | top nav |
| CMS | `:topbar` + `<.tabs>` per site | dock omitted (`dock={[]}`), tabs scroll | same | same |

Dock: daisyUI `dock` (64px + safe area), plush `size-6` or Lucide `size-5`, label `text-xs` (patched from 11px),
active item `dock-active` + `aria-current="page"`. Hidden while a text field has focus (`has-[input:focus]`
variant on `<body>`).

### 4.6 Icons in context

Buttons: Lucide before the label, `size-4`; icon-only buttons `btn-square` + `aria-label`. Navigation and categories:
plush. Chevrons and arrows: Lucide only (no `←`, `›` glyphs). Spinners: daisyUI `loading`.

## 5. Behaviour without Bootstrap JS

| Need | Mechanism |
|---|---|
| Modal, sheet, side panel | `<dialog>` + `showModal()` via `JS.dispatch`; `<form method="dialog">`; native Escape and focus return |
| Dropdown, account menu, row `⋮` menu | `<details>` + `phx-click-away` + Escape via `phx-window-keydown`; `JS.ignore_attributes(["open"])` |
| Disclosure | `<details>`/`collapse` |
| Tabs, segmented time ranges | links with `patch`, server state |
| Flash | `JS.push("lv:clear-flash")` + `JS.hide` transition |
| Confirm | shared `<.confirm_dialog>` (E6b): trigger via `show_confirm/3` (`JS.set_attribute` + `JS.dispatch`), destructive `phx-click` on the dialog's confirm button; no `data-confirm` |
| Sidebar overlay | `<.modal placement={:start}>` (native dialog) |
| Theme | `<.theme_script>` (nonce) + colocated `ThemeToggle` hook, or server-rendered `data-theme` |
| Submit lock | `phx-disable-with` (replaces hand-written submit locks) |
| Infinite scroll | streams + `phx-viewport-bottom` |
| Charts | app hooks; the package only provides token reading and theme-change events |

Reduced motion: daisyUI transitions are 0.2–0.3s state changes; spinners use `motion-safe:`.

## 6. Touch-target strategy

| Element | Fine pointer | Coarse pointer | How |
|---|---|---|---|
| `btn`, `input`, `select`, `tab` md | 40px | 44px | theme patch `min-height: 2.75rem` under `(pointer: coarse)` |
| `btn-sm`, `btn-square` | 32px | 44 × 44px | same patch (+ `min-width`) |
| menu items, summaries | ≈ 33px / 21px | 44px | same patch |
| checkbox, radio, toggle | 24px control | 44px label row | label wraps the control, `pointer-coarse:min-h-11` |
| table rows | 45px (`:md`) | 45px | row height; `:sm` tables (34px) only for read-only data |
| list rows | ≥ 53px | ≥ 53px | daisyUI `list-row` |
| dock items | ≈ 48px | ≈ 48px | daisyUI `dock` |
| inline links in sentences | – | – | exempt (WCAG 2.5.8) |
| standalone text links (back, "Filter zurücksetzen") | – | 44px | render as `btn btn-ghost btn-sm` or `btn-link` |

Pointer, not viewport, decides (one app mixed both): touch tablets get 44px, desktops keep daisyUI's 40px.
Desktop density for a budget register stays in the app (rows about 36px).

## 7. Theme switching

- No `data-theme` → system decides (`prefersdark`). Explicit choice → `data-theme="zipfel-light|zipfel-dark"`.
- Tailwind `dark:` matches both (custom variant in `setzkasten.css`); Phoenix's generator variant matched only
  `[data-theme=dark]`.
- `<meta name="theme-color">` twice with `media="(prefers-color-scheme: …)"`, in the page surface base-100,
  `#ffffff` / `#2d2f33` (`<.theme_meta />`); error pages load the same CSS and script.

## 8. To verify in a consuming app

1. Layer order of the patches (`utilities.daisyui.l1.l2.l3`, `utilities.setzkasten`) in the compiled CSS.
2. `@theme` chart/sidebar tokens overridden per theme at runtime.
3. Stretched row links in `<table>` on Safari.
4. Rendered contrast spot checks on real pages.
