defmodule Setzkasten.Dev.CatalogLive do
  @moduledoc false
  use Phoenix.LiveView
  use Setzkasten
  alias Setzkasten.Dev.Pages

  @pages [
    {"", Pages.Index},
    {"foundations", Pages.Foundations},
    {"icons", Pages.IconsPage},
    {"actions", Pages.ActionsPage},
    {"forms", Pages.FormsPage},
    {"feedback", Pages.FeedbackPage},
    {"layout", Pages.LayoutPage},
    {"tables", Pages.TablesPage},
    {"values", Pages.ValuesPage},
    {"navigation", Pages.NavigationPage},
    {"overlays", Pages.OverlaysPage},
    {"shell", Pages.ShellPage}
  ]

  def pages, do: @pages

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, view: "list", deleted: 0, form: Pages.FormsPage.build_form(%{}))}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    slug = params["page"] || ""

    {slug, module} = List.keyfind(@pages, slug, 0) || hd(@pages)

    {:noreply,
     assign(socket,
       slug: slug,
       page: module,
       page_title: module.title(),
       range: params["r"] || "1y",
       depot: params["d"] || "all"
     )}
  end

  @impl true
  def handle_event("view", %{"value" => view}, socket), do: {:noreply, assign(socket, view: view)}

  def handle_event("delete", params, socket) do
    {:noreply,
     socket
     |> update(:deleted, &(&1 + 1))
     |> put_flash(:info, "Gelöscht (Demo): #{params["title"] || "Eintrag"}")}
  end

  def handle_event("validate", %{"expense" => params}, socket) do
    {:noreply, assign(socket, form: Pages.FormsPage.build_form(params, :validate))}
  end

  def handle_event("save", %{"expense" => params}, socket) do
    {:noreply, assign(socket, form: Pages.FormsPage.build_form(params, :validate))}
  end

  def handle_event("flash", %{"kind" => kind}, socket) do
    {kind, msg} =
      if kind == "error",
        do: {:error, "Speichern fehlgeschlagen. Bitte versuch es noch einmal."},
        else: {:info, "Ausgabe „Wocheneinkauf“ angelegt."}

    {:noreply, put_flash(socket, kind, msg)}
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :pages, @pages)

    ~H"""
    <a
      href="#main"
      class="sr-only focus:not-sr-only focus:fixed focus:top-2 focus:start-2 btn btn-sm z-50"
    >
      Zum Inhalt springen
    </a>
    <header class="border-b border-base-content/10">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-4 flex flex-wrap items-center gap-x-6 gap-y-3">
        <div class="flex items-center gap-3 min-w-0 grow basis-72">
          <img src="/images/setzkasten.webp" alt="" class="size-12 shrink-0" />
          <div class="min-w-0">
            <p class="text-2xl font-semibold">setzkasten</p>
            <p class="text-sm text-base-content/70 max-w-prose">
              Komponentenkatalog · daisyUI 5.5.20 + Tailwind 4.3.3 · Themes <code>zipfel-light</code>
              / <code>zipfel-dark</code>
            </p>
          </div>
        </div>
        <.theme_toggle id="theme-top" />
      </div>
    </header>
    <details
      id="toc-phone"
      class="lg:hidden sticky top-0 z-40 bg-base-100 border-b border-base-content/10"
      phx-mounted={Phoenix.LiveView.JS.ignore_attributes(["open"])}
    >
      <summary class="cursor-pointer px-4 py-3 font-semibold flex items-center gap-2">
        <.icon name="list" />Inhalt: {@page.title()}
      </summary>
      <nav aria-label="Seiten (kompakt)" class="border-t border-base-content/10">
        <ul class="menu w-full">{nav_items(assigns)}</ul>
      </nav>
    </details>
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-6 lg:grid lg:grid-cols-[13rem_minmax(0,1fr)] lg:gap-10">
      <nav
        aria-label="Seiten"
        class="hidden lg:block sticky top-4 self-start max-h-[calc(100vh-2rem)] overflow-y-auto"
      >
        <ul class="menu w-full p-0">{nav_items(assigns)}</ul>
      </nav>
      <main id="main" class="min-w-0 pb-12">
        <h1 class="text-2xl font-semibold mb-6">{@page.title()}</h1>
        <div class="space-y-12">{@page.render(assigns)}</div>
      </main>
    </div>
    <.flash_group flash={@flash} />
    <.confirm_dialog />
    """
  end

  defp nav_items(assigns) do
    ~H"""
    <li :for={{slug, module} <- @pages}>
      <.link
        navigate={"/" <> slug}
        class={slug == @slug && "menu-active"}
        aria-current={slug == @slug && "page"}
      >
        {module.title()}
      </.link>
    </li>
    <li class="menu-title text-base-content/70">Screens</li>
    <li :for={{slug, title} <- Setzkasten.Dev.ScreenLive.screens()}>
      <.link navigate={"/screens/" <> slug}>{title}</.link>
    </li>
    """
  end
end
