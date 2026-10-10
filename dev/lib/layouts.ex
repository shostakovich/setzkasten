defmodule Setzkasten.Dev.Layouts do
  @moduledoc false
  use Phoenix.Component
  use Setzkasten

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="de">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()} />
        <.live_title suffix=" · setzkasten">{assigns[:page_title] || "Katalog"}</.live_title>
        <.theme_meta />
        <.theme_script />
        <script>
          (() => { const t = new URLSearchParams(location.search).get("theme"); if (t === "light" || t === "dark") document.documentElement.setAttribute("data-theme", "zipfel-" + t) })()
        </script>
        <link rel="stylesheet" href="/assets/app.css" />
        <script defer src="/assets/app.js">
        </script>
      </head>
      <body class="bg-base-100 text-base-content">
        {@inner_content}
      </body>
    </html>
    """
  end
end

defmodule Setzkasten.Dev.ErrorHTML do
  @moduledoc false
  def render(template, _assigns), do: Phoenix.Controller.status_message_from_template(template)
end
