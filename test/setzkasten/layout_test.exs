defmodule Setzkasten.LayoutTest do
  use Setzkasten.ComponentCase, async: true

  test "header with back link, subtitle, badge and actions" do
    assigns = %{}

    doc =
      parse(~H"""
      <.header back="/bestand" back_label="Bestand">
        Titel
        <:subtitle>Sub</:subtitle>
        <:badge>
          <.badge>b</.badge>
        </:badge>
        <:actions><.button>A</.button></:actions>
      </.header>
      """)

    assert text(doc, "h1.text-2xl") == "Titel"
    assert attr(doc, "a.btn-ghost", "href") == "/bestand"
    assert Enum.all?(~w(basis-40 min-h-10), &(&1 in classes(doc, "header > div.grow")))
    assert text(doc, "p.text-sm") == "Sub"
  end

  test "section heading with count" do
    assigns = %{}
    doc = parse(~H|<.section_heading count={3} level={3}>Depots</.section_heading>|)

    assert classes(doc, "h3") ==
             ~w(flex min-w-0 items-center gap-2 text-lg font-semibold wrap-anywhere)

    # The count is quiet text, no badge.
    assert text(doc, "h3 span.tabular-nums") == "3"
    assert count(doc, "h3 .badge") == 0
  end

  test "card is flat with hairline; list slot uses a header strip" do
    assigns = %{}
    doc = parse(~H|<.card title="Kosten">
  Body<:footer>F</:footer>
</.card>|)

    assert classes(doc, "section") |> Enum.take(4) ==
             ~w(card bg-base-100 border border-base-content/10)

    assert text(doc, ".card-body h2.card-title") == "Kosten"
    assert text(doc, "section > div.border-t") == "F"
    # The footer follows a card's --card-p (tighter phone cards) as the body does.
    assert "px-[var(--card-p,1.5rem)]" in classes(doc, "section > div.border-t")

    doc = parse(~H|<.card title="Liste" bleed={:phone}>
  <:list>
    <ul></ul>
  </:list>
</.card>|)
    assert count(doc, ".card-body") == 0

    assert classes(doc, "section > div:first-child") ==
             ~w|px-[var(--card-p,1.5rem)] pt-[var(--card-p,1.5rem)] pb-2|

    assert "max-sm:-mx-4" in classes(doc, "section")
  end

  test "clickable card stretches its title link" do
    assigns = %{}
    doc = parse(~H|<.card title="Depot" navigate="/d">x</.card>|)
    assert "after:inset-0" in classes(doc, "h2 a")
    assert "has-[a:focus-visible]:outline-2" in classes(doc, "section")
  end

  test "card leading slot sits before the title" do
    assigns = %{}

    doc =
      parse(~H"""
      <.card title="Feldnotizen" subtitle="feldnotizen.example" navigate="/s">
        <:leading><span class="tile">🪶</span></:leading>
      </.card>
      """)

    assert count(doc, ".card-body > div > div:first-child > span.tile") == 1
    assert "flex-1" in classes(doc, ".card-body > div > div:nth-child(2)")
  end

  test "theme toggle: sr-only radios in label buttons, hook, legend" do
    assigns = %{}
    doc = parse(~H|<.theme_toggle value="dark" />|)
    assert attr(doc, "#theme-toggle", "phx-hook") == "Setzkasten.Components.Layout.ThemeToggle"
    assert attr(doc, "#theme-toggle", "data-store") == "local"
    assert count(doc, "label.btn input[type=radio].sr-only") == 3
    assert attr(doc, "input[value=dark]", "checked") != nil
    assert "has-checked:setzkasten-selected" in classes(doc, "label")
    assert text(doc, "legend") == "Farbschema"
    assert Enum.all?(~w(btn btn-square), &(&1 in classes(doc, "label")))
    refute "btn-sm" in classes(doc, "label")
    assert attr(doc, "label:has(input[value=system])", "title") == "System"
    assert text(doc, "label:has(input[value=dark]) span.sr-only") == "Dunkel"

    segments = rendered_to_string(~H|<.theme_toggle />|) |> String.split("<label") |> tl()

    for {segment, icon} <- Enum.zip(segments, ~w(sun-moon sun moon)) do
      {:safe, body} = Setzkasten.Lucide.svg(icon)
      assert segment =~ body, icon
    end

    doc =
      parse(
        ~H|<.theme_toggle labels={%{"system" => "Auto", "light" => "Light", "dark" => "Dark"}} />|
      )

    assert attr(doc, "label:has(input[value=system])", "title") == "Auto"
    assert text(doc, "label:has(input[value=light]) span.sr-only") == "Light"
  end

  test "a compact theme toggle is one button showing the scheme, with the choices in a menu" do
    assigns = %{}
    doc = parse(~H|<.theme_toggle id="tt" value="light" compact />|)

    assert attr(doc, "#tt", "phx-hook") == "Setzkasten.Components.Layout.ThemeToggle"
    menu = "#tt > details#tt-menu"
    assert Enum.all?(~w(dropdown dropdown-end), &(&1 in classes(doc, menu)))
    assert attr(doc, menu, "phx-click-away") =~ "open"
    assert ~w(btn btn-ghost btn-square) == classes(doc, "#{menu} > summary")
    assert attr(doc, "#{menu} > summary", "title") == "Farbschema"
    assert text(doc, "#{menu} > summary span.sr-only") == "Farbschema"

    icons = find(doc, "#{menu} > summary svg")
    assert Enum.count(icons) == 3

    assert "[:root[data-theme$=light]_&]:block" in classes(
             doc,
             "#{menu} > summary svg:nth-of-type(2)"
           )

    assert "[:root:not([data-theme$=light],[data-theme$=dark])_&]:block" in classes(
             doc,
             "#{menu} > summary svg:nth-of-type(1)"
           )

    assert count(doc, "#{menu} fieldset ul.menu li label input[type=radio].sr-only") == 3
    assert text(doc, "#{menu} fieldset legend") == "Farbschema"
    assert attr(doc, "input[value=light]", "checked") != nil
    assert attr(doc, "input[value=dark]", "phx-keydown") =~ "focus_first"
    assert text(doc, "label:has(input[value=dark])") == "Dunkel"

    hook = colocated_js("Setzkasten.Components.Layout")
    assert hook =~ ~s[menu.querySelector("summary").focus()]
    assert hook =~ ~s[this.el.contains(menu)]
    assert hook =~ ~s[this.el.addEventListener("click", (e) => {]

    assert hook =~
             ~s|if (e.key === "Escape" && this.el.querySelector("details[open]")) e.preventDefault()|

    doc = parse(~H|<.theme_toggle store={:server} on_change="t" compact />|)
    assert attr(doc, "form details input[value=dark]", "name") == "theme"

    doc = parse(~H|<.theme_toggle store={:server} value={nil} on_change="t" compact />|)
    assert attr(doc, "input[value=system]", "checked") != nil
  end

  test "server-stored theme toggle is a form sending the change" do
    assigns = %{}
    doc = parse(~H|<.theme_toggle store={:server} on_change="set-theme" />|)
    assert attr(doc, "form", "phx-change") == "set-theme"
    assert attr(doc, "input[value=light]", "name") == "theme"
  end

  test "theme script and meta" do
    assigns = %{}
    assert rendered_to_string(~H|<.theme_script nonce="abc" />|) =~ ~s(nonce="abc")
    doc = parse(~H|<.theme_meta />|)
    assert attr(doc, "meta[media*=light]", "content") == "#ffffff"
    assert attr(doc, "meta[media*=dark]", "content") == "#202328"
  end

  test "the early script applies a collapsed sidebar before paint" do
    assigns = %{}
    script = rendered_to_string(~H|<.theme_script />|)
    assert script =~ ~s[localStorage.getItem("setzkasten:sidebar") === "collapsed"]
    assert script =~ ~s[r.setAttribute("data-sidebar", "collapsed")]
  end

  test "the early script publishes the keyboard inset on every page, only while typing on a touch screen" do
    assigns = %{}
    script = rendered_to_string(~H|<.theme_script />|)
    assert script =~ ~s|v.addEventListener("resize", follow)|
    assert script =~ ~s|v.addEventListener("scroll", follow)|
    assert script =~ ~s|addEventListener("focusin", follow)|
    assert script =~ ~s|addEventListener("focusout", follow)|
    assert script =~ ~s|setProperty("--setzkasten-keyboard-inset"|
    assert script =~ "innerHeight - v.height - v.offsetTop"

    # The same condition as the CSS rule that hides the dock, so a pinch-zoom or a scrollbar lifts nothing.
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    [typing] =
      Regex.run(~r/@media \(pointer: coarse\) \{\s*:root:has\((.+)\) \{/, css,
        capture: :all_but_first
      )

    assert script =~ ~s|const touch = matchMedia("(pointer: coarse)")|
    assert script =~ "const typing = '#{typing}'"
    assert script =~ "touch.matches && document.querySelector(typing) ?"
  end

  test "an explicit theme choice wins over the media theme-color metas" do
    assigns = %{}
    script = rendered_to_string(~H|<.theme_script />|)
    assert script =~ ~s(m.id = "setzkasten-theme-color")
    assert script =~ ~s(meta[name="theme-color"][media*=")

    hook = colocated_js("Setzkasten.Components.Layout")
    assert hook =~ "setzkasten-theme-color"
    assert hook =~ "syncMeta()"
  end

  test "a theme choice reveals as a soft circle through a view transition, skipped with reduced motion" do
    hook = colocated_js("Setzkasten.Components.Layout")
    assert hook =~ "document.startViewTransition"
    assert hook =~ "prefers-reduced-motion: reduce"
    assert hook =~ ~s(style.setProperty("--setzkasten-reveal-x")

    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    assert css =~ ":root[data-setzkasten-reveal]::view-transition-new(root)"
    assert css =~ "--setzkasten-duration-reveal: 700ms"
    assert css =~ "--setzkasten-ease-in-out: cubic-bezier(0.65, 0, 0.35, 1)"
    assert css =~ "@property --setzkasten-reveal-radius"
    assert hook =~ ~s[root.removeAttribute("style")]
  end

  test "theme tokens that equal a role follow it, so an app overrides the role once" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    # Both dark blocks: the system one and the explicit choice.
    for declaration <- [
          "--color-success-ink: var(--color-success);",
          "--color-error-ink: var(--color-error);",
          "--color-sidebar-negative: var(--color-error-ink);"
        ] do
      assert length(String.split(css, declaration)) == 3, declaration
    end

    assert css =~
             "--color-selected: var(--color-neutral);\n    --color-selected-content: var(--color-neutral-content);"
  end

  test "info and warning inks: their roles in dark, utilities everywhere" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    for declaration <- [
          "--color-info-ink: var(--color-info);",
          "--color-warning-ink: var(--color-warning);"
        ] do
      assert length(String.split(css, declaration)) == 3, declaration
    end

    assert css =~ ~r/@theme \{[^}]*--color-info-ink: oklch[^}]*--color-warning-ink: oklch/
  end

  test "chart series are graphic colours of their own: 3:1 on base-100 and base-200, fill = line, bars 1, 4, 5, 8 on their track" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    series = Enum.map(1..8, &"chart-#{&1}") ++ ["chart-other"]

    refute css =~ ~r/--color-chart-[\w-]+: var\(--color-(?!chart-)/

    for name <- series do
      fill = "--color-#{name}-fill: var(--color-#{name});"
      assert length(String.split(css, fill)) == 4, fill
      assert css =~ ~r/@theme \{[^}]*--color-#{name}-fill: oklch[^}]*--color-#{name}: oklch/
    end

    for marker <- [
          ~s([data-theme="zipfel-light"] {),
          ":root:not([data-theme]) {",
          ~s([data-theme="zipfel-dark"] {)
        ] do
      tokens = theme_tokens(css, marker)

      for name <- series, surface <- ~w(base-100 base-200) do
        assert contrast(tokens[name], tokens[surface]) >= 3, "#{marker} #{name} on #{surface}"
      end

      for name <- ~w(chart-1 chart-4 chart-5 chart-8), surface <- ~w(base-100 base-200) do
        on_track = contrast(tokens[name], track(tokens[name], tokens[surface]))
        assert on_track >= 3, "#{marker} #{name} bar on its track over #{surface}"
      end
    end
  end

  test "every ink is text-grade: 4.5:1 on base-100 and base-200 in each theme" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    for marker <- [
          ~s([data-theme="zipfel-light"] {),
          ":root:not([data-theme]) {",
          ~s([data-theme="zipfel-dark"] {)
        ] do
      tokens = theme_tokens(css, marker)
      inks = tokens |> Map.keys() |> Enum.filter(&String.ends_with?(&1, "-ink"))
      assert Enum.sort(inks) == ~w(error-ink info-ink success-ink warning-ink)

      for ink <- inks, surface <- ~w(base-100 base-200) do
        assert contrast(tokens[ink], tokens[surface]) >= 4.5, "#{marker} #{ink} on #{surface}"
      end
    end
  end

  test "header and card text break long unbroken strings" do
    assigns = %{}

    doc =
      parse(~H"""
      <.header>
        a-very-long-hostname.example.com<:subtitle>Sub</:subtitle>
      </.header>
      """)

    assert Enum.all?(~w(min-w-0 wrap-anywhere), &(&1 in classes(doc, "h1")))
    assert "wrap-anywhere" in classes(doc, "p.text-sm")

    card = parse(~H|<.card title="T" subtitle="S">x</.card>|)
    assert "wrap-anywhere" in classes(card, "p.text-sm")
  end

  test "a section heading carries its own gap, none as the first child" do
    assigns = %{}
    doc = parse(~H|<.section_heading>Depots</.section_heading>|)
    assert Enum.all?(~w(mt-8 first:mt-0), &(&1 in classes(doc, "div")))

    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    refute css =~ "section-heading"
  end

  test "a small section heading fits a popover: 14px and a smaller gap" do
    assigns = %{}
    doc = parse(~H|<.section_heading size={:sm}>Zusammenfassung</.section_heading>|)
    assert Enum.all?(~w(mt-4 first:mt-0), &(&1 in classes(doc, "div")))
    assert "text-sm" in classes(doc, "h2")
    refute "text-lg" in classes(doc, "h2")
  end

  test "the header's back link navigates, patches or loads the page" do
    assigns = %{}
    doc = parse(~H|<.header back="/a">T</.header>|)
    assert attr(doc, "header a", "data-phx-link") == "redirect"

    doc = parse(~H|<.header back_patch="/b" back_label="Liste">T</.header>|)
    assert attr(doc, "header a", "data-phx-link") == "patch"
    assert text(doc, "header a") == "Liste"

    doc = parse(~H|<.header back_href="/settings">T</.header>|)
    assert attr(doc, "header a", "href") == "/settings"
    assert attr(doc, "header a", "data-phx-link") == nil
    assert count(parse(~H|<.header>T</.header>|), "header a") == 0
  end

  defp theme_tokens(css, marker) do
    block =
      css |> String.split(marker, parts: 2) |> List.last() |> String.split("}", parts: 2) |> hd()

    values =
      ~r/--color-([\w-]+): (?:oklch\(([\d.]+)% ([\d.]+) ([\d.]+)\)|var\(--color-([\w-]+)\));/
      |> Regex.scan(block)
      |> Map.new(fn
        [_, name, l, c, h] -> {name, Enum.map([l, c, h], &(&1 |> Float.parse() |> elem(0)))}
        [_, name, "", "", "", ref] -> {name, ref}
      end)

    Map.new(values, fn {name, value} -> {name, resolve(values, value)} end)
  end

  defp resolve(values, ref) when is_binary(ref), do: resolve(values, values[ref])
  defp resolve(_values, oklch), do: oklch

  defp contrast(a, b) do
    [hi, lo] = Enum.sort([luminance(a), luminance(b)], :desc)
    (hi + 0.05) / (lo + 0.05)
  end

  # daisyUI's progress track: the bar colour at 20 % alpha, composited over the surface in sRGB.
  defp track(color, surface) do
    {:srgb, Enum.zip_with(srgb(color), srgb(surface), &(0.2 * &1 + 0.8 * &2))}
  end

  defp luminance(color) do
    color |> linear() |> Enum.zip_with([0.2126, 0.7152, 0.0722], &(&1 * &2)) |> Enum.sum()
  end

  defp srgb(color), do: color |> linear() |> Enum.map(&encode/1)

  defp encode(c) when c <= 0.0031308, do: 12.92 * c
  defp encode(c), do: 1.055 * c ** (1 / 2.4) - 0.055

  defp decode(c) when c <= 0.04045, do: c / 12.92
  defp decode(c), do: ((c + 0.055) / 1.055) ** 2.4

  defp linear({:srgb, rgb}), do: Enum.map(rgb, &decode/1)

  # OKLCH to linear sRGB (Björn Ottosson's matrices), clipped to the gamut.
  defp linear([l, c, h]) do
    {a, b} = {c * :math.cos(h * :math.pi() / 180), c * :math.sin(h * :math.pi() / 180)}
    l = l / 100

    [lms_l, lms_m, lms_s] =
      Enum.map(
        [
          l + 0.3963377774 * a + 0.2158037573 * b,
          l - 0.1055613458 * a - 0.0638541728 * b,
          l - 0.0894841775 * a - 1.2914855480 * b
        ],
        &(&1 ** 3)
      )

    Enum.map(
      [
        4.0767416621 * lms_l - 3.3077115913 * lms_m + 0.2309699292 * lms_s,
        -1.2684380046 * lms_l + 2.6097574011 * lms_m - 0.3413193965 * lms_s,
        -0.0041960863 * lms_l - 0.7034186147 * lms_m + 1.7076147010 * lms_s
      ],
      &min(max(&1, 0.0), 1.0)
    )
  end
end
