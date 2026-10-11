defmodule Setzkasten.Format do
  @moduledoc """
  German number formatting as the components render it: thousands dot, decimal comma,
  U+2212 minus, no-break space before the unit.

  Values are integers in minor units (cents) or `Decimal` structs. `Decimal` is read
  structurally, so the package does not depend on it.
  """

  @minus "−"
  @nbsp " "
  @symbols %{"EUR" => "€", "USD" => "$", "GBP" => "£", "CHF" => "CHF"}

  @doc """
  Formats money.

      iex> Setzkasten.Format.money(-123456)
      "−1.234,56 €"
      iex> Setzkasten.Format.money(35020, signed: true)
      "+350,20 €"
      iex> Setzkasten.Format.money(4200, currency: "USD")
      "42,00 $"

      iex> Setzkasten.Format.money(110, currency: "USD", currency_display: :code)
      "1,10 USD"

  Options: `:currency` (default `"EUR"`, unknown codes print as the code), `:currency_display`
  (`:symbol`, the default, or `:code` for the ISO code), `:signed` (prefix `+` for positive
  values), `:decimals` (default 2).
  """
  def money(value, opts \\ []) do
    currency = Keyword.get(opts, :currency, "EUR")

    unit =
      case Keyword.get(opts, :currency_display, :symbol) do
        :symbol -> symbol(currency)
        :code -> currency
      end

    number(value, Keyword.put_new(opts, :minor_units, true)) <> @nbsp <> unit
  end

  @doc """
  Formats a number. Integers are whole numbers unless `minor_units: true`.

      iex> Setzkasten.Format.number(1234)
      "1.234"
      iex> Setzkasten.Format.number(-20.49, decimals: 1)
      "−20,5"
  """
  def number(value, opts \\ []) do
    decimals = Keyword.get(opts, :decimals, if(opts[:minor_units], do: 2, else: 0))
    {sign, units} = scaled(value, decimals, opts[:minor_units] || false)
    {int, frac} = split_digits(Integer.to_string(units), decimals)
    prefix(sign, units, opts[:signed]) <> group(int) <> frac
  end

  defp split_digits(digits, 0), do: {digits, ""}

  defp split_digits(digits, decimals) do
    {int, frac} = digits |> String.pad_leading(decimals + 1, "0") |> String.split_at(-decimals)
    {int, "," <> frac}
  end

  defp prefix(_sign, 0, _signed), do: ""
  defp prefix(-1, _units, _signed), do: @minus
  defp prefix(1, _units, true), do: "+"
  defp prefix(_sign, _units, _signed), do: ""

  @doc """
  The machine-readable value for `<data value>`: dot decimal, ASCII minus.

      iex> Setzkasten.Format.machine(-7420)
      "-74.20"
  """
  def machine(value, opts \\ []) do
    decimals = Keyword.get(opts, :decimals, 2)
    {sign, units} = scaled(value, decimals, true)
    digits = units |> Integer.to_string() |> String.pad_leading(decimals + 1, "0")
    {int, frac} = String.split_at(digits, -decimals)
    if(sign < 0 and units != 0, do: "-", else: "") <> int <> "." <> frac
  end

  @doc """
  Sign of a money value as `money/2` shows it with `decimals` places: a value that rounds to
  zero is 0.

      iex> Setzkasten.Format.shown_sign(-40, 0)
      0
      iex> Setzkasten.Format.shown_sign(-40)
      -1
  """
  def shown_sign(value, decimals \\ 2) do
    case scaled(value, decimals, true) do
      {_sign, 0} -> 0
      {sign, _units} -> sign
    end
  end

  @doc "Sign of a value: -1, 0 or 1."
  def sign(value) when is_integer(value) and value > 0, do: 1
  def sign(value) when is_integer(value) and value < 0, do: -1
  def sign(value) when is_integer(value), do: 0
  def sign(%{__struct__: Decimal, coef: 0}), do: 0
  def sign(%{__struct__: Decimal, sign: sign}), do: sign

  def sign(value) when is_float(value) and value > 0, do: 1
  def sign(value) when is_float(value) and value < 0, do: -1
  def sign(value) when is_float(value), do: 0

  defp symbol(code), do: Map.get(@symbols, code, code)

  # Returns {sign, absolute value scaled to `decimals` places, rounded half away from zero}.
  defp scaled(value, decimals, true) when is_integer(value),
    do: {sign(value), shift(abs(value), decimals - 2)}

  defp scaled(value, decimals, false) when is_integer(value),
    do: {sign(value), abs(value) * pow10(decimals)}

  defp scaled(%{__struct__: Decimal, sign: sign, coef: coef, exp: exp}, decimals, _minor)
       when is_integer(coef),
       do: {sign, shift(coef, exp + decimals)}

  defp scaled(value, decimals, _minor) when is_float(value),
    do: {sign(value), round(abs(value) * pow10(decimals))}

  defp shift(int, places) when places >= 0, do: int * pow10(places)

  defp shift(int, places) do
    divisor = pow10(-places)
    div(int + div(divisor, 2), divisor)
  end

  defp pow10(n), do: Integer.pow(10, n)

  defp group(int) do
    int
    |> String.reverse()
    |> String.to_charlist()
    |> Enum.chunk_every(3)
    |> Enum.join(".")
    |> String.reverse()
  end
end
