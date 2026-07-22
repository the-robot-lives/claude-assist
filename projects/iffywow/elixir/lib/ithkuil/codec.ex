defmodule Ithkuil.Codec do
  @moduledoc """
  codec-v1 — byte-level serialization and integer ranking, exactly per
  `../../CODEC.md` (normative). Both this module and the Python reference
  codec must reproduce every vector in `../../conformance/`.

  ## Term algebra

  | Tag    | Term            | Payload                                    |
  |--------|-----------------|--------------------------------------------|
  | `0x00` | `{:nat, n}`     | minimal unsigned LEB128 varint of `n`      |
  | `0x01` | `{:pair, x, y}` | `ser(x) ser(y)`                            |
  | `0x02` | `{:list, es}`   | varint `length(es)`, then each element     |
  | `0x03` | `{:bytes, b}`   | varint `byte_size(b)`, then the raw bytes  |
  | `0x04` | reserved        | never emitted; decoders MUST reject        |

  ## Integer ranking

  With `B = ser(term)` of byte length `m`:

      S_m  = (256^m - 1) / 255
      E(t) = S_m + V256(B)      # V256 = big-endian base-256 value of B

  Length intervals are disjoint, so decode recovers `m` first (largest `m`
  with `S_m <= E`), then `B = E - S_m` as exactly `m` bytes **preserving
  leading zeros**, then parses the term strictly (no trailing bytes,
  minimal varints, canonical word structure).

  Elixir integers are arbitrary precision, so no big-number special casing
  is required anywhere in this module.
  """

  import Bitwise

  alias Ithkuil.Coord

  @type term_t ::
          {:nat, non_neg_integer()}
          | {:pair, term_t(), term_t()}
          | {:list, [term_t()]}
          | {:bytes, binary()}

  # ------------------------------------------------------------------
  # Varint (unsigned LEB128, minimal)
  # ------------------------------------------------------------------

  @doc "Minimal unsigned LEB128 encoding of a natural number."
  @spec encode_varint(non_neg_integer()) :: binary()
  def encode_varint(n) when is_integer(n) and n >= 0 and n < 0x80, do: <<n>>

  def encode_varint(n) when is_integer(n) and n >= 0x80 do
    <<band(n, 0x7F) ||| 0x80, encode_varint(bsr(n, 7))::binary>>
  end

  @doc """
  Strict varint decode. Rejects non-minimal encodings (a final zero
  continuation group, e.g. `<<0x80, 0x00>>` for 0) with
  `{:error, :nonminimal_varint}` and truncation with `{:error, :truncated}`.
  """
  @spec decode_varint(binary()) ::
          {:ok, non_neg_integer(), binary()} | {:error, Coord.reason()}
  def decode_varint(bin), do: do_decode_varint(bin, 0, 0, 0)

  defp do_decode_varint(<<b, rest::binary>>, shift, acc, count) do
    group = band(b, 0x7F)
    acc = acc ||| bsl(group, shift)
    count = count + 1

    if band(b, 0x80) == 0 do
      # Minimality: the most significant (final) group must be non-zero
      # unless it is the only group.
      if group == 0 and count > 1 do
        {:error, :nonminimal_varint}
      else
        {:ok, acc, rest}
      end
    else
      do_decode_varint(rest, shift + 7, acc, count)
    end
  end

  defp do_decode_varint(<<>>, _shift, _acc, _count), do: {:error, :truncated}

  # ------------------------------------------------------------------
  # Term serialization
  # ------------------------------------------------------------------

  @doc "Serialize a term: tag byte followed by its payload (prefix-decodable)."
  @spec encode_term(term_t()) :: binary()
  def encode_term({:nat, n}), do: <<0x00, encode_varint(n)::binary>>

  def encode_term({:pair, x, y}) do
    <<0x01, encode_term(x)::binary, encode_term(y)::binary>>
  end

  def encode_term({:list, elements}) when is_list(elements) do
    payload = Enum.reduce(elements, <<>>, fn e, acc -> <<acc::binary, encode_term(e)::binary>> end)
    <<0x02, encode_varint(length(elements))::binary, payload::binary>>
  end

  def encode_term({:bytes, b}) when is_binary(b) do
    <<0x03, encode_varint(byte_size(b))::binary, b::binary>>
  end

  @doc """
  Strict prefix decode of one term. Returns `{:ok, term, rest}` or
  `{:error, reason}` (`:truncated`, `:nonminimal_varint`, `:reserved_tag`,
  `{:unknown_tag, t}`).
  """
  @spec decode_term(binary()) :: {:ok, term_t(), binary()} | {:error, Coord.reason()}
  def decode_term(<<0x00, rest::binary>>) do
    with {:ok, n, rest} <- decode_varint(rest), do: {:ok, {:nat, n}, rest}
  end

  def decode_term(<<0x01, rest::binary>>) do
    with {:ok, x, rest} <- decode_term(rest),
         {:ok, y, rest} <- decode_term(rest) do
      {:ok, {:pair, x, y}, rest}
    end
  end

  def decode_term(<<0x02, rest::binary>>) do
    with {:ok, count, rest} <- decode_varint(rest),
         {:ok, elements, rest} <- decode_elements(count, rest, []) do
      {:ok, {:list, elements}, rest}
    end
  end

  def decode_term(<<0x03, rest::binary>>) do
    with {:ok, len, rest} <- decode_varint(rest) do
      case rest do
        <<b::binary-size(len), rest2::binary>> -> {:ok, {:bytes, b}, rest2}
        _ -> {:error, :truncated}
      end
    end
  end

  def decode_term(<<0x04, _::binary>>), do: {:error, :reserved_tag}
  def decode_term(<<tag, _::binary>>), do: {:error, {:unknown_tag, tag}}
  def decode_term(<<>>), do: {:error, :truncated}

  defp decode_elements(0, rest, acc), do: {:ok, Enum.reverse(acc), rest}

  defp decode_elements(count, rest, acc) do
    with {:ok, element, rest} <- decode_term(rest) do
      decode_elements(count - 1, rest, [element | acc])
    end
  end

  # ------------------------------------------------------------------
  # Integer ranking  E(t) = S_m + V256(B)
  # ------------------------------------------------------------------

  @doc "Rank a byte string among all finite byte strings: `S_m + V256(bytes)`."
  @spec rank(binary()) :: non_neg_integer()
  def rank(bytes) when is_binary(bytes) do
    m = byte_size(bytes)
    s_m(m) + v256(bytes)
  end

  @doc """
  Inverse of `rank/1`: recover the exact byte string (leading zeros
  preserved) from a natural number.
  """
  @spec unrank(non_neg_integer()) :: {:ok, binary()} | {:error, Coord.reason()}
  def unrank(e) when is_integer(e) and e >= 0 do
    {m, s_m} = find_length(0, 0, e)
    {:ok, int_to_bytes(e - s_m, m)}
  end

  def unrank(_), do: {:error, :invalid_natural_number}

  # Largest m with S_m <= e; S_0 = 0, S_{m+1} = S_m * 256 + 1.
  defp find_length(m, s_m, e) do
    s_next = s_m * 256 + 1
    if s_next <= e, do: find_length(m + 1, s_next, e), else: {m, s_m}
  end

  defp s_m(0), do: 0
  defp s_m(m), do: s_m(m - 1) * 256 + 1

  defp v256(<<>>), do: 0
  defp v256(bytes), do: :binary.decode_unsigned(bytes, :big)

  defp int_to_bytes(0, m), do: :binary.copy(<<0>>, m)

  defp int_to_bytes(v, m) do
    b = :binary.encode_unsigned(v, :big)
    <<:binary.copy(<<0>>, m - byte_size(b))::binary, b::binary>>
  end

  # ------------------------------------------------------------------
  # Word <-> term mapping (schema v1, CODEC.md section 2)
  # ------------------------------------------------------------------

  @doc "Canonical coordinate -> term. Input MUST already be canonical (`Ithkuil.Coord`)."
  @spec word_to_term(Coord.t()) :: term_t()
  def word_to_term({:ithkuil_word, version, glyphs}) do
    {:pair, {:nat, version}, {:list, Enum.map(glyphs, &glyph_to_term/1)}}
  end

  defp glyph_to_term({:glyph, cc, base, orientation, sockets}) do
    {:list,
     [
       {:nat, cc},
       {:nat, base},
       {:nat, orientation},
       {:list, Enum.map(sockets, &socket_to_term/1)}
     ]}
  end

  defp socket_to_term({id, modifier}), do: {:pair, {:nat, id}, modifier_to_term(modifier)}

  defp modifier_to_term({:modifier, shape, orientation, diacritics, sockets}) do
    {:list,
     [
       {:nat, shape},
       {:nat, orientation},
       {:list, Enum.map(diacritics, &{:nat, &1})},
       {:list, Enum.map(sockets, &socket_to_term/1)}
     ]}
  end

  @doc """
  Strict term -> canonical coordinate. Only canonical serializations of valid
  words succeed: `version >= 1`, `orientation in 0..3`, `socket_id in 0..7`,
  sockets strictly ascending (duplicates rejected), exact arity everywhere.
  """
  @spec term_to_word(term_t()) :: {:ok, Coord.t()} | {:error, Coord.reason()}
  def term_to_word({:pair, {:nat, version}, {:list, glyphs}}) do
    if version >= 1 do
      with {:ok, gs} <- map_all(glyphs, &term_to_glyph/1) do
        {:ok, {:ithkuil_word, version, gs}}
      end
    else
      {:error, {:invalid_version, version}}
    end
  end

  def term_to_word(other), do: {:error, {:invalid_structure, other}}

  defp term_to_glyph({:list, [{:nat, cc}, {:nat, base}, {:nat, orientation}, {:list, sockets}]}) do
    with :ok <- check_orientation(orientation),
         {:ok, socks} <- term_to_sockets(sockets, -1, []) do
      {:ok, {:glyph, cc, base, orientation, socks}}
    end
  end

  defp term_to_glyph(other), do: {:error, {:invalid_structure, other}}

  defp term_to_sockets([], _last, acc), do: {:ok, Enum.reverse(acc)}

  defp term_to_sockets([{:pair, {:nat, id}, modifier} | rest], last, acc) do
    cond do
      id > 7 ->
        {:error, {:invalid_socket_id, id}}

      id == last ->
        {:error, {:duplicate_socket, id}}

      id < last ->
        {:error, {:unsorted_sockets, id}}

      true ->
        with {:ok, m} <- term_to_modifier(modifier) do
          term_to_sockets(rest, id, [{id, m} | acc])
        end
    end
  end

  defp term_to_sockets([other | _rest], _last, _acc), do: {:error, {:invalid_structure, other}}

  defp term_to_modifier(
         {:list, [{:nat, shape}, {:nat, orientation}, {:list, diacritics}, {:list, sockets}]}
       ) do
    with :ok <- check_orientation(orientation),
         {:ok, ds} <- nat_list(diacritics, []),
         {:ok, socks} <- term_to_sockets(sockets, -1, []) do
      {:ok, {:modifier, shape, orientation, ds, socks}}
    end
  end

  defp term_to_modifier(other), do: {:error, {:invalid_structure, other}}

  defp nat_list([], acc), do: {:ok, Enum.reverse(acc)}
  defp nat_list([{:nat, n} | rest], acc), do: nat_list(rest, [n | acc])
  defp nat_list([other | _rest], _acc), do: {:error, {:invalid_structure, other}}

  defp check_orientation(o) when o >= 0 and o <= 3, do: :ok
  defp check_orientation(o), do: {:error, {:invalid_orientation, o}}

  # ------------------------------------------------------------------
  # Word-level convenience (bytes / integer)
  # ------------------------------------------------------------------

  @doc "Canonical coordinate -> canonical codec-v1 byte string."
  @spec encode_word(Coord.t()) :: binary()
  def encode_word(coord), do: coord |> word_to_term() |> encode_term()

  @doc "Strict byte string -> canonical coordinate (no trailing bytes allowed)."
  @spec decode_word(binary()) :: {:ok, Coord.t()} | {:error, Coord.reason()}
  def decode_word(bytes) when is_binary(bytes) do
    with {:ok, term, rest} <- decode_term(bytes) do
      if rest == <<>>, do: term_to_word(term), else: {:error, :trailing_bytes}
    end
  end

  @doc "Canonical coordinate -> natural number `E(t)`."
  @spec word_to_integer(Coord.t()) :: non_neg_integer()
  def word_to_integer(coord), do: coord |> encode_word() |> rank()

  @doc "Natural number -> canonical coordinate (strict; errors on non-words)."
  @spec integer_to_word(non_neg_integer()) :: {:ok, Coord.t()} | {:error, Coord.reason()}
  def integer_to_word(e) when is_integer(e) and e >= 0 do
    with {:ok, bytes} <- unrank(e), do: decode_word(bytes)
  end

  def integer_to_word(_), do: {:error, :invalid_natural_number}

  @doc "Term -> natural number (used by term-level conformance vectors)."
  @spec term_to_integer(term_t()) :: non_neg_integer()
  def term_to_integer(term), do: term |> encode_term() |> rank()

  @doc "Natural number -> term (strict full-buffer decode)."
  @spec integer_to_term(non_neg_integer()) :: {:ok, term_t()} | {:error, Coord.reason()}
  def integer_to_term(e) when is_integer(e) and e >= 0 do
    with {:ok, bytes} <- unrank(e),
         {:ok, term, rest} <- decode_term(bytes) do
      if rest == <<>>, do: {:ok, term}, else: {:error, :trailing_bytes}
    end
  end

  def integer_to_term(_), do: {:error, :invalid_natural_number}

  defp map_all(items, fun) do
    items
    |> Enum.reduce_while({:ok, []}, fn item, {:ok, acc} ->
      case fun.(item) do
        {:ok, v} -> {:cont, {:ok, [v | acc]}}
        {:error, _} = e -> {:halt, e}
      end
    end)
    |> case do
      {:ok, acc} -> {:ok, Enum.reverse(acc)}
      error -> error
    end
  end
end
