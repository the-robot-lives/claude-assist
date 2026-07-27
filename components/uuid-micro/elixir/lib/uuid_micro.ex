defmodule UUIDMicro do
  @moduledoc """
  Four-glyph printable Unicode UUID display tokens.

  The token is deterministic but lossy. Store the UUID when identity matters.
  """

  @token_ranges [
    {0x10980, 0x1099F},
    {0x13000, 0x1342F},
    {0x13460, 0x143FF},
    {0x14400, 0x1467F}
  ]
  @token_length 4
  @token_size Enum.reduce(@token_ranges, 0, fn {start, stop}, acc -> acc + stop - start + 1 end)

  def token_ranges, do: @token_ranges
  def token_length, do: @token_length
  def token_size, do: @token_size

  def encode!(uuid) do
    uuid
    |> parse_uuid!()
    |> :binary.decode_unsigned(:big)
    |> rem(pow(@token_size, @token_length))
    |> encode_number([])
  end

  def encode(uuid) do
    {:ok, encode!(uuid)}
  rescue
    error in [ArgumentError] -> {:error, error.message}
  end

  def codepoints!(uuid) do
    uuid
    |> encode!()
    |> String.codepoints()
    |> Enum.map(fn <<point::utf8>> -> "U+" <> String.upcase(Integer.to_string(point, 16)) end)
  end

  def token?(value) when is_binary(value) do
    chars = String.codepoints(value)
    length(chars) == @token_length and Enum.all?(chars, &token_char?/1)
  end

  def token?(_), do: false

  defp encode_number(_number, chars) when length(chars) == @token_length do
    Enum.join(chars)
  end

  defp encode_number(number, chars) do
    index = rem(number, @token_size)
    encode_number(div(number, @token_size), [token_char(index) | chars])
  end

  defp token_char(index) do
    {point, 0} =
      Enum.reduce_while(@token_ranges, {nil, index}, fn {start, stop}, {_point, remaining} ->
        size = stop - start + 1

        if remaining < size do
          {:halt, {start + remaining, 0}}
        else
          {:cont, {nil, remaining - size}}
        end
      end)

    <<point::utf8>>
  end

  defp token_char?(<<point::utf8>>) do
    Enum.any?(@token_ranges, fn {start, stop} -> point >= start and point <= stop end)
  end

  defp token_char?(_), do: false

  defp parse_uuid!(uuid) when is_binary(uuid) do
    hex = uuid |> String.trim() |> String.replace("-", "")

    unless Regex.match?(~r/\A[0-9a-fA-F]{32}\z/, hex) do
      raise ArgumentError, "invalid UUID"
    end

    case Base.decode16(hex, case: :mixed) do
      {:ok, bytes} -> bytes
      :error -> raise ArgumentError, "invalid UUID"
    end
  end

  defp parse_uuid!(_), do: raise(ArgumentError, "invalid UUID")

  defp pow(_base, 0), do: 1
  defp pow(base, exp), do: base * pow(base, exp - 1)
end
