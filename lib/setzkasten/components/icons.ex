defmodule Setzkasten.Components.Icons do
  @moduledoc """
  Lucide stroke icons (`<.icon>`) and plush raster icons (`<.plush>`).

  Class names are `lucide` and `plush`, never `icon`.
  """
  use Phoenix.Component

  @doc """
  Renders a Lucide stroke icon as inline SVG in `currentColor`.

  Decorative by default (`aria-hidden`); with `label` it becomes `role="img"` with a `<title>`.
  Default size `size-4` (16px, next to `text-sm`); a `size-*` class in `class` replaces it.
  Names resolve through `Setzkasten.Icons.fetch!/1`.

      <.icon name="trash-2" />
      <.icon name="circle-alert" class="size-5 text-error-ink" label="Fehler" />
  """
  attr :name, :string, required: true
  attr :label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  def icon(assigns) do
    assigns =
      assigns
      |> assign(:body, Setzkasten.Icons.fetch!(assigns.name))
      |> assign(:size, if(sized?(assigns.class), do: nil, else: "size-4"))

    ~H"""
    <svg
      class={["lucide", @size, @class]}
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden={if(@label, do: nil, else: "true")}
      role={@label && "img"}
      aria-label={@label}
      {@rest}
    ><title :if={@label}>{@label}</title>{@body}</svg>
    """
  end

  @plush_sizes %{
    sm: {"size-5", 20},
    md: {"size-6", 24},
    lg: {"size-8", 32},
    xl: {"size-12", 48},
    xxl: {"size-24", 96}
  }

  @doc """
  Renders a plush WebP icon. With a dark file it renders two images and lets the theme pick
  one (`dark:hidden` / `hidden dark:inline-block`), so an explicit theme choice swaps it too.
  Global attrs go on both; an `id` stays on the light image and the dark one takes `<id>-dark`.

  Sizes: `:sm` 20px (sidebar), `:md` 24px (dock, top-bar menu), `:lg` 32px (list leading), `:xl` 48px (empty
  pages), `:xxl` 96px (empty pages where the plush is the figure). Sources come from the
  module configured as `config :setzkasten, plush: …`
  (see `Setzkasten.Plush`) or from `src`/`dark_src`. Decorative by default (`alt=""`).

  As with `icon`, a `size-*` class in `class` replaces the size class, e.g. to scale with its
  container (`size-[clamp(2rem,8vw,3rem)]`); `width` and `height` still come from `size`, the
  box and aspect ratio the image has before the CSS applies.

      <.plush name="cart" size={:lg} />
      <.plush src={~p"/images/mascot.webp"} size={:xl} alt="Maskottchen" />
  """
  attr :name, :string, default: nil
  attr :src, :string, default: nil
  attr :dark_src, :string, default: nil
  attr :size, :atom, default: :md, values: [:sm, :md, :lg, :xl, :xxl]
  attr :alt, :string, default: ""
  attr :class, :any, default: nil
  attr :rest, :global

  def plush(assigns) do
    {light, dark} =
      if assigns.src,
        do: {assigns.src, assigns.dark_src},
        else: Setzkasten.Plush.sources(assigns.name)

    {size_class, px} = Map.fetch!(@plush_sizes, assigns.size)

    assigns =
      assign(assigns,
        light: light,
        dark: dark,
        size_class: if(sized?(assigns.class), do: nil, else: size_class),
        px: px,
        dark_rest: dark_rest(assigns.rest)
      )

    ~H"""
    <img
      :if={@light}
      class={["plush object-contain shrink-0", @size_class, @dark && "dark:hidden", @class]}
      src={@light}
      width={@px}
      height={@px}
      alt={@alt}
      {@rest}
    /><img
      :if={@light && @dark}
      class={["plush object-contain shrink-0 hidden dark:inline-block", @size_class, @class]}
      src={@dark}
      width={@px}
      height={@px}
      alt={@alt}
      {@dark_rest}
    />
    """
  end

  defp dark_rest(%{id: id} = rest) when is_binary(id), do: %{rest | id: "#{id}-dark"}
  defp dark_rest(rest), do: rest

  defp sized?(nil), do: false
  defp sized?(class) when is_binary(class), do: String.contains?(class, "size-")
  defp sized?(class) when is_list(class), do: Enum.any?(class, &(is_binary(&1) and sized?(&1)))
  defp sized?(_), do: false
end
