defmodule Setzkasten.IconsTest do
  use Setzkasten.ComponentCase, async: true

  test "icon renders a decorative lucide svg with default size" do
    assigns = %{}
    doc = parse(~H|<.icon name="trash-2" />|)
    assert classes(doc, "svg") == ["lucide", "size-4"]
    assert attr(doc, "svg", "aria-hidden") == "true"
    assert count(doc, "svg path") > 0
  end

  test "a size class replaces the default size" do
    assigns = %{}
    doc = parse(~H|<.icon name="x" class="size-6 text-error-ink" />|)
    assert classes(doc, "svg") == ["lucide", "size-6", "text-error-ink"]
  end

  test "a label makes the icon an image with a title" do
    assigns = %{}
    doc = parse(~H|<.icon name="circle-alert" label="Fehler" />|)
    assert attr(doc, "svg", "role") == "img"
    assert attr(doc, "svg", "aria-hidden") == nil
    assert text(doc, "svg title") == "Fehler"
  end

  test "app icons resolve through the configured module" do
    assigns = %{}
    assert count(parse(~H|<.icon name="plus" />|), "svg") == 1
  end

  test "unknown icons raise" do
    assigns = %{}
    assert_raise ArgumentError, ~r/unknown icon/, fn -> parse(~H|<.icon name="nope" />|) end
  end

  test "built-in set covers what the components draw" do
    for name <-
          ~w(chevron-left chevron-right chevron-down x ellipsis-vertical circle-alert
                   triangle-alert info circle-check trash-2 sun-moon sun moon panel-left-open panel-left-close
                   check plus upload) do
      assert Setzkasten.Lucide.svg(name), name
    end
  end

  @tag :tmp_dir
  test "an icon path without SVG files fails to compile", %{tmp_dir: tmp_dir} do
    for dir <- [tmp_dir, Path.join(tmp_dir, "missing")] do
      message = "no Lucide SVG files in #{dir} (path: #{inspect(dir)})"

      assert_raise ArgumentError, message, fn ->
        Code.eval_quoted(
          quote do
            defmodule Setzkasten.IconsTest.Empty do
              use Setzkasten.Icons, path: unquote(dir)
            end
          end
        )
      end
    end
  end

  test "plush with a dark file renders two images that swap with the theme" do
    assigns = %{}
    doc = parse(~H|<.plush src="/cart.webp" dark_src="/cart-dark.webp" size={:lg} />|)
    assert count(doc, "img.plush") == 2
    assert "dark:hidden" in classes(doc, "img:first-child")
    assert attr(doc, "img", "width") == "32"
    assert attr(doc, "img", "alt") == ""
  end

  test "plush with a dark file keeps ids unique, other attrs on both images" do
    assigns = %{}

    doc =
      parse(~H|<.plush src="/a.webp" dark_src="/a-dark.webp" id="mascot" title="Maskottchen" />|)

    assert attr(doc, "img#mascot", "src") == "/a.webp"
    assert attr(doc, "img#mascot-dark", "src") == "/a-dark.webp"
    assert doc |> find("img") |> LazyHTML.attribute("title") == ["Maskottchen", "Maskottchen"]

    assert attr(parse(~H|<.plush src="/a.webp" id="mascot" />|), "img", "id") == "mascot"
  end

  test "plush without a dark file renders one image, unknown names nothing" do
    assigns = %{}
    assert count(parse(~H|<.plush name="nav-solar" />|), "img") == 1
    assert count(parse(~H|<.plush name="missing" />|), "img") == 0
  end

  test "a size class on a plush replaces its size class, width and height stay" do
    assigns = %{}

    doc =
      parse(
        ~H|<.plush src="/a.webp" dark_src="/a-dark.webp" size={:xl} class="size-[clamp(2rem,8vw,3rem)]" />|
      )

    for img <- ["img:first-child", "img:last-child"] do
      assert "size-[clamp(2rem,8vw,3rem)]" in classes(doc, img)
      refute "size-12" in classes(doc, img)
    end

    assert attr(doc, "img", "width") == "48"

    assert "size-12" in classes(
             parse(~H|<.plush src="/a.webp" size={:xl} class="mx-auto" />|),
             "img"
           )
  end

  test "plush takes direct sources" do
    assigns = %{}
    doc = parse(~H|<.plush src="/a.webp" size={:xl} alt="Maus" />|)
    assert attr(doc, "img", "src") == "/a.webp"
    assert "size-12" in classes(doc, "img")
    assert attr(doc, "img", "alt") == "Maus"
  end
end
