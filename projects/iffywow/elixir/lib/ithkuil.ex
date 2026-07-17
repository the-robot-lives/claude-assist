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
  tagged-array wire form (as Elixir data — JSON text is the caller's concern)
  and are canonicalized on entry.
  """

  alias Ithkuil.{Codec, Coord, Romanization, Scene}

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
