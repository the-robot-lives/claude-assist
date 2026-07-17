defmodule Ithkuil.Coord do
  @moduledoc """
  The canonical, versioned coordinate tuple — the single source of truth for a
  New Ithkuil word in this SDK (see `../../README.md` and `../../CODEC.md`).

  Canonical Elixir-internal form:

      {:ithkuil_word, version,
       [
         {:glyph, character_class, base, orientation,
          [
            {socket_id, {:modifier, shape, orientation, diacritics, child_sockets}}
          ]}
       ]}

  Canonical-form invariants (CODEC.md §2):

    * `version >= 1`
    * `orientation in 0..3`, `socket_id in 0..7` (schema v1)
    * sockets sorted strictly ascending by socket id; duplicates rejected
    * **empty sockets are omitted** — `{id, :empty}` / wire `[id, null]` are
      accepted on input but never appear in the canonical form

  Wire form (JSON tagged arrays, as plain Elixir lists — JSON text is the
  caller's concern):

      ["ithkuil-word", v, glyphs]
      ["glyph", character_class, base, orientation, sockets]
      [socket_id, nil | modifier]
      ["modifier", shape, orientation, diacritics, sockets]

  Errors are `{:error, class}` or `{:error, {class, detail}}` where `class`
  matches the conformance vocabulary (`:invalid_version`,
  `:invalid_orientation`, `:invalid_socket_id`, `:duplicate_socket`, ...).
  """

  @word_tag "ithkuil-word"
  @glyph_tag "glyph"
  @modifier_tag "modifier"
  @max_socket_id 7

  @type socket_id :: 0..7
  @type orientation :: 0..3
  @type diacritic :: non_neg_integer()
  @type modifier ::
          {:modifier, shape :: non_neg_integer(), orientation(), [diacritic()], [socket()]}
  @type socket :: {socket_id(), modifier()}
  @type loose_socket :: {non_neg_integer(), modifier() | :empty | nil}
  @type glyph ::
          {:glyph, character_class :: non_neg_integer(), base :: non_neg_integer(),
           orientation(), [socket()]}
  @type t :: {:ithkuil_word, pos_integer(), [glyph()]}
  @type wire :: [term()]
  @type reason :: atom() | {atom(), term()}

  @doc "Wire tag strings (positional in the byte encoding; strings exist only in JSON)."
  def word_tag, do: @word_tag
  def glyph_tag, do: @glyph_tag
  def modifier_tag, do: @modifier_tag

  @doc """
  Build a canonical coordinate from either the wire form (tagged arrays) or a
  (possibly loose) internal tuple. Returns `{:ok, t}` or `{:error, reason}`.
  """
  @spec new(wire() | tuple()) :: {:ok, t()} | {:error, reason()}
  def new(input) when is_list(input), do: from_wire(input)
  def new({:ithkuil_word, _, _} = coord), do: canonicalize(coord)
  def new(other), do: {:error, {:invalid_structure, other}}

  @doc """
  Check that `coord` is already in canonical form.
  Returns `:ok` or `{:error, reason}` (`:not_canonical` when merely non-canonical).
  """
  @spec validate(term()) :: :ok | {:error, reason()}
  def validate(coord) do
    case canonicalize(coord) do
      {:ok, ^coord} -> :ok
      {:ok, _other} -> {:error, :not_canonical}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Validate and canonicalize a (loose) internal tuple: sockets are sorted
  ascending, duplicate socket ids rejected, `{id, :empty}` / `{id, nil}`
  entries dropped.
  """
  @spec canonicalize(term()) :: {:ok, t()} | {:error, reason()}
  def canonicalize({:ithkuil_word, version, glyphs}) when is_list(glyphs) do
    if is_integer(version) and version >= 1 do
      with {:ok, gs} <- map_all(glyphs, &canon_glyph/1) do
        {:ok, {:ithkuil_word, version, gs}}
      end
    else
      {:error, {:invalid_version, version}}
    end
  end

  def canonicalize(other), do: {:error, {:invalid_structure, other}}

  @doc """
  Parse the JSON-tagged-array wire form (already decoded to Elixir lists /
  strings / integers / nil) into a canonical coordinate.
  """
  @spec from_wire(term()) :: {:ok, t()} | {:error, reason()}
  def from_wire(wire) do
    with {:ok, loose} <- wire_to_tuple(wire), do: canonicalize(loose)
  end

  @doc "Canonical coordinate -> wire form (tagged arrays as Elixir data)."
  @spec to_wire(t()) :: wire()
  def to_wire({:ithkuil_word, version, glyphs}) do
    [@word_tag, version, Enum.map(glyphs, &glyph_to_wire/1)]
  end

  # -- wire -> loose tuple (structure only; value rules live in canonicalize) --

  defp wire_to_tuple([@word_tag, v, glyphs]) when is_list(glyphs) do
    with {:ok, gs} <- map_all(glyphs, &glyph_from_wire/1), do: {:ok, {:ithkuil_word, v, gs}}
  end

  defp wire_to_tuple(other), do: {:error, {:invalid_structure, other}}

  defp glyph_from_wire([@glyph_tag, cc, base, o, sockets]) when is_list(sockets) do
    with {:ok, socks} <- map_all(sockets, &socket_from_wire/1) do
      {:ok, {:glyph, cc, base, o, socks}}
    end
  end

  defp glyph_from_wire(other), do: {:error, {:invalid_structure, other}}

  defp socket_from_wire([id, nil]), do: {:ok, {id, :empty}}

  defp socket_from_wire([id, modifier]) do
    with {:ok, m} <- modifier_from_wire(modifier), do: {:ok, {id, m}}
  end

  defp socket_from_wire(other), do: {:error, {:invalid_structure, other}}

  defp modifier_from_wire([@modifier_tag, shape, o, diacritics, sockets])
       when is_list(diacritics) and is_list(sockets) do
    with {:ok, socks} <- map_all(sockets, &socket_from_wire/1) do
      {:ok, {:modifier, shape, o, diacritics, socks}}
    end
  end

  defp modifier_from_wire(other), do: {:error, {:invalid_structure, other}}

  # -- canonical tuple -> wire --

  defp glyph_to_wire({:glyph, cc, base, o, sockets}) do
    [@glyph_tag, cc, base, o, Enum.map(sockets, &socket_to_wire/1)]
  end

  defp socket_to_wire({id, modifier}), do: [id, modifier_to_wire(modifier)]

  defp modifier_to_wire({:modifier, shape, o, diacritics, sockets}) do
    [@modifier_tag, shape, o, diacritics, Enum.map(sockets, &socket_to_wire/1)]
  end

  # -- canonicalization internals --

  defp canon_glyph({:glyph, cc, base, orientation, sockets}) do
    with :ok <- check_nat(cc),
         :ok <- check_nat(base),
         :ok <- check_orientation(orientation),
         {:ok, socks} <- canon_sockets(sockets) do
      {:ok, {:glyph, cc, base, orientation, socks}}
    end
  end

  defp canon_glyph(other), do: {:error, {:invalid_structure, other}}

  defp canon_sockets(sockets) when is_list(sockets), do: canon_sockets(sockets, MapSet.new(), [])
  defp canon_sockets(other), do: {:error, {:invalid_structure, other}}

  defp canon_sockets([], _seen, acc) do
    canonical =
      acc
      |> Enum.reverse()
      |> Enum.reject(fn {_id, m} -> m == :empty end)
      |> Enum.sort_by(fn {id, _m} -> id end)

    {:ok, canonical}
  end

  defp canon_sockets([{id, payload} | rest], seen, acc) do
    cond do
      not is_integer(id) or id < 0 or id > @max_socket_id ->
        {:error, {:invalid_socket_id, id}}

      MapSet.member?(seen, id) ->
        # Duplicates are invalid even when one of them is empty (one meaning,
        # one representation — mirrors web/src/coordinate.js).
        {:error, {:duplicate_socket, id}}

      payload in [:empty, nil] ->
        canon_sockets(rest, MapSet.put(seen, id), [{id, :empty} | acc])

      true ->
        with {:ok, m} <- canon_modifier(payload) do
          canon_sockets(rest, MapSet.put(seen, id), [{id, m} | acc])
        end
    end
  end

  defp canon_sockets([other | _rest], _seen, _acc), do: {:error, {:invalid_structure, other}}

  defp canon_modifier({:modifier, shape, orientation, diacritics, sockets}) do
    with :ok <- check_nat(shape),
         :ok <- check_orientation(orientation),
         :ok <- check_diacritics(diacritics),
         {:ok, socks} <- canon_sockets(sockets) do
      {:ok, {:modifier, shape, orientation, diacritics, socks}}
    end
  end

  defp canon_modifier(other), do: {:error, {:invalid_structure, other}}

  defp check_nat(n) when is_integer(n) and n >= 0, do: :ok
  defp check_nat(n), do: {:error, {:invalid_natural_number, n}}

  defp check_orientation(o) when is_integer(o) and o >= 0 and o <= 3, do: :ok
  defp check_orientation(o), do: {:error, {:invalid_orientation, o}}

  defp check_diacritics(diacritics) when is_list(diacritics) do
    if Enum.all?(diacritics, &(is_integer(&1) and &1 >= 0)) do
      :ok
    else
      {:error, {:invalid_natural_number, diacritics}}
    end
  end

  defp check_diacritics(other), do: {:error, {:invalid_structure, other}}

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
