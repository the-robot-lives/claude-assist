defmodule Timely.Sync.Entities do
  @moduledoc """
  The registry that ties an `EntityKind` to its schema, its table, its
  `ChangeSet` bucket, and its wire shape.

  Everything that needs to iterate "all nine buckets" or "the ten entity kinds"
  reads it from here, so adding an entity is one edit rather than nine.

  Two shapes differ between the database and the wire and are reconciled here
  rather than in each caller:

  - `time_span.start_at` / `end_at` are `start` / `end` on the wire. The SQL
    words are reserved; the contract keeps the short names.
  - `settings` stores its body in a `document` jsonb column, but the contract
    flattens that document to top level under a `kind` discriminator. See
    `wire/2` and `payload_to_attrs/2`.
  """

  alias Timely.Schema.Devices.Device
  alias Timely.Schema.Evidence.CensoredScreenshot
  alias Timely.Schema.Evidence.Screenshot
  alias Timely.Schema.Evidence.VisionAnalysis
  alias Timely.Schema.Settings.Setting
  alias Timely.Schema.Taxonomy
  alias Timely.Schema.Tracking.TimeSpan

  # kind => {schema module, changes bucket}
  #
  # `user_settings` and `workspace_policy` are two kinds over one table and one
  # bucket; the union is discriminated by the `kind` column.
  @registry %{
    "client" => {Taxonomy.Client, "clients"},
    "project" => {Taxonomy.Project, "projects"},
    "ticket" => {Taxonomy.Ticket, "tickets"},
    "time_span" => {TimeSpan, "time_spans"},
    "screenshot" => {Screenshot, "screenshots"},
    "vision_analysis" => {VisionAnalysis, "vision_analyses"},
    "censored_screenshot" => {CensoredScreenshot, "censored_screenshots"},
    "device" => {Device, "devices"},
    "user_settings" => {Setting, "settings"},
    "workspace_policy" => {Setting, "settings"}
  }

  # The nine buckets, each with the schema whose rows fill it.
  @buckets [
    {"clients", Taxonomy.Client, "client"},
    {"projects", Taxonomy.Project, "project"},
    {"tickets", Taxonomy.Ticket, "ticket"},
    {"time_spans", TimeSpan, "time_span"},
    {"screenshots", Screenshot, "screenshot"},
    {"vision_analyses", VisionAnalysis, "vision_analysis"},
    {"censored_screenshots", CensoredScreenshot, "censored_screenshot"},
    {"devices", Device, "device"},
    {"settings", Setting, "settings"}
  ]

  @envelope_wire_fields [
    :id,
    :workspace_id,
    :created_at,
    :updated_at,
    :server_revision,
    :deleted_at,
    :origin_device_id
  ]

  # Append-only entities: conflict matrix rows 14 and 15 reject every `update`.
  @append_only ~w(vision_analysis censored_screenshot)

  # Name-keyed entities, whose ids are derived rather than random (3.2) and
  # whose creates take the `duplicate_name` path (rows 12 and 13).
  @taxonomy ~w(client project ticket)

  @doc "All nine `ChangeSet` buckets as `{bucket, schema, kind}`."
  # ⟦𓃀𓎡𓏏𓋴⟧ buckets :: The nine ChangeSet buckets.
  def buckets, do: @buckets

  @doc "The ten `EntityKind` values."
  # ⟦𓎡𓈖𓂧𓋴⟧ kinds :: The ten EntityKind values.
  def kinds, do: Map.keys(@registry)

  @doc "The schema module backing an entity kind."
  # ⟦𓋴𓎡𓅓𓂧⟧ schema :: Schema module for an entity kind.
  def schema(kind) do
    case Map.fetch(@registry, kind) do
      {:ok, {module, _bucket}} -> {:ok, module}
      :error -> {:error, :unknown_entity}
    end
  end

  @doc "The `ChangeSet` bucket an entity kind's rows appear in."
  # ⟦𓃀𓅓𓎡𓏏⟧ bucket :: ChangeSet bucket for an entity kind.
  def bucket(kind) do
    {_module, bucket} = Map.fetch!(@registry, kind)
    bucket
  end

  @doc "True for entities whose every `update` is rejected as `immutable_entity`."
  # ⟦𓄿𓊪𓊪𓈖⟧ append_only? :: True for append-only entity kinds.
  def append_only?(kind), do: kind in @append_only

  @doc "True for the name-keyed `client` / `project` / `ticket` kinds."
  # ⟦𓏏𓐍𓈖𓋴⟧ taxonomy? :: True for name-keyed taxonomy kinds.
  def taxonomy?(kind), do: kind in @taxonomy

  @doc """
  Renders a row in the shape the OpenAPI contract defines.

  `opts[:blob_url_builder]` is a 1-arity function used to render
  `screenshot.blob_url`; omitted, the field is null.
  """
  # ⟦𓅱𓇋𓂋𓋴⟧ wire :: Renders a row in the contract's wire shape.
  def wire(row, opts \\ [])

  def wire(%Taxonomy.Client{} = row, _opts) do
    row
    |> envelope()
    |> Map.merge(
      take(row, [:name, :canonical_name, :notes, :auto_created, :merged_into_id, :review_state])
    )
  end

  def wire(%Taxonomy.Project{} = row, _opts) do
    row
    |> envelope()
    |> Map.merge(
      take(row, [
        :name,
        :canonical_name,
        :client_id,
        :client_name,
        :notes,
        :auto_created,
        :merged_into_id,
        :review_state
      ])
    )
  end

  def wire(%Taxonomy.Ticket{} = row, _opts) do
    row
    |> envelope()
    |> Map.merge(
      take(row, [
        :name,
        :canonical_name,
        :client_id,
        :project_id,
        :client_name,
        :project_name,
        :notes,
        :auto_created,
        :merged_into_id,
        :review_state
      ])
    )
  end

  def wire(%TimeSpan{} = row, _opts) do
    row
    |> envelope()
    |> Map.merge(
      take(row, [
        :title,
        :client_id,
        :project_id,
        :ticket_id,
        :client_name,
        :project_name,
        :ticket_name,
        :source,
        :is_billable,
        :notes,
        :review_state,
        :derived_from_span_ids
      ])
    )
    |> Map.merge(%{
      # The SQL columns are start_at / end_at because `start` and `end` are
      # reserved words; the contract keeps the short names.
      "start" => iso(row.start_at),
      "end" => iso(row.end_at),
      "locked_at" => iso(row.locked_at),
      "updated_at_effective" => iso(row.updated_at_effective),
      "review_reasons" => row.review_reasons || []
    })
  end

  def wire(%Screenshot{} = row, opts) do
    builder = Keyword.get(opts, :blob_url_builder)

    row
    |> envelope()
    |> Map.merge(take(row, [:span_id, :file_name, :active_app_name, :upload_state]))
    |> Map.merge(%{
      "captured_at" => iso(row.captured_at),
      # Derived, never stored: "are the bytes here right now".
      "blob_available" => row.upload_state == "uploaded",
      "blob_content_hash" => row.blob_content_hash,
      "blob_byte_size" => row.blob_byte_size,
      "blob_uploaded_at" => iso(row.blob_uploaded_at),
      "blob_url" =>
        if(row.upload_state == "uploaded" and is_function(builder, 1),
          do: builder.(row.id),
          else: nil
        )
    })
  end

  def wire(%VisionAnalysis{} = row, _opts) do
    row
    |> envelope()
    |> Map.merge(
      take(row, [
        :screenshot_id,
        :model,
        :status_update,
        :inferred_project,
        :inferred_task,
        :project_switch_detected,
        :confidence,
        :evidence,
        :privacy_sensitive,
        :privacy_category,
        :raw_response,
        :raw_response_withheld,
        :error_message
      ])
    )
    |> Map.put("analyzed_at", iso(row.analyzed_at))
  end

  def wire(%CensoredScreenshot{} = row, _opts) do
    row
    |> envelope()
    |> Map.merge(
      take(row, [
        :screenshot_id,
        :span_id,
        :file_name,
        :active_app_name,
        :model,
        :category,
        :reason,
        :confidence,
        :deleted_local_file
      ])
    )
    |> Map.merge(%{
      "captured_at" => iso(row.captured_at),
      "censored_at" => iso(row.censored_at)
    })
  end

  def wire(%Device{} = row, _opts) do
    row
    |> envelope()
    |> Map.merge(
      take(row, [
        :user_id,
        :platform,
        :name,
        :app_version,
        :os_version,
        :local_only_screenshots,
        :is_capture_agent,
        :last_sync_revision
      ])
    )
    |> Map.merge(%{
      "last_seen_at" => iso(row.last_seen_at),
      "revoked_at" => iso(row.revoked_at)
    })
  end

  # The stored `document` is flattened to top level under the `kind`
  # discriminator, which is the shape `SettingsRow` describes. Defaults are
  # merged underneath so a row written before a field existed still reads as a
  # complete document.
  def wire(%Setting{} = row, _opts) do
    defaults =
      case row.kind do
        "workspace_policy" -> Setting.policy_defaults()
        _ -> Setting.user_defaults()
      end

    base =
      row
      |> envelope()
      |> Map.put("kind", row.kind)

    base =
      if row.kind == "user_settings",
        do: Map.put(base, "user_id", row.user_id),
        else: base

    defaults
    |> Map.merge(row.document || %{})
    |> Map.merge(base)
  end

  @doc """
  Folds a wire payload into schema attributes: renames `start` / `end`, and for
  settings gathers every non-envelope key back into `document`.
  """
  # ⟦𓊪𓄿𓏏𓂋⟧ payload_to_attrs :: Wire payload to schema attributes.
  def payload_to_attrs("time_span", payload) do
    payload
    |> Map.drop(["start", "end"])
    |> maybe_put("start_at", payload, "start")
    |> maybe_put("end_at", payload, "end")
  end

  def payload_to_attrs(kind, payload) when kind in ["user_settings", "workspace_policy"] do
    reserved =
      ~w(id workspace_id created_at updated_at updated_at_effective server_revision
         deleted_at origin_device_id kind user_id)

    document = Map.drop(payload, reserved)

    payload
    |> Map.take(reserved)
    |> Map.put("kind", kind)
    |> Map.put("document", document)
  end

  def payload_to_attrs(_kind, payload), do: payload

  # `end: null` must be distinguishable from `end` absent - the first reopens a
  # span (rows 6 and 7), the second leaves it alone - so the key is only carried
  # across when the client actually sent it.
  defp maybe_put(attrs, target, payload, source) do
    if Map.has_key?(payload, source),
      do: Map.put(attrs, target, Map.get(payload, source)),
      else: attrs
  end

  defp envelope(row) do
    @envelope_wire_fields
    |> Enum.map(fn field -> {Atom.to_string(field), encode(Map.get(row, field))} end)
    |> Map.new()
  end

  defp take(row, fields) do
    fields
    |> Enum.map(fn field -> {Atom.to_string(field), encode(Map.get(row, field))} end)
    |> Map.new()
  end

  defp encode(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp encode(value), do: value

  defp iso(nil), do: nil
  defp iso(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp iso(value), do: value
end
