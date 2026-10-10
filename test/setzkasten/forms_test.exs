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

  test "errors stay hidden for unused fields" do
    assigns = %{form: to_form(%{}, as: :expense, errors: [title: {"leer", []}])}
    doc = parse(~H|<.input field={@form[:title]} label="Titel" />|)
    assert count(doc, "[aria-invalid]") == 0
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

  test "sticky action bar sits above the dock" do
    assigns = %{}
    doc = parse(~H|<.action_bar sticky><.button>OK</.button></.action_bar>|)
    assert "sticky" in classes(doc, "div")
    assert "bottom-[var(--setzkasten-dock-offset,0px)]" in classes(doc, "div")
  end
end
