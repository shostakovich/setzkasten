# Changelog

## 0.1.0 (unreleased)

- Released into the public domain under the Unlicense.
- Soft alerts (`<.alert>`, flashes) mix 25 % of their tone into the background in the light theme,
  where daisyUI's 8 % was barely visible on white; dark keeps 8 %. `--setzkasten-alert-tint`
  overrides it (README, "Alert tint").
- The library's CSS variables, layer and events use the `setzkasten` prefix; hooks come from
  `phoenix-colocated/setzkasten`. The themes are `zipfel-light`/`zipfel-dark`.
- Chart series are the colour roles (primary, warning, success, error, accent, info, secondary,
  neutral): new `--color-chart-N-fill` for bars, areas and legend dots; `--color-chart-N` stays the
  line/outline colour (≥ 3:1). `<.legend>` draws fill plus outline. Rose (old chart-8) is gone.
- `<.list_row>`: below `md` the `:trailing` slot moves under the title, so a badge no longer
  squeezes the title next to the `⋮` menu and the chevron. The menu's accessible name is
  `"<actions_label>: <title>"` (was `"Aktionen für <title>"`, German only).
- Confirm dialog: `label:` for `show_confirm/5`, `confirm_label` on `<.button>` and `list_row`
  actions, for irreversible actions other than a plain delete (the trash icon then hides).
- `<.list_row>` actions: `id` (menu entry `<id>-menu-item`, row menu `<row id>-menu-toggle`)
  and `disabled`. `<.card>`: `:leading` slot before the title. `<.flash_group>`: `close_label`.
- `<.alert>`: `on_close` + `close_label` for a dismiss button that stays at the end on phones.
- `<.dropdown>`: `:header` slot and `trigger_class`. `<.tabs>`: `class` per tab.
  `<.app_shell layout={:topbar}>` renders no menu without `:nav` entries.
- `<.button confirm>`: the parked push sends `phx-value-*` values as strings, as the browser
  does without the dialog (integers reached `handle_event` as numbers before).
- `use Setzkasten` no longer imports `Setzkasten.Components.Forms.translate_error/1`; it clashed
  with the generated `CoreComponents.translate_error/1` that the README tells apps to keep.
- README: import the package CSS through the Mix build path on `NODE_PATH`, the same line for
  path, git and hex dependencies.
- First version: 28 components from the design system, themes `zipfel-light`/`zipfel-dark`
  with patches, colocated hooks for modals and the theme toggle, catalog dev app.
