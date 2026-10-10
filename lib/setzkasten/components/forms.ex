defmodule Setzkasten.Components.Forms do
  @moduledoc "Form fields and the form footer."
  use Phoenix.Component
  import Setzkasten.Components.Icons

  @doc """
  A labelled form field: `fieldset.fieldset` > label > field > help > errors.

  Types: the HTML input types (`text`, `email`, `password`, `number`, `date`,
  `datetime-local`, `search`, `tel`, `url`, `hidden`, …) plus `select`, `textarea`,
  `checkbox`, `toggle` and `radio_group`.

  Errors from `field` show after the field was used (`used_input?/1`), with `aria-invalid`,
  the field border in `error-ink` and error lines linked by `aria-describedby`. Messages go
  through the function configured as `config :setzkasten, translate_error: {Mod, :fun}`
  (an app's Gettext `translate_error/1`); without it `%{count}`-style bindings are filled in.

  `class` lands on the field box (e.g. `max-w-40` for a narrow amount); `numeric` right-aligns
  the value with tabular figures and defaults `inputmode` to `decimal`.

      <.input field={@form[:amount]} label="Betrag" suffix="€" numeric class="max-w-40"
              help="Mit Komma, z. B. 87,42" />
      <.input field={@form[:category_id]} type="select" label="Kategorie" options={@categories}
              prompt="Bitte wählen" />
      <.input field={@form[:recurring]} type="checkbox" label="Jeden Monat wiederholen" />
      <.input field={@form[:split]} type="radio_group" label="Aufteilung"
              options={[{"Gleichmäßig", "equal"}, {"Nach Anteilen", "shares"}]} />
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
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
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
      <.field_help id={@id} help={@help} errors={@errors} />
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
      <.field_help id={@id} help={@help} errors={@errors} />
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
      <.field_help id={@id} help={@help} errors={@errors} />
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
      <.field_help id={@id} help={@help} errors={@errors} />
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
      <.field_label id={@id} label={@label} hide={@hide_label} />
      <label :if={@boxed} class={["input w-full", @errors != [] && "input-error", @class]}>
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
          @errors != [] && "input-error",
          @numeric && "text-end tabular-nums",
          @class
        ]}
        aria-invalid={@errors != [] && "true"}
        aria-describedby={@describedby}
        {@rest}
      />
      <.field_help id={@id} help={@help} errors={@errors} />
    </fieldset>
    """
  end

  defp prepare(assigns) do
    ids =
      [assigns.help && "#{assigns.id}-help"] ++
        for {_, i} <- Enum.with_index(assigns.errors), do: "#{assigns.id}-error-#{i}"

    assigns
    |> assign_new(:value, fn -> nil end)
    |> assign_new(:name, fn -> assigns.id end)
    |> assign_new(:options, fn -> [] end)
    |> assign(:describedby, ids |> Enum.reject(&is_nil/1) |> Enum.join(" ") |> blank_to_nil())
  end

  defp numeric_rest(%{numeric: true, rest: rest}), do: Map.put_new(rest, :inputmode, "decimal")
  defp numeric_rest(%{rest: rest}), do: rest

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

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

  attr :id, :any, required: true
  attr :help, :string, default: nil
  attr :errors, :list, default: []

  defp field_help(assigns) do
    ~H"""
    <p :if={@help} id={"#{@id}-help"} class="label whitespace-normal">{@help}</p>
    <p
      :for={{msg, i} <- Enum.with_index(@errors)}
      id={"#{@id}-error-#{i}"}
      class="flex items-center gap-1.5 text-sm text-error-ink"
    >
      <.icon name="circle-alert" class="size-4 shrink-0" />{msg}
    </p>
    """
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
  primary action on top; a `sticky` bar keeps primary and cancel side by side in one row and
  puts `:secondary` on a second row, so it covers less of the screen. `sticky` pins the bar to the bottom of the viewport (above the dock
  inside `<.app_shell>`).

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
        "flex gap-2 border-t border-base-content/10 bg-base-100 sm:flex-row sm:items-center",
        if(@sticky,
          do: [
            "sticky bottom-[var(--setzkasten-dock-offset,0px)] z-10 py-3",
            "max-sm:flex-wrap max-sm:[&>.btn]:flex-1"
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
          @sticky && "max-sm:order-last max-sm:basis-full max-sm:[&_.btn]:w-full"
        ]}
      >
        {render_slot(@secondary)}
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
