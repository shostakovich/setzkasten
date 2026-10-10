defmodule Setzkasten.Dev.Pages.LayoutPage do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten
  import Setzkasten.Dev.Demo

  def title, do: "Gliederung"
  def summary, do: "header, section_heading, card, theme_toggle"

  def render(assigns) do
    ~H"""
    <.showcase
      id="header"
      name="<.header>"
      title="Seitenkopf"
      apps="Hausautomation, CMS, Depot, Budget (Ausgaben nach dem Umbau)"
      code={code(0)}
    >
      <:intro>
        Seitentitel mit Zurück-Link, Untertitel, Badge und Aktionen; die Aktionen rutschen auf dem
        Handy unter den Titel (Titelblock <code>grow basis-64</code>).
      </:intro>
      <.demo title="Mit Zurück-Link, Badge und Aktionen">
        <.header back="/layout" back_label="Bestand" level={3}>
          Vanguard FTSE All-World
          <:subtitle>IE00BK5BQT80 · Langfristig · 95 Stück</:subtitle>
          <:badge>
            <.badge tone={:success}>aktuell</.badge>
          </:badge>
          <:actions>
            <.button icon="pencil">Bearbeiten</.button>
            <.button variant={:primary} icon="plus">Buchung</.button>
          </:actions>
        </.header>
      </.demo>
      <.demo title="Nur Titel und Untertitel">
        <.header level={3}>
          Bestand
          <:subtitle>2 Depots · 11 Wertpapiere · 2 Konten</:subtitle>
        </.header>
      </.demo>
    </.showcase>

    <.showcase
      id="section-heading"
      name="<.section_heading>"
      title="Abschnittsüberschrift"
      apps="Hausautomation, CMS, Depot, Ausgaben"
      code={code(1)}
    >
      <:intro>
        Gliedert eine Seite: Satzschreibung, text-base 600 (E2a), optional Anzahl und Aktionen.
      </:intro>
      <.demo title="Zwei Abschnitte">
        <div>
          <.section_heading count={2} level={3}>
            Depots
            <:actions><.button size={:sm} icon="plus">Depot</.button></:actions>
          </.section_heading>
          <.list>
            <.list_row title="Kinderdepot" navigate="/layout">
              <:trailing><.amount value={799_483} /></:trailing>
            </.list_row>
            <.list_row title="Langfristig" navigate="/layout">
              <:trailing><.amount value={4_241_291} /></:trailing>
            </.list_row>
          </.list>
          <.section_heading level={3}>Konten</.section_heading>
          <.list>
            <.list_row title="Tagesgeld" navigate="/layout">
              <:trailing><.amount value={1_287_140} /></:trailing>
            </.list_row>
          </.list>
        </div>
      </.demo>
    </.showcase>

    <.showcase id="card" name="<.card>" title="Karte" apps="alle fünf" code={code(2)}>
      <:intro>
        Nur für eigenständige Objekte (E1b): Dashboard-Kacheln, KPI-Gruppen, Diagramme mit eigenem
        Titel, klickbare Objektraster, Dialoge. Flach mit Haarlinie.
      </:intro>
      <.demo
        title="Titel, Aktionen, Fußzeile · klickbare Karte"
        class="grid gap-4 md:gap-6 md:grid-cols-2"
      >
        <.card title="Kosten" subtitle="gewichtet 0,20 %" level={3}>
          <:actions>
            <.button variant={:ghost} size={:sm} icon="ellipsis-vertical" icon_only label="Mehr" />
          </:actions>
          <p>76&nbsp;€ pro Jahr bei 63.279,14&nbsp;€ Bestand.</p>
          <:footer>
            Laufende Kosten, die im Kurs stecken. Ordergebühren kommen aus den Buchungen.
          </:footer>
        </.card>
        <.card
          title="Kinderdepot"
          subtitle="Klickbare Karte: der Titel-Link deckt die Fläche"
          navigate="/layout"
          level={3}
        >
          <.amount value={799_483} class="text-2xl font-semibold" />
        </.card>
      </.demo>
      <.demo title="Mit :list-Slot, auf dem Handy randlos (bleed={:phone})">
        <.card
          title="Ausgaben"
          subtitle="Kopf mit px-6 pt-6 pb-2, Liste bündig"
          bleed={:phone}
          level={3}
        >
          <:actions><.button size={:sm} icon="download">Export</.button></:actions>
          <:list>
            <.list flush>
              <.list_row title="Wocheneinkauf">
                <:leading><.plush name="cart" size={:lg} /></:leading>
                <:meta>Jonas für alle · Lebensmittel</:meta>
                <:trailing><.amount value={8742} /></:trailing>
              </.list_row>
              <.list_row title="Abschlag Strom Oktober">
                <:leading><.plush name="zap" size={:lg} /></:leading>
                <:meta>Dana für alle · Strom</:meta>
                <:trailing><.amount value={11_200} /></:trailing>
              </.list_row>
            </.list>
          </:list>
        </.card>
      </.demo>
    </.showcase>

    <.showcase
      id="theme-toggle"
      name="<.theme_toggle>"
      title="Farbschema"
      apps="Budget, Ausgaben; künftig alle"
      code={code(3)}
    >
      <:intro>
        System, Hell, Dunkel. „System“ entfernt <code>data-theme</code>; gespeichert lokal oder
        pro Person auf dem Server. Diese Instanzen sind mit dem Schalter oben verbunden.
      </:intro>
      <.demo title="Standard und kompakt" class="flex flex-wrap items-center gap-4">
        <.theme_toggle id="theme-demo" />
        <.theme_toggle id="theme-demo-compact" compact />
      </.demo>
    </.showcase>
    """
  end

  defp code(0) do
    ~S"""
    <.header back={~p"/bestand"} back_label="Bestand">
      Vanguard FTSE All-World
      <:subtitle>IE00BK5BQT80 · Langfristig</:subtitle>
      <:badge><.badge tone={:success}>aktuell</.badge></:badge>
      <:actions><.button variant={:primary} icon="plus">Buchung</.button></:actions>
    </.header>
    """
  end

  defp code(1) do
    ~S"""
    <.section_heading count={2}>
      Depots
      <:actions><.button size={:sm} icon="plus">Depot</.button></:actions>
    </.section_heading>
    """
  end

  defp code(2) do
    ~S"""
    <.card title="Kosten" subtitle="gewichtet 0,20 %">
      <:actions>…</:actions>
      …
      <:footer>Laufende Kosten, die im Kurs stecken.</:footer>
    </.card>
    <.card title="Ausgaben" bleed={:phone}><:list><.list flush>…</.list></:list></.card>
    """
  end

  defp code(3) do
    ~S"""
    <.theme_toggle />                                  <%!-- localStorage --%>
    <.theme_toggle store={:server} value={@user.theme} on_change="set-theme" />
    """
  end
end
