defmodule Setzkasten.Dev.Dashboard do
  @moduledoc false
  # Demo data and the app-specific pieces of a home-automation start page. The energy flow and
  # the charts are static SVG placeholders: a real app draws them itself (a hook, Chart.js).
  use Phoenix.Component
  use Setzkasten
  alias Setzkasten.Format

  @live %{pv: ~w(486 512 498 471 455 503), battery: ~w(78 78 77 77 76 76)}

  def live(key, step), do: Enum.at(@live[key], rem(step, length(@live[key])))

  @hours Enum.to_list(14..23) ++ Enum.to_list(0..13)

  # kWh per hour, 14:00 yesterday to 13:00 today (the last hour is still running).
  @produced [0.44, 0.31, 0.18, 0.06, 0.01, 0, 0, 0, 0, 0] ++
              [0, 0, 0, 0, 0, 0, 0, 0.03, 0.09, 0.22, 0.36, 0.49, 0.56, 0.39]
  @consumed [0.31, 0.22, 0.18, 0.29, 0.41, 0.38, 0.26, 0.21, 0.14, 0.09] ++
              [0.07, 0.06, 0.06, 0.06, 0.06, 0.07, 0.12, 0.24, 0.31, 0.22, 0.19, 0.36, 0.68, 0.52]

  # Watt, hourly samples plus "now" (13:42).
  @pv_w [470, 360, 220, 90, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 40, 120, 260, 400, 520] ++
          [590, 540, 486]
  @home_w [310, 220, 180, 290, 410, 380, 260, 210, 140, 90, 70, 60, 60, 60, 60, 70, 120] ++
            [240, 310, 220, 190, 360, 680, 520, 712]

  @yield [2.8, 3.1, 1.4, 0.9, 2.2, 3.0, 2.6, 1.1, 0.7, 1.9, 2.9, 3.2, 2.5, 2.14]

  def tiles do
    [
      %{label: "Erzeugt heute", value: kwh(2.14), unit: "kWh"},
      %{label: "Verbraucht heute", value: kwh(3.02), unit: "kWh"},
      %{label: "Gespart heute", value: "0,65", unit: "€"},
      %{label: "Bilanz heute", value: kwh(-0.88, true), unit: "kWh", tone: :error},
      %{label: "Verbrauch jetzt", value: "712", unit: "W"},
      %{label: "Bilanz jetzt", value: Format.number(-106, signed: true), unit: "W", tone: :error},
      %{label: "Autarkie heute", value: "66,9", unit: "%"},
      %{label: "Eigen­verbrauchs­quote", value: "94,4", unit: "%"}
    ]
  end

  def plugs do
    [
      %{name: "Waschmaschine", watt: 412},
      %{name: "Arbeitsplatz", watt: 138},
      %{name: "Kühlschrank", watt: 86},
      %{name: "Router & NAS", watt: 14}
    ]
  end

  defp kwh(value, signed \\ false), do: Format.number(value, decimals: 2, signed: signed)

  @doc "The four-ring energy flow, drawn statically (a real app animates it in its own hook)."
  def energy_flow(assigns) do
    assigns =
      assign(assigns,
        rings: [
          {200, 62, "PV", "486 W", "stroke-chart-2"},
          {62, 172, "Netz", "106 W", "stroke-chart-1"},
          {338, 172, "Haus", "712 W", "stroke-base-content/40"},
          {200, 282, "Batterie", "78 %", "stroke-chart-3"}
        ],
        links: [
          {"M 222,93 C 240,140 270,150 300,162", "stroke-chart-2"},
          {"M 100,172 L 300,172", "stroke-chart-1"},
          {"M 222,251 C 240,204 270,194 300,182", "stroke-chart-3"},
          {"M 200,100 L 200,244", "stroke-base-content/15"},
          {"M 178,93 C 160,140 130,150 100,162", "stroke-base-content/15"}
        ]
      )

    ~H"""
    <svg viewBox="0 0 400 340" class="h-full w-full" aria-hidden="true">
      <path
        :for={{d, tone} <- @links}
        d={d}
        class={["fill-none", tone]}
        stroke-width="3"
        stroke-linecap="round"
      />
      <g :for={{x, y, label, value, tone} <- @rings}>
        <circle cx={x} cy={y} r="38" class={["fill-base-100", tone]} stroke-width="4" />
        <text x={x} y={y - 4} text-anchor="middle" class="fill-base-content/70" font-size="15">
          {label}
        </text>
        <text
          x={x}
          y={y + 16}
          text-anchor="middle"
          class="fill-base-content tabular-nums"
          font-size="17"
          font-weight="700"
        >
          {value}
        </text>
      </g>
    </svg>
    """
  end

  def energy_rows do
    Enum.zip_with([@hours, @produced, @consumed], fn [h, p, c] ->
      %{hour: hour(h), produced: kwh(p), consumed: kwh(c)}
    end)
  end

  def power_rows do
    Enum.zip_with([Enum.map(@hours, &hour/1) ++ ["13:42"], @pv_w, @home_w], fn [h, pv, home] ->
      %{hour: h, pv: Format.number(pv), home: Format.number(home)}
    end)
  end

  def yield_rows do
    ~D[2026-09-27]
    |> Date.range(~D[2026-10-10])
    |> Enum.zip(@yield)
    |> Enum.map(fn {date, kwh} -> %{day: day(date), kwh: kwh(kwh)} end)
  end

  defp hour(h), do: String.pad_leading("#{h}", 2, "0") <> ":00"
  defp day(date), do: "#{date.day}.#{date.month}."

  @doc "Hourly energy as paired bars (produced series 2 warning, consumed series 1 primary)."
  def energy_chart(assigns) do
    max = 0.7
    n = length(@hours)

    assigns =
      assign(assigns,
        n: n,
        bars:
          for {{p, c}, i} <- Enum.with_index(Enum.zip(@produced, @consumed)) do
            {i * 10 + 1, p / max * 100, c / max * 100}
          end,
        y_ticks: ["0,7", "0,35", "0"],
        x_ticks: ["14:00", "20:00", "02:00", "08:00", "13:00"]
      )

    ~H"""
    <.plot y_ticks={@y_ticks} x_ticks={@x_ticks} width={@n * 10}>
      <g :for={{x, p, c} <- @bars}>
        <rect
          x={x}
          y={100 - p}
          width="4"
          height={p}
          class="fill-chart-2-fill"
        />
        <rect
          x={x + 4}
          y={100 - c}
          width="4"
          height={c}
          class="fill-chart-1-fill"
        />
      </g>
    </.plot>
    """
  end

  @doc "Power over 24 h as two lines (PV series 2, consumption series 1)."
  def power_chart(assigns) do
    max = 800

    assigns =
      assign(assigns,
        pv: points(@pv_w, max),
        home: points(@home_w, max),
        width: (length(@pv_w) - 1) * 10,
        y_ticks: ["800", "400", "0"],
        x_ticks: ["14:00", "20:00", "02:00", "08:00", "jetzt"]
      )

    ~H"""
    <.plot y_ticks={@y_ticks} x_ticks={@x_ticks} width={@width}>
      <polyline
        points={@pv}
        class="fill-none stroke-chart-2"
        stroke-width="2"
        vector-effect="non-scaling-stroke"
        stroke-linejoin="round"
      />
      <polyline
        points={@home}
        class="fill-none stroke-chart-1"
        stroke-width="2"
        vector-effect="non-scaling-stroke"
        stroke-linejoin="round"
      />
    </.plot>
    """
  end

  @doc "Daily yield over 14 days as bars (series 2 warning)."
  def yield_chart(assigns) do
    max = 3.5

    assigns =
      assign(assigns,
        bars: for({kwh, i} <- Enum.with_index(@yield), do: {i * 10 + 2, kwh / max * 100}),
        width: length(@yield) * 10,
        y_ticks: ["3,5", "1,75", "0"],
        x_ticks: ["27.9.", "1.10.", "5.10.", "heute"]
      )

    ~H"""
    <.plot y_ticks={@y_ticks} x_ticks={@x_ticks} width={@width}>
      <rect
        :for={{x, h} <- @bars}
        x={x}
        y={100 - h}
        width="6"
        height={h}
        class="fill-chart-2-fill"
      />
    </.plot>
    """
  end

  defp points(values, max) do
    values
    |> Enum.with_index()
    |> Enum.map_join(" ", fn {v, i} -> "#{i * 10},#{Float.round(100 - v / max * 100, 1)}" end)
  end

  # Marks scale with the frame (preserveAspectRatio="none"); tick labels are HTML text so
  # they stay at 12px at every width.
  attr :y_ticks, :list, required: true
  attr :x_ticks, :list, required: true
  attr :width, :integer, required: true
  slot :inner_block, required: true

  defp plot(assigns) do
    ~H"""
    <div class="flex min-h-0 flex-1 gap-2 text-xs text-base-content/70 tabular-nums">
      <div class="flex flex-col justify-between pb-5 text-end" aria-hidden="true">
        <span :for={tick <- @y_ticks} class="-my-1.5">{tick}</span>
      </div>
      <div class="flex min-w-0 flex-1 flex-col gap-1">
        <svg
          viewBox={"0 0 #{@width} 100"}
          preserveAspectRatio="none"
          class="min-h-0 w-full flex-1 overflow-visible"
          aria-hidden="true"
        >
          <line
            :for={y <- [0, 50, 100]}
            x1="0"
            x2={@width}
            y1={y}
            y2={y}
            class="stroke-base-content/10"
            vector-effect="non-scaling-stroke"
          />
          {render_slot(@inner_block)}
        </svg>
        <div class="flex h-4 justify-between" aria-hidden="true">
          <span :for={tick <- @x_ticks}>{tick}</span>
        </div>
      </div>
    </div>
    """
  end
end
