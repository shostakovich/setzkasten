defmodule Setzkasten.Dev.Pages.Index do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten

  def title, do: "Übersicht"

  def render(assigns) do
    assigns = assign(assigns, :entries, tl(Setzkasten.Dev.CatalogLive.pages()))

    ~H"""
    <div class="max-w-prose space-y-3">
      <p>
        Jede Seite zeigt eine Gruppe von Komponenten aus <code>guides/design-system.md</code>
        mit allen Varianten, Größen und Zuständen. Alles hier wird von den echten HEEx-Komponenten
        gerendert; der Katalog ist zugleich Ziel für Screenshots, Kontrastprüfungen und
        visuelle Regressionstests.
      </p>
      <p class="text-sm text-base-content/70">
        Hover und Fokus mit Maus und Tab-Taste ausprobieren. Das Farbschema oben rechts schaltet
        System, Hell und Dunkel.
      </p>
    </div>
    <section class="space-y-3">
      <.section_heading count={length(@entries)}>Seiten</.section_heading>
      <.list>
        <.list_row :for={{slug, module} <- @entries} title={module.title()} navigate={"/" <> slug}>
          <:meta>{module.summary()}</:meta>
        </.list_row>
      </.list>
    </section>
    <section class="space-y-3">
      <.section_heading count={length(Setzkasten.Dev.ScreenLive.screens())}>Screens</.section_heading>
      <p class="text-sm text-base-content/70 max-w-prose">
        Zusammengesetzte Seiten im echten <code>&lt;.app_shell&gt;</code>, ohne Katalog-Rahmen.
      </p>
      <div class="grid gap-4 md:gap-6 sm:grid-cols-2 lg:grid-cols-3">
        <.card
          :for={{slug, title, desc} <- Setzkasten.Dev.ScreenLive.screens(:full)}
          title={title}
          level={3}
          navigate={"/screens/" <> slug}
        >
          <p class="text-sm text-base-content/70">{desc}</p>
        </.card>
      </div>
    </section>
    """
  end

  def summary, do: ""
end
