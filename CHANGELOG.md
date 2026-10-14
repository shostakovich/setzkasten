# Changelog

## 0.1.0 (unreleased)

- First version.
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
- `table` `size={:dense}` for data grids: 36px rows (44px on coarse pointers), 32px controls in cells.
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
- `app_shell layout={:sidebar}`: the dock shows its "Mehr" button whenever entries are left out of it, so they stay reachable on phones.
- Dock labels stay on one line and end in an ellipsis; the link keeps the full label as its name.
