# Shared test support: conformance JSONL loading + a deterministic,
# dependency-free coordinate generator. Loaded via Code.require_file/2
# (idempotent across test files).

defmodule Ithkuil.TestSupport.Conformance do
  @moduledoc false

  @conformance_dir Path.expand("../../../conformance", __DIR__)

  @doc "Parse a conformance JSONL file into a list of maps (string keys)."
  def vectors(file) do
    @conformance_dir
    |> Path.join(file)
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      case Ithkuil.JSON.parse(line) do
        {:ok, obj} when is_map(obj) -> obj
        other -> raise "unparseable conformance line #{inspect(line)}: #{inspect(other)}"
      end
    end)
  end

  @doc ~S|JSON term form (["nat", n] / ["pair", x, y] / ["list", [...]] / ["bytes", hex]) -> internal term.|
  def json_term(["nat", n]) when is_integer(n), do: {:nat, n}
  def json_term(["pair", x, y]), do: {:pair, json_term(x), json_term(y)}
  def json_term(["list", items]) when is_list(items), do: {:list, Enum.map(items, &json_term/1)}
  def json_term(["bytes", hex]) when is_binary(hex), do: {:bytes, hex!(hex)}

  @doc "Lowercase hex -> binary."
  def hex!(s), do: Base.decode16!(s, case: :lower)

  @doc "Extract the error class atom from an {:error, _} result."
  def error_class({:error, {class, _detail}}) when is_atom(class), do: class
  def error_class({:error, class}) when is_atom(class), do: class
end

defmodule Ithkuil.TestSupport.Gen do
  @moduledoc false
  # Deterministic 64-bit LCG (Knuth MMIX constants) threaded explicitly —
  # identical output on every machine and OTP release; no dependencies.

  import Bitwise

  @a 6_364_136_223_846_793_005
  @c 1_442_695_040_888_963_407
  @mask 0xFFFFFFFFFFFFFFFF

  def next(s), do: band(s * @a + @c, @mask)

  @doc "Uniform-ish pick in 0..(n-1); returns {value, state}."
  def pick(s, n) when n >= 1 do
    s2 = next(s)
    {rem(bsr(s2, 16), n), s2}
  end

  @doc "Generate a valid canonical coordinate; returns {coord, state}."
  def coord(s) do
    {n, s} = pick(s, 4)
    {glyphs, s} = repeat(n, s, &glyph/1)
    {{:ithkuil_word, 1, glyphs}, s}
  end

  defp glyph(s) do
    {cc, s} = pick(s, 5)
    {base, s} = pick(s, 64)
    {orientation, s} = pick(s, 4)
    {sockets, s} = sockets(s, 0)
    {{:glyph, cc, base, orientation, sockets}, s}
  end

  defp sockets(s, depth) when depth >= 2, do: {[], s}

  defp sockets(s, depth) do
    {n, s} = pick(s, 4 - depth)

    {ids, s} = take_distinct(Enum.to_list(0..7), n, s, [])

    Enum.map_reduce(Enum.sort(ids), s, fn id, s ->
      {m, s} = modifier(s, depth)
      {{id, m}, s}
    end)
  end

  defp take_distinct(_pool, 0, s, acc), do: {acc, s}

  defp take_distinct(pool, n, s, acc) do
    {i, s} = pick(s, length(pool))
    {id, pool} = List.pop_at(pool, i)
    take_distinct(pool, n - 1, s, [id | acc])
  end

  defp modifier(s, depth) do
    {shape, s} = pick(s, 40)
    {orientation, s} = pick(s, 4)
    {nd, s} = pick(s, 4)
    {diacritics, s} = repeat(nd, s, fn s -> pick(s, 13) end)
    {child_sockets, s} = sockets(s, depth + 1)
    {{:modifier, shape, orientation, diacritics, child_sockets}, s}
  end

  defp repeat(0, s, _fun), do: {[], s}

  defp repeat(n, s, fun) do
    {v, s} = fun.(s)
    {rest, s} = repeat(n - 1, s, fun)
    {[v | rest], s}
  end
end
