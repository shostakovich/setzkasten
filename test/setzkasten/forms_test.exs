defmodule Setzkasten.FormsTest do
  use Setzkasten.ComponentCase, async: false

  defp form(params, errors \\ []),
    do: to_form(params, as: :expense, errors: errors, action: :validate)

  test "a bare toggle lines up with a heading and keeps a 44px hit area on touch screens" do
    assigns = %{}
    doc = parse(~H|<.input name="auto" id="auto" type="toggle" label="Automatik" bare />|)

    assert count(doc, ".fieldset") == 0
    assert classes(doc, "div") == ~w(inline-flex min-w-0 flex-col)
    label = classes(doc, "label")
    refute "pointer-coarse:min-h-11" in label

    assert Enum.all?(
             ~w(relative pointer-coarse:after:absolute pointer-coarse:after:h-11
                pointer-coarse:after:min-w-11 pointer-coarse:after:left-1/2
                pointer-coarse:after:-translate-x-1/2),
             &(&1 in label)
           )

    refute "pointer-coarse:after:inset-x-0" in label

    assert attr(doc, "input[type=checkbox]", "role") == "switch"

    assert "pointer-coarse:min-h-11" in classes(
             parse(~H|<.input name="a" id="a" type="toggle" label="A" />|),
             "label"
           )
  end

  test "a shipped hook focuses the first invalid field once a submit comes back" do
    hook = colocated_js("Setzkasten.Components.Forms")
    assert hook =~ ~s|this.el.querySelector('[aria-invalid="true"]')|
    assert hook =~ ~s|this.loading = this.el.classList.contains("phx-submit-loading")|
    assert hook =~ ~s|if (!wasLoading \|\| this.loading) return|
    refute hook =~ ~s|addEventListener("submit"|
    assert hook =~ ~s|invalid.querySelector(CONTROLS)|
    assert hook =~ ~s|setTimeout(() => target.focus())|
  end

  test "a field with a visible label ends where a button beside it ends" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    assert css =~ ~r/  \.fieldset \{\s*padding-block: 0\.5rem 0;/

    assert css =~
             ~r/\.fieldset:has\(> :is\(label, legend\)\.sr-only:first-child\) \{\s*padding-block: 0;/
  end

  test "text input with label, help and describedby" do
    assigns = %{form: form(%{"title" => "Wocheneinkauf"})}
    doc = parse(~H|<.input field={@form[:title]} label="Titel" help="Kurz" />|)
    assert attr(doc, "label.fieldset-legend", "for") == "expense_title"
    assert classes(doc, "input") == ["input", "w-full"]
    assert attr(doc, "input", "value") == "Wocheneinkauf"
    assert attr(doc, "input", "aria-describedby") == "expense_title-help"
    assert text(doc, "#expense_title-help") == "Kurz"
  end

  test "errors show after use with error border, aria-invalid and translated message" do
    assigns = %{form: form(%{"amount" => "0"}, amount: {"muss größer als %{n} sein", [n: 0]})}

    doc =
      parse(
        ~H|<.input field={@form[:amount]} label="Betrag" suffix="€" numeric class="max-w-40" />|
      )

    assert classes(doc, "label.input") == ~w(input w-full input-error max-w-40)
    assert attr(doc, "input", "aria-invalid") == "true"
    assert attr(doc, "input", "inputmode") == "decimal"
    assert "tabular-nums" in classes(doc, "input")
    # Like the labels, the message starts as a sentence.
    assert text(doc, "#expense_amount-error-0") == "Muss größer als 0 sein"
    assert "text-error-ink" in classes(doc, "#expense_amount-error-0")
    assert text(doc, "label.input .label") == "€"
  end

  test "errors sit directly under the field, before the help, in the describedby order" do
    assigns = %{form: form(%{"title" => ""}, title: {"leer", []})}
    doc = parse(~H|<.input field={@form[:title]} label="Titel" help="Kurz" />|)
    ids = doc |> find("fieldset > p") |> LazyHTML.attribute("id")
    assert ids == ["expense_title-error-0", "expense_title-help"]
    assert attr(doc, "input", "aria-describedby") == "expense_title-error-0 expense_title-help"
  end

  test "errors stay hidden for unused fields" do
    assigns = %{form: to_form(%{}, as: :expense, errors: [title: {"leer", []}])}
    doc = parse(~H|<.input field={@form[:title]} label="Titel" />|)
    assert count(doc, "[aria-invalid]") == 0
  end

  test "field_error and field_help render like input's, for other controls" do
    assigns = %{}

    doc =
      parse(~H"""
      <fieldset class="fieldset">
        <input type="file" id="photo" />
        <.field_error id="photo" errors={["zu groß", {"höchstens %{n} Dateien", [n: 3]}]} />
        <.field_help id="photo">JPEG oder PNG</.field_help>
      </fieldset>
      """)

    ids = doc |> find("fieldset > p") |> LazyHTML.attribute("id")
    assert ids == ["photo-error-0", "photo-error-1", "photo-help"]
    assert text(doc, "#photo-error-0") == "Zu groß"
    assert text(doc, "#photo-error-1") == "Höchstens 3 Dateien"
    assert count(doc, "#photo-error-0 svg.lucide") == 1
    assert "text-error-ink" in classes(doc, "#photo-error-0")
    assert classes(doc, "#photo-help") == ~w(label whitespace-normal)

    assert field_describedby("photo", ["a", "b"], true) ==
             "photo-error-0 photo-error-1 photo-help"

    assert field_describedby("photo", [], nil) == nil
  end

  test "a file input with file-input-error takes the error-ink border" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    assert css =~
             ~r/:is\(\.input, \.select, \.textarea, \.file-input\):is\([^)]*\.file-input-error\) \{\s*--input-color: var\(--color-error-ink\);/
  end

  test "field_error takes id and errors from a used form field" do
    assigns = %{
      used: form(%{"photo" => ""}, photo: {"fehlt", []}),
      unused: to_form(%{}, as: :expense, errors: [photo: {"fehlt", []}])
    }

    assert text(parse(~H|<.field_error field={@used[:photo]} />|), "#expense_photo-error-0") ==
             "Fehlt"

    assert count(parse(~H|<.field_error field={@unused[:photo]} />|), "p") == 0
  end

  test "hide_label keeps the label for screen readers" do
    assigns = %{}
    doc = parse(~H|<.input name="q" id="q" label="Suchen" hide_label icon="search" />|)
    assert classes(doc, "label[for=q]") == ["sr-only"]
    assert count(doc, "label.input svg.lucide") == 1
  end

  test "select with prompt and selected option" do
    assigns = %{}

    doc =
      parse(~H"""
      <.input
        name="c"
        id="c"
        type="select"
        label="Kategorie"
        prompt="Bitte wählen"
        options={[{"A", "a"}, {"B", "b"}]}
        value="b"
      />
      """)

    assert classes(doc, "select") == ["select", "w-full"]
    assert text(doc, "option[value='']") == "Bitte wählen"
    assert attr(doc, "option[value=b]", "selected") != nil
  end

  test "checkbox and toggle send false when unchecked and wrap a 44px label row" do
    assigns = %{}
    doc = parse(~H|<.input name="r" id="r" type="checkbox" label="Wiederholen" value="true" />|)
    assert attr(doc, "input[type=hidden]", "value") == "false"
    assert classes(doc, "input[type=checkbox]") == ~w(checkbox checkbox-primary)
    assert attr(doc, "input[type=checkbox]", "checked") != nil
    assert "pointer-coarse:min-h-11" in classes(doc, "label")

    assert attr(doc, "input[type=checkbox]", "role") == nil

    doc = parse(~H|<.input name="t" id="t" type="toggle" label="An" />|)
    assert classes(doc, "input[type=checkbox]") == ~w(toggle toggle-primary)
    # The native checked state is the switch's on/off; an aria-checked would go stale.
    assert attr(doc, "input[type=checkbox]", "role") == "switch"
    assert attr(doc, "input[type=checkbox]", "aria-checked") == nil
  end

  test "checkbox and radio without a colour variant take the 50 % field border" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    assert css =~
             ~r/@layer utilities\.daisyui\.l1\.l2\.l3 \{[^@]*\.checkbox \{\s*border-color: var\(--input-color, color-mix\(in oklab, var\(--color-base-content\) 50%, #0000\)\);\s*\}\s*\.radio \{\s*border-color: var\(--input-color, color-mix\(in oklab, currentColor 50%, #0000\)\);/
  end

  test "checkbox hidden input follows the form attribute" do
    assigns = %{}
    doc = parse(~H|<.input name="r" id="r" type="checkbox" label="R" form="other" />|)
    assert attr(doc, "input[type=hidden]", "form") == "other"
    assert attr(doc, "input[type=checkbox]", "form") == "other"

    doc = parse(~H|<.input name="r" id="r" type="checkbox" label="R" />|)
    assert attr(doc, "input[type=hidden]", "form") == nil
  end

  test "radio group is a fieldset with legend" do
    assigns = %{}

    doc =
      parse(~H"""
      <.input
        name="s"
        id="s"
        type="radio_group"
        label="Aufteilung"
        value="b"
        options={[{"A", "a"}, {"B", "b"}]}
      />
      """)

    assert text(doc, "fieldset > legend") == "Aufteilung"
    assert count(doc, "input.radio.radio-primary") == 2
    assert attr(doc, "#s_b", "checked") != nil
    assert attr(doc, "fieldset", "role") == "radiogroup"
    assert attr(doc, "fieldset", "aria-invalid") == nil
    assert attr(doc, "#s_a", "aria-labelledby") == nil
    assert attr(doc, "#s_a", "aria-describedby") == nil

    doc =
      parse(~H"""
      <.input
        name="s"
        id="s"
        type="radio_group"
        label="Aufteilung"
        options={[{"A", "a"}]}
        errors={["muss gewählt sein"]}
      />
      """)

    assert attr(doc, "fieldset[role=radiogroup]", "aria-invalid") == "true"
  end

  test "a radio option's description sits under its label and describes the radio" do
    assigns = %{}

    doc =
      parse(~H"""
      <.input
        name="f"
        id="f"
        type="radio_group"
        label="Wie oft?"
        value="monthly"
        options={[
          %{label: "Monatlich", value: "monthly", description: "Nächster Termin 19.11.2026"},
          {"Jährlich", "yearly"}
        ]}
      />
      """)

    assert attr(doc, "#f_monthly", "aria-labelledby") == "f-option-0-label"
    assert attr(doc, "#f_monthly", "aria-describedby") == "f-option-0-description"
    assert text(doc, "#f-option-0-label") == "Monatlich"
    assert text(doc, "#f-option-0-description") == "Nächster Termin 19.11.2026"
    assert attr(doc, "#f_monthly", "checked") != nil
    assert attr(doc, "#f_yearly", "aria-describedby") == nil
    assert count(doc, "label.items-start") == 1
  end

  test "a radio option's value with a space still names and describes its radio" do
    assigns = %{}

    doc =
      parse(~H"""
      <.input
        name="f"
        id="f"
        type="radio_group"
        label="Wie oft?"
        options={[
          {"Monatlich", "monthly"},
          %{label: "Alle zwei Wochen", value: "every 2 weeks", description: "Am Montag"}
        ]}
      />
      """)

    radio = "input[value='every 2 weeks']"
    assert attr(doc, radio, "aria-labelledby") == "f-option-1-label"
    assert attr(doc, radio, "aria-describedby") == "f-option-1-description"
    assert text(doc, "#f-option-1-label") == "Alle zwei Wochen"
    assert text(doc, "#f-option-1-description") == "Am Montag"
  end

  test "textarea" do
    assigns = %{}
    doc = parse(~H|<.input name="n" id="n" type="textarea" label="Notiz" value="Hallo" />|)
    assert text(doc, "textarea.textarea") == "Hallo"
  end

  test "use Setzkasten leaves translate_error/1 to the app" do
    refute {:translate_error, 1} in __ENV__.functions[Setzkasten.Components.Forms]
    assert {:input, 1} in __ENV__.functions[Setzkasten.Components.Forms]
  end

  test "translate_error uses the configured translator" do
    Application.put_env(:setzkasten, :translate_error, {__MODULE__, :shout})
    on_exit(fn -> Application.delete_env(:setzkasten, :translate_error) end)
    assert Setzkasten.Components.Forms.translate_error({"leer", []}) == "LEER"
  end

  def shout({msg, _}), do: String.upcase(msg)

  test "action bar orders secondary first in the DOM and stacks reversed on phones" do
    assigns = %{}

    doc =
      parse(~H"""
      <.action_bar>
        <:secondary><.button variant={:danger}>Löschen</.button></:secondary>
        <.button>Abbrechen</.button>
        <.button variant={:primary}>Speichern</.button>
      </.action_bar>
      """)

    assert "flex-col-reverse" in classes(doc, "div")
    assert doc |> find("button") |> LazyHTML.text() =~ ~r/Löschen.*Abbrechen.*Speichern/s
    assert Enum.all?(~w(setzkasten-action-bar border-t pt-4), &(&1 in classes(doc, "div")))
    refute "mt-6" in classes(doc, "div")
  end

  test "the action bar's margins sit in a layer that a margin utility in its class beats" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    assert css =~
             ~r/@layer utilities\.setzkasten \{\s*\.setzkasten-action-bar,\s*\.setzkasten-action-bar-pinned \{\s*margin-top: 1\.5rem;\s*\}\s*:is\(\.grid, \.flex\) > \.setzkasten-action-bar,\s*:is\(\.grid, \.flex\) > \* > \.setzkasten-action-bar-pinned \{\s*margin-top: 0\.5rem;/
  end

  test "sticky action bar sits above the dock and spans the page gutters on phones only" do
    assigns = %{}
    doc = parse(~H|<.action_bar sticky><.button>OK</.button></.action_bar>|)
    bar = classes(doc, "div")
    assert "sticky" in bar
    assert "bottom-[var(--setzkasten-dock-offset,0px)]" in bar
    assert Enum.all?(~w(max-sm:-mx-4 max-sm:px-4), &(&1 in bar))
    refute Enum.any?(bar, &(&1 =~ ~r/^(sm|lg):-mx-/))
    # 12px on phones, 16px from sm; the home indicator only counts without a dock below.
    assert Enum.all?(
             ~w([--setzkasten-bar-pad:0.75rem] sm:[--setzkasten-bar-pad:1rem]),
             &(&1 in bar)
           )

    assert Enum.any?(bar, &(&1 =~ "env(safe-area-inset-bottom)_-_var(--setzkasten-dock-offset"))
    refute "max-sm:-mx-4" in classes(parse(~H|<.action_bar>x</.action_bar>|), "div")
  end

  test "a sticky bar pins cancel and primary on their own on phones, the secondary after them" do
    assigns = %{}

    doc =
      parse(~H"""
      <form>
        <.action_bar sticky class="mt-6">
          <:secondary><.button variant={:danger}>Löschen</.button></:secondary>
          <.button>Abbrechen</.button>
        </.action_bar>
      </form>
      """)

    assert count(doc, "button") == 2

    assert Enum.all?(
             ~w(max-sm:contents max-sm:[.modal-box_&]:flex),
             &(&1 in classes(doc, "form > div"))
           )

    pinned = classes(doc, "form > div > div:first-child")

    assert Enum.all?(
             ~w(setzkasten-action-bar-pinned contents max-sm:flex max-sm:[.modal-box_&]:contents sticky mt-6),
             &(&1 in pinned)
           )

    assert text(doc, "form > div > div:first-child") == "Abbrechen"

    secondary = classes(doc, "form > div > div:last-child")

    assert Enum.all?(
             ~w(sm:order-first sm:me-auto max-sm:[.modal-box_&]:basis-full),
             &(&1 in secondary)
           )

    assert text(doc, "form > div > div:last-child") == "Löschen"

    doc =
      parse(~H"""
      <form>
        <.action_bar>
          <:secondary><.button variant={:danger}>Löschen</.button></:secondary>
          <.button>Abbrechen</.button>
        </.action_bar>
      </form>
      """)

    assert count(doc, "button") == 2
    assert text(doc, "form > div > div:first-child") == "Löschen"
    refute "max-sm:contents" in classes(doc, "form > div")
  end

  test "secondary buttons with an id render once, on a page and in a dialog" do
    for sticky <- [true, false] do
      assigns = %{sticky: sticky}

      doc =
        parse(~H"""
        <form>
          <.action_bar sticky={@sticky}>
            <:secondary><.button id="delete">Löschen</.button></:secondary>
            <.button type="submit">Speichern</.button>
          </.action_bar>
        </form>
        <.modal id="dialog">
          <.action_bar sticky={@sticky}>
            <:secondary><.button id="discard">Verwerfen</.button></:secondary>
            <.button type="submit">Speichern</.button>
          </.action_bar>
        </.modal>
        """)

      assert count(doc, "#delete") == 1
      assert count(doc, ".modal-box #discard") == 1
      assert count(doc, "#discard") == 1
    end
  end

  test "a fieldset whose label is for screen readers only has no block padding" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    assert css =~
             ~r/\.fieldset:has\(> :is\(label, legend\)\.sr-only:first-child\) \{\s*padding-block: 0;/

    assigns = %{}

    doc =
      parse(~H|<.input name="q" id="q" type="search" label="Suchen" hide_label icon="search" />|)

    assert classes(doc, "fieldset > :first-child") == ["sr-only"]
  end

  test "a warning help line has an icon, full text colour and stays described" do
    assigns = %{}

    doc =
      parse(
        ~H|<.input name="iban" id="iban" label="IBAN" help="Nicht bestätigt" help_tone={:warning} />|
      )

    assert attr(doc, "input", "aria-describedby") == "iban-help"
    assert count(doc, "#iban-help svg.lucide") == 1
    assert "text-base-content" in classes(doc, "#iban-help")
    assert text(doc, "#iban-help") == "Nicht bestätigt"

    doc = parse(~H|<.input name="t" id="t" label="Titel" help="Kurz" />|)
    assert count(doc, "#t-help svg") == 0
    assert classes(doc, "#t-help") == ~w(label whitespace-normal)
  end

  test "field_help takes the warning tone and global attrs" do
    assigns = %{}

    doc =
      parse(~H"""
      <.field_help id="photo" tone={:warning} aria-live="polite" class="mt-1">Groß</.field_help>
      """)

    assert attr(doc, "#photo-help", "aria-live") == "polite"
    assert count(doc, "#photo-help svg.lucide") == 1
    assert classes(doc, "#photo-help") == ~w(label whitespace-normal text-base-content mt-1)
  end

  test "inline input joins the field and its button, errors below the join" do
    assigns = %{form: form(%{"name" => ""}, name: {"leer", []})}

    doc =
      parse(~H"""
      <.input field={@form[:name]} label="Neue Kategorie" help="Kurz" inline placeholder="z. B. Haus">
        <.button type="submit" class="join-item">Hinzufügen</.button>
      </.input>
      """)

    assert classes(doc, "label[for=expense_name]") == ["sr-only"]
    assert classes(doc, "fieldset > div") == ~w(join max-sm:join-vertical w-full)
    assert classes(doc, ".join > input") == ~w(input w-full join-item input-error)
    assert attr(doc, ".join > input", "placeholder") == "z. B. Haus"
    assert text(doc, ".join > button") == "Hinzufügen"
    ids = doc |> find("fieldset > p") |> LazyHTML.attribute("id")
    assert ids == ["expense_name-error-0", "expense_name-help"]
    assert attr(doc, "input", "aria-describedby") == "expense_name-error-0 expense_name-help"
    assert attr(doc, "input", "aria-invalid") == "true"
  end

  test "inline input with a boxed field" do
    assigns = %{}

    doc =
      parse(~H"""
      <.input name="q" id="q" label="Suchen" icon="search" inline>
        <.button class="join-item">Los</.button>
      </.input>
      """)

    assert "join-item" in classes(doc, ".join > label.input")
    assert count(doc, ".join > label.input input#q") == 1
  end

  test "action bar takes the dialog surface and spans the dialog padding when sticky" do
    assigns = %{}
    doc = parse(~H|<.action_bar sticky><.button>OK</.button></.action_bar>|)
    assert "[.modal-box_&]:bg-popover" in classes(doc, "div")
    assert "[.modal-box_&]:-mx-6" in classes(doc, "div")
    # The box padding insets the sticky edge; the bar pins to the box's bottom edge instead.
    assert "[.modal-box_&]:-bottom-6" in classes(doc, "div")
    refute "[.modal-box_&]:-bottom-6" in classes(parse(~H|<.action_bar>x</.action_bar>|), "div")
    assert "[.modal-box_&]:bg-popover" in classes(parse(~H|<.action_bar>x</.action_bar>|), "div")

    # The dock offset does not reach into a dialog.
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    assert css =~ ~r/\.modal-box \{\s*--setzkasten-dock-offset: 0px;/
  end

  test "action bar puts the primary at the end and balances its padding in a dialog" do
    assigns = %{}
    doc = parse(~H|<.action_bar><.button>OK</.button></.action_bar>|)
    bar = classes(doc, "div")
    assert "sm:justify-end" in bar
    assert Enum.all?(~w([.modal-box_&]:-mb-6 [.modal-box_&]:py-4), &(&1 in bar))

    doc = parse(~H|<.action_bar sticky><.button>OK</.button></.action_bar>|)

    assert Enum.all?(
             ~w(sm:justify-end [.modal-box_&]:-mb-6 [.modal-box_&]:py-4),
             &(&1 in classes(doc, "div"))
           )
  end

  test "combobox: a labelled combobox field, a hidden field with the value, a listbox popover" do
    assigns = %{form: to_form(%{"category" => "food"}, as: :tx)}

    doc =
      parse(~H"""
      <.combobox
        field={@form[:category]}
        label="Kategorie"
        placeholder="Suchen"
        required
        options={[{"Miete", "rent"}, {"Lebensmittel", "food"}]}
      />
      """)

    assert attr(doc, "label[for=tx_category]", "class") == "fieldset-legend"
    input = "input#tx_category"
    assert attr(doc, input, "role") == "combobox"
    assert attr(doc, input, "aria-autocomplete") == "list"
    assert attr(doc, input, "aria-expanded") == "false"
    assert attr(doc, input, "aria-controls") == "tx_category-listbox"
    assert attr(doc, input, "autocomplete") == "off"
    assert attr(doc, input, "name") == nil
    assert attr(doc, input, "required") != nil
    assert attr(doc, input, "value") == "Lebensmittel"
    assert attr(doc, input, "placeholder") == "Suchen"
    value = "input[data-value-input]"
    assert attr(doc, value, "name") == "tx[category]"
    assert attr(doc, value, "value") == "food"
    assert attr(doc, value, "hidden") != nil
    assert attr(doc, value, "autocomplete") == "off"

    assert attr(doc, "#tx_category-combobox", "phx-hook") ==
             "Setzkasten.Components.Forms.Combobox"

    assert attr(doc, "#tx_category-combobox", "data-text") == "Lebensmittel"
    assert "setzkasten-combobox" in classes(doc, "#tx_category-combobox")
    assert "input" in classes(doc, "#tx_category-combobox > label")

    listbox = "#tx_category-listbox"
    assert attr(doc, listbox, "role") == "listbox"
    assert attr(doc, listbox, "popover") == "manual"
    assert attr(doc, listbox, "phx-mounted") == nil
    assert attr(doc, listbox, "aria-label") == "Kategorie"
    assert attr(doc, "#tx_category-option-0", "role") == "option"
    assert attr(doc, "#tx_category-option-0", "aria-selected") == "false"
    assert attr(doc, "#tx_category-option-0", "data-value") == "rent"
    assert attr(doc, "#tx_category-option-0", "data-label") == "Miete"
    # The chosen option carries a check.
    assert attr(doc, "#tx_category-option-1", "data-current") == "true"
    assert attr(doc, "#tx_category-option-0", "data-current") == nil
    # Every option keeps the check's room; CSS shows it on the chosen one only.
    assert count(doc, "[role=option] svg.setzkasten-option-check") == 2
    assert text(doc, "#{listbox} [data-empty]") == "Keine Treffer"
    assert attr(doc, "#{listbox} [data-empty]", "hidden") != nil
    assert count(doc, "[data-create]") == 0
  end

  test "combobox groups, extra search text and the option slot" do
    assigns = %{}

    doc =
      parse(~H"""
      <.combobox
        id="c"
        name="c"
        label="Kategorie"
        options={[
          {"Fixkosten", [%{label: "Miete", value: 1, key: "Wohnung", note: "fix"}]},
          {"Alltag", [{"Lebensmittel", 2}, {"Drogerie", 3}]}
        ]}
      >
        <:option :let={option}><b>{option.label}</b><i>{option[:note]}</i></:option>
      </.combobox>
      """)

    assert attr(doc, "[role=group]:first-child", "aria-labelledby") == "c-group-0"
    assert text(doc, "#c-group-0") == "Fixkosten"
    assert attr(doc, "#c-group-0", "role") == "presentation"
    assert count(doc, "[role=group]:has(#c-group-1) [role=option]") == 2
    assert attr(doc, "#c-option-0", "data-key") == "Miete Wohnung"
    assert text(doc, "#c-option-0 i") == "fix"
    assert attr(doc, "#c-option-2", "data-value") == "3"
    assert attr(doc, "input#c", "value") == ""

    # As the form sends them: nil empty, false as "false", never a missing data-value.
    doc =
      parse(~H"""
      <.combobox id="n" name="n" label="K" options={[{"Keine", nil}, {"Nein", false}]} />
      """)

    assert attr(doc, "#n-option-0", "data-value") == ""
    assert attr(doc, "#n-option-1", "data-value") == "false"
  end

  test "combobox create entry: German default, the text as value or in create_field" do
    assigns = %{form: to_form(%{"payee" => "Neu GmbH", "new" => "Bargeld"}, as: :tx)}

    doc =
      parse(~H"""
      <.combobox field={@form[:payee]} label="Empfänger" options={[{"Bäcker", "Bäcker"}]} allow_create />
      """)

    assert attr(doc, "[data-create]", "role") == "option"
    assert attr(doc, "[data-create]", "hidden") != nil
    assert text(doc, "[data-create] span") == "„“ anlegen"
    assert count(doc, "[data-create] [data-create-text]") == 1
    # A name field: a value that matches no option is its own text.
    assert attr(doc, "input#tx_payee", "value") == "Neu GmbH"
    assert count(doc, "[data-create-input]") == 0

    doc =
      parse(~H"""
      <.combobox
        field={@form[:account]}
        label="Konto"
        options={[{"Giro", "1"}]}
        allow_create
        create_label="Konto %{text} hinzufügen"
        create_field={@form[:new]}
        form="other"
      />
      """)

    assert text(doc, "[data-create] span") == "Konto  hinzufügen"
    assert attr(doc, "[data-create-input]", "name") == "tx[new]"
    assert attr(doc, "[data-create-input]", "form") == "other"
    assert attr(doc, "[data-value-input]", "form") == "other"
    # The text field belongs to the form too, so Enter in it submits (implicit submission).
    assert attr(doc, "input#tx_account", "form") == "other"
    assert attr(doc, "input#tx_account", "name") == nil
    assert attr(doc, "input#tx_account", "value") == "Bargeld"
  end

  test "combobox errors wait until the value field was used, as LiveView's client reports it" do
    # LiveView sends _unused_ only for a field that is not type="hidden" and not yet changed.
    assigns = %{}
    doc = parse(~H|<.combobox id="c" name="c" label="K" options={[]} />|)
    assert attr(doc, "input[data-value-input]", "type") == "text"

    live_view = Application.app_dir(:phoenix_live_view, "priv/static/phoenix_live_view.esm.js")
    assert File.read!(live_view) =~ ~s|const isHidden = input.type === "hidden";|

    params = %{"category" => "", "_unused_category" => ""}
    errors = [category: {"can't be blank", []}]
    assigns = %{form: to_form(params, as: :tx, errors: errors, action: :validate)}
    doc = parse(~H|<.combobox field={@form[:category]} label="K" options={[]} />|)
    assert count(doc, "#tx_category-error-0") == 0

    assigns = %{form: to_form(%{"category" => ""}, as: :tx, errors: errors, action: :validate)}
    doc = parse(~H|<.combobox field={@form[:category]} label="K" options={[]} />|)
    assert count(doc, "#tx_category-error-0") == 1
  end

  test "combobox without field or id raises" do
    assigns = %{}

    assert_raise ArgumentError, ~r/needs a field or an id/, fn ->
      parse(~H|<.combobox name="c" label="K" options={[]} />|)
    end
  end

  test "combobox errors and help as input shows them" do
    assigns = %{}

    doc =
      parse(~H"""
      <.combobox id="c" name="c" label="K" options={[]} errors={["muss gewählt sein"]} help="Hilfe" />
      """)

    assert attr(doc, "input#c", "aria-invalid") == "true"
    assert attr(doc, "input#c", "aria-describedby") == "c-error-0 c-help"
    assert "input-error" in classes(doc, "#c-combobox > label")
    assert text(doc, "#c-error-0") == "Muss gewählt sein"
  end

  test "the combobox hook filters loosely, keeps typing out of phx-change and fires a choice" do
    hook = colocated_js("Setzkasten.Components.Forms")
    assert hook =~ ~s|.normalize("NFKD").replace(/\\p{M}/gu, "")|
    assert hook =~ ~s|.replace(/ß/g, "ss")|
    assert hook =~ "if (e.target === this.input) e.stopPropagation()"
    assert hook =~ ~s|this.value.dispatchEvent(new Event("input", { bubbles: true }))|
    # Placed after filtering, at the list's final height; at least 16rem wide as in CSS.
    assert hook =~ ~r/visible\[0\]\)\s*if \(this.isOpen\(\)\) this.place\(\)\s*\},/
    # A patch while the list is open keeps the arrow-key highlight on an option still shown.
    assert hook =~
             ~r/if \(!this.isOpen\(\)\) return\s*const active = this.active && this.active.id\s*this.filter\(/

    assert hook =~
             ~r/const kept = active && this.options\(\).find\(\(option\) => option.id === active\)\s*if \(kept\) this.highlight\(kept\)/

    assert hook =~ "style.minWidth = `max(16rem, ${box.width}px)`"
    # Escape closes the list only, not a popover or dialog around it.
    assert hook =~ ~r/case "Escape":\s*e.preventDefault\(\)\s*e.stopPropagation\(\)/
    assert hook =~ ~r/case "Tab":\s*if \(this.active\) this.pick\(this.active\)/
    # Enter on a text that matches nothing does not submit the old value under it.
    assert hook =~ "else if (this.input.value !== this.text) e.preventDefault()"
    # A server-set value reaches a focused field the user has not typed in.
    assert hook =~
             ~r/const typed = this.input.value !== this.text\s*this.text = text\s*(\/\/[^\n]*\s*)?if \(document.activeElement !== this.input \|\| !typed\) \{\s*this.input.value = text\s*if \(this.isOpen\(\)\) this.input.select\(\)/

    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    assert css =~ ~r/\.setzkasten-combobox \{\s*anchor-scope: --setzkasten-combobox;/
    assert css =~ "min-width: max(16rem, anchor-size(width));"

    assert css =~
             ~r/\.setzkasten-option\[aria-selected="true"\] \{[^}]*outline: 2px solid var\(--color-primary\);/

    assert css =~
             ~r/@media \(pointer: coarse\) \{\s*\.setzkasten-option \{\s*min-height: 2.75rem;/
  end

  defp upload(errors \\ []) do
    conf =
      Phoenix.LiveView.UploadConfig.build(:statement, "phx-up", accept: ~w(.csv), max_entries: 1)

    %{conf | errors: Enum.map(errors, &{"phx-up", &1})}
  end

  test "file_drop: a labelled drop target around the file input" do
    assigns = %{upload: upload()}

    doc =
      parse(~H"""
      <.file_drop upload={@upload} label="Kontoauszug" help="OFX, höchstens 5 MB" required />
      """)

    assert text(doc, "label.fieldset-legend[for=phx-up]") == "Kontoauszug"
    zone = "label.setzkasten-file-drop"
    assert attr(doc, zone, "for") == "phx-up"
    assert attr(doc, zone, "phx-drop-target") == "phx-up"
    assert text(doc, "#{zone} > span.text-sm[aria-hidden]") == "Hierher ziehen oder auswählen"
    assert count(doc, "#{zone} svg.lucide") == 1
    input = "#{zone} input[type=file]#phx-up"
    assert attr(doc, input, "accept") == ".csv"
    assert attr(doc, input, "required") != nil
    assert attr(doc, input, "aria-describedby") == "phx-up-help"
    assert attr(doc, input, "aria-invalid") == nil
    assert text(doc, "#phx-up-help") == "OFX, höchstens 5 MB"
    assert count(doc, "[id^=phx-up-error]") == 0
  end

  test "file_drop hides the browser's own file text behind a German button and the chosen name" do
    assigns = %{upload: upload()}

    doc = parse(~H|<.file_drop upload={@upload} label="Kontoauszug" />|)
    zone = "label.setzkasten-file-drop"
    assert classes(doc, "#{zone} > input[type=file]#phx-up") == ["sr-only"]
    assert count(doc, "#{zone} > span:not([aria-hidden=true])") == 0
    assert text(doc, "#{zone} .setzkasten-file-drop-button") == "Datei auswählen"
    assert "btn" in classes(doc, "#{zone} .setzkasten-file-drop-button")
    assert text(doc, "#{zone} .setzkasten-file-drop-button + span") == "Keine Datei ausgewählt"

    entry = %Phoenix.LiveView.UploadEntry{ref: "0", upload_ref: "phx-up", client_name: "okt.csv"}
    assigns = %{upload: %{upload() | entries: [entry]}}

    doc =
      parse(~H"""
      <.file_drop upload={@upload} label="Datei" button_label="Wählen" no_file_label="Nichts" disabled />
      """)

    assert text(doc, ".setzkasten-file-drop-button") == "Wählen"
    assert text(doc, ".setzkasten-file-drop-button + span") == "okt.csv"
    assert "btn-disabled" in classes(doc, ".setzkasten-file-drop-button")

    several = %{upload() | max_entries: 3}
    assigns = %{upload: several}
    doc = parse(~H|<.file_drop upload={@upload} label="Belege" />|)
    assert text(doc, ".setzkasten-file-drop-button") == "Dateien auswählen"
    assert text(doc, ".setzkasten-file-drop-button + span") == "Keine Dateien ausgewählt"

    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    assert css =~
             ~r/\.setzkasten-file-drop:has\(> input:focus-visible\) \.setzkasten-file-drop-button \{\s*outline: 2px solid var\(--color-primary\);/
  end

  test "file_drop names the upload's errors in German, overridable" do
    assigns = %{upload: upload([:too_large, :too_many_files, :mystery])}

    doc = parse(~H|<.file_drop upload={@upload} label="Datei" />|)
    assert text(doc, "#phx-up-error-0") == "Die Datei ist zu groß."
    assert text(doc, "#phx-up-error-1") == "Zu viele Dateien."
    assert text(doc, "#phx-up-error-2") == "Die Datei ließ sich nicht hochladen."
    input = "input[type=file]"
    assert attr(doc, input, "aria-invalid") == "true"
    assert attr(doc, input, "aria-describedby") == "phx-up-error-0 phx-up-error-1 phx-up-error-2"
    assert "setzkasten-file-drop-error" in classes(doc, "label.setzkasten-file-drop")

    doc =
      parse(~H"""
      <.file_drop upload={@upload} label="Datei" error_labels={%{too_large: "Größer als 5 MB."}} />
      """)

    assert text(doc, "#phx-up-error-0") == "Größer als 5 MB."
    assert text(doc, "#phx-up-error-1") == "Zu viele Dateien."

    doc =
      parse(
        ~H|<.file_drop upload={@upload} label="Datei" errors={["Bitte erst ein Konto wählen"]} />|
      )

    assert count(doc, "[id^=phx-up-error]") == 1
    assert text(doc, "#phx-up-error-0") == "Bitte erst ein Konto wählen"
  end

  test "file_drop turns primary while a file is dragged over it" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    assert css =~
             ~r/\.setzkasten-file-drop\.phx-drop-target-active \{\s*border-style: solid;\s*border-color: var\(--color-primary\);/
  end

  test "comboboxes share one option list rendered once" do
    assigns = %{options: [{"Alltag", [{"Lebensmittel", "food"}, {"Drogerie", "drug"}]}]}

    doc =
      parse(~H"""
      <.combobox_options id="cats" options={@options} />
      <.combobox
        :for={i <- 1..2}
        id={"part-#{i}"}
        name={"part[#{i}]"}
        label="Kategorie"
        value="drug"
        options_from="cats"
        options={[{"Drogerie", "drug"}]}
      />
      """)

    # A hidden div, not a <template>: LiveView patches its options like any other markup.
    assert count(doc, "template") == 0
    assert attr(doc, "div#cats", "hidden") != nil
    assert count(doc, "[role=option]") == 2
    assert count(doc, "#cats [role=option]") == 2
    assert count(doc, "#part-1-listbox [data-options][phx-update=ignore]#part-1-options") == 1
    assert attr(doc, "#part-1-combobox", "data-options-from") == "cats"
    assert attr(doc, "input#part-2", "value") == "Drogerie"

    assert attr(doc, "#cats [role=group] #cats-option-0", "data-value") == "food"

    hook = colocated_js("Setzkasten.Components.Forms")

    assert hook =~
             "this.shared.replaceChildren(...[...source.children].map((child) => child.cloneNode(true)))"

    assert hook =~ "option.id = `${prefix}-option-${i}`"
    assert hook =~ ~s|if (this.shared) this.shared.replaceChildren()|

    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    assert css =~
             ~r/\.setzkasten-option:not\(\[data-current\]\) > \.setzkasten-option-check \{\s*visibility: hidden;/
  end
end
