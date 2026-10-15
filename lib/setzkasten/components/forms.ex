defmodule Setzkasten.Components.Forms do
  @moduledoc """
  Form fields, a searchable select, a file drop zone and the form footer.

  `phx-hook="Setzkasten.Components.Forms.FocusInvalid"` on a `<.form>` (with an `id`) moves
  focus to the first field with `aria-invalid="true"` once a submit comes back with errors (a
  radio or checkbox group to its first control). `JS.focus(to: "[aria-invalid=true]")` cannot:
  it focuses every match in turn and ends on the last.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.ColocatedHook
  import Setzkasten.Components.Icons

  @doc """
  A labelled form field: `fieldset.fieldset` > label > field > errors > help.

  Types: the HTML input types (`text`, `email`, `password`, `number`, `date`,
  `datetime-local`, `search`, `tel`, `url`, `hidden`, …) plus `select`, `textarea`,
  `checkbox`, `toggle` and `radio_group`.

  Errors from `field` show after the field was used (`used_input?/1`), with `aria-invalid`,
  the field border in `error-ink` and error lines linked by `aria-describedby`. Messages go
  through the function configured as `config :setzkasten, translate_error: {Mod, :fun}`
  (an app's Gettext `translate_error/1`); without it `%{count}`-style bindings are filled in.

  A `toggle` is a checkbox with `role="switch"`: screen readers announce a switch, on or off
  from the native checked state. `bare` (checkbox and toggle) drops the field's padding and
  row height, so the control lines up with a heading beside it (a card's `:actions`); on touch
  screens a hit area centred on the label, at least 44px each way, keeps the target without
  growing the row, also with `hide_label`.

  `class` lands on the field box (e.g. `max-w-40` for a narrow amount); `numeric` right-aligns
  the value with tabular figures and defaults `inputmode` to `decimal`. `help_tone={:warning}`
  marks the help line as a warning (`triangle-alert` icon, full base-content text); it stays
  linked by `aria-describedby`.

  `inline` (text-like types) puts the field and the inner block, the form's button, in one
  `join` (stacked below `sm`) with the label for screen readers only; errors and help go below
  the join. The button takes `class="join-item"`.

  `radio_group` options are `{label, value}` tuples or maps with `:label`, `:value` and an optional
  `:description`: a quieter line under the label (what the choice means or brings), the radio's
  description for screen readers, while the label alone stays its name.

      <.input field={@form[:amount]} label="Betrag" suffix="€" numeric class="max-w-40"
              help="Mit Komma, z. B. 87,42" />
      <.input field={@form[:category_id]} type="select" label="Kategorie" options={@categories}
              prompt="Bitte wählen" />
      <.input field={@form[:recurring]} type="checkbox" label="Jeden Monat wiederholen" />
      <.input field={@form[:split]} type="radio_group" label="Aufteilung"
              options={[{"Gleichmäßig", "equal"}, {"Nach Anteilen", "shares"}]} />
      <.input field={@form[:name]} label="Neue Kategorie" placeholder="z. B. Haustier" inline>
        <.button type="submit" variant={:primary} icon="plus" class="join-item">Hinzufügen</.button>
      </.input>
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any
  attr :type, :string, default: "text"
  attr :field, Phoenix.HTML.FormField, doc: "a form field, e.g. `@form[:email]`"
  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "checked flag for checkbox and toggle"
  attr :hide_label, :boolean, default: false
  attr :help, :string, default: nil
  attr :help_tone, :atom, default: nil, values: [nil, :warning]
  attr :inline, :boolean, default: false, doc: "field and inner block (a button) in one join"

  attr :bare, :boolean,
    default: false,
    doc: "checkbox and toggle: no field padding or row height, e.g. beside a heading"

  attr :prefix, :string, default: nil
  attr :suffix, :string, default: nil
  attr :icon, :string, default: nil, doc: "Lucide icon at the start of the field (search)"
  attr :numeric, :boolean, default: false

  attr :options, :list,
    doc: "options for select and radio_group (a radio option may be a map with `:description`)"

  attr :prompt, :string, default: nil
  attr :multiple, :boolean, default: false
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                pattern placeholder readonly required rows size step inputmode)

  slot :inner_block, doc: "with `inline`: the button after the field, `class=\"join-item\"`"

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error/1))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: type} = assigns) when type in ["checkbox", "toggle"] do
    assigns =
      assigns
      |> prepare()
      |> assign_new(:checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class={if @bare, do: "inline-flex min-w-0 flex-col", else: "fieldset min-w-0"}>
      <label class={[
        "flex items-center gap-3 text-sm",
        if(@bare,
          do: [
            "relative pointer-coarse:after:absolute pointer-coarse:after:left-1/2 pointer-coarse:after:top-1/2",
            "pointer-coarse:after:h-11 pointer-coarse:after:w-full pointer-coarse:after:min-w-11",
            "pointer-coarse:after:-translate-x-1/2 pointer-coarse:after:-translate-y-1/2"
          ],
          else: "pointer-coarse:min-h-11"
        )
      ]}>
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          role={@type == "toggle" && "switch"}
          class={[control_class(@type), @class]}
          aria-invalid={@errors != [] && "true"}
          aria-describedby={@describedby}
          {@rest}
        />
        <span class={@hide_label && "sr-only"}>{@label}</span>
      </label>
      <.field_error id={@id} errors={@errors} />
      <.field_help :if={@help} id={@id} tone={@help_tone}>{@help}</.field_help>
    </div>
    """
  end

  def input(%{type: "radio_group"} = assigns) do
    assigns = prepare(assigns)

    options =
      for {option, i} <- Enum.with_index(assigns.options), do: radio_option(option, assigns.id, i)

    assigns = assign(assigns, :options, options)

    ~H"""
    <fieldset
      class="fieldset min-w-0"
      role="radiogroup"
      aria-invalid={@errors != [] && "true"}
      aria-describedby={@describedby}
    >
      <legend class={["fieldset-legend", @hide_label && "sr-only"]}>{@label}</legend>
      <label
        :for={option <- @options}
        class={[
          "flex gap-3 text-sm pointer-coarse:min-h-11",
          if(option.description, do: "items-start", else: "items-center")
        ]}
      >
        <input
          type="radio"
          id={option.id}
          name={@name}
          value={option.value}
          checked={to_string(option.value) == to_string(@value)}
          class={["radio radio-primary", option.description && "-mt-0.5", @class]}
          aria-labelledby={option.description && option.label_id}
          aria-describedby={option.description && option.description_id}
          {@rest}
        />
        <%= if option.description do %>
          <span class="min-w-0">
            <span id={option.label_id} class="block">{option.label}</span>
            <span id={option.description_id} class="block text-base-content/70">
              {option.description}
            </span>
          </span>
        <% else %>
          {option.label}
        <% end %>
      </label>
      <.field_error id={@id} errors={@errors} />
      <.field_help :if={@help} id={@id} tone={@help_tone}>{@help}</.field_help>
    </fieldset>
    """
  end

  def input(%{type: "select"} = assigns) do
    assigns = prepare(assigns)

    ~H"""
    <fieldset class="fieldset min-w-0">
      <.field_label id={@id} label={@label} hide={@hide_label} />
      <select
        id={@id}
        name={@name}
        class={["select w-full", @errors != [] && "select-error", @class]}
        multiple={@multiple}
        aria-invalid={@errors != [] && "true"}
        aria-describedby={@describedby}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.field_error id={@id} errors={@errors} />
      <.field_help :if={@help} id={@id} tone={@help_tone}>{@help}</.field_help>
    </fieldset>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    assigns = prepare(assigns)

    ~H"""
    <fieldset class="fieldset min-w-0">
      <.field_label id={@id} label={@label} hide={@hide_label} />
      <textarea
        id={@id}
        name={@name}
        class={["textarea w-full", @errors != [] && "textarea-error", @class]}
        aria-invalid={@errors != [] && "true"}
        aria-describedby={@describedby}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <.field_error id={@id} errors={@errors} />
      <.field_help :if={@help} id={@id} tone={@help_tone}>{@help}</.field_help>
    </fieldset>
    """
  end

  def input(assigns) do
    assigns = prepare(assigns)

    assigns =
      assign(assigns,
        boxed: assigns.prefix || assigns.suffix || assigns.icon,
        rest: numeric_rest(assigns)
      )

    ~H"""
    <fieldset class="fieldset min-w-0">
      <.field_label id={@id} label={@label} hide={@hide_label || @inline} />
      <div :if={@inline} class="join max-sm:join-vertical w-full">
        <.text_field {field_attrs(assigns)} join />
        {render_slot(@inner_block)}
      </div>
      <.text_field :if={!@inline} {field_attrs(assigns)} />
      <.field_error id={@id} errors={@errors} />
      <.field_help :if={@help} id={@id} tone={@help_tone}>{@help}</.field_help>
    </fieldset>
    """
  end

  defp field_attrs(assigns) do
    Map.take(
      assigns,
      ~w(type id name value errors numeric icon prefix suffix boxed class describedby rest)a
    )
  end

  attr :type, :string, required: true
  attr :id, :any, required: true
  attr :name, :any, required: true
  attr :value, :any, required: true
  attr :errors, :list, required: true
  attr :numeric, :boolean, required: true
  attr :icon, :string, required: true
  attr :prefix, :string, required: true
  attr :suffix, :string, required: true
  attr :boxed, :any, required: true
  attr :class, :any, required: true
  attr :describedby, :string, required: true
  attr :rest, :map, required: true
  attr :join, :boolean, default: false

  defp text_field(assigns) do
    ~H"""
    <label
      :if={@boxed}
      class={["input w-full", @join && "join-item", @errors != [] && "input-error", @class]}
    >
      <.icon :if={@icon} name={@icon} class="size-4 text-base-content/70" />
      <span :if={@prefix} class="label">{@prefix}</span>
      <input
        type={@type}
        id={@id}
        name={@name}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={@numeric && "text-end tabular-nums"}
        aria-invalid={@errors != [] && "true"}
        aria-describedby={@describedby}
        {@rest}
      />
      <span :if={@suffix} class="label">{@suffix}</span>
    </label>
    <input
      :if={!@boxed}
      type={@type}
      id={@id}
      name={@name}
      value={Phoenix.HTML.Form.normalize_value(@type, @value)}
      class={[
        "input w-full",
        @join && "join-item",
        @errors != [] && "input-error",
        @numeric && "text-end tabular-nums",
        @class
      ]}
      aria-invalid={@errors != [] && "true"}
      aria-describedby={@describedby}
      {@rest}
    />
    """
  end

  defp radio_option({label, value}, id, i),
    do: radio_option(%{label: label, value: value}, id, i)

  # The label and description ids are IDREFs, which a value with a space would split.
  defp radio_option(%{label: label, value: value} = option, id, i) do
    %{
      id: "#{id}_#{value}",
      label_id: "#{id}-option-#{i}-label",
      description_id: "#{id}-option-#{i}-description",
      label: label,
      value: value,
      description: option[:description]
    }
  end

  defp prepare(assigns) do
    assigns
    |> assign_new(:value, fn -> nil end)
    |> assign_new(:name, fn -> assigns.id end)
    |> assign_new(:options, fn -> [] end)
    |> assign(:describedby, field_describedby(assigns.id, assigns.errors, assigns.help))
  end

  defp numeric_rest(%{numeric: true, rest: rest}), do: Map.put_new(rest, :inputmode, "decimal")
  defp numeric_rest(%{rest: rest}), do: rest

  defp control_class("checkbox"), do: "checkbox checkbox-primary"
  defp control_class("toggle"), do: "toggle toggle-primary"

  attr :id, :any, required: true
  attr :label, :string, default: nil
  attr :hide, :boolean, default: false

  defp field_label(assigns) do
    ~H"""
    <label :if={@label} for={@id} class={if @hide, do: "sr-only", else: "fieldset-legend"}>
      {@label}
    </label>
    """
  end

  @doc """
  A searchable select (ARIA combobox with a listbox): a text field that filters its options as
  you type, for long lists such as payees or categories. A hidden field carries the value, so it
  works in a form like `input/1` (errors after `used_input?/1`, once a choice was made or the
  form submitted): `field` (or `id`, `name` and `value`), `label`, `hide_label`, `help`,
  `errors`, `class` on the field box.

  `options` are `{label, value}` tuples or maps with `:label`, `:value` and an optional `:key`
  (extra search text); `{group_label, [options]}` makes a group. Filtering runs in the browser
  and ignores case, accents, "ß"/"ss" and emoji. The `:option` slot renders an option's content
  (`:let={option}`, the option as a map, e.g. with an amount at its end).

  Keyboard: the list opens on focus, click, typing and ArrowDown; ArrowUp/ArrowDown move,
  Enter and Tab take the highlighted option, Escape closes the list (and only the list, not a
  surrounding popover or dialog) and restores the text. Leaving the field without a choice puts
  the chosen option's text back; clearing the text clears the value. A choice fires `input` on
  the hidden field, so the form's `phx-change` runs; typing does not.

  `allow_create` adds an entry for the typed text when no option matches it exactly
  (`create_label`, `%{text}` is the text). Without `create_field` the text becomes the value (a
  field that stores names, such as a payee); with it the value is cleared and the text goes into
  `create_field`, so the server tells a new entry from an id.

  The list is a popover in the top layer, anchored below the field (above when there is no
  room), so it escapes dialogs, popovers and scrolling tables.

  Many comboboxes with the same options (e.g. the parts of a split transaction) can share one
  list: render it once with `combobox_options/1` and pass its id as `options_from`; each
  combobox copies it while its list is open. `options` then only names the chosen value (the
  full list, or just the chosen option).

      <.combobox_options id="category-options" options={@category_groups} />
      <.combobox :for={part <- @parts} field={part[:category_id]} label="Kategorie"
        options_from="category-options" options={@category_groups} />

      <.combobox field={@form[:category_id]} label="Kategorie" options={@category_groups}
        placeholder="Kategorie suchen">
        <:option :let={option}>
          <span class="flex-1 truncate">{option.label}</span><.amount value={option.available} tone />
        </:option>
      </.combobox>
      <.combobox field={@form[:payee]} label="Empfänger" options={@payees} allow_create />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :value, :any
  attr :field, Phoenix.HTML.FormField, doc: "a form field, e.g. `@form[:category_id]`"
  attr :errors, :list, default: []
  attr :label, :string, default: nil
  attr :hide_label, :boolean, default: false
  attr :help, :string, default: nil
  attr :help_tone, :atom, default: nil, values: [nil, :warning]

  attr :options, :list,
    default: [],
    doc:
      "`{label, value}`, maps, or `{group, options}`; with `options_from` only for the shown text"

  attr :options_from, :string,
    default: nil,
    doc: "id of a `combobox_options/1` list rendered once for several comboboxes"

  attr :placeholder, :string, default: nil
  attr :allow_create, :boolean, default: false
  attr :create_label, :string, default: "„%{text}“ anlegen"

  attr :create_field, Phoenix.HTML.FormField,
    default: nil,
    doc: "takes a new entry's text; without it the text becomes the value"

  attr :empty_label, :string, default: "Keine Treffer"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled required form autofocus)
  slot :option, doc: "an option's content, `:let={option}`"

  def combobox(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error/1))
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> combobox()
  end

  def combobox(%{id: nil}) do
    raise ArgumentError,
          "<.combobox> needs a field or an id: its listbox and options derive theirs from it"
  end

  def combobox(assigns) do
    assigns =
      assigns
      |> assign_new(:value, fn -> nil end)
      |> assign_new(:name, fn -> assigns.id end)
      |> assign(:describedby, field_describedby(assigns.id, assigns.errors, assigns.help))
      |> assign(:groups, combobox_groups(assigns.options, assigns.id))

    created = assigns.create_field && assigns.create_field.value

    {before, after_text} =
      case String.split(assigns.create_label, "%{text}", parts: 2) do
        [before, after_text] -> {before, after_text}
        [label] -> {label <> " ", ""}
      end

    assigns =
      assign(assigns,
        text: combobox_text(assigns.groups, assigns.value, created, assigns.allow_create),
        create_before: before,
        create_after: after_text,
        hidden_rest: Map.take(assigns.rest, [:form, :disabled])
      )

    ~H"""
    <fieldset class="fieldset min-w-0">
      <.field_label id={@id} label={@label} hide={@hide_label} />
      <div
        id={"#{@id}-combobox"}
        class="setzkasten-combobox"
        phx-hook=".Combobox"
        data-text={@text}
        data-options-from={@options_from}
      >
        <label class={["input w-full", @errors != [] && "input-error", @class]}>
          <input
            type="text"
            id={@id}
            value={@text}
            role="combobox"
            aria-autocomplete="list"
            aria-expanded="false"
            aria-controls={"#{@id}-listbox"}
            aria-invalid={@errors != [] && "true"}
            aria-describedby={@describedby}
            autocomplete="off"
            placeholder={@placeholder}
            phx-mounted={
              Phoenix.LiveView.JS.ignore_attributes(["aria-expanded", "aria-activedescendant"])
            }
            {@rest}
          />
          <.icon name="chevron-down" class="size-4 shrink-0 text-base-content/70" />
        </label>
        <%!-- Not type="hidden": LiveView never marks a hidden input used, so its errors would show at once. --%>
        <input
          type="text"
          name={@name}
          value={@value}
          hidden
          autocomplete="off"
          data-value-input
          {@hidden_rest}
        />
        <input
          :if={@create_field}
          type="hidden"
          name={@create_field.name}
          value={@create_field.value}
          data-create-input
          {@hidden_rest}
        />
        <div
          id={"#{@id}-listbox"}
          role="listbox"
          popover="manual"
          aria-label={@label}
          class="setzkasten-listbox shadow-lg"
        >
          <div
            :if={@allow_create}
            id={"#{@id}-create"}
            role="option"
            aria-selected="false"
            class="setzkasten-option text-primary"
            data-create
            hidden
          >
            <.icon name="plus" class="size-4 shrink-0" />
            <span class="min-w-0 flex-1 truncate">
              {@create_before}<span data-create-text></span>{@create_after}
            </span>
          </div>
          <div :if={@options_from} id={"#{@id}-options"} data-options phx-update="ignore"></div>
          <.combobox_list :if={!@options_from} groups={@groups} current={@value} slot={@option} />
          <div class="setzkasten-listbox-empty" data-empty hidden>{@empty_label}</div>
        </div>
      </div>
      <.field_error id={@id} errors={@errors} />
      <.field_help :if={@help} id={@id} tone={@help_tone}>{@help}</.field_help>
    </fieldset>
    <script :type={ColocatedHook} name=".Combobox">
      const EMOJI = /[\p{Extended_Pictographic}\p{Emoji_Modifier}\p{Regional_Indicator}‍︎️⃣]/gu
      const key = (text) =>
        (text || "").normalize("NFKD").replace(/\p{M}/gu, "").replace(EMOJI, " ").replace(/ß/g, "ss")
          .replace(/\s+/g, " ").trim().toLowerCase()
      const NATIVE = CSS.supports("anchor-scope: all") && CSS.supports("position-area: block-end")
      const EDGE = 8
      const GAP = 4
      export default {
        mounted() {
          this.input = this.el.querySelector("[role=combobox]")
          this.list = this.el.querySelector("[role=listbox]")
          this.shared = this.el.querySelector("[data-options]")
          this.value = this.el.querySelector("[data-value-input]")
          this.created = this.el.querySelector("[data-create-input]")
          this.text = this.el.dataset.text || ""
          this.onMove = () => {
            cancelAnimationFrame(this.frame)
            this.frame = requestAnimationFrame(() => this.place())
          }
          // Typing is a search, not a form change: only a choice reaches phx-change.
          for (const type of ["input", "change"]) {
            this.el.addEventListener(type, (e) => { if (e.target === this.input) e.stopPropagation() })
          }
          // A field focused while its popover opens (autofocus) opens its list once that is shown.
          this.input.addEventListener("focus", () =>
            requestAnimationFrame(() => { if (document.activeElement === this.input) this.open() }))
          this.input.addEventListener("click", () => this.open())
          this.input.addEventListener("input", () => (this.isOpen() ? this.filter(this.input.value) : this.open(true)))
          this.input.addEventListener("keydown", (e) => this.keydown(e))
          this.input.addEventListener("blur", () => this.leave())
          this.list.addEventListener("mousedown", (e) => e.preventDefault())
          this.list.addEventListener("click", (e) => {
            const option = e.target.closest("[role=option]")
            if (option) this.pick(option)
          })
        },
        updated() {
          const text = this.el.dataset.text || ""
          if (text !== this.text) {
            const typed = this.input.value !== this.text
            this.text = text
            // A server-set value reaches a focused field the user has not typed in, so blur does not clear it.
            if (document.activeElement !== this.input || !typed) {
              this.input.value = text
              if (this.isOpen()) this.input.select()
            }
          }
          if (!this.isOpen()) return
          const active = this.active && this.active.id
          this.filter(this.input.value === this.text ? "" : this.input.value)
          const kept = active && this.options().find((option) => option.id === active)
          if (kept) this.highlight(kept)
        },
        destroyed() { this.stopTracking() },
        isOpen() { return this.list.matches(":popover-open") },
        options() { return [...this.list.querySelectorAll("[role=option]")].filter((o) => !o.hidden) },
        open(typing = false) {
          if (this.isOpen() || this.input.disabled || this.input.readOnly) return
          if (this.shared) this.copyOptions()
          for (const option of this.list.querySelectorAll("[role=option][data-value]")) {
            option.toggleAttribute("data-current", option.dataset.value === this.value.value)
          }
          this.list.showPopover()
          this.input.setAttribute("aria-expanded", "true")
          window.addEventListener("scroll", this.onMove, { capture: true, passive: true })
          window.addEventListener("resize", this.onMove)
          if (!typing) this.input.select()
          this.filter(typing ? this.input.value : "")
        },
        close() {
          if (this.isOpen()) this.list.hidePopover()
          this.stopTracking()
          this.highlight(null)
          this.input.setAttribute("aria-expanded", "false")
          if (this.shared) this.shared.replaceChildren()
        },
        // A shared list is copied in while open; ids are made this listbox's own.
        copyOptions() {
          const source = document.getElementById(this.el.dataset.optionsFrom)
          if (!source) return
          this.shared.replaceChildren(...[...source.children].map((child) => child.cloneNode(true)))
          const prefix = this.list.id
          this.shared.querySelectorAll("[role=option]").forEach((option, i) => (option.id = `${prefix}-option-${i}`))
          this.shared.querySelectorAll("[role=group]").forEach((group, i) => {
            const label = group.querySelector(".setzkasten-option-group")
            label.id = `${prefix}-group-${i}`
            group.setAttribute("aria-labelledby", label.id)
          })
        },
        stopTracking() {
          cancelAnimationFrame(this.frame)
          window.removeEventListener("scroll", this.onMove, { capture: true })
          window.removeEventListener("resize", this.onMove)
        },
        // Without a query everything shows and the chosen option is highlighted; with one the first match.
        filter(text) {
          const query = key(text)
          const options = [...this.list.querySelectorAll("[role=option]:not([data-create])")]
          for (const option of options) option.hidden = query !== "" && !key(option.dataset.key).includes(query)
          for (const group of this.list.querySelectorAll("[role=group]")) {
            group.hidden = !group.querySelector("[role=option]:not([hidden])")
          }
          const create = this.list.querySelector("[data-create]")
          if (create) {
            create.hidden = query === "" || options.some((o) => key(o.dataset.label) === query)
            create.querySelector("[data-create-text]").textContent = text.trim()
          }
          const visible = this.options()
          this.list.querySelector("[data-empty]").hidden = visible.length > 0
          const current = options.find((o) => o.dataset.value === this.value.value && !o.hidden)
          this.highlight(query === "" ? current : visible.find((o) => !o.hasAttribute("data-create")) || visible[0])
          if (this.isOpen()) this.place()
        },
        highlight(option) {
          if (this.active) this.active.setAttribute("aria-selected", "false")
          this.active = option || null
          if (!option) return this.input.removeAttribute("aria-activedescendant")
          option.setAttribute("aria-selected", "true")
          option.scrollIntoView({ block: "nearest" })
          this.input.setAttribute("aria-activedescendant", option.id)
        },
        keydown(e) {
          if (!this.isOpen()) {
            if (e.key === "ArrowDown" || e.key === "ArrowUp") { e.preventDefault(); this.open() }
            return
          }
          const options = this.options()
          const index = options.indexOf(this.active)
          switch (e.key) {
            case "ArrowDown":
            case "ArrowUp": {
              e.preventDefault()
              const step = e.key === "ArrowDown" ? 1 : -1
              this.highlight(options[Math.min(Math.max(index + step, 0), options.length - 1)])
              break
            }
            case "Enter":
              if (this.active) { e.preventDefault(); this.pick(this.active) }
              else if (this.input.value !== this.text) e.preventDefault()
              break
            case "Tab":
              if (this.active) this.pick(this.active)
              break
            case "Escape":
              e.preventDefault()
              e.stopPropagation()
              this.close()
              this.input.value = this.text
              break
          }
        },
        pick(option) {
          const create = option.hasAttribute("data-create")
          const text = create ? this.input.value.trim() : option.dataset.label
          this.choose(create ? (this.created ? "" : text) : option.dataset.value, create && this.created ? text : "", text)
          this.close()
        },
        leave() {
          if (!this.isOpen()) return
          this.close()
          if (this.input.value.trim() === "") this.choose("", "", "")
          else this.input.value = this.text
        },
        choose(value, created, text) {
          this.input.value = text
          this.text = text
          const changed = this.value.value !== value || (this.created && this.created.value !== created)
          this.value.value = value
          if (this.created) this.created.value = created
          if (changed) this.value.dispatchEvent(new Event("input", { bubbles: true }))
        },
        place() {
          const style = this.list.style
          if (NATIVE) return
          const box = this.input.closest(".input").getBoundingClientRect()
          style.minWidth = `max(16rem, ${box.width}px)`
          const width = this.list.offsetWidth
          const height = this.list.offsetHeight
          const vw = document.documentElement.clientWidth
          const below = box.bottom + GAP
          const above = box.top - GAP - height
          const top = below + height <= window.innerHeight - EDGE || above < EDGE ? below : above
          style.left = `${Math.max(EDGE, Math.min(box.left, vw - width - EDGE))}px`
          style.top = `${Math.max(EDGE, top)}px`
        }
      }
    </script>
    """
  end

  @doc """
  An option list for several `combobox/1`s (`options_from`), rendered once in a hidden `<div>`
  (not a `<template>`, whose content LiveView cannot patch): `id`, `options` and the `:option`
  slot as `combobox/1` takes them.
  """
  attr :id, :string, required: true
  attr :options, :list, required: true
  slot :option, doc: "an option's content, `:let={option}`"

  def combobox_options(assigns) do
    assigns = assign(assigns, :groups, combobox_groups(assigns.options, assigns.id))

    ~H"""
    <div id={@id} hidden>
      <.combobox_list groups={@groups} current={nil} slot={@option} />
    </div>
    """
  end

  attr :groups, :list, required: true
  attr :current, :any, required: true
  attr :slot, :list, required: true

  defp combobox_list(assigns) do
    ~H"""
    <%= for {group, options, group_id} <- @groups do %>
      <div :if={group} role="group" aria-labelledby={group_id}>
        <div id={group_id} class="setzkasten-option-group" role="presentation">{group}</div>
        <.combobox_option :for={option <- options} option={option} current={@current} slot={@slot} />
      </div>
      <.combobox_option
        :for={option <- options}
        :if={!group}
        option={option}
        current={@current}
        slot={@slot}
      />
    <% end %>
    """
  end

  attr :option, :map, required: true
  attr :current, :any, required: true
  attr :slot, :list, required: true

  defp combobox_option(assigns) do
    assigns =
      assign(assigns, :current?, to_string(assigns.option.value) == to_string(assigns.current))

    ~H"""
    <div
      id={@option.id}
      role="option"
      aria-selected="false"
      class="setzkasten-option"
      data-value={to_string(@option.value)}
      data-label={@option.label}
      data-key={Enum.join([@option.label, @option[:key]] |> Enum.reject(&is_nil/1), " ")}
      data-current={@current? && "true"}
    >
      <%= if @slot != [] do %>
        {render_slot(@slot, @option)}
      <% else %>
        <span class="min-w-0 flex-1 truncate">{@option.label}</span>
      <% end %>
      <.icon name="check" class="setzkasten-option-check size-4 shrink-0" />
    </div>
    """
  end

  # The options as `{group_label | nil, options, group_id}`, each option a map with its own id.
  defp combobox_groups(options, id) do
    options
    |> Enum.chunk_by(&match?({_, list} when is_list(list), &1))
    |> Enum.flat_map(fn
      [{_, list} | _] = groups when is_list(list) ->
        Enum.map(groups, fn {label, opts} -> {label, opts} end)

      plain ->
        [{nil, plain}]
    end)
    |> Enum.with_index()
    |> Enum.map_reduce(0, fn {{label, opts}, g}, n ->
      opts =
        opts
        |> Enum.with_index(n)
        |> Enum.map(fn {option, i} ->
          option |> combobox_option_map() |> Map.put(:id, "#{id}-option-#{i}")
        end)

      {{label, opts, "#{id}-group-#{g}"}, n + length(opts)}
    end)
    |> elem(0)
  end

  defp combobox_option_map({label, value}), do: %{label: label, value: value}
  defp combobox_option_map(%{label: _, value: _} = option), do: option

  defp combobox_text(groups, value, created, allow_create) do
    option =
      Enum.find_value(groups, fn {_, options, _} ->
        Enum.find(options, &(value not in [nil, ""] and to_string(&1.value) == to_string(value)))
      end)

    cond do
      option -> option.label
      created not in [nil, ""] -> created
      allow_create and value not in [nil, ""] -> to_string(value)
      true -> ""
    end
  end

  @upload_errors %{
    too_large: "Die Datei ist zu groß.",
    too_many_files: "Zu viele Dateien.",
    not_accepted: "Dieser Dateityp passt nicht.",
    external_client_failure: "Die Datei ließ sich nicht hochladen."
  }

  @doc """
  A drop zone around `live_file_input/1` (`phx-drop-target`): a label above, a dashed area with
  an upload icon, `drop_label` and the file input, then the inner block (e.g. the chosen
  entries with their progress), errors and help as `input/1` shows them.

  The file input is the control: Tab reaches it, Enter or Space opens the file dialog, and its
  accessible name is `label`. It is visually hidden; in its place the area shows a button
  (`button_label`, ringed while the input has keyboard focus) and the chosen file names, or
  `no_file_label`, instead of the browser's own text in the browser's language. The whole
  area is the input's label, so a click or tap anywhere in it opens the file dialog. While a
  file is dragged over it the border turns primary (`phx-drop-target-active`, set by LiveView).

  Errors come from the upload itself (`upload_errors/1`, also per entry), named by
  `error_labels` (German defaults for `:too_large`, `:too_many_files`, `:not_accepted` and
  `:external_client_failure`); `errors` replaces them with your own messages. Global attrs
  (`accept`, `required`, `disabled`, `capture`) go to the file input.

      <form id="import-form" phx-change="validate" phx-submit="import">
        <.file_drop upload={@uploads.statement} label="Kontoauszug" help="OFX oder QFX, höchstens 5 MB">
          <progress :for={e <- @uploads.statement.entries} class="progress" value={e.progress} max="100" />
        </.file_drop>
      </form>
  """
  attr :upload, Phoenix.LiveView.UploadConfig, required: true
  attr :label, :string, required: true
  attr :hide_label, :boolean, default: false
  attr :drop_label, :string, default: "Hierher ziehen oder auswählen"

  attr :button_label, :string,
    default: nil,
    doc: "„Datei auswählen“, or „Dateien auswählen“ when the upload takes several"

  attr :no_file_label, :string,
    default: nil,
    doc: "„Keine Datei ausgewählt“, or „Keine Dateien ausgewählt“ when the upload takes several"

  attr :help, :string, default: nil
  attr :errors, :list, default: nil, doc: "messages instead of the upload's own errors"

  attr :error_labels, :map,
    default: @upload_errors,
    doc: "messages for the upload's error atoms"

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(accept capture required disabled)
  slot :inner_block, doc: "below the zone, e.g. the chosen entries"

  def file_drop(assigns) do
    upload = assigns.upload
    labels = Map.merge(@upload_errors, assigns.error_labels)

    errors =
      assigns.errors ||
        (Phoenix.Component.upload_errors(upload) ++
           Enum.flat_map(upload.entries, &Phoenix.Component.upload_errors(upload, &1)))
        |> Enum.uniq()
        |> Enum.map(&(labels[&1] || labels.external_client_failure))

    several? = upload.max_entries > 1

    assigns =
      assign(assigns,
        errors: errors,
        describedby: field_describedby(upload.ref, errors, assigns.help),
        chosen: Enum.map_join(upload.entries, ", ", & &1.client_name),
        button_label:
          assigns.button_label || if(several?, do: "Dateien auswählen", else: "Datei auswählen"),
        no_file_label:
          assigns.no_file_label ||
            if(several?, do: "Keine Dateien ausgewählt", else: "Keine Datei ausgewählt")
      )

    ~H"""
    <fieldset class="fieldset min-w-0">
      <label for={@upload.ref} class={if @hide_label, do: "sr-only", else: "fieldset-legend"}>
        {@label}
      </label>
      <label
        for={@upload.ref}
        class={["setzkasten-file-drop", @errors != [] && "setzkasten-file-drop-error", @class]}
        phx-drop-target={@upload.ref}
      >
        <.icon name="upload" class="size-6 text-base-content/70" />
        <span class="text-sm" aria-hidden="true">{@drop_label}</span>
        <span class="flex max-w-full min-w-0 items-center gap-3" aria-hidden="true">
          <span class={[
            "btn setzkasten-file-drop-button shrink-0",
            @rest[:disabled] && "btn-disabled"
          ]}>
            {@button_label}
          </span>
          <span class={["min-w-0 truncate text-sm", @chosen == "" && "text-base-content/70"]}>
            {if @chosen == "", do: @no_file_label, else: @chosen}
          </span>
        </span>
        <.live_file_input
          upload={@upload}
          class="sr-only"
          aria-invalid={@errors != [] && "true"}
          aria-describedby={@describedby}
          {@rest}
        />
      </label>
      {render_slot(@inner_block)}
      <.field_error id={@upload.ref} errors={@errors} />
      <.field_help :if={@help} id={@upload.ref}>{@help}</.field_help>
    </fieldset>
    """
  end

  @doc """
  The error lines of a field, as `input` renders them: `circle-alert` icon, `error-ink`, first
  letter upper case, ids `<id>-error-0`, `<id>-error-1`, … For controls that are no `<.input>`
  (`live_file_input`, a custom picker); place it after the control inside a `fieldset.fieldset`
  and link the lines with `aria-describedby={field_describedby(id, errors, help)}`.

  `errors` takes messages or Ecto error tuples (translated like `input`'s); `field` takes its
  id and errors from a form field, shown after `used_input?/1`.

      <fieldset class="fieldset">
        <label for={@uploads.photo.ref} class="fieldset-legend">Foto</label>
        <.live_file_input upload={@uploads.photo}
          aria-describedby={field_describedby(@uploads.photo.ref, @photo_errors, true)} />
        <.field_error id={@uploads.photo.ref} errors={@photo_errors} />
        <.field_help id={@uploads.photo.ref}>JPEG oder PNG, höchstens 5 MB</.field_help>
      </fieldset>
  """
  attr :id, :any, default: nil, doc: "the control's id; taken from `field` when given"
  attr :field, Phoenix.HTML.FormField, doc: "a form field, e.g. `@form[:photo]`"
  attr :errors, :list, default: [], doc: "messages or `{msg, opts}` tuples"

  def field_error(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id, errors: errors)
    |> field_error()
  end

  def field_error(assigns) do
    assigns = assign(assigns, :messages, Enum.map(assigns.errors, &translate_error/1))

    ~H"""
    <p
      :for={{msg, i} <- Enum.with_index(@messages)}
      id={"#{@id}-error-#{i}"}
      class="flex items-center gap-1.5 text-sm text-error-ink"
    >
      <.icon name="circle-alert" class="size-4 shrink-0" />{upcase_first(msg)}
    </p>
    """
  end

  @doc """
  The help line of a field, as `input` renders it, with the id `<id>-help`. See `field_error/1`.
  `tone={:warning}` adds a `triangle-alert` icon and sets the text in full base-content (the
  warning fill is too faint as text). Global attrs (e.g. `aria-live`) land on the `<p>`.

      <.field_help id="iban" tone={:warning}>Konto ist noch nicht bestätigt</.field_help>
  """
  attr :id, :any, required: true, doc: "the control's id"
  attr :tone, :atom, default: nil, values: [nil, :warning]
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def field_help(assigns) do
    ~H"""
    <p
      id={"#{@id}-help"}
      class={["label whitespace-normal", @tone == :warning && "text-base-content", @class]}
      {@rest}
    >
      <.icon :if={@tone == :warning} name="triangle-alert" class="size-4 shrink-0" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  The `aria-describedby` value for a control with `errors` and, when `help` is truthy, a help
  line: the ids `field_error/1` and `field_help/1` render, or `nil`.
  """
  def field_describedby(id, errors, help) do
    ids =
      for({_, i} <- Enum.with_index(errors || []), do: "#{id}-error-#{i}") ++
        [help && "#{id}-help"]

    case Enum.reject(ids, &(&1 in [nil, false])) do
      [] -> nil
      ids -> Enum.join(ids, " ")
    end
  end

  # Error messages start like a sentence ("can't be blank" -> "Can't be blank"), as the labels do.
  defp upcase_first(msg) do
    {first, rest} = String.split_at(msg, 1)
    String.upcase(first) <> rest
  end

  @doc """
  Translates an Ecto error tuple with the configured translator, or fills in the bindings.
  """
  def translate_error({msg, opts} = error) do
    case Application.get_env(:setzkasten, :translate_error) do
      {module, fun} -> apply(module, fun, [error])
      nil -> Enum.reduce(opts, msg, &interpolate/2)
    end
  end

  def translate_error(msg) when is_binary(msg), do: msg

  defp interpolate({key, value}, msg),
    do: String.replace(msg, "%{#{key}}", fn _ -> to_string(value) end)

  @doc """
  The footer of a form: primary action at the end, cancel before it, destructive actions in
  `:secondary` at the start. Below `sm` the buttons are full width and stacked with the
  primary action on top. Its hairline sits 24px below the content and 16px above the buttons:
  a footer, set apart from the last field, not glued to it. In a grid or flex column it adds
  8px to the forms' `gap-4`. A margin in `class` (`mt-0`, `mt-8`) replaces these.

  `sticky` pins the bar to the bottom of the viewport, above the dock inside `<.app_shell>`.
  On phones it spans `main`'s side gutters so nothing shows through beside it; from `sm` the bar
  and its hairline align with the content edge, like tables and lists. It keeps 12px above and
  below the buttons on phones and 16px from `sm`, plus the home indicator
  (`safe-area-inset-bottom`) when no dock is below it. Below `sm` only cancel and primary
  stay pinned, side by side, and `:secondary` follows in a normal row after the bar, so a delete
  is not under the thumb all the time. `:secondary` renders once, so its buttons may carry ids;
  in a sticky bar it comes last in the DOM and tab order. Below `sm` outside a modal the sticky
  bar's element is `display: contents` and the pinned row takes `class` as well, so spacing
  like `mt-6` holds at every width.

  Inside a `<.modal>` the bar takes the dialog's surface (`bg-popover`), covers the box's
  bottom padding and keeps 16px above and below the buttons; a sticky bar pins to the box's
  bottom edge (through its padding) without the dock offset and keeps `:secondary` in a second
  row of the bar.

      <.action_bar sticky>
        <:secondary>
          <.button variant={:danger_outline} icon="trash-2" confirm="Post löschen?" phx-click="delete">
            Löschen
          </.button>
        </:secondary>
        <.button navigate={~p"/posts"}>Abbrechen</.button>
        <.button type="submit" variant={:primary} phx-disable-with="Speichert …">Speichern</.button>
      </.action_bar>
  """
  attr :sticky, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :secondary
  slot :inner_block, required: true

  def action_bar(assigns) do
    ~H"""
    <div
      class={[
        "setzkasten-action-bar flex gap-2 border-t border-base-content/10 bg-base-100",
        "sm:flex-row sm:items-center sm:justify-end",
        "[.modal-box_&]:bg-popover [.modal-box_&]:-mb-6 [.modal-box_&]:py-4",
        if(@sticky,
          do: [
            pinned_bar(),
            "max-sm:contents max-sm:[.modal-box_&]:flex max-sm:flex-wrap",
            "[.modal-box_&]:-mx-6 [.modal-box_&]:px-6 [.modal-box_&]:-bottom-6"
          ],
          else: "pt-4 flex-col-reverse max-sm:[&_.btn]:w-full"
        ),
        @class
      ]}
      {@rest}
    >
      <div
        :if={@secondary != [] and not @sticky}
        class="flex flex-col gap-2 sm:me-auto sm:flex-row"
      >
        {render_slot(@secondary)}
      </div>
      <%= if @sticky do %>
        <%!-- Pinned on its own on phone pages, where the outer bar is display: contents. --%>
        <div class={[
          "setzkasten-action-bar-pinned contents max-sm:flex max-sm:[.modal-box_&]:contents",
          "flex-wrap gap-2",
          "border-t border-base-content/10 bg-base-100 max-sm:[&>.btn]:flex-1",
          pinned_bar(),
          @class
        ]}>
          {render_slot(@inner_block)}
        </div>
        <div
          :if={@secondary != []}
          class={[
            "flex flex-col gap-2 sm:order-first sm:me-auto sm:flex-row max-sm:[&_.btn]:w-full",
            "max-sm:pt-4 max-sm:[.modal-box_&]:basis-full max-sm:[.modal-box_&]:pt-0"
          ]}
        >
          {render_slot(@secondary)}
        </div>
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </div>
    <script :type={ColocatedHook} name=".FocusInvalid">
      const CONTROLS = "input:not([type=hidden]), select, textarea, button"
      export default {
        mounted() {
          this.observer = new MutationObserver(() => {
            const wasLoading = this.loading
            this.loading = this.el.classList.contains("phx-submit-loading")
            if (!wasLoading || this.loading) return
            const invalid = this.el.querySelector('[aria-invalid="true"]')
            const target = invalid && (invalid.matches(CONTROLS) ? invalid : invalid.querySelector(CONTROLS))
            // LiveView puts focus back on the submitter after this, so the move waits a task.
            if (target) setTimeout(() => target.focus())
          })
          this.observer.observe(this.el, { attributes: true, attributeFilter: ["class"] })
        },
        destroyed() { this.observer.disconnect() }
      }
    </script>
    """
  end

  defp pinned_bar do
    [
      "sticky bottom-[var(--setzkasten-dock-offset,0px)] z-10",
      "max-sm:-mx-4 max-sm:px-4",
      "[--setzkasten-bar-pad:0.75rem] sm:[--setzkasten-bar-pad:1rem] pt-(--setzkasten-bar-pad)",
      "pb-[max(var(--setzkasten-bar-pad),calc(var(--setzkasten-bar-pad)_+_env(safe-area-inset-bottom)_-_var(--setzkasten-dock-offset,0px)))]"
    ]
  end
end
