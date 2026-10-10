defmodule Setzkasten.Dev.Router do
  @moduledoc false
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {Setzkasten.Dev.Layouts, :root}
    plug :protect_from_forgery
  end

  scope "/" do
    pipe_through :browser

    live "/", Setzkasten.Dev.CatalogLive, :show
    live "/screens/:screen", Setzkasten.Dev.ScreenLive, :show
    live "/:page", Setzkasten.Dev.CatalogLive, :show
  end
end
