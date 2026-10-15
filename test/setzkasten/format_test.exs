defmodule Setzkasten.FormatTest do
  use ExUnit.Case, async: true
  alias Setzkasten.Format
  doctest Setzkasten.Format

  @minus "−"
  @nbsp " "

  test "money groups thousands and uses a real minus" do
    assert Format.money(-123_456_789) == "#{@minus}1.234.567,89#{@nbsp}€"
    assert Format.money(5) == "0,05#{@nbsp}€"
    assert Format.money(0, signed: true) == "0,00#{@nbsp}€"
  end

  test "reads Decimal structurally and rounds half away from zero" do
    decimal = %{__struct__: Decimal, sign: 1, coef: 6_327_915, exp: -3}
    assert Format.money(decimal) == "6.327,92#{@nbsp}€"
    negative = %{__struct__: Decimal, sign: -1, coef: 7420, exp: -2}
    assert Format.money(negative) == "#{@minus}74,20#{@nbsp}€"
    assert Format.machine(negative) == "-74.20"
    assert Format.sign(%{__struct__: Decimal, sign: 1, coef: 0, exp: 0}) == 0
  end

  test "unknown currencies print their code" do
    assert Format.money(100, currency: "SEK") == "1,00#{@nbsp}SEK"
  end

  test "number with decimals and sign" do
    assert Format.number(1_234_567) == "1.234.567"
    assert Format.number(38.04, decimals: 1, signed: true) == "+38,0"
    assert Format.number(-0.04, decimals: 1) == "0,0"
  end

  test "money shows the ISO code on request" do
    assert Format.money(110, currency: "USD", currency_display: :code) == "1,10#{@nbsp}USD"
    assert Format.money(-500, currency_display: :code) == "#{@minus}5,00#{@nbsp}EUR"
    assert Format.money(110, currency: "USD", currency_display: :symbol) == "1,10#{@nbsp}$"
  end

  test "money in minor units of a currency with other decimal places" do
    assert Format.money(485_000, currency: "JPY", minor_digits: 0) == "485.000#{@nbsp}JPY"
    assert Format.money(-1234, currency: "KWD", minor_digits: 3) == "#{@minus}1,234#{@nbsp}KWD"
    assert Format.money(1235, currency: "KWD", minor_digits: 3, decimals: 2) == "1,24#{@nbsp}KWD"
    assert Format.machine(-485_000, minor_digits: 0) == "-485000"
    assert Format.machine(1234, minor_digits: 3) == "1.234"
    assert Format.shown_sign(-4, 2, 3) == 0
  end

  test "minor_digits with sign, zero and Decimal" do
    assert Format.money(4850, currency: "JPY", minor_digits: 0, signed: true) ==
             "+4.850#{@nbsp}JPY"

    assert Format.money(0, currency: "JPY", minor_digits: 0, signed: true) == "0#{@nbsp}JPY"
    assert Format.machine(0, minor_digits: 0) == "0"
    assert Format.machine(-4, minor_digits: 3, decimals: 2) == "0.00"
    assert Format.shown_sign(0, 0, 0) == 0

    decimal = %{__struct__: Decimal, sign: -1, coef: 12_345, exp: -1}
    assert Format.money(decimal, currency: "JPY", minor_digits: 0) == "#{@minus}1.235#{@nbsp}JPY"

    assert Format.money(decimal, currency: "KWD", minor_digits: 3) ==
             "#{@minus}1.234,500#{@nbsp}KWD"

    assert Format.machine(decimal, minor_digits: 0) == "-1235"
    assert Format.shown_sign(%{decimal | coef: 4}, 0, 0) == 0
  end

  test "dates with two-digit day and month, weekday and year by option" do
    assert Format.date(~D[2026-03-01]) == "01.03.2026"
    assert Format.date(~D[2026-10-12], weekday: :short) == "Mo, 12.10.2026"
    assert Format.date(~D[2026-10-18], weekday: :short, year: false) == "So, 18.10."

    for {day, name} <- Enum.zip(12..18, ~w(Mo Di Mi Do Fr Sa So)) do
      assert Format.date(Date.new!(2026, 10, day), weekday: :short) =~ ~r/\A#{name}, /
    end

    assert Format.date(~D[2026-10-12], weekday: false) == "12.10.2026"
    assert Format.date(~D[2026-10-12], weekday: nil) == "12.10.2026"

    assert_raise ArgumentError, ~r/unknown :weekday :long/, fn ->
      Format.date(~D[2026-10-12], weekday: :long)
    end
  end

  test "the date of a local moment is its date part; a DateTime is no local time" do
    assert Format.date(~N[2026-10-14 23:59:59]) == "14.10.2026"

    for format <- [&Format.date/1, &Format.datetime/1, &Format.time/1] do
      assert_raise FunctionClauseError, fn -> format.(~U[2026-10-14 23:30:00Z]) end
    end
  end

  test "date and time of a local moment, times in hours and minutes" do
    assert Format.datetime(~N[2026-01-05 07:09:59.999]) == "05.01.2026, 07:09"
    assert Format.datetime(~N[2026-01-05 00:00:00], year: false) == "05.01., 00:00"
    assert Format.time(~T[23:59:59]) == "23:59"
    assert Format.time(~N[2026-01-05 00:07:00]) == "00:07"
  end

  test "the minus sign comes from its own Figtree face, roman and italic" do
    css = File.read!(Path.expand("../../priv/static/setzkasten.css", __DIR__))

    for {style, file} <- [
          normal: "SetzkastenMinus-Variable",
          italic: "SetzkastenMinus-Italic-Variable"
        ] do
      assert css =~
               ~r/font-family: "Figtree";\s*font-style: #{style};\s*font-weight: 300 900;\s*font-display: swap;\s*src: url\("\/setzkasten\/fonts\/#{file}\.woff2"\) format\("woff2"\);\s*unicode-range: U\+2212;/

      assert <<"wOF2", _::binary>> =
               File.read!(Path.expand("../../priv/static/fonts/#{file}.woff2", __DIR__))
    end

    [main, minus] =
      for name <- ["Figtree-Variable.woff2", "SetzkastenMinus-Variable.woff2"],
          do: :binary.match(css, name) |> elem(0)

    assert minus > main
  end
end
