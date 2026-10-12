defmodule Setzkasten.Components.Forms do
  @moduledoc "Form fields and the form footer."
  use Phoenix.Component
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

  `class` lands on the field box (e.g. `max-w-40` for a narrow amount); `numeric` right-aligns
  the value with tabular figures and defaults `inputmode` to `decimal`. `help_tone={:warning}`
  marks the help line as a warning (`triangle-alert` icon, full base-content text); it stays
  linked by `aria-describedby`.

  `inline` (text-like types) puts the field and the inner block, the form's button, in one
  `join` (stacked below `sm`) with the label for screen readers only; errors and help go below
  the join. The button takes `class="join-item"`.

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
  attr :prefix, :string, default: nil
  attr :suffix, :string, default: nil
  attr :icon, :string, default: nil, doc: "Lucide icon at the start of the field (search)"
  attr :numeric, :boolean, default: false
  attr :options, :list, doc: "options for select and radio_group"
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
    <div class="fieldset min-w-0">
      <label class="flex items-center gap-3 text-sm pointer-coarse:min-h-11">
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

    ~H"""
    <fieldset class="fieldset min-w-0" aria-describedby={@describedby}>
      <legend class={["fieldset-legend", @hide_label && "sr-only"]}>{@label}</legend>
      <label
        :for={{label, value} <- @options}
        class="flex items-center gap-3 text-sm pointer-coarse:min-h-11"
      >
        <input
          type="radio"
          id={"#{@id}_#{value}"}
          name={@name}
          value={value}
          checked={to_string(value) == to_string(@value)}
          class={["radio radio-primary", @class]}
          {@rest}
        />
        {label}
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
  primary action on top.

  `sticky` pins the bar to the bottom of the viewport, above the dock inside `<.app_shell>`.
  On phones it spans `main`'s side gutters so nothing shows through beside it; from `sm` the bar
  and its hairline align with the content edge, like tables and lists. It keeps 12px above and
  below the buttons on phones and 16px from `sm`, plus the home indicator
  (`safe-area-inset-bottom`) when no dock is below it. Below `sm` only cancel and primary
  stay pinned, side by side; `:secondary` renders a second time in a normal row after the bar,
  so a delete is not under the thumb all the time (give its buttons no `id`).

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
        "flex gap-2 border-t border-base-content/10 bg-base-100",
        "sm:flex-row sm:items-center sm:justify-end",
        "[.modal-box_&]:bg-popover [.modal-box_&]:-mb-6 [.modal-box_&]:py-4",
        if(@sticky,
          do: [
            "sticky bottom-[var(--setzkasten-dock-offset,0px)] z-10",
            "max-sm:-mx-4 max-sm:px-4",
            "[--setzkasten-bar-pad:0.75rem] sm:[--setzkasten-bar-pad:1rem] pt-(--setzkasten-bar-pad)",
            "pb-[max(var(--setzkasten-bar-pad),calc(var(--setzkasten-bar-pad)_+_env(safe-area-inset-bottom)_-_var(--setzkasten-dock-offset,0px)))]",
            "max-sm:flex-wrap max-sm:[&>.btn]:flex-1",
            "[.modal-box_&]:-mx-6 [.modal-box_&]:px-6 [.modal-box_&]:-bottom-6"
          ],
          else: "pt-4 flex-col-reverse max-sm:[&_.btn]:w-full"
        ),
        @class
      ]}
      {@rest}
    >
      <div
        :if={@secondary != []}
        class={[
          "flex flex-col gap-2 sm:me-auto sm:flex-row",
          @sticky &&
            "max-sm:hidden max-sm:[.modal-box_&]:flex max-sm:order-last max-sm:basis-full max-sm:[&_.btn]:w-full"
        ]}
      >
        {render_slot(@secondary)}
      </div>
      {render_slot(@inner_block)}
    </div>
    <div
      :if={@sticky and @secondary != []}
      class="flex flex-col gap-2 pt-4 sm:hidden [.modal-box_&]:hidden [&_.btn]:w-full"
    >
      {render_slot(@secondary)}
    </div>
    """
  end
end
