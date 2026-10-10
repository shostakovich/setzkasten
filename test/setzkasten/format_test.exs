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
end
