defmodule Setzkasten.Dev.Pages.FormsPage do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  import Setzkasten.Dev.Demo

  def title, do: "Formulare"

  def summary,
    do:
      "input, field_row, on_escape, combobox, file_drop, field_error, field_help, error_bubble, action_bar, Formular mit Fehlern"

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
        <.input
          name="d[isin]"
          id="d-isin"
          label="ISIN (identifier, maxlength 12)"
          identifier
          maxlength="12"
          value="IE00BK5BQT80"
          placeholder="XX0000000000"
        />
        <.input
          name="d[symbol]"
          id="d-symbol"
          label="Yahoo-Symbol (getippt: vwce.de)"
          identifier
          value="vwce.de"
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
          identifier
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
        <.input
          name="c[frequency]"
          id="c-frequency"
          type="radio_group"
          label="Wie oft?"
          value="monthly"
          options={[
            %{label: "Wöchentlich", value: "weekly", description: "Nächster Termin 21.10.2026"},
            %{label: "Monatlich", value: "monthly", description: "Nächster Termin 14.11.2026"},
            %{label: "Jährlich", value: "yearly", description: "Nächster Termin 14.10.2027"}
          ]}
        />
      </.demo>
      <.demo title="Schalter zwischen beschrifteten Feldern" class="max-w-md">
        <.input name="r[payee]" id="r-payee" label="Empfänger" value="Hausverwaltung Ost" />
        <.input name="r[recurring]" id="r-recurring" type="toggle" label="Jeden Monat wiederholen" />
        <.input name="r[notify]" id="r-notify" type="checkbox" label="Vorher erinnern" />
        <.input name="r[purpose]" id="r-purpose" label="Verwendungszweck" />
        <:note>
          Der Schalter beginnt, wo das Label eines Felds beginnen würde; ein zweiter direkt
          darunter bleibt nah. Mit dem Finger hat die 44px-Zeile den Raum schon.
        </:note>
      </.demo>
    </.showcase>

    <.showcase
      id="field-error"
      name="<.field_error>, <.field_help>, <.error_bubble>"
      title="Fehler und Hinweis für eigene Felder"
      code={code(2)}
    >
      <:intro>
        Fehler- und Hinweiszeilen wie bei <code>&lt;.input&gt;</code>
        für Felder, die keins sind (Datei-Upload, eigene Auswahl). <code>field_describedby/3</code>
        verknüpft sie mit dem Feld. <code>&lt;.error_bubble&gt;</code>
        zeigt den Fehler eines
        dichten Felds (Tabellenzelle) sofort als Blase daran.
      </:intro>
      <.demo
        title="Zeitraum in einer Zeile: sichtbare Labels, Feld und Button enden unten bündig"
        class="flex flex-wrap items-end gap-3"
      >
        <.input id="range-from" name="from" type="date" label="Von" value="2026-08-27" class="w-44" />
        <.input id="range-to" name="to" type="date" label="Bis" value="2026-09-12" class="w-44" />
        <.button id="range-apply" variant={:primary}>Anwenden</.button>
      </.demo>
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
      <.demo title="Fehlerblase an einem Feld in einer scrollenden Tabelle" class="max-w-md">
        <div class="max-h-40 overflow-auto rounded-box border border-base-content/10">
          <table class="table table-sm">
            <thead class="sticky top-0 z-10 bg-base-100">
              <tr>
                <th>Kategorie</th>
                <th class="text-end">Zugewiesen</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={{id, label, value, errors} <- bubble_cells()}>
                <td>{label}</td>
                <td class="w-32">
                  <input
                    id={id}
                    class={["input input-sm text-end tabular-nums", errors != [] && "input-error"]}
                    value={value}
                    inputmode="decimal"
                    aria-label={"#{label}, zugewiesen"}
                    aria-invalid={errors != [] && "true"}
                    aria-describedby={field_describedby(id, errors, nil)}
                  />
                  <.error_bubble id={id} errors={errors} align={:end} />
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <:note>
          In der obersten Ebene, so schneidet die Tabelle sie nicht ab; verschwindet, wenn das
          Feld aus der Tabelle oder dem Fenster scrollt oder unter dem Tabellenkopf liegt.
        </:note>
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
        phx-hook="Setzkasten.Components.Forms.FocusInvalid"
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

    <.showcase
      id="field-row"
      name="<.field_row>, <.input bare>"
      title="Feldzeile"
      code={code(6)}
    >
      <:intro>
        Felder ohne Rahmen des Formularfelds (<code>bare</code>) und Buttons in einer Zeile, etwa
        die Bedingungen einer Regel. Das Textfeld nimmt den Rest der Breite, die Auswahl ihre
        eigene oder eine feste (<code>w-32</code>), damit die Zeilen fluchten, die Buttons ihre Größe; die Labels sind für Screenreader da. Ein Fehler steht
        unter seinem Feld, die Buttons bleiben oben. Auch auf dem Handy eine Zeile.
      </:intro>
      <.demo title="Umbenennen, wenn der Empfänger …" class="max-w-md space-y-2">
        <.field_row :for={{key, operator, text, errors} <- rule_rows()} id={"rule-#{key}"}>
          <.input
            type="select"
            bare
            id={"rule-#{key}-operator"}
            name={"rules[#{key}][operator]"}
            label="Bedingung"
            options={rule_operators()}
            value={operator}
            class="select-sm w-32"
          />
          <.input
            bare
            id={"rule-#{key}-text"}
            name={"rules[#{key}][text]"}
            label="Text im Empfänger"
            value={text}
            errors={errors}
            class="input-sm"
            autocomplete="off"
          />
          <.button
            id={"rule-#{key}-remove"}
            variant={:ghost}
            size={:sm}
            icon="minus"
            icon_only
            label="Regel entfernen"
          />
          <.button
            id={"rule-#{key}-add"}
            variant={:ghost}
            size={:sm}
            icon="plus"
            icon_only
            label="Regel hinzufügen"
            class={key != 2 && "invisible"}
          />
        </.field_row>
      </.demo>
    </.showcase>

    <.showcase
      id="on-escape"
      name="<.input on_escape>"
      title="Escape bricht eine Bearbeitung ab"
      code={code(7)}
    >
      <:intro>
        Escape im Feld führt <code>on_escape</code>
        aus (Ereignis oder <code>%JS{"{}"}</code>) und geht nicht weiter: Der Dialog um das Feld
        bleibt offen, nur das Umbenennen endet. Ein zweites Escape schließt den Dialog.
      </:intro>
      <.demo title="Empfänger umbenennen im Dialog">
        <.button id="edit-name-open" phx-click={show_modal("edit-name-modal")}>
          Empfänger bearbeiten
        </.button>
        <.modal id="edit-name-modal" title="Empfänger">
          <div :if={!@editing_name} class="flex min-h-10 items-center justify-between gap-2">
            <p id="edit-name-text" class="truncate text-lg font-semibold">{@edit_name}</p>
            <.button
              id="edit-name-start"
              variant={:ghost}
              size={:sm}
              icon="pencil"
              phx-click="edit_name"
            >
              Umbenennen
            </.button>
          </div>
          <.form :if={@editing_name} for={%{}} id="edit-name-form" phx-submit="save_name">
            <.field_row>
              <.input
                id="edit-name-field"
                name="name"
                value={@edit_name}
                label="Name des Empfängers"
                bare
                autocomplete="off"
                on_escape="cancel_edit_name"
                phx-mounted={Phoenix.LiveView.JS.focus()}
              />
              <.button id="edit-name-cancel" phx-click="cancel_edit_name">Abbrechen</.button>
              <.button id="edit-name-save" type="submit" variant={:primary}>Sichern</.button>
            </.field_row>
          </.form>
        </.modal>
        <:note>Ohne <code>on_escape</code> schlösse Escape im Feld den ganzen Dialog.</:note>
      </.demo>
    </.showcase>

    <.showcase id="file-drop" name="<.file_drop>" title="Datei ablegen" code={code(5)}>
      <:intro>
        Eine Ablagefläche um <code>live_file_input</code>: Datei hineinziehen oder antippen. Das
        Dateifeld ist das Bedienelement (Tab, Enter), unsichtbar; an seiner Stelle stehen ein
        Knopf „Datei auswählen“ und der gewählte Dateiname statt des Browsertexts. Beim Ziehen
        wird der Rand blau. Fehler des Uploads stehen auf Deutsch darunter.
      </:intro>
      <.demo title="Kontoauszug (CSV oder PDF, eine Datei, höchstens 5 MB)" class="max-w-xl">
        <form id="statement-form" phx-change="statement" phx-submit="statement">
          <.file_drop
            upload={@uploads.statement}
            label="Kontoauszug"
            help="CSV oder PDF aus dem Online-Banking, höchstens 5 MB"
          >
            <div
              :for={entry <- @uploads.statement.entries}
              class="flex items-center gap-3 py-1 text-sm"
            >
              <progress
                class="progress progress-primary w-full max-w-48"
                value={entry.progress}
                max="100"
              >
                {entry.progress} %
              </progress>
              <span class="flex-1 text-base-content/70 tabular-nums">{entry.progress}&nbsp;%</span>
              <.button
                variant={:ghost}
                size={:sm}
                icon="x"
                icon_only
                label={"#{entry.client_name} entfernen"}
                phx-click="cancel_statement"
                phx-value-ref={entry.ref}
              />
            </div>
          </.file_drop>
        </form>
      </.demo>
    </.showcase>

    <.showcase id="combobox" name="<.combobox>" title="Suchbare Auswahl" code={code(4)}>
      <:intro>
        Ein Textfeld, das seine Optionen beim Tippen filtert, für lange Listen wie Empfänger oder
        Kategorien. Pfeiltasten wählen, Enter und Tab übernehmen, Escape schließt nur die Liste.
        Ein verstecktes Feld trägt den Wert; erst eine Wahl löst <code>phx-change</code>
        aus. Mit <code>allow_create</code>
        lässt sich ein neuer Eintrag anlegen.
      </:intro>
      <.demo title="Gruppen und eigener Inhalt, anlegen, Fehler" class="max-w-3xl">
        <.form for={@combo} id="combo-form" phx-change="combo" class="grid gap-4 md:grid-cols-2">
          <.combobox
            field={@combo[:category]}
            label="Kategorie"
            placeholder="Kategorie suchen"
            options={combo_categories()}
          >
            <:option :let={option}>
              <span class="min-w-0 flex-1 truncate">{option.label}</span>
              <.amount value={option.available} tone />
            </:option>
          </.combobox>
          <.combobox
            field={@combo[:payee]}
            label="Empfänger"
            placeholder="Empfänger"
            options={combo_payees()}
            allow_create
            help="Ein neuer Name wird angelegt."
          />
          <.combobox
            field={@combo[:account]}
            label="Konto"
            options={[{"🏦 Girokonto", "giro"}, {"💳 Kreditkarte", "card"}]}
            allow_create
            create_label="Konto „%{text}“ hinzufügen"
            create_field={@combo[:new_account]}
          />
          <.combobox
            name="combo-error"
            id="combo-error"
            label="Mit Fehler"
            options={[{"Miete", "rent"}]}
            errors={["muss gewählt sein"]}
          />
        </.form>
        <:note>
          Gesendet: Kategorie „{@combo[:category].value}“, Empfänger „{@combo[:payee].value}“,
          Konto „{@combo[:account].value}“, neues Konto „{@combo[:new_account].value}“.
        </:note>
      </.demo>
      <.demo title="Aufteilung: eine Liste für alle Teile (options_from)" class="max-w-3xl">
        <.combobox_options id="split-categories" options={combo_categories()}>
          <:option :let={option}>
            <span class="min-w-0 flex-1 truncate">{option.label}</span>
            <.amount value={option.available} tone />
          </:option>
        </.combobox_options>
        <div class="grid gap-4 md:grid-cols-3">
          <.combobox
            :for={part <- 1..3}
            id={"split-#{part}"}
            name={"split[#{part}]"}
            label={"Teil #{part}"}
            placeholder="Kategorie suchen"
            options_from="split-categories"
          />
        </div>
        <:note>
          Die Optionen stehen einmal im Markup; jedes Feld kopiert sie, solange es offen ist.
        </:note>
      </.demo>
    </.showcase>
    """
  end

  defp combo_payees,
    do:
      Enum.map(
        ["Bäckerei Krume", "Stadtwerke", "Supermarkt Frisch", "Tankstelle Nord"],
        &{&1, &1}
      )

  defp combo_categories do
    [
      {"Fixkosten",
       [
         %{label: "Miete", value: "rent", available: 0},
         %{label: "Strom", value: "power", available: 4_500},
         %{label: "Internet", value: "internet", available: -1_299}
       ]},
      {"Alltag",
       [
         %{label: "Lebensmittel", value: "groceries", available: 31_248, key: "Essen Einkauf"},
         %{label: "Drogerie", value: "drugstore", available: 2_310},
         %{label: "Café & Bäckerei", value: "cafe", available: 870}
       ]}
    ]
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
    <%!-- a code: monospace, shown in capitals, no spell checking; maxlength sets the width --%>
    <.input field={@form[:isin]} label="ISIN" identifier maxlength="12" placeholder="XX0000000000" />
    """
  end

  defp code(6) do
    ~S"""
    <.field_row :for={rule <- @rules} id={"rule-#{rule.key}"}>
      <.input type="select" bare name={"rules[#{rule.key}][operator]"} id={"rule-#{rule.key}-op"}
              label="Bedingung" options={@operators} value={rule.operator} class="select-sm w-32" />
      <.input bare name={"rules[#{rule.key}][text]"} id={"rule-#{rule.key}-text"}
              label="Text im Empfänger" value={rule.text} errors={rule.errors} class="input-sm" />
      <.button variant={:ghost} size={:sm} icon="minus" icon_only label="Regel entfernen"
               phx-click="remove_rule" phx-value-key={rule.key} />
      <.button variant={:ghost} size={:sm} icon="plus" icon_only label="Regel hinzufügen"
               phx-click="add_rule" />
    </.field_row>
    """
  end

  defp code(7) do
    ~S"""
    <.form :if={@renaming} for={%{}} id="rename-form" phx-submit="rename" phx-target={@myself}>
      <.field_row>
        <.input id="rename-name" name="name" value={@name} label="Name" bare
                on_escape="cancel_rename" phx-target={@myself} phx-mounted={JS.focus()} />
        <.button phx-click="cancel_rename" phx-target={@myself}>Abbrechen</.button>
        <.button type="submit" variant={:primary}>Sichern</.button>
      </.field_row>
    </.form>
    """
  end

  defp code(5) do
    ~S"""
    <%!-- allow_upload(socket, :statement, accept: ~w(.csv .pdf), max_entries: 1) --%>
    <form id="import-form" phx-change="validate" phx-submit="import">
      <.file_drop upload={@uploads.statement} label="Kontoauszug"
                  help="CSV oder PDF aus dem Online-Banking, höchstens 5 MB">
        <%!-- the zone names the chosen file; below it, e.g., progress and a remove button --%>
        <progress :for={e <- @uploads.statement.entries} class="progress" value={e.progress} max="100" />
      </.file_drop>
    </form>
    """
  end

  defp code(4) do
    ~S"""
    <.combobox field={@form[:category_id]} label="Kategorie" options={@category_groups}
               placeholder="Kategorie suchen">
      <:option :let={option}>
        <span class="min-w-0 flex-1 truncate">{option.label}</span>
        <.amount value={option.available} tone />
      </:option>
    </.combobox>

    <%!-- a name field: the typed text becomes the value --%>
    <.combobox field={@form[:payee]} label="Empfänger" options={@payees} allow_create />

    <%!-- an id field: a new entry's text goes into create_field --%>
    <.combobox field={@form[:account_id]} label="Konto" options={@accounts} allow_create
               create_field={@form[:new_account]} />
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

    <%!-- a dense field in a table cell --%>
    <input id="assign-food" class="input input-sm" value={@typed}
      aria-invalid={@errors != [] && "true"}
      aria-describedby={field_describedby("assign-food", @errors, nil)} />
    <.error_bubble id="assign-food" errors={@errors} align={:end} />
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

  defp rule_operators,
    do: [
      {"enthält", "contains"},
      {"ist", "is"},
      {"beginnt mit", "starts_with"},
      {"endet mit", "ends_with"}
    ]

  defp rule_rows do
    [
      {1, "starts_with", "PAYPAL *BAECKEREI", []},
      {2, "contains", "", ["darf nicht leer sein"]}
    ]
  end

  defp bubble_cells do
    [
      {"bubble-food", "Lebensmittel", "350,00", []},
      {"bubble-fuel", "Tanken", "60*2",
       ["„60*2“ ist kein gültiger Betrag.\nRechnen geht mit + und −, etwa 50+20."]},
      {"bubble-gifts", "Geschenke", "25,00", []},
      {"bubble-drugstore", "Drogerie", "40,00", []},
      {"bubble-clothes", "Kleidung", "80,00", []}
    ]
  end
end
