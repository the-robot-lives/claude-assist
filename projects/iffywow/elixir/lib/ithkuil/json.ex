defmodule Ithkuil.JSON do
  @moduledoc """
  Minimal, dependency-free JSON support — just enough for this SDK:

    * `encode/1` — compact encoding matching `JSON.stringify` output for the
      value shapes we emit (SVG `<metadata>` blocks, render models): `nil`,
      booleans, integers, floats, binaries, lists, ordered `{:object, pairs}`
      tuples, and maps (keys sorted for determinism).
    * `parse/1` — strict parser for objects, arrays, strings (with `\\uXXXX`
      escapes incl. surrogate pairs), integers, simple floats, booleans and
      null. Sufficient for the metadata we generate and for the conformance
      JSONL vectors; **not** a general-purpose JSON library.
    * `format_number/1` — JS `Number#toString` parity: integer-valued floats
      print without a decimal point (`130.0` -> `"130"`), everything else uses
      the shortest round-trip representation (both JS engines and OTP's
      `float_to_binary(..., [:short])` implement the same shortest-repr rule).

  JSON *text* never crosses the public API boundary of `Ithkuil` — this module
  exists for SVG metadata embedding/extraction and the test suite.
  """

  # ------------------------------------------------------------------
  # Number formatting (shared with Scene / SVG for JS output parity)
  # ------------------------------------------------------------------

  @spec format_number(number()) :: String.t()
  def format_number(n) when is_integer(n), do: Integer.to_string(n)

  def format_number(n) when is_float(n) do
    cond do
      # Covers -0.0 as well (-0.0 == 0.0) — JS `r1` normalizes -0 to 0 too.
      n == 0.0 -> "0"
      n == trunc(n) -> Integer.to_string(trunc(n))
      true -> Float.to_string(n)
    end
  end

  # ------------------------------------------------------------------
  # Encoding
  # ------------------------------------------------------------------

  @typedoc "Ordered object: preserves key order exactly like a JS object literal."
  @type ordered_object :: {:object, [{String.t() | atom(), encodable()}]}
  @type encodable ::
          nil
          | boolean()
          | number()
          | String.t()
          | [encodable()]
          | ordered_object()
          | %{optional(String.t() | atom()) => encodable()}

  @spec encode(encodable()) :: String.t()
  def encode(value), do: value |> encode_iodata() |> IO.iodata_to_binary()

  defp encode_iodata(nil), do: "null"
  defp encode_iodata(true), do: "true"
  defp encode_iodata(false), do: "false"
  defp encode_iodata(n) when is_number(n), do: format_number(n)
  defp encode_iodata(s) when is_binary(s), do: encode_string(s)

  defp encode_iodata(list) when is_list(list) do
    ["[", list |> Enum.map(&encode_iodata/1) |> Enum.intersperse(","), "]"]
  end

  defp encode_iodata({:object, pairs}) when is_list(pairs) do
    inner =
      pairs
      |> Enum.map(fn {k, v} -> [encode_string(to_string(k)), ":", encode_iodata(v)] end)
      |> Enum.intersperse(",")

    ["{", inner, "}"]
  end

  defp encode_iodata(map) when is_map(map) do
    pairs =
      map
      |> Enum.map(fn {k, v} -> {to_string(k), v} end)
      |> Enum.sort_by(fn {k, _v} -> k end)

    encode_iodata({:object, pairs})
  end

  defp encode_string(s) do
    ["\"", s |> String.to_charlist() |> Enum.map(&escape_char/1), "\""]
  end

  # Same escape set JSON.stringify uses; non-ASCII stays literal UTF-8.
  defp escape_char(?"), do: "\\\""
  defp escape_char(?\\), do: "\\\\"
  defp escape_char(?\b), do: "\\b"
  defp escape_char(?\f), do: "\\f"
  defp escape_char(?\n), do: "\\n"
  defp escape_char(?\r), do: "\\r"
  defp escape_char(?\t), do: "\\t"

  defp escape_char(c) when c < 0x20 do
    "\\u" <> String.pad_leading(Integer.to_string(c, 16), 4, "0")
  end

  defp escape_char(c), do: <<c::utf8>>

  # ------------------------------------------------------------------
  # Parsing
  # ------------------------------------------------------------------

  @spec parse(binary()) :: {:ok, term()} | {:error, term()}
  def parse(bin) when is_binary(bin) do
    case value(skip_ws(bin)) do
      {:ok, v, rest} ->
        if skip_ws(rest) == "", do: {:ok, v}, else: {:error, :trailing_data}

      {:error, _} = error ->
        error
    end
  end

  defp skip_ws(<<c, rest::binary>>) when c in [?\s, ?\t, ?\n, ?\r], do: skip_ws(rest)
  defp skip_ws(bin), do: bin

  defp value(<<"null", rest::binary>>), do: {:ok, nil, rest}
  defp value(<<"true", rest::binary>>), do: {:ok, true, rest}
  defp value(<<"false", rest::binary>>), do: {:ok, false, rest}
  defp value(<<?", rest::binary>>), do: string(rest, [])
  defp value(<<?[, rest::binary>>), do: array(skip_ws(rest), [])
  defp value(<<?{, rest::binary>>), do: object(skip_ws(rest), [])
  defp value(<<c, _::binary>> = bin) when c == ?- or c in ?0..?9, do: number(bin)
  defp value(_), do: {:error, :unexpected_token}

  defp array(<<?], rest::binary>>, []), do: {:ok, [], rest}

  defp array(bin, acc) do
    with {:ok, v, rest} <- value(skip_ws(bin)) do
      case skip_ws(rest) do
        <<?,, rest2::binary>> -> array(skip_ws(rest2), [v | acc])
        <<?], rest2::binary>> -> {:ok, Enum.reverse([v | acc]), rest2}
        _ -> {:error, :expected_comma_or_bracket}
      end
    end
  end

  defp object(<<?}, rest::binary>>, []), do: {:ok, %{}, rest}

  defp object(<<?", srest::binary>>, acc) do
    with {:ok, key, rest} <- string(srest, []),
         {:colon, <<?:, rest2::binary>>} <- {:colon, skip_ws(rest)},
         {:ok, v, rest3} <- value(skip_ws(rest2)) do
      case skip_ws(rest3) do
        <<?,, r::binary>> -> object(skip_ws(r), [{key, v} | acc])
        <<?}, r::binary>> -> {:ok, Map.new([{key, v} | acc]), r}
        _ -> {:error, :expected_comma_or_brace}
      end
    else
      {:colon, _} -> {:error, :expected_colon}
      {:error, _} = error -> error
    end
  end

  defp object(_bin, _acc), do: {:error, :invalid_object}

  defp string(<<?", rest::binary>>, acc) do
    {:ok, acc |> Enum.reverse() |> IO.iodata_to_binary(), rest}
  end

  defp string(<<?\\, esc, rest::binary>>, acc) do
    case esc do
      ?" -> string(rest, ["\"" | acc])
      ?\\ -> string(rest, ["\\" | acc])
      ?/ -> string(rest, ["/" | acc])
      ?b -> string(rest, ["\b" | acc])
      ?f -> string(rest, ["\f" | acc])
      ?n -> string(rest, ["\n" | acc])
      ?r -> string(rest, ["\r" | acc])
      ?t -> string(rest, ["\t" | acc])
      ?u -> unicode_escape(rest, acc)
      _ -> {:error, :invalid_escape}
    end
  end

  defp string(<<c::utf8, rest::binary>>, acc), do: string(rest, [<<c::utf8>> | acc])
  defp string(_, _acc), do: {:error, :unterminated_string}

  defp unicode_escape(<<h::binary-size(4), rest::binary>>, acc) do
    case Integer.parse(h, 16) do
      {cp, ""} when cp >= 0xD800 and cp <= 0xDBFF ->
        # Surrogate pair: expect \uDC00..\uDFFF next.
        case rest do
          <<?\\, ?u, l::binary-size(4), rest2::binary>> ->
            case Integer.parse(l, 16) do
              {low, ""} when low >= 0xDC00 and low <= 0xDFFF ->
                combined = 0x10000 + (cp - 0xD800) * 0x400 + (low - 0xDC00)
                string(rest2, [<<combined::utf8>> | acc])

              _ ->
                {:error, :invalid_surrogate_pair}
            end

          _ ->
            {:error, :invalid_surrogate_pair}
        end

      {cp, ""} when cp >= 0xDC00 and cp <= 0xDFFF ->
        {:error, :invalid_surrogate_pair}

      {cp, ""} when cp >= 0 and cp <= 0x10FFFF ->
        string(rest, [<<cp::utf8>> | acc])

      _ ->
        {:error, :invalid_unicode_escape}
    end
  end

  defp unicode_escape(_, _acc), do: {:error, :invalid_unicode_escape}

  defp number(bin) do
    {sign, rest} =
      case bin do
        <<?-, r::binary>> -> {"-", r}
        _ -> {"", bin}
      end

    with {:ok, int_digits, rest} <- digits(rest) do
      case rest do
        <<?., rest2::binary>> ->
          with {:ok, frac_digits, rest3} <- digits(rest2),
               {:ok, exp, rest4} <- optional_exponent(rest3) do
            {:ok, to_float(sign, int_digits, frac_digits, exp), rest4}
          end

        <<e, _::binary>> when e in [?e, ?E] ->
          with {:ok, exp, rest2} <- optional_exponent(rest) do
            {:ok, to_float(sign, int_digits, "0", exp), rest2}
          end

        _ ->
          {:ok, String.to_integer(sign <> int_digits), rest}
      end
    end
  end

  defp optional_exponent(<<e, rest::binary>>) when e in [?e, ?E] do
    {esign, rest} =
      case rest do
        <<?+, r::binary>> -> {"+", r}
        <<?-, r::binary>> -> {"-", r}
        _ -> {"", rest}
      end

    with {:ok, ds, rest} <- digits(rest), do: {:ok, "e" <> esign <> ds, rest}
  end

  defp optional_exponent(rest), do: {:ok, "", rest}

  defp to_float(sign, int_digits, frac_digits, exp) do
    String.to_float(sign <> int_digits <> "." <> frac_digits <> exp)
  end

  defp digits(bin), do: digits(bin, [])
  defp digits(<<c, rest::binary>>, acc) when c in ?0..?9, do: digits(rest, [c | acc])
  defp digits(_bin, []), do: {:error, :expected_digits}
  defp digits(bin, acc), do: {:ok, acc |> Enum.reverse() |> List.to_string(), bin}
end
