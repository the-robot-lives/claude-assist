defmodule Ithkuil do
  @moduledoc """
  iffywow — New Ithkuil coordinate codec & SDK (production Elixir codec).

  Every New Ithkuil word gets one canonical, versioned coordinate tuple
  (`Ithkuil.Coord.t()`). Everything else — romanization, the natural-number
  code, compact/exploded SVG — is a reversible projection of that tuple.

  Acceptance laws (enforced by conformance vectors + property tests):

      from_integer(to_integer(c))                 == {:ok, c}
      to_latin(from_latin(w))                     == {:ok, canonical(w)}
      SVG.extract_coordinate(SVG.render(scene))   == {:ok, Coord.to_wire(c)}

  The integer crosses every language/JSON boundary as an **unsigned decimal
  string** (`to_integer_string/1` / `from_integer_string/1`); the arithmetic
  itself is plain arbitrary-precision Elixir integers.

  Coordinate arguments accept either the canonical tuple or the JSON
  tagged-array wire form (as Elixir data) and are canonicalized on entry;
  `to_wire_json/1` / `from_wire_json/1` carry the wire form as JSON text.
  Full operation/error contract: `../SDK-INTERFACE.md` §2–§3 — byte/integer
  inputs are strict, wire/JSON inputs lenient but canonicalizing.
  """

  alias Ithkuil.{Codec, Coord, JSON, Romanization, Scene}

  @doc "Parse a romanized word into a canonical coordinate. See `Ithkuil.Romanization`."
  @spec from_latin(String.t()) :: {:ok, Coord.t()} | {:error, term()}
  defdelegate from_latin(string), to: Romanization

  @doc "Emit the canonical romanization for a coordinate (partial; see `Ithkuil.Romanization`)."
  @spec to_latin(Coord.t() | Coord.wire()) :: {:ok, String.t()} | {:error, term()}
  def to_latin(coord) do
    with {:ok, c} <- Coord.new(coord), do: Romanization.to_latin(c)
  end

  @doc "Coordinate -> natural number (codec-v1 ranking, CODEC.md section 3)."
  @spec to_integer(Coord.t() | Coord.wire()) :: {:ok, non_neg_integer()} | {:error, term()}
  def to_integer(coord) do
    with {:ok, c} <- Coord.new(coord), do: {:ok, Codec.word_to_integer(c)}
  end

  @doc """
  Natural number -> canonical coordinate. Strict: only canonical
  serializations of valid words decode successfully.
  """
  @spec from_integer(non_neg_integer()) :: {:ok, Coord.t()} | {:error, term()}
  def from_integer(n) when is_integer(n) and n >= 0, do: Codec.integer_to_word(n)
  def from_integer(_), do: {:error, :invalid_natural_number}

  @doc "Coordinate -> unsigned decimal string (the boundary form of the integer)."
  @spec to_integer_string(Coord.t() | Coord.wire()) :: {:ok, String.t()} | {:error, term()}
  def to_integer_string(coord) do
    with {:ok, n} <- to_integer(coord), do: {:ok, Integer.to_string(n)}
  end

  @doc """
  Unsigned decimal string -> canonical coordinate. Rejects anything that is
  not a plain string of ASCII digits (`{:error, :invalid_natural_number}`).
  """
  @spec from_integer_string(String.t()) :: {:ok, Coord.t()} | {:error, term()}
  def from_integer_string(s) when is_binary(s) do
    if s != "" and digits_only?(s) do
      from_integer(String.to_integer(s))
    else
      {:error, :invalid_natural_number}
    end
  end

  def from_integer_string(_), do: {:error, :invalid_natural_number}

  defp digits_only?(<<c, rest::binary>>) when c in ?0..?9, do: digits_only?(rest)
  defp digits_only?(<<>>), do: true
  defp digits_only?(_), do: false

  @doc "Coordinate -> canonical codec-v1 byte serialization `ser(word)`."
  @spec to_bytes(Coord.t() | Coord.wire()) :: {:ok, binary()} | {:error, term()}
  def to_bytes(coord) do
    with {:ok, c} <- Coord.new(coord), do: {:ok, Codec.encode_word(c)}
  end

  @doc """
  Strict byte decode: minimal varints, sorted sockets, no trailing bytes —
  only the canonical serialization of a valid word succeeds
  (SDK-INTERFACE.md strictness boundary).
  """
  @spec from_bytes(binary()) :: {:ok, Coord.t()} | {:error, term()}
  def from_bytes(bytes) when is_binary(bytes), do: Codec.decode_word(bytes)
  def from_bytes(other), do: {:error, {:invalid_structure, other}}

  @doc "Coordinate -> canonical JSON tagged-array wire form (as Elixir data)."
  @spec to_wire(Coord.t() | Coord.wire()) :: {:ok, Coord.wire()} | {:error, term()}
  def to_wire(coord) do
    with {:ok, c} <- Coord.new(coord), do: {:ok, Coord.to_wire(c)}
  end

  @doc """
  Lenient-canonicalizing wire parse: accepts unsorted sockets and `[id, nil]`
  empties (empties dropped, sockets sorted); duplicate sockets always error.
  """
  @spec from_wire(Coord.wire()) :: {:ok, Coord.t()} | {:error, term()}
  defdelegate from_wire(wire), to: Coord

  @doc "Coordinate -> canonical wire-form JSON text."
  @spec to_wire_json(Coord.t() | Coord.wire()) :: {:ok, String.t()} | {:error, term()}
  def to_wire_json(coord) do
    with {:ok, wire} <- to_wire(coord), do: {:ok, JSON.encode(wire)}
  end

  @doc """
  Wire-form JSON text -> canonical coordinate. Same lenient-canonicalizing
  rules as `from_wire/1`; text that is not valid JSON is
  `{:error, {:invalid_structure, detail}}`.
  """
  @spec from_wire_json(String.t()) :: {:ok, Coord.t()} | {:error, term()}
  def from_wire_json(json) when is_binary(json) do
    case JSON.parse(json) do
      {:ok, wire} -> Coord.from_wire(wire)
      {:error, reason} -> {:error, {:invalid_structure, reason}}
    end
  end

  def from_wire_json(other), do: {:error, {:invalid_structure, other}}

  @doc """
  Structural check of a language-native coordinate value. Returns
  `{:ok, coord}` only when `coord` is already the canonical tuple;
  merely non-canonical input (unsorted sockets, `{id, :empty}` entries)
  is `{:error, {:invalid_structure, :not_canonical}}` — use
  `canonicalize/1` to repair instead.
  """
  @spec validate(term()) :: {:ok, Coord.t()} | {:error, term()}
  def validate(coord) do
    with :ok <- Coord.validate(coord), do: {:ok, coord}
  end

  @doc """
  Lenient repair + validate: sockets sorted ascending, `{id, :empty}` /
  `[id, nil]` empties dropped; duplicate sockets always error. Accepts the
  canonical tuple or the wire form (as Elixir data).
  """
  @spec canonicalize(Coord.t() | Coord.wire() | term()) :: {:ok, Coord.t()} | {:error, term()}
  defdelegate canonicalize(coord), to: Coord, as: :new

  @doc """
  Coordinate -> deterministic render model (see `Ithkuil.Scene`).

  The codec-provided facts are attached automatically: `integer` always
  (this *is* the codec), `latinized` when the romanization layer covers the
  coordinate (`nil` otherwise — never guessed).
  """
  @spec to_scene(Coord.t() | Coord.wire()) :: {:ok, Scene.model()} | {:error, term()}
  def to_scene(coord) do
    with {:ok, c} <- Coord.new(coord) do
      integer = c |> Codec.word_to_integer() |> Integer.to_string()

      latinized =
        case Romanization.to_latin(c) do
          {:ok, s} -> s
          {:error, _} -> nil
        end

      {:ok, Scene.compile(c, latinized: latinized, integer: integer)}
    end
  end
end
