defmodule Setzkasten.ComponentCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      use Setzkasten
      import Phoenix.Component, only: [sigil_H: 2, to_form: 2]
      import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
      import Setzkasten.ComponentCase
      alias Phoenix.LiveView.JS
    end
  end

  @doc "Renders HEEx to a LazyHTML document."
  def parse(rendered),
    do: rendered |> Phoenix.LiveViewTest.rendered_to_string() |> LazyHTML.from_fragment()

  def find(doc, selector), do: LazyHTML.query(doc, selector)

  def count(doc, selector), do: doc |> find(selector) |> Enum.count()

  def attr(doc, selector, name) do
    case doc |> find(selector) |> LazyHTML.attribute(name) do
      [value | _] -> value
      [] -> nil
    end
  end

  def text(doc, selector), do: doc |> find(selector) |> LazyHTML.text() |> String.trim()

  @doc "The push ops of a `phx-click`, including one parked on the confirmation dialog."
  def pushes(nil), do: []

  def pushes(js) do
    js
    |> Jason.decode!()
    |> Enum.flat_map(fn
      ["push", args] -> [args]
      ["set_attr", %{"attr" => ["data-confirm-action", action]}] -> pushes(action)
      _ -> []
    end)
  end

  def classes(doc, selector), do: doc |> attr(selector, "class") |> to_string() |> String.split()
end
