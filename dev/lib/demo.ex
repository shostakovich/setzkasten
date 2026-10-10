defmodule Setzkasten.Dev.Demo do
  @moduledoc false
  use Phoenix.Component

  attr :id, :string, required: true
  attr :name, :string, required: true, doc: "component call, e.g. <.button>"
  attr :title, :string, required: true
  attr :apps, :string, default: nil
  attr :code, :string, default: nil
  slot :intro
  slot :inner_block, required: true

  def showcase(assigns) do
    ~H"""
    <section id={@id} class="space-y-6 scroll-mt-6">
      <div class="space-y-1">
        <h2 class="text-xl font-semibold"><code>{@name}</code> {@title}</h2>
        <p :if={@intro != []} class="max-w-prose">{render_slot(@intro)}</p>
        <p :if={@apps} class="text-sm text-base-content/70 max-w-prose">Apps: {@apps}</p>
      </div>
      <pre :if={@code} class="rounded-box bg-base-200 px-4 py-3 text-xs leading-5 overflow-x-auto"><code>{dedent(@code)}</code></pre>
      {render_slot(@inner_block)}
    </section>
    """
  end

  defp dedent(code) do
    lines = code |> String.trim_trailing() |> String.split("\n") |> Enum.drop_while(&(&1 == ""))

    indent =
      lines
      |> Enum.reject(&(String.trim(&1) == ""))
      |> Enum.map(&(String.length(&1) - String.length(String.trim_leading(&1))))
      |> Enum.min(fn -> 0 end)

    Enum.map_join(lines, "\n", &String.slice(&1, indent..-1//1))
  end

  attr :title, :string, required: true
  attr :class, :any, default: nil
  slot :note
  slot :inner_block, required: true

  def demo(assigns) do
    ~H"""
    <div class="space-y-3 border-t border-base-content/10 pt-5">
      <h3 class="text-sm font-semibold">{@title}</h3>
      <div class={@class}>{render_slot(@inner_block)}</div>
      <p :if={@note != []} class="text-xs text-base-content/70 max-w-prose">{render_slot(@note)}</p>
    </div>
    """
  end
end
