defmodule Timely.Sync.Canon do
  @moduledoc """
  Canonical name normalization and the deterministic UUIDv5 ids derived from it.

  `canon/1` MUST be implemented identically here, in Swift and in Kotlin. Any
  divergence silently produces duplicate taxonomy rows - it does not throw, does
  not log, and does not fail a sync - which is why
  `apps/shared/contracts/canon-fixtures.json` is a hard conformance gate for all
  three implementations (SYNC-PROTOCOL section 14).

  The eight steps, in order, are fixed by the fixture's `canon_algorithm`:

    1. Strip the enumerated invisible formatting code points.
    2. NFKC normalization.
    3. Map the enumerated smart quotes to their ASCII equivalents.
    4. Replace every enumerated whitespace code point with U+0020.
    5. Collapse runs of U+0020 to one; trim leading and trailing U+0020.
    6. Lowercase, locale-independent.
    7. Map U+03C2 FINAL SIGMA to U+03C3 SIGMA.
    8. NFC normalization.

  Three of those steps exist only because the implementations disagree without
  them, and each is easy to "simplify" into a bug:

  - **Step 3 must run after step 2, not before.** U+0149 LATIN SMALL LETTER N
    PRECEDED BY APOSTROPHE NFKC-decomposes to U+02BC + U+006E. Mapping quotes
    first would leave that U+02BC behind and diverge from the ASCII spelling.
    U+0149 is the only code point in Unicode that NFKC maps into the quote
    target set, and it is pinned by a fixture case.

  - **Step 6 is lowercase, not case folding.** `String.downcase/1` in `:default`
    mode is locale-independent: it maps `I` to `i` and never to the Turkish
    dotless `ı`, so a device in a `tr_TR` locale converges with everyone else.
    Because it is lowercase and not folding, `Straße` and `strasse` stay
    different clients. That is deliberate, reviewed, and pinned by two fixture
    cases - do not "fix" it.

  - **Step 7 exists because of Elixir specifically.** Java, Swift and Python
    apply the Unicode `Final_Sigma` context rule while lowercasing and emit `ς`;
    Elixir's `:default` mode emits `σ`. Normalizing `ς` to `σ` afterwards makes
    all four converge on the same id.

  Diacritics are deliberately *not* folded: "Munoz" and "Muñoz" are different
  clients. U+200C ZWNJ and U+200D ZWJ are deliberately *not* stripped - they are
  semantically significant in Indic and Persian text and in emoji ZWJ sequences.
  """

  # Invisible formatting noise that survives copy-paste. Enumerated rather than
  # derived from a category so the Swift and Kotlin ports have an unambiguous
  # list. Note that U+200C and U+200D are absent on purpose.
  @strip MapSet.new([
           0x00AD,
           0x200B,
           0x200E,
           0x200F,
           0x202A,
           0x202B,
           0x202C,
           0x202D,
           0x202E,
           0x2066,
           0x2067,
           0x2068,
           0x2069,
           0xFEFF
         ])

  # A fixed, closed set: the marks that US and German smart-quote features
  # substitute for the ASCII ' and " keys. Not a general punctuation-folding
  # table - "Acme, Inc." and "Acme Inc" remain different clients.
  @quotes %{
    0x02BC => 0x27,
    0x2018 => 0x27,
    0x2019 => 0x27,
    0x201A => 0x27,
    0x201B => 0x27,
    0x201C => 0x22,
    0x201D => 0x22,
    0x201E => 0x22,
    0x201F => 0x22
  }

  # The Unicode White_Space property, enumerated rather than delegated to a `\s`
  # regex or a runtime `isWhitespace` predicate, which vary between platforms.
  # NFKC folds most of these to U+0020 already; U+1680 OGHAM SPACE MARK is the
  # notable survivor, so this step is not redundant.
  @whitespace MapSet.new(
                [
                  0x0009,
                  0x000A,
                  0x000B,
                  0x000C,
                  0x000D,
                  0x0020,
                  0x0085,
                  0x00A0,
                  0x1680,
                  0x2028,
                  0x2029,
                  0x202F,
                  0x205F,
                  0x3000
                ] ++ Enum.to_list(0x2000..0x200A)
              )

  @space 0x20
  @final_sigma 0x03C2
  @sigma 0x03C3

  @doc """
  The strip table `canon/1` consults, exposed (not duplicated) so the
  conformance suite can diff it against the fixture's declared
  `strip_code_points` directly. A behavioural fixture case only proves
  agreement on the code points it happens to exercise; this catches a
  transcription slip anywhere else in the set.
  """
  def strip_code_points, do: @strip

  @doc "The quote-mapping table `canon/1` consults. See `strip_code_points/0`."
  def quote_code_points, do: @quotes

  @doc "The whitespace table `canon/1` consults. See `strip_code_points/0`."
  def whitespace_code_points, do: @whitespace

  @doc """
  Canonicalizes a name. Returns `""` for nil and for anything that normalizes
  away to nothing.

  An empty canonical form is not an entity: callers MUST treat `""` as "no
  reference" rather than minting an id or creating a row named `""`
  (SYNC-PROTOCOL 3.3 and 6.1 step 5).
  """
  # ⟦𓋴𓃀𓇋𓎼⟧ canon :: Canonicalizes a name per SYNC-PROTOCOL 3.3.
  def canon(nil), do: ""

  def canon(value) when is_binary(value) do
    value
    # Step 1
    |> map_codepoints(fn cp -> if MapSet.member?(@strip, cp), do: [], else: [cp] end)
    # Step 2
    |> normalize(:nfkc)
    # Steps 3 and 4 operate on disjoint code point sets, so one pass is safe.
    |> map_codepoints(fn cp ->
      cond do
        Map.has_key?(@quotes, cp) -> [Map.fetch!(@quotes, cp)]
        MapSet.member?(@whitespace, cp) -> [@space]
        true -> [cp]
      end
    end)
    # Step 5
    |> collapse_spaces()
    # Step 6
    |> String.downcase(:default)
    # Step 7
    |> map_codepoints(fn
      @final_sigma -> [@sigma]
      cp -> [cp]
    end)
    # Step 8
    |> normalize(:nfc)
  end

  def canon(value), do: value |> to_string() |> canon()

  @doc "True when a name carries no reference at all."
  # ⟦𓈖𓅱𓃭𓊪⟧ blank? :: True when a canonicalized name carries no reference.
  def blank?(value), do: canon(value) == ""

  @doc """
  Deterministic client id: `uuidv5(workspace_id, "client:" <> canon(name))`.

  Returns `nil` when the name canonicalizes away - an absent reference must not
  mint an entity.
  """
  # ⟦𓎡𓃭𓇋𓏏⟧ client_id :: Deterministic UUIDv5 for a client name, or nil.
  def client_id(workspace_id, name) do
    case canon(name) do
      "" -> nil
      canonical -> uuid5(workspace_id, "client:" <> canonical)
    end
  end

  @doc """
  Deterministic project id:
  `uuidv5(workspace_id, "project:" <> canon(client_name) <> "/" <> canon(name))`.

  An absent parent contributes an empty segment, e.g. `"project:/internal"`; an
  absent *own* name is still no entity.
  """
  # ⟦𓊪𓂋𓊗𓆓⟧ project_id :: Deterministic UUIDv5 for a project name, or nil.
  def project_id(workspace_id, client_name, name) do
    case canon(name) do
      "" -> nil
      canonical -> uuid5(workspace_id, "project:" <> canon(client_name) <> "/" <> canonical)
    end
  end

  @doc """
  Deterministic ticket id:
  `uuidv5(workspace_id, "ticket:" <> canon(client) <> "/" <> canon(project) <> "/" <> canon(name))`.
  """
  # ⟦𓏏𓎡𓏏𓋴⟧ ticket_id :: Deterministic UUIDv5 for a ticket name, or nil.
  def ticket_id(workspace_id, client_name, project_name, name) do
    case canon(name) do
      "" ->
        nil

      canonical ->
        uuid5(
          workspace_id,
          "ticket:" <> canon(client_name) <> "/" <> canon(project_name) <> "/" <> canonical
        )
    end
  end

  @doc """
  Deterministic per-(workspace, user) settings id. The user id is *not*
  canonicalized - it is already a uuid, not a human-typed name.
  """
  # ⟦𓄿𓊃𓏏𓎼⟧ user_settings_id :: Deterministic UUIDv5 for a user's settings row.
  def user_settings_id(workspace_id, user_id) do
    uuid5(workspace_id, "user_settings:" <> to_string(user_id))
  end

  @doc """
  RFC 4122 name-based UUIDv5 (SHA-1) in the workspace's namespace, lowercased.
  """
  # ⟦𓅓𓇋𓂧𓋴⟧ uuid5 :: RFC 4122 UUIDv5 in the workspace namespace.
  def uuid5(workspace_id, name) when is_binary(workspace_id) and is_binary(name) do
    workspace_id
    |> String.downcase()
    |> UUID.uuid5(name)
    |> String.downcase()
  end

  # Rewrites a string one code point at a time. The mapper returns a list so a
  # code point can be dropped (step 1) as well as replaced (steps 3, 4, 7).
  defp map_codepoints(value, mapper) do
    value
    |> to_codepoints()
    |> Enum.flat_map(mapper)
    |> List.to_string()
  end

  # Step 5's three sub-rules in one pass: never emit two U+0020 in a row, and
  # drop the leading and trailing one.
  defp collapse_spaces(value) do
    value
    |> to_codepoints()
    |> Enum.reduce([], fn
      @space, [] -> []
      @space, [@space | _] = acc -> acc
      char, acc -> [char | acc]
    end)
    |> case do
      [@space | rest] -> rest
      acc -> acc
    end
    |> Enum.reverse()
    |> List.to_string()
  end

  defp normalize(value, form) do
    normalized =
      case form do
        :nfkc -> :unicode.characters_to_nfkc_binary(value)
        :nfc -> :unicode.characters_to_nfc_binary(value)
      end

    # Malformed UTF-8 cannot be normalized, and canonicalizing it anyway would
    # be a lie. The raw bytes pass through and the uniqueness index sees them
    # as-is.
    if is_binary(normalized), do: normalized, else: value
  end

  defp to_codepoints(value) do
    case :unicode.characters_to_list(value) do
      chars when is_list(chars) -> chars
      _ -> :binary.bin_to_list(value)
    end
  end
end
