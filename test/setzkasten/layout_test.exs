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

    doc = parse(~H|<.card title="Liste" bleed={:phone}>
  <:list>
    <ul></ul>
  </:list>
</.card>|)
    assert count(doc, ".card-body") == 0
    assert classes(doc, "section > div:first-child") == ~w(px-6 pt-6 pb-2)
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
end
