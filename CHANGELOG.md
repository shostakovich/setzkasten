# Changelog

## 0.1.0 (unreleased)

- First version.
- Chart series `chart-1` … `chart-8` and `chart-other` are graphic colours of their own, vivid hues at 3:1 on
  base-100/200 in both themes, no longer the roles and the inks (4.5:1 text colours, dull as fills); `chart-N-fill` is
  `chart-N`. An app overrides a series directly; overriding a role or an ink no longer moves the series.
- `composer`: a bar fixed to the bottom of the page column for a form that is only the bar, above the dock and
  right on top of the on-screen keyboard; `app_shell` exports the column's width, gutter and alignment for it.
- Toasts (`flash`, `flash_group`) sit at the bottom, above dock, keyboard, composer, a pinned action bar and a
  shown selection bar; they rise opaque and leave downward. `fab` and `selection_bar` sit above a composer. Info
  flashes close themselves after 5 s, paused under the pointer or focus; a `flash` with slot content stays, and
  its ✕ only hides it.
- `put_toast/3`: a toast for a done action with an optional action button ("Rückgängig"), for LiveViews and
  controllers.
- `--setzkasten-dock-offset` is set on `<html>` and is 0 while the on-screen keyboard is up.
- `theme_script` publishes the on-screen keyboard's height as `--setzkasten-keyboard-inset` on every page, so toasts
  clear the keyboard also without a composer; it belongs in every root layout.
- `app_shell` nav entries: long labels end in an ellipsis (full label as `title`), `glyph`, `section_amount`,
  a count next to an amount as a badge, `amount_tone={:negative}` with the `sidebar-negative` token, and button entries
  (`on_click`); `id` on entries, suffixed per place.
- `tooltip`: daisyUI tooltip with the text as the described element's accessible description.
- `popover` with `show_popover/1` and `hide_popover/1`: free content in the top layer, anchored to its trigger
  or an element elsewhere, a bottom sheet on phones.
- `combobox`: searchable select with groups, an option slot and an optional create entry, as a form field.
  A value the server sets while the field has focus shows when nothing was typed in it, so leaving the field keeps it.
- `confirm` on `<.button type="submit">`: the confirmation submits the button's form, with the button as submitter.
- `file_drop`: a drop zone around `live_file_input` with label, help and the upload's errors in German.
- `selection_bar`: fixed bar for a multi-selection beside the shell's sidebar, with a live region for the count.
- `amount` `tone={:negative}`: negative and zero toned, positive plain, for balances.
- `header` `back_patch` and `back_href` next to `back`.
- `Setzkasten.Test.Confirm`: test helpers for confirmed actions (`asked/3`, `confirm_click/4`, `close_modal/3`).
- `disclosure` `:title` slot for a summary with markup.
- `alert` places its `:actions` by its own width (a container query), not the viewport's.
- `alert` content spans the alert's full width, so `:actions` end at its edge.
- `section_heading` `size={:sm}` for compact surfaces such as a popover.
- `combobox_options` and `options_from`: one option list for many comboboxes.
- Escape in an open `dropdown` closes only the menu, not a `<dialog>` around it.
- `modal` side panels (`placement` `:start`, `:end`) keep their content and ✕ clear of the top and bottom safe areas.
- `input type="radio_group"` is a `radiogroup` that carries `aria-invalid` with errors, so screen readers and
  `FocusInvalid` find it.
- `table` `size={:dense}` for data grids: 36px rows (44px on coarse pointers), 32px controls in cells.
- `list` `size={:dense}`: 53px rows, also with a meta line or a 40px leading tile (a shopping list).
- `list_row` `muted` for done or secondary rows: title at the meta's 70 % and normal weight, leading content faded.
- `list_row` `exit={:strike}`: a tap strikes the title through at once, a row LiveView removes strikes and then
  collapses (`phx-remove` and a colocated hook; needs `id`).
- `list_row` `exit={:strike}` keeps a removed row in its place in a `:for` list too, where morphdom moved the rows
  below it in front of it when comments (HEEx debug annotations) or text sat between the rows.
