defmodule Setzkasten.FeedbackTest do
  use Setzkasten.ComponentCase, async: true

  test "alert is soft with base-content text, tone icon and status role" do
    assigns = %{}
    doc = parse(~H|<.alert tone={:warning} title="API-Key fehlt">Text</.alert>|)

    assert classes(doc, "div") |> Enum.take(4) ==
             ~w(alert alert-soft text-base-content alert-warning)

    assert attr(doc, "div", "role") == "status"
    assert "text-warning" in classes(doc, "svg")
    assert text(doc, "p.font-semibold") == "API-Key fehlt"
  end

  test "error alerts are alerts with an error-ink icon" do
    assigns = %{}
    doc = parse(~H|<.alert tone={:error}>Kaputt</.alert>|)
    assert attr(doc, "div", "role") == "alert"
    assert "text-error-ink" in classes(doc, "svg")
  end

  test "alert actions move below the text on phones" do
    assigns = %{}
    doc = parse(~H|<.alert>
  x<:actions><.button size={:sm}>Los</.button></:actions>
</.alert>|)
    assert "max-sm:grid-flow-row" in classes(doc, ".alert")
    assert "max-sm:col-start-2" in classes(doc, ".alert > div:last-child")
  end

  test "busy alert shows a spinner and can hide the icon" do
    assigns = %{}
    doc = parse(~H|<.alert busy>Lädt</.alert>|)
    assert attr(doc, ".alert", "aria-busy") == "true"
    assert count(doc, ".loading") == 1
    assert count(parse(~H|<.alert icon={false}>x</.alert>|), "svg") == 0
  end

  test "flash info is alert-info in a top toast with a real dismiss button" do
    assigns = %{flash: %{"info" => "Gespeichert"}}
    doc = parse(~H|<.flash kind={:info} flash={@flash} />|)
    assert "toast-top" in classes(doc, ".toast")
    assert "alert-info" in classes(doc, "#flash-info")
    assert attr(doc, "#flash-info", "role") == "status"
    assert attr(doc, "button", "aria-label") == "Schließen"
    assert attr(doc, "button", "phx-click") =~ "lv:clear-flash"
  end

  test "alert with a close button keeps it at the end on phones" do
    assigns = %{}

    doc =
      parse(~H"""
      <.alert tone={:warning} on_close={JS.push("dismiss", value: %{id: 1})} close_label="Close">
        Nicht veröffentlicht.
      </.alert>
      """)

    assert attr(doc, ".alert > button", "aria-label") == "Close"
    assert attr(doc, ".alert > button", "phx-click") =~ "dismiss"
    assert "grid-cols-[auto_minmax(0,1fr)_auto]" in classes(doc, ".alert")

    doc =
      parse(~H"""
      <.alert on_close="dismiss">
        Text<:actions><.button size={:sm}>Ok</.button></:actions>
      </.alert>
      """)

    assert "sm:grid-cols-[auto_minmax(0,1fr)_auto_auto]" in classes(doc, ".alert")
    assert "max-sm:col-start-3" in classes(doc, ".alert > button")
  end

  test "flash renders nothing without a message" do
    assigns = %{}
    assert count(parse(~H|<.flash kind={:error} flash={%{}} />|), ".alert") == 0
  end

  test "flash group stacks flashes and the hidden connection errors" do
    assigns = %{flash: %{"error" => "Fehler"}}
    doc = parse(~H|<.flash_group flash={@flash} />|)
    assert count(doc, "#flash-group .alert") == 3
    assert attr(doc, "#client-error", "hidden") != nil

    doc = parse(~H|<.flash_group flash={@flash} close_label="Close" />|)
    assert attr(doc, "#client-error button", "aria-label") == "Close"
  end

  test "badge with dot by default, solid for alarms" do
    assigns = %{}
    doc = parse(~H|<.badge tone={:success}>Veröffentlicht</.badge>|)
    assert classes(doc, "span.badge") == ~w(badge badge-sm)
    assert classes(doc, ".status") == ~w(status status-success)

    doc = parse(~H|<.badge tone={:error} style={:solid}>überzogen</.badge>|)
    assert "badge-error" in classes(doc, ".badge")
    assert count(doc, ".status") == 0
  end

  test "icon-only badge is named" do
    assigns = %{}
    doc = parse(~H|<.badge icon="repeat" label="Wiederkehrend" />|)
    assert attr(doc, ".badge", "role") == "img"
    assert attr(doc, ".badge", "aria-label") == "Wiederkehrend"
  end

  test "empty state inline and page layouts" do
    assigns = %{}
    doc = parse(~H|<.empty_state icon="inbox" title="Leer">
  Text<:action>A</:action>
</.empty_state>|)
    assert text(doc, "p.font-semibold") == "Leer"
    assert "py-6" in classes(doc, "div")

    doc = parse(~H|<.empty_state plush="receipt" layout={:page} title="Leer">T</.empty_state>|)
    assert text(doc, "h2.text-lg") == "Leer"
    assert count(doc, "img.size-12") == 2
  end
end
