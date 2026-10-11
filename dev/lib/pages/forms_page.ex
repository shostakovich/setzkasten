defmodule Setzkasten.Dev.Pages.FormsPage do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  import Setzkasten.Dev.Demo

  def title, do: "Formulare"
  def summary, do: "input, field_error, field_help, action_bar, Formular mit Fehlern, Inline"

  @initial %{
    "title" => "",
    "amount" => "0,00",
    "date" => "2026-10-07",
    "payer" => "jonas",
    "category" => "food",
    "split" => "equal",
    "recurring" => "true",
    "note" => ""
  }

  def build_form(params, action \\ :validate) do
    params = Map.merge(@initial, params)
    errors = if action, do: validate(params), else: []
    to_form(params, as: :expense, errors: errors, action: action)
  end

  defp validate(params) do
    title = if String.trim(params["title"]) == "", do: [title: {"darf nicht leer sein", []}]
    amount = parse_amount(params["amount"])

    amount =
      if amount <= 0,
        do: [amount: {"muss größer als %{number} sein", [number: 0]}]

    (title || []) ++ (amount || [])
  end

  defp parse_amount(value) do
    case Float.parse(String.replace(value || "", ",", ".")) do
      {number, _} -> number
      :error -> 0
    end
  end

  def render(assigns) do
    assigns =
      assign(assigns,
        payers: [{"Jonas", "jonas"}, {"Dana", "dana"}, {"Kim", "kim"}],
        categories: [{"Lebensmittel", "food"}, {"Essen gehen", "dining"}, {"Wohnen", "home"}]
      )

    ~H"""
    <.showcase id="input" name="<.input>" title="Formularfeld" code={code(0)}>
      <:intro>
        Text, Zahl, Datum, Auswahl, Textfeld, Checkbox, Schalter, Radiogruppe. Label oben,
        Hinweis darunter, Fehler zuletzt.
      </:intro>
      <.demo title="Typen" class="grid gap-4 md:grid-cols-2">
        <.input
          name="d[title]"
          id="d-title"
          label="Titel"
          value="Wocheneinkauf"
          help="Erscheint in der Liste und im Verlauf."
        />
        <.input
          name="d[amount]"
          id="d-amount"
          label="Betrag"
          value="87,42"
          suffix="€"
          numeric
          class="max-w-40"
          help="Mit Komma, z. B. 87,42"
        />
        <.input name="d[shares]" id="d-shares" label="Stück" value="95" suffix="Anteile" numeric />
        <.input name="d[date]" id="d-date" type="date" label="Datum" value="2026-10-07" />
        <.input
          name="d[category]"
          id="d-category"
          type="select"
          label="Kategorie"
          options={@categories}
          value="food"
          prompt="Bitte wählen"
        />
        <.input
          name="q"
          id="d-search"
          type="search"
          label="Wertpapier suchen"
          hide_label
          icon="search"
          placeholder="Name oder ISIN"
        />
        <div class="md:col-span-2">
          <.input
            name="d[note]"
            id="d-note"
            type="textarea"
            label="Notiz"
            rows="3"
            value="Inklusive Pfand, Bon liegt im Ordner."
          />
        </div>
      </.demo>
      <.demo title="Zustände" class="grid gap-4 md:grid-cols-2">
        <.input name="s[ph]" id="s-ph" label="Leer mit Platzhalter" placeholder="z. B. Wocheneinkauf" />
        <.input name="s[err]" id="s-err" label="Fehler" value="" errors={["darf nicht leer sein"]} />
        <.input name="s[dis]" id="s-dis" label="Deaktiviert" value="Referenzkonto · EUR" disabled />
        <.input
          name="s[warn]"
          id="s-warn"
          label="Hinweis als Warnung (help_tone={:warning})"
          value="DE02 1203 0000 0000 2020 51"
          help="Dieses Konto ist noch nicht bestätigt."
          help_tone={:warning}
        />
        <.input
          name="s[sel]"
          id="s-sel"
          type="select"
          label="Auswahl mit Fehler"
          options={[]}
          prompt="Bitte wählen"
          errors={["muss ausgewählt sein"]}
        />
        <:note>Fokus mit der Tab-Taste: 2px-Umriss in Grundfarbe.</:note>
      </.demo>
      <.demo title="Checkbox, Schalter, Radiogruppe" class="grid gap-6 md:grid-cols-2">
        <div>
          <.input
            name="c[recurring]"
            id="c-recurring"
            type="checkbox"
            label="Jeden Monat wiederholen"
            value="true"
          />
          <.input name="c[done]" id="c-done" type="checkbox" label="Als erledigt markieren" />
          <.input name="c[disabled]" id="c-disabled" type="checkbox" label="Deaktiviert" disabled />
          <.input
            name="c[notify]"
            id="c-notify"
            type="toggle"
            label="Benachrichtigungen"
            value="true"
          />
          <.input name="c[compact]" id="c-compact" type="toggle" label="Kompakte Liste" />
        </div>
        <.input
          name="c[split]"
          id="c-split"
          type="radio_group"
          label="Aufteilung"
          value="equal"
          options={[
            {"Gleichmäßig", "equal"},
            {"Nach Anteilen", "shares"},
            {"Genaue Beträge", "exact"}
          ]}
        />
      </.demo>
    </.showcase>

    <.showcase
      id="field-error"
      name="<.field_error>, <.field_help>"
      title="Fehler und Hinweis für eigene Felder"
      code={code(2)}
    >
      <:intro>
        Fehler- und Hinweiszeilen wie bei <code>&lt;.input&gt;</code>
        für Felder, die keins sind (Datei-Upload, eigene Auswahl). <code>field_describedby/3</code>
        verknüpft sie mit dem Feld.
      </:intro>
      <.demo title="Datei-Upload mit Fehler und Hinweis" class="max-w-md">
        <fieldset class="fieldset">
          <label for="u-photo" class="fieldset-legend">Beleg</label>
          <input
            type="file"
            id="u-photo"
            class="file-input file-input-error w-full"
            aria-invalid="true"
            aria-describedby={field_describedby("u-photo", ["zu groß"], true)}
          />
          <.field_error id="u-photo" errors={["zu groß"]} />
          <.field_help id="u-photo">PDF, JPEG oder PNG, höchstens 5 MB</.field_help>
        </fieldset>
      </.demo>
      <.demo title="Warnung, tone={:warning}" class="max-w-md">
        <fieldset class="fieldset">
          <label for="u-scan" class="fieldset-legend">Kontoauszug</label>
          <input
            type="file"
            id="u-scan"
            class="file-input w-full"
            aria-describedby={field_describedby("u-scan", [], true)}
          />
          <.field_help id="u-scan" tone={:warning} aria-live="polite">
            Scan ist unscharf, Beträge bitte prüfen.
          </.field_help>
        </fieldset>
        <:note>Icon und Text in Grundfarbe: Gelb ist als Schrift zu schwach.</:note>
      </.demo>
    </.showcase>

    <.showcase
      id="action-bar"
      name="<.action_bar>"
      title="Aktionsleiste"
      code={code(1)}
    >
      <:intro>
        Fuß eines Formulars: Primär rechts, Abbrechen links daneben, Löschen ganz links. Auf dem
        Handy volle Breite, gestapelt, Primär oben.
      </:intro>
      <.demo title="Mit Löschen (bestätigt im Dialog)">
        <.action_bar>
          <:secondary>
            <.button
              variant={:danger_outline}
              icon="trash-2"
              confirm="Ausgabe löschen?"
              phx-click="delete"
              phx-value-title="Wocheneinkauf"
            >Löschen</.button>
          </:secondary>
          <.button navigate="/forms">Abbrechen</.button>
          <.button variant={:primary}>Speichern</.button>
        </.action_bar>
      </.demo>
    </.showcase>

    <section id="muster-formular" class="space-y-6">
      <div class="space-y-1">
        <h2 class="text-xl font-semibold">Muster: Formular mit Fehlern pro Feld</h2>
        <p class="max-w-prose">
          Flach auf der Seite in schmaler Spalte. Eine Spalte auf dem Handy, kurze Felder ab
          <code>md</code>
          zweispaltig. Sammel-Alert oben mit Anzahl, Fehler unter jedem Feld; die
          Fehler verschwinden beim Tippen (<code>phx-change</code>).
        </p>
      </div>
      <.form
        for={@form}
        id="expense-form"
        phx-change="validate"
        phx-submit="save"
        class="max-w-3xl space-y-4"
        novalidate
      >
        <h3 class="text-lg font-semibold">Ausgabe bearbeiten</h3>
        <.alert :if={@form.errors != []} tone={:error} title={error_title(@form.errors)}>
          Bitte prüfe die markierten Felder.
        </.alert>
        <div class="grid gap-4 md:grid-cols-2">
          <div class="md:col-span-2"><.input field={@form[:title]} label="Titel" required /></div>
          <.input
            field={@form[:amount]}
            label="Betrag"
            suffix="€"
            numeric
            class="max-w-40"
            required
          />
          <.input field={@form[:date]} type="date" label="Datum" />
          <.input field={@form[:payer]} type="select" label="Bezahlt von" options={@payers} />
          <.input
            field={@form[:category]}
            type="select"
            label="Kategorie"
            options={@categories}
            help="Bestimmt das Plüsch-Icon in der Liste."
          />
          <.input
            field={@form[:split]}
            type="radio_group"
            label="Aufteilung"
            options={[{"Gleichmäßig", "equal"}, {"Nach Anteilen", "shares"}]}
          />
          <.input field={@form[:recurring]} type="toggle" label="Jeden Monat wiederholen" />
        </div>
        <.action_bar>
          <:secondary>
            <.button
              variant={:danger_outline}
              icon="trash-2"
              confirm="Ausgabe löschen?"
              phx-click="delete"
            >Löschen</.button>
          </:secondary>
          <.button navigate="/forms">Abbrechen</.button>
          <.button type="submit" variant={:primary} phx-disable-with="Speichert …">Speichern</.button>
        </.action_bar>
      </.form>
    </section>

    <.showcase
      id="inline-form"
      name="<.input inline>"
      title="Inline-Formular (Feld und Button)"
      code={code(3)}
    >
      <:intro>
        Ein Feld mit seinem Button in einem <code>join</code>, auf dem Handy gestapelt. Das Label
        ist nur für Screenreader da (die Überschrift darüber sagt, worum es geht); Fehler und
        Hinweis stehen unter dem Join.
      </:intro>
      <.demo title="Kategorie hinzufügen" class="max-w-3xl space-y-3">
        <.section_heading>Kategorien</.section_heading>
        <form phx-submit="noop">
          <.input
            name="category[name]"
            id="f-newcat"
            label="Neue Kategorie"
            placeholder="Neue Kategorie, z. B. Haustier"
            inline
          >
            <.button type="submit" variant={:primary} icon="plus" class="join-item">
              Hinzufügen
            </.button>
          </.input>
        </form>
      </.demo>
      <.demo title="Mit Fehler und Hinweis" class="max-w-3xl">
        <.input
          name="invite[email]"
          id="f-invite"
          type="email"
          label="E-Mail-Adresse"
          value="jonas@"
          errors={["ist keine gültige Adresse"]}
          help="Die Einladung gilt sieben Tage."
          inline
        >
          <.button variant={:primary} class="join-item">Einladen</.button>
        </.input>
      </.demo>
    </.showcase>
    """
  end

  defp error_title([_]), do: "1 Feld ist noch nicht richtig"
  defp error_title(errors), do: "#{length(errors)} Felder sind noch nicht richtig"

  defp code(0) do
    ~S"""
    <.input field={@form[:amount]} label="Betrag" suffix="€" numeric class="max-w-40"
            help="Mit Komma, z. B. 87,42" />
    <.input field={@form[:category_id]} type="select" label="Kategorie"
            options={@categories} prompt="Bitte wählen" />
    <.input field={@form[:recurring]} type="checkbox" label="Jeden Monat wiederholen" />
    <.input field={@form[:split]} type="radio_group" label="Aufteilung"
            options={[{"Gleichmäßig", "equal"}, {"Nach Anteilen", "shares"}]} />
    <.input field={@form[:iban]} label="IBAN" help="Noch nicht bestätigt" help_tone={:warning} />
    """
  end

  defp code(3) do
    ~S"""
    <.form for={@form} phx-submit="add">
      <.input field={@form[:name]} label="Neue Kategorie" placeholder="z. B. Haustier" inline>
        <.button type="submit" variant={:primary} icon="plus" class="join-item">Hinzufügen</.button>
      </.input>
    </.form>
    """
  end

  defp code(2) do
    ~S"""
    <fieldset class="fieldset">
      <label for={@uploads.receipt.ref} class="fieldset-legend">Beleg</label>
      <.live_file_input upload={@uploads.receipt}
        aria-describedby={field_describedby(@uploads.receipt.ref, @receipt_errors, true)} />
      <.field_error id={@uploads.receipt.ref} errors={@receipt_errors} />
      <.field_help id={@uploads.receipt.ref}>PDF, JPEG oder PNG, höchstens 5 MB</.field_help>
    </fieldset>
    <.field_error field={@form[:receipt]} />
    <.field_help id={@uploads.receipt.ref} tone={:warning}>Scan ist unscharf</.field_help>
    """
  end

  defp code(1) do
    ~S"""
    <.action_bar sticky>
      <:secondary>
        <.button variant={:danger_outline} icon="trash-2" confirm="Post löschen?"
                 phx-click="delete">Löschen</.button>
      </:secondary>
      <.button navigate={~p"/posts"}>Abbrechen</.button>
      <.button type="submit" variant={:primary} phx-disable-with="Speichert …">Speichern</.button>
    </.action_bar>
    """
  end
end