- `modal`: the title row and `:actions` stay in place while a long body scrolls between them, with a hairline
  while content runs under them. A `:center` modal box (and `confirm_dialog`'s) is at most the dynamic viewport
  high less 5em, at every width; a `max-h-*` class still wins.
- `row-selected` token (`bg-row-selected`): `table` rows with `aria-current` or `aria-selected="true"` take it with a 3px `selected` bar at their start.
- A proper minus sign: U+2212 comes from a one-glyph Figtree face built from its plus (0.45em, plus-sign height and side bearings) instead of Figtree's short minus.
- `btn-sm` (small buttons, `segmented size={:sm}`) sets its label in 13px instead of daisyUI's 12px.
- `app_shell layout={:sidebar}`: capped page widths start at the content edge instead of being centred, so every page starts at the same x; the top-bar layout stays centred.
- `file_drop` shows a German button (`button_label`) and the chosen file names or `no_file_label` instead of the browser's own file text; the native input, visually hidden, stays the control.
- Neutral buttons in a soft `alert` take `--setzkasten-alert-control` and a 50 % base-content border, so they read as buttons on every tint (3.2:1 and more).
- Opening a modal no longer shifts the page by the scrollbar's width: `:root` has `scrollbar-gutter: stable`.
- `app_shell` button entries (`on_click`) in the sidebar dialog close the dialog before their action runs.
- `tabs`: the first tab's label lines up with the content edge instead of sitting 12px in.
- `app_shell` `:nav` `parent`: an entry left out of dock or rail names the entry that dock and rail mark while it is current.
- `app_shell` sidebar: an entry without icon, plush or glyph keeps the icon's place when others have one, so all labels share one text column.
- A plain `checkbox` or `radio` (no colour variant) has the 50 % base-content field border instead of daisyUI's 20 % (1.53:1 light, 1.80:1 dark): 3.39:1 and 4.38:1 on the page, 3.32:1 and 4.11:1 on base-200 and the dark popover.
- `setzkasten-table-dense` is a public utility: the `:dense` table size for a hand-written `<table class="table">`.
- `segmented mode={:button}` sends its option in browsers too: the buttons carry `value`, which LiveView's client sends
  over `phx-value-value`; option values render as strings, so `false` arrives as `"false"`. `<.button>` renders a
  `phx-value-value` as its `value` as well.
- Table columns (`show_from`), `show_from/1` and `cell_sub` (`show_from`, `hide_from`) accept `:"2xl"`.
- A sticky `action_bar` renders `:secondary` once, so its buttons may carry ids; it now comes after cancel and primary in the DOM.
- `dropdown` `:item` `active` marks button items (`on_click`) too: `menu-active` and `aria-current="true"`.
- `show_confirm(id, question, action, opts)` works without a leading `%JS{}`; piped onto commands it still takes one.
- `join_meta/1` leaves out `false` parts, as it does `nil` and `""`.
- A confirmed click parks its `phx-value-*` as the rendered button sends them: `nil` and `false` left out, `true` empty.
- A confirmed click also parks a button's `value` as `"value"`, as LiveView's client sends it without `confirm`.
- `app_shell layout={:sidebar}`: the dock shows its "Mehr" button whenever entries are left out of it, so they stay reachable on phones.
- Dock labels stay on one line and end in an ellipsis; the link keeps the full label as its name.
- `plush` with a dark file: an `id` no longer repeats, the dark image takes `<id>-dark`.
- The dock hides only for fields that bring up the on-screen keyboard, no longer for a focused slider, colour,
  date or time picker, button or file input.
- `app_shell`: the dock holds six entries; with more than six, entries left out of the dock or a sidebar
  `:nav_footer` it shows five and a "Mehr" button (with `layout={:topbar}` a sheet with the rest), so every entry
  stays reachable on phones.
- `modal` on phones: the bottom sheet keeps its content and a sticky action bar above the bottom safe area.
- `app_shell` `layout={:sidebar}` without a dock: a button at the start of the top bar opens the sidebar on phones,
  which had no way into the navigation.
- Theme tokens that equal a role follow it: the dark `success-ink`, `error-ink` and `sidebar-negative`, the light
  `selected` and `selected-content`. Overriding `success`, `error` or `neutral` no longer means restating them.
- `info-ink` and `warning-ink` tokens (`text-info-ink`, `text-warning-ink`, …), text-grade like the other inks, for text,
  icons and marks such as ratings; alert and flash icons use them (darker in light).
- `app_shell` `layout={:sidebar}`: a `:nav_footer` brings the dock's "Mehr" button, so phones reach it in the sidebar
  also when every entry fits the dock.
- `chart_card` `hook_attrs`: attributes on the hook element, e.g. the series as `data-*` for the chart hook.
- `segmented` `mode={:checkbox}`: any number of options chosen, a checkbox group sent as `name[]`.
- Guide: categorical chart series skip the series numbers a chart already uses semantically; what does not fit the
  free series is grouped.
- `chart_card` `height={:auto}`: a self-sizing inner block (server-drawn SVG) sets the chart's height.
- `chart_card` `subtitle` for the unit or period, as in `card`, so ticks show bare numbers.
- `stat` keeps label, value and note at the top when a taller neighbour in its grid row stretches it.
- `stat` `:figure` slot: a plush, icon, gauge or sparkline at the tile's end, at the end of the label row on phones.
- `stat` `tone={:warning}`: the value in `warning-ink`.
- `chart-other` and `chart-other-fill` tokens for the grouped rest of a chart, and `legend` `color: :other`.
- `segmented` `:radio` and `:checkbox` are fields like `input`: a visible label (`hide_label`), errors after use,
  `help`, `aria-describedby` and `aria-invalid`. The label now shows by default. An app that renders its own error
  line beside it now shows the error twice: drop that line.
- `chart_card` keeps daisyUI's card rules off its content: a `figure` is no centred flex box, a `p` does not grow.
- `input type="toggle"` has `role="switch"`, so screen readers announce a switch.
- `segmented mode={:patch}` replaces the history entry by default (`replace`), so Back leaves the page instead of
  stepping through every choice.
- `bar` `color` (chart series 1–8 or `:other`): the series fill without an outline, in place of a tone, as are the
  `legend` dots. Bars in series 2, 3, 6, 7 and `:other` stay below 3:1 against their track and need `show_value` or
  their value as text beside them (a stat's `:meter`).
- `app_shell` `bar_width`: the top bar row's own width (default `width`), so the header keeps its width on pages of
  different widths.
- `plush`: a `size-*` class replaces its size class, as with `icon`; `width`/`height` still follow `size`.
- A field with a visible label ends at its last line (its room moves above it), so it lines up at the bottom with a
  button or `segmented` beside it in an `items-end` row.
- `chart_card`: the hook element is `relative` for Chart.js's responsive mode, and the card `min-w-0`, so a chart in a
  flex row shrinks.
- `share_bar`: a whole split into its shares in one continuous bar, with a legend of values.
- `legend` items take a `value_label`, shown right-aligned in a grid of up to three columns sized by the legend's width.
- Sequential ramp `seq-1` … `seq-5` (one hue, light and dark) for ordered categories, as `color: {:seq, n}` in `legend`,
  `bar` and `share_bar`.
- `setzkasten-stat-grid`: stats in such a grid share its rows (subgrid), so a label on two lines no longer drops its value below its neighbours'.
- `theme_toggle compact`: one icon button showing the current scheme, with System / Hell / Dunkel in a small menu.
- `action_bar` keeps 24px above its hairline, so the footer no longer sits on the last field; a margin in its `class` replaces it.
- `list_row` with `trailing_on_phone={:title}`: the `⋮` menu sits on the title line beside the amount on phones.
- `app_shell`: plush in the top-bar menu at 24px (`:md`), as in the dock; the bar keeps its height.
- Dock: Lucide icons, glyphs and "Mehr" take the 24px box of a plush, so every dock label sits on one line.
- `Setzkasten.Components.Forms.FocusInvalid` hook for a `<.form>`: focus on the first invalid field after a failed submit.
  The guide's `JS.focus(to: "[aria-invalid=true]")` ended on the last one.
- Guide: at most 5–6 value ticks on a chart axis, fewer on phones.
- `disclosure variant={:button}`: `count` is a small neutral badge, set apart from the label.
- `card`: the footer and the `:list` header follow `--card-p` set on the card, so a card with tighter padding keeps them lined up.
- `disclosure variant={:row}`: a quiet 14px row with a hairline above; `chart_card`'s data table uses it (and keeps its
  open state across patches).
- `stat` `:meter`: a full-width meter under the value; `bar` `hide_label` keeps its label only as the accessible name.
- `list` `:foot`: a total row whose value lines up with the rows' trailing column, also beside their actions.
- `input` checkbox and toggle `bare`: no field padding or row height, beside a heading; a 44px hit area on touch screens.
- `Setzkasten.Format.date/2`, `datetime/2` and `time/2`: German dates and times ("14.10.2026", "Mi, 14.10.",
  "14.10.2026, 18:05", "18:05") from the app's local time as `Date`, `Time` or `NaiveDateTime`.
- `amount`, `Format.money/2`, `Format.machine/2` and `Format.shown_sign/3` take `minor_digits` for integers in another
  minor unit: yen without decimals, dinar with three; `decimals` follows it.
- `list_row` takes `:meta` more than once, one truncated line each (who paid, then what it means for you); with
  `trailing_on_phone={:meta}` the trailing content ends the last line.
- `stat` with `navigate`, `patch` or `href`: the whole tile links to the KPI's detail page, `:meter` and `:figure`
  included.
- `button` with an `icon` keeps it through `phx-disable-with`: the pending text stands in a stack beside the label
  instead of LiveView replacing the content and restoring only its text; clicked, it looks disabled until the reply.
  `icon_only` with a `phx-disable-with` text raises.
- `radio_group` options may be maps with a `:description`: a quieter line under the label, the radio's
  accessible description.
- `button` with `href`, `navigate` or `patch` and `disabled`: an `<a>` without its target, `aria-disabled` and in the
  disabled look, instead of a link that still navigates.
- `app_shell` `layout={:sidebar}` `:area` entries with `current_area`: a segmented area switch at the top of the sidebar,
  its dialog and the icon rail, shown with more than one area.
- `app_shell` `layout={:sidebar}` `:back`: a sidebar mode with the page's own navigation (e.g. the settings), a way back
  at the top of sidebar, dialog and rail, and no dock.
- `app_shell` `:area` and `dropdown` `:item` take `plush`, as `:nav` entries do: 20px in the area switch, 24px in a
  menu, the `icon` when the plush module has no image for it.
- `dropdown`: once an item shows a plush, all labels share one text column; icons and items without one keep a 24px
  place, and every item keeps the height of its text row.
- `app_shell` `width={:full}`: a 16px side gutter at every breakpoint for the column and the top bar, so dense tables
  get the room; the other widths keep `px-4 sm:px-6 lg:px-8`.
