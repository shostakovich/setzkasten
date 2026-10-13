defmodule Setzkasten.FormsTest do
  use Setzkasten.ComponentCase, async: false

  defp form(params, errors \\ []),
    do: to_form(params, as: :expense, errors: errors, action: :validate)

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

    doc = parse(~H|<.input name="t" id="t" type="toggle" label="An" />|)
    assert classes(doc, "input[type=checkbox]") == ~w(toggle toggle-primary)
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
             ~w(contents max-sm:flex max-sm:[.modal-box_&]:contents sticky mt-6),
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
end
