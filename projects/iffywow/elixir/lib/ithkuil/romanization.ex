defmodule Ithkuil.Romanization do
  @moduledoc """
  New Ithkuil (Ithkuil IV) romanization layer — deliberately **partial**.

  Full Ithkuil IV morphology (68 cases, 61 biases, 36 aspects, the full Ca
  complex, affix stacking, concatenation, stress-marked relation, ...) is the
  project target, but enum inventories land registry-first (`spec/*.yaml`
  before code). This module therefore implements a conservative, exactly
  reversible core and returns `{:error, {:unsupported, detail}}` for anything
  it cannot encode with confidence — it never guesses.

  ## Formative slot structure (target grammar)

      I    Cc   concatenation status            (NOT yet supported: word-initial h-forms rejected via shape)
      II   Vv   stem + version                  (SUPPORTED: standard series, see table)
      III  Cr   root consonant cluster          (SUPPORTED: clusters over the root inventory below)
      IV   Vr   function + specification        (SUPPORTED for the existential context EXS)
      V    CsVx affixes                         (NOT supported)
      VI   Ca   configuration/extension/
                affiliation/perspective/essence (SUPPORTED: the four single-consonant
                                                 default forms only, see table)
      VII  VxCs affixes                         (NOT supported)
      VIII VnCn valence/phase/level/effect +
                mood/case-scope                 (NOT supported)
      IX   Vc   case (also Vf/Vk)               (SUPPORTED: cases 1-9, the vocalic core)
      X    stress                               (NOT supported: accented vowels are rejected)

  ## Accepted word shape

  Exactly `Vv Cr Vr Ca Vc` — five alternating vowel/consonant runs, vowel
  first. No Cc, no affixes, no VnCn, no stress marks, no glottal stop, no
  hyphens/concatenation. Input is trimmed, NFC-normalized and downcased;
  the emitted (canonical) romanization is exactly what `to_latin/1` returns,
  so `to_latin(from_latin(w)) == {:ok, w}` for every accepted `w` already in
  that canonical spelling.

  ## Parsing tables (closed categories)

  Vv (stem + version):

      a  stem1 PRC   ä  stem1 CPT
      e  stem2 PRC   i  stem2 CPT
      u  stem3 PRC   ü  stem3 CPT
      o  stem0 PRC   ö  stem0 CPT

  Vr (function + specification, context EXS only):

      STA:  a BSC   ä CTE   e CSV   i OBJ
      DYN:  u BSC   ü CTE   o CSV   ö OBJ

  Ca (perspective, essence NRM, default configuration/extension/affiliation):

      l = M (monadic)   r = G (agglomerative)   w = N (nomic)   y = A (abstract)

  Vc (cases 1-9):

      a THM   ä INS   e ABS   i AFF   ëi STM   ö EFF   o ERG   ü DAT   u IND

  Root inventory (27 consonants; order is normative for the provisional root
  code): p b t d k g f v ţ ḑ s z c ẓ š ž č j ç x ļ l r ř m n ň

  ## Provisional coordinate mapping (documented, reversible)

  Until `spec/*.yaml` registries land, parsed formatives map onto the
  coordinate scheme as follows. **This mapping is provisional** — it will be
  superseded by the generated registries; only the coordinate tuple itself is
  canonical.

      glyph.character_class = 0                      (formative)
      glyph.base            = root code: the Cr cluster read as a bijective
                              base-27 numeral over the root inventory
                              ("p" = 1, "pp" = 28, ...); always >= 1
      glyph.orientation     = stem (0..3)
      socket 0 modifier     = shape: specification (BSC 0, CTE 1, CSV 2, OBJ 3)
                              orientation: function + 2 * version
                              (STA/PRC 0, DYN/PRC 1, STA/CPT 2, DYN/CPT 3)
      socket 1 modifier     = shape: perspective (M 0, G 1, N 2, A 3), orientation 0
      socket 2 modifier     = shape: case index (0..8), orientation 0

  All three sockets are always emitted (they are semantically occupied); no
  diacritics, no child sockets. `to_latin/1` accepts exactly coordinates of
  this shape and rejects everything else as `{:unsupported, ...}`.

  Sources: ithkuil.net writing-system + morphology docs (Dec 2022 spec with
  the 2023-02-15 amendments) — see the repository README for the pinned
  references.
  """

  alias Ithkuil.Coord

  @vowels ~w(a e i o u ä ë ö ü)
  @stress_vowels ~w(á é í ó ú â ê î ô û)

  @root_consonants ~w(p b t d k g f v ţ ḑ s z c ẓ š ž č j ç x ļ l r ř m n ň)
  @root_base length(@root_consonants)
  @max_root_cluster 4

  # Consonants recognized by the segmenter (superset of the root inventory);
  # "h" / "'" segment cleanly but are rejected later (shape / root lookup).
  @all_consonants @root_consonants ++ ~w(h w y ')

  # Vv: vowel => {stem, version}  (version: 0 = PRC, 1 = CPT)
  @vv %{
    "a" => {1, 0},
    "ä" => {1, 1},
    "e" => {2, 0},
    "i" => {2, 1},
    "u" => {3, 0},
    "ü" => {3, 1},
    "o" => {0, 0},
    "ö" => {0, 1}
  }
  @vv_inv Map.new(@vv, fn {k, v} -> {v, k} end)

  # Vr: vowel => {function, specification}
  # (function: 0 = STA, 1 = DYN; spec: 0 = BSC, 1 = CTE, 2 = CSV, 3 = OBJ)
  @vr %{
    "a" => {0, 0},
    "ä" => {0, 1},
    "e" => {0, 2},
    "i" => {0, 3},
    "u" => {1, 0},
    "ü" => {1, 1},
    "o" => {1, 2},
    "ö" => {1, 3}
  }
  @vr_inv Map.new(@vr, fn {k, v} -> {v, k} end)

  # Ca: consonant => perspective (essence NRM, defaults elsewhere)
  @ca %{"l" => 0, "r" => 1, "w" => 2, "y" => 3}
  @ca_inv Map.new(@ca, fn {k, v} -> {v, k} end)

  # Vc: case index 0..8 (THM INS ABS AFF STM EFF ERG DAT IND)
  @vc ~w(a ä e i ëi ö o ü u)

  @type reason :: {:unsupported, term()} | {:invalid_input, term()}

  @doc """
  Parse a romanized New Ithkuil formative into a canonical coordinate.
  Returns `{:ok, coord}` or `{:error, {:unsupported, detail}}` /
  `{:error, {:invalid_input, detail}}`.
  """
  @spec from_latin(String.t()) :: {:ok, Coord.t()} | {:error, reason()}
  def from_latin(input) when is_binary(input) do
    word =
      input
      |> String.trim()
      |> String.normalize(:nfc)
      |> String.downcase()

    with {:ok, runs} <- segment(word),
         {:ok, {vv, cr, vr, ca, vc}} <- shape(runs),
         {:ok, {stem, version}} <- table(@vv, vv, :vv),
         {:ok, base} <- root_code(cr),
         {:ok, {function, spec}} <- table(@vr, vr, :vr),
         {:ok, perspective} <- table(@ca, ca, :ca),
         {:ok, case_id} <- vc_index(vc) do
      {:ok,
       {:ithkuil_word, 1,
        [
          {:glyph, 0, base, stem,
           [
             {0, {:modifier, spec, function + 2 * version, [], []}},
             {1, {:modifier, perspective, 0, [], []}},
             {2, {:modifier, case_id, 0, [], []}}
           ]}
        ]}}
    end
  end

  def from_latin(other), do: {:error, {:invalid_input, other}}

  @doc """
  Emit the canonical romanization for a coordinate produced by (or shaped
  like the output of) `from_latin/1`. Anything outside the provisional
  mapping — multiple glyphs, other socket layouts, diacritics, child
  sockets, out-of-range shapes — returns `{:error, {:unsupported, detail}}`.
  """
  @spec to_latin(Coord.t()) :: {:ok, String.t()} | {:error, reason()}
  def to_latin(
        {:ithkuil_word, 1,
         [
           {:glyph, 0, base, stem,
            [
              {0, {:modifier, spec, fn_ver, [], []}},
              {1, {:modifier, perspective, 0, [], []}},
              {2, {:modifier, case_id, 0, [], []}}
            ]}
         ]}
      )
      when is_integer(base) and base >= 1 and stem in 0..3 and spec in 0..3 and
             fn_ver in 0..3 and perspective in 0..3 and is_integer(case_id) and case_id >= 0 do
    version = div(fn_ver, 2)
    function = rem(fn_ver, 2)

    with {:ok, cr} <- root_cluster(base),
         {:ok, vc} <- vc_vowel(case_id) do
      vv = Map.fetch!(@vv_inv, {stem, version})
      vr = Map.fetch!(@vr_inv, {function, spec})
      ca = Map.fetch!(@ca_inv, perspective)
      {:ok, vv <> cr <> vr <> ca <> vc}
    end
  end

  def to_latin({:ithkuil_word, _, _} = coord),
    do: {:error, {:unsupported, {:coordinate_shape, coord}}}

  def to_latin(other), do: {:error, {:invalid_input, other}}

  # ------------------------------------------------------------------
  # Segmentation: grapheme stream -> alternating vowel/consonant runs
  # ------------------------------------------------------------------

  defp segment(word), do: word |> String.graphemes() |> do_segment([])

  defp do_segment([], []), do: {:error, {:unsupported, :empty_word}}

  defp do_segment([], acc) do
    runs =
      acc
      |> Enum.reverse()
      |> Enum.map(fn {kind, chars} -> {kind, chars |> Enum.reverse() |> Enum.join()} end)

    {:ok, runs}
  end

  defp do_segment([ch | rest], acc) do
    case classify(ch) do
      {:error, _} = error ->
        error

      {:ok, kind} ->
        case acc do
          [{^kind, chars} | tail] -> do_segment(rest, [{kind, [ch | chars]} | tail])
          _ -> do_segment(rest, [{kind, [ch]} | acc])
        end
    end
  end

  defp classify(ch) do
    cond do
      ch in @stress_vowels -> {:error, {:unsupported, {:stress_marking, ch}}}
      ch in @vowels -> {:ok, :v}
      ch in @all_consonants -> {:ok, :c}
      true -> {:error, {:unsupported, {:character, ch}}}
    end
  end

  # Exactly Vv Cr Vr Ca Vc.
  defp shape([{:v, vv}, {:c, cr}, {:v, vr}, {:c, ca}, {:v, vc}]) do
    {:ok, {vv, cr, vr, ca, vc}}
  end

  defp shape(runs), do: {:error, {:unsupported, {:word_shape, runs}}}

  # ------------------------------------------------------------------
  # Root code: Cr cluster <-> bijective base-27 numeral (provisional)
  # ------------------------------------------------------------------

  defp root_code(cluster) do
    graphemes = String.graphemes(cluster)

    if length(graphemes) > @max_root_cluster do
      {:error, {:unsupported, {:root_cluster_length, cluster}}}
    else
      Enum.reduce_while(graphemes, {:ok, 0}, fn ch, {:ok, acc} ->
        case Enum.find_index(@root_consonants, &(&1 == ch)) do
          nil -> {:halt, {:error, {:unsupported, {:root_consonant, ch}}}}
          idx -> {:cont, {:ok, acc * @root_base + idx + 1}}
        end
      end)
    end
  end

  defp root_cluster(base) when is_integer(base) and base >= 1 do
    decode_root(base, [])
  end

  defp root_cluster(base), do: {:error, {:unsupported, {:root_code, base}}}

  defp decode_root(0, acc) when length(acc) <= @max_root_cluster, do: {:ok, Enum.join(acc)}
  defp decode_root(0, acc), do: {:error, {:unsupported, {:root_cluster_length, Enum.join(acc)}}}

  defp decode_root(n, acc) do
    digit = Integer.mod(n - 1, @root_base) + 1
    consonant = Enum.at(@root_consonants, digit - 1)
    decode_root(div(n - 1, @root_base), [consonant | acc])
  end

  # ------------------------------------------------------------------
  # Table lookups
  # ------------------------------------------------------------------

  defp table(map, key, slot) do
    case Map.fetch(map, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:unsupported, {slot, key}}}
    end
  end

  defp vc_index(vc) do
    case Enum.find_index(@vc, &(&1 == vc)) do
      nil -> {:error, {:unsupported, {:vc, vc}}}
      idx -> {:ok, idx}
    end
  end

  defp vc_vowel(case_id) do
    case Enum.at(@vc, case_id) do
      nil -> {:error, {:unsupported, {:case_id, case_id}}}
      vowel -> {:ok, vowel}
    end
  end
end
