defmodule Setzkasten.FeedbackTest do
  use Setzkasten.ComponentCase, async: true

  test "alert is soft with base-content text, tone icon and status role" do
    assigns = %{}
    doc = parse(~H|<.alert tone={:warning} title="API-Key fehlt">Text</.alert>|)

    assert classes(doc, "div") |> Enum.take(4) ==
             ~w(alert alert-soft text-base-content alert-warning)

    assert attr(doc, "div", "role") == "status"
    assert "text-warning-ink" in classes(doc, "svg")
    assert text(doc, "p.font-semibold") == "API-Key fehlt"
  end

  test "error alerts are alerts with an error-ink icon" do
    assigns = %{}
    doc = parse(~H|<.alert tone={:error}>Kaputt</.alert>|)
    assert attr(doc, "div", "role") == "alert"
    assert "text-error-ink" in classes(doc, "svg")
  end

  test "alert actions move below the text when the alert itself is narrow" do
    assigns = %{}
    doc = parse(~H|<.alert>
  x<:actions><.button size={:sm}>Los</.button></:actions>
</.alert>|)
    # A container query: also in a narrow side column on a wide screen.
    assert Enum.all?(~w(@container block), &(&1 in classes(doc, ".alert")))

    # Containment only where a query needs it: it would collapse an alert in a shrink-to-fit parent.
    refute "@container" in classes(parse(~H|<.alert>Text</.alert>|), ".alert")
    assert "@max-lg:grid-flow-row" in classes(doc, ".alert > div")
    refute Enum.any?(classes(doc, ".alert > div"), &String.starts_with?(&1, "max-sm:"))
    assert "@max-lg:col-start-2" in classes(doc, ".alert > div > div:last-child")
  end

  test "alert content spans the full width, so actions end at the alert's edge" do
    assigns = %{}
    doc = parse(~H|<.alert>
  x<:actions><.button size={:sm}>Los</.button></:actions>
</.alert>|)
    # daisyUI's justify-items: start shrinks the block's inner grid to its content.
    assert "justify-items-stretch" in classes(doc, ".alert")
  end

  test "busy alert shows a spinner and can hide the icon" do
    assigns = %{}
    doc = parse(~H|<.alert busy>Lädt</.alert>|)
    assert attr(doc, ".alert", "aria-busy") == "true"

    assert classes(doc, ".loading") ==
             ~w(loading loading-spinner loading-sm motion-reduce:hidden text-info-ink)

    assert classes(doc, "svg.lucide") == ~w(lucide size-5 motion-safe:hidden text-info-ink)
    assert count(parse(~H|<.alert icon={false}>x</.alert>|), "svg") == 0
  end

  test "flash info is alert-info in a bottom toast with a real dismiss button" do
    assigns = %{flash: %{"info" => "Gespeichert"}}
    doc = parse(~H|<.flash kind={:info} flash={@flash} />|)
    assert "setzkasten-toasts" in classes(doc, ".toast")
    refute "toast-top" in classes(doc, ".toast")
    assert "alert-info" in classes(doc, "#flash-info")
    assert attr(doc, "#flash-info", "role") == "status"
    assert "text-info-ink" in classes(doc, "#flash-info svg")
    assert attr(doc, "button", "aria-label") == "Schließen"
    assert attr(doc, "button", "phx-click") =~ "lv:clear-flash"
    click = attr(doc, "button", "phx-click")
    assert click =~ "duration-(--setzkasten-duration-exit)"
    assert click =~ "motion-safe:translate-y-2"
    refute click =~ "-translate-y-2"
    assert click =~ ~s("time":150)
  end

  test "an info flash closes itself as its ✕ does, an error flash stays" do
    assigns = %{flash: %{"info" => "Gespeichert", "error" => "Kaputt"}}
    doc = parse(~H|<.flash_group flash={@flash} />|)
    assert attr(doc, "#flash-info", "phx-hook") == "Setzkasten.Components.Feedback.AutoDismiss"

    assert attr(doc, "#flash-info", "data-dismiss") ==
             attr(doc, "#flash-info button", "phx-click")

    assert attr(doc, "#flash-error", "phx-hook") == nil
    assert attr(doc, "#client-error", "phx-hook") == nil

    hook = colocated_js("Setzkasten.Components.Feedback")
    assert hook =~ "this.timer = setTimeout(() => this.js().exec(this.el.dataset.dismiss), 5000)"
    assert Enum.all?(~w(pointerenter pointerleave focusin focusout), &(hook =~ &1))

    # Resuming restarts the full 5 s, unless the pointer is still over it or focus is still inside.
    assert hook =~ "if (!this.pointer && !this.el.contains(focused)) this.start()"
    assert hook =~ ~s|this.el.addEventListener("focusout", (e) => this.resume(e.relatedTarget))|
    refute hook =~ ~s|matches(":hover|
  end

  test "each toast is a single root and a diff skips the ones that did not change, so no timer restarts" do
    toast = %{id: "toast-1", message: "Milch hinzugefügt", action: nil, on_action: nil}
    old = %{"info" => "Gespeichert", "toast" => toast}

    rendered = flash_group(%{flash: old}).dynamic.(false)
    alerts = for %Phoenix.LiveView.Rendered{static: [_, _ | _]} = r <- rendered, do: r
    assert length(alerts) == 4
    assert Enum.all?(alerts, & &1.root)

    diff =
      flash_group(%{flash: Map.delete(old, "toast"), __changed__: %{flash: old}}).dynamic.(true)

    assert [%Phoenix.LiveView.Rendered{static: [""]}] = Enum.reject(diff, &is_nil/1)
  end

  test "a flash with slot content stays and its ✕ only hides it, never clearing the real flash" do
    assigns = %{flash: %{"info" => "Echte Meldung"}}
    doc = parse(~H|<.flash kind={:info} flash={@flash}>Vorschau</.flash>|)

    assert text(doc, "#flash-info p") == "Vorschau"
    assert attr(doc, "#flash-info", "phx-hook") == nil
    assert attr(doc, "#flash-info", "data-dismiss") == nil

    click = attr(doc, "#flash-info button", "phx-click")
    assert pushes(click) == []
    assert click =~ ~s("to":"#flash-info")

    doc = parse(~H|<.flash_group flash={%{}} />|)
    assert pushes(attr(doc, "#client-error button", "phx-click")) == []
  end

  test "put_toast stores the message, the action and a fresh key under :toast" do
    socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, flash: %{}}}
    undo = JS.push("undo", value: %{id: 1})
    socket = put_toast(socket, "Bananen abgehakt", action: "Rückgängig", on_action: undo)

    assert %{message: "Bananen abgehakt", action: "Rückgängig", on_action: ^undo, id: id} =
             Phoenix.Flash.get(socket.assigns.flash, :toast)

    assert id =~ ~r/^toast-\d+$/

    socket = put_toast(socket, "Milch hinzugefügt")
    toast = Phoenix.Flash.get(socket.assigns.flash, :toast)
    assert %{message: "Milch hinzugefügt", action: nil, on_action: nil} = toast
    assert toast.id != id
    assert Map.keys(socket.assigns.flash) == ["toast"]
  end

  test "put_toast works on a conn, so a controller can redirect with it" do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Phoenix.Controller.fetch_flash([])
      |> put_toast("Liste geleert", action: "Rückgängig", on_action: "restore")

    assert %{message: "Liste geleert", on_action: "restore"} =
             Phoenix.Flash.get(conn.assigns.flash, :toast)
  end

  test "an action toast: neutral surface, its text and one ghost action, no ✕" do
    assigns = %{
      flash: %{
        "toast" => %{
          message: "Bananen abgehakt",
          action: "Rückgängig",
          on_action: JS.push("undo", value: %{id: 1}),
          id: "toast-7"
        }
      }
    }

    doc = parse(~H|<.flash_group flash={@flash} />|)
    toast = "#flash-group #toast-7"
    assert attr(doc, toast, "role") == "status"

    assert Enum.all?(
             ~w(bg-popover border border-base-content/10 shadow-lg rounded-box w-full sm:w-96),
             &(&1 in classes(doc, toast))
           )

    assert count(doc, "#{toast} svg") == 0
    assert count(doc, "#{toast} button") == 1
    assert text(doc, "#{toast} button") == "Rückgängig"
    assert attr(doc, "#{toast} button", "aria-label") == nil
    assert Enum.all?(~w(btn btn-ghost btn-sm), &(&1 in classes(doc, "#{toast} button")))
    assert text(doc, "#{toast} p") == "Bananen abgehakt"

    click = attr(doc, "#{toast} button", "phx-click")

    assert [%{"event" => "lv:clear-flash", "value" => %{"key" => "toast"}}, undo] =
             pushes(click)

    assert undo == %{"event" => "undo", "value" => %{"id" => 1}}
    assert click =~ ~s("to":"#toast-7")

    assert attr(doc, toast, "phx-hook") == "Setzkasten.Components.Feedback.AutoDismiss"
    # Only hidden: a clear by key would wipe a newer toast that the next action puts meanwhile.
    dismiss = attr(doc, toast, "data-dismiss")
    assert pushes(dismiss) == []
    assert dismiss =~ ~s("to":"#toast-7")
  end

  test "an action toast takes an event name, and without action it is plain text" do
    assigns = %{
      flash: %{
        "toast" => %{id: "toast-1", message: "Gelöscht", action: "Rückgängig", on_action: "undo"}
      }
    }

    doc = parse(~H|<.flash_group flash={@flash} />|)
    assert [_clear, %{"event" => "undo"}] = pushes(attr(doc, "#toast-1 button", "phx-click"))

    assigns = %{
      flash: %{
        "toast" => %{id: "toast-2", message: "Milch hinzugefügt", action: nil, on_action: nil}
      }
    }

    doc = parse(~H|<.flash_group flash={@flash} />|)
    assert text(doc, "#toast-2") == "Milch hinzugefügt"
    assert count(doc, "#toast-2 button") == 0
  end

  test "toasts sit at the bottom, rise opaque and leave downward" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    assert css =~ ~r/@keyframes setzkasten-rise \{\s*from \{\s*translate: 0 0\.5rem;\s*\}\s*\}/
    assert css =~ ~r/\.toast > \* \{\s*animation: setzkasten-rise /
    refute css =~ ".toast-top"

    # Reduced motion: a toast appears at once (the rule sits inside a reduced-motion block).
    assert css =~
             ~r/@media \(prefers-reduced-motion: reduce\) \{(?:(?!\n  \}\n).)*?\.toast > \* \{\s*animation: none;/s

    # One rule takes the highest of everything at the bottom, so a composer and a pinned action bar on one
    # page do not fight over specificity, and the keyboard covers a pinned bar.
    assert css =~
             ~r/\.setzkasten-toasts \{\s*bottom: calc\(max\(var\(--setzkasten-bottom-offset\), env\(safe-area-inset-bottom\), var\(--setzkasten-composer-top, 0px\), var\(--setzkasten-pinned-top, 0px\), var\(--setzkasten-selection-top, 0px\)\) \+ 1rem\);/

    assert length(Regex.scan(~r/\.setzkasten-toasts \{/, css)) == 1

    assert css =~
             ~r/:root:has\(\.setzkasten-action-bar-pinned:not\(\.modal-box \*\)\) \{\s*--setzkasten-pinned-top: calc\(max\(var\(--setzkasten-dock-offset, 0px\), env\(safe-area-inset-bottom\)\) \+ 4\.25rem \+ 1px\);/
  end

  test "alert with a close button keeps it at the end on phones" do
    assigns = %{}

    doc =
      parse(~H"""
      <.alert tone={:warning} on_close={JS.push("dismiss", value: %{id: 1})} close_label="Close">
        Nicht veröffentlicht.
      </.alert>
      """)

    assert attr(doc, ".alert > div > button", "aria-label") == "Close"
    assert attr(doc, ".alert > div > button", "phx-click") =~ "dismiss"
    assert "grid-cols-[auto_minmax(0,1fr)_auto]" in classes(doc, ".alert > div")

    doc =
      parse(~H"""
      <.alert on_close="dismiss">
        Text<:actions><.button size={:sm}>Ok</.button></:actions>
      </.alert>
      """)

    assert "@lg:grid-cols-[auto_minmax(0,1fr)_auto_auto]" in classes(doc, ".alert > div")
    assert "@max-lg:col-start-3" in classes(doc, ".alert > div > button")
  end

  test "an alert without icon drops the icon's column" do
    assigns = %{}

    doc =
      parse(~H"""
      <.alert icon={false} on_close="dismiss">
        Text<:actions><.button size={:sm}>Ok</.button></:actions>
      </.alert>
      """)

    assert "@max-lg:grid-cols-[minmax(0,1fr)_auto]" in classes(doc, ".alert > div")
    assert "@lg:grid-cols-[minmax(0,1fr)_auto_auto]" in classes(doc, ".alert > div")
    assert "@max-lg:col-start-1" in classes(doc, ".alert > div > div:has(.btn)")
    assert "@max-lg:col-start-2" in classes(doc, ".alert > div > button")

    doc = parse(~H|<.alert icon={false} on_close="dismiss">Text</.alert>|)
    assert "grid-cols-[minmax(0,1fr)_auto]" in classes(doc, ".alert > div")
    refute Enum.any?(classes(doc, ".alert > div > button"), &String.starts_with?(&1, "@"))
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
    assert "motion-reduce:hidden" in classes(doc, "#client-error .loading")

    group = classes(doc, "#flash-group")
    assert attr(doc, "#flash-group", "aria-live") == "polite"

    assert Enum.all?(
             ["setzkasten-toasts", "max-sm:inset-x-4", "max-sm:w-auto"],
             &(&1 in group)
           )

    assert Enum.all?(~w(shadow-lg w-full sm:w-96), &(&1 in classes(doc, "#flash-error")))

    doc = parse(~H|<.flash_group flash={@flash} close_label="Close" />|)
    assert attr(doc, "#client-error button", "aria-label") == "Close"
  end

  test "badge with dot by default, solid for alarms" do
    assigns = %{}
    doc = parse(~H|<.badge tone={:success}>Veröffentlicht</.badge>|)

    assert classes(doc, "span.badge") ==
             ~w(whitespace-nowrap max-sm:min-w-0 sm:shrink-0 badge badge-sm)

    assert text(doc, ".badge > span.truncate") == "Veröffentlicht"
    assert classes(doc, ".status") == ~w(status status-success)

    doc = parse(~H|<.badge tone={:error} style={:solid}>überzogen</.badge>|)
    assert "badge-error" in classes(doc, ".badge")
    assert count(doc, ".status") == 0
  end

  test "text badge is the dot and the label without a pill" do
    assigns = %{}
    doc = parse(~H|<.badge tone={:info} style={:text}>Entwurf</.badge>|)
    refute "badge" in classes(doc, "span:first-child")
    assert count(doc, ".status.status-info") == 1
    assert text(doc, "span.truncate") == "Entwurf"
  end

  test "the neutral dot is visible (50 %), not daisyUI's 20 %" do
    assigns = %{}
    doc = parse(~H|<.badge>Entwurf</.badge>|)
    assert "bg-base-content/50" in classes(doc, ".status")
  end

  test "a neutral badge is marked, so the phone page bar can leave out its dot" do
    assigns = %{}
    assert "setzkasten-badge-neutral" in classes(parse(~H|<.badge>Entwurf</.badge>|), ".badge")

    refute "setzkasten-badge-neutral" in classes(
             parse(~H|<.badge tone={:warning}>Fällig</.badge>|),
             ".badge"
           )
  end

  test "plain badge is a pill without a dot" do
    assigns = %{}
    doc = parse(~H|<.badge style={:plain}>Du</.badge>|)
    assert "badge" in classes(doc, "span:first-child")
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
    assert count(doc, "img.size-12") == 1

    doc =
      parse(~H|<.empty_state plush="receipt" layout={:page} plush_size={:xxl}>T</.empty_state>|)

    assert count(doc, "img.size-24") == 1
  end

  test "empty state falls back to its icon when the plush has no image" do
    assigns = %{}
    doc = parse(~H|<.empty_state plush="missing" icon="inbox" title="Leer" />|)
    assert count(doc, "img") == 0
    assert count(doc, "svg.lucide.size-6") == 1

    doc = parse(~H|<.empty_state plush="missing" icon="inbox" layout={:page} title="Leer" />|)
    assert count(doc, "svg.lucide.size-12") == 1

    doc = parse(~H|<.empty_state plush="missing" title="Leer" />|)
    assert count(doc, "img, svg") == 0

    assert count(parse(~H|<.empty_state plush="receipt" icon="inbox" />|), "svg") == 0
  end

  test "alert, flash and empty state text break long strings" do
    assigns = %{}
    alert = parse(~H|<.alert title="T">x</.alert>|)
    assert "wrap-anywhere" in classes(alert, ".alert > div > div")

    flash = parse(~H|<.flash kind={:info} flash={%{"info" => "x"}} />|)
    assert "wrap-anywhere" in classes(flash, ".alert > div")

    empty = parse(~H|<.empty_state title="T">x</.empty_state>|)
    assert "wrap-anywhere" in classes(empty, "div > div")

    page = parse(~H|<.empty_state layout={:page} title="T">x</.empty_state>|)
    assert "wrap-anywhere" in classes(page, "h2")
    assert "wrap-anywhere" in classes(page, "p")
  end

  test "neutral buttons in a soft alert get a fill and a border that hold on its tint" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))
    assert css =~ "--setzkasten-alert-control: var(--color-base-100);"
    assert length(String.split(css, "--setzkasten-alert-control: var(--color-base-300);")) == 3

    assert css =~
             ~r/\.alert-soft & \{\s*--btn-bg: var\(--setzkasten-alert-control\);\s*--btn-border: color-mix\(in oklab, var\(--color-base-content\) 50%, transparent\);/
  end
end
