defmodule Setzkasten.Dev.Pages.ShellPage do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  import Setzkasten.Dev.Demo

  def title, do: "Gerüst"
  def summary, do: "app_shell :sidebar und :topbar, Dock"

  def render(assigns) do
    ~H"""
    <.showcase
      id="app-shell"
      name="<.app_shell>"
      title="Navigations-Gerüst"
      code={code(0)}
    >
      <:intro>
        Zwei Layouts. <code>:sidebar</code>: dunkle Seitenleiste mit Konto und Einklapp-Knopf am Fuß ab <code>lg</code>, Icon-Leiste von
        <code>md</code>
        bis <code>lg</code>
        (ausklappbar als
        Dialog) mit Kopfzeile, auf dem Handy Kopfzeile + Dock. Eingeklappt zeigt auch ab
        <code>lg</code>
        die Icon-Leiste; das Gerät merkt sich die Wahl. <code>:topbar</code>: Navbar ab <code>md</code>, darunter Dock und ggf. FAB. Ein
        <code>count</code>
        steht in der Seitenleiste als Zahl, in Icon-Leiste und Dock als Badge am Icon;
        <code>count_label</code>
        nennt ihn für Screenreader („Buchungen, 2 neu“). Ein Eintrag ohne <code>section</code>
        nach einer Gruppe (Einstellungen in <code>/screens/holdings</code>) steht mit dem Abstand
        einer Gruppe abgesetzt, ohne Titel. Ein <code>plush</code>, für den die App kein Bild
        hat, fällt auf das <code>icon</code>
        des Eintrags zurück, ein <code>glyph</code>
        (Emoji, Initiale) steht an Stelle des Icons.
        Lange Namen enden mit Auslassungspunkten (voller Name als <code>title</code>);
        <code>section_amount</code>
        zeigt die Summe einer Gruppe, <code>amount_tone={"{:negative}"}</code>
        negative Beträge in <code>sidebar-negative</code>, ein <code>count</code>
        neben einem Betrag
        wird ein Badge. Ein Eintrag mit <code>on_click</code>
        ist ein leiser Knopf an seiner Stelle
        („Konto hinzufügen“ in <code>/screens/budget</code>). Mehrere <code>:area</code>-Einträge
        geben der Seitenleiste oben einen Bereichswechsel, auch in der Icon-Leiste; <code>:back</code>
        schaltet sie in einen eigenen Modus wie die Einstellungen, mit einem Weg zurück oben und
        ohne Dock. Die Vorschauen sind
        die echten Screens in festen Breiten.
      </:intro>
      <.demo
        :for={
          {slug, label} <- [
            {"holdings", ":sidebar"},
            {"post", ":sidebar, Detailseite mit :bar"},
            {"posts", ":topbar mit FAB"},
            {"settings", ":topbar ohne Dock"},
            {"dashboard", ":topbar mit Plüsch-Dock"},
            {"budget",
             ":sidebar mit Plüsch-Bereichswechsel, Kontogruppen, Summen, negativen Salden und Knopf-Eintrag"},
            {"budget?m=settings", ":sidebar im Einstellungsmodus mit :back"}
          ]
        }
        title={"#{label} – /screens/#{slug}"}
        class="flex gap-4 overflow-x-auto p-1 pb-2"
      >
        <figure :for={{w, h} <- [{390, 640}, {800, 640}, {1280, 640}]} class="shrink-0 space-y-1">
          <iframe
            src={"/screens/#{slug}"}
            width={w}
            height={h}
            title={"#{label} bei #{w}px"}
            loading="lazy"
            class="rounded-box border border-base-content/10 bg-base-100"
          ></iframe>
          <figcaption class="text-xs text-base-content/70">{w}px</figcaption>
        </figure>
      </.demo>
    </.showcase>
    """
  end

  defp code(0) do
    ~S"""
    <.app_shell layout={:sidebar} current={:holdings} width={:wide}>
      <:brand>Depotblick</:brand>
      <:nav key={:overview} label="Übersicht" icon="chart-line" navigate={~p"/"} />
      <:nav key={:holdings} label="Bestand" icon="list" navigate={~p"/bestand"} />
      <:nav key={:bookings} label="Buchungen" icon="receipt" count={2} count_label="neu" navigate={…} />
      <:nav key={:kinder} label="Kinderdepot" icon="wallet" amount={799_483} section="Depots" navigate={…} />
      <%!-- rail={false}: object lists such as accounts stay out of the icon rail --%>
      <:nav key={:giro} label="Girokonto" icon="landmark" amount={248_310} section="Konten" rail={false} navigate={…} />
      <:nav key={:settings} label="Einstellungen" icon="settings" navigate={…} />
      <:nav key={:stats} label="Statistik" plush="stats" icon="chart-pie" navigate={…} />
      {@inner_content}
    </.app_shell>

    <%!-- money in the sidebar: glyphs, section totals, negative balances, a button entry --%>
    <.app_shell layout={:sidebar} current={{:account, @account.id}} amount_tone={:negative}>
      <:nav :for={{account, i} <- Enum.with_index(@accounts)} key={{:account, account.id}}
        label={account.name} glyph={account.emoji} amount={account.balance}
        count={account.unapproved} count_label="offen" section="Budgetkonten"
        section_amount={i == 0 && @accounts_total} rail={false} navigate={…} />
      <:nav key={:add_account} label="Konto hinzufügen" icon="plus" section="Budgetkonten"
        on_click="add_account" />
      <:account :let={place}>
        <.dropdown id={"account-#{place}"} position={if place == :sidebar, do: :top, else: :bottom} …/>
      </:account>
      {@inner_content}
    </.app_shell>
    """
  end
end
