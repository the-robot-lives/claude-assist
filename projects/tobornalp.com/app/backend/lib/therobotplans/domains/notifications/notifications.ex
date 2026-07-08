defmodule Therobotplans.Domains.Notifications do
  @moduledoc """
  Per-recipient notification inbox.

  `notify/1` resolves a target (one or more recipient handles) to a concrete set
  of recipients and inserts one row per recipient, so read/seen/ack state is
  genuinely per-recipient. A `:dedup_key` collapses repeating items into one
  still-unread row that resurfaces with a fresh `seq` instead of piling up.

  `get/3` is a cursor pull: rows with `seq > cursor`, due (`deliver_after` null or
  past), not acked, ordered `seq ASC`. `poll/3` is the Monitor/long-poll variant —
  it blocks until a matching row is published or `:wait_ms` elapses. Both apply a
  hardcoded per-recipient delivery rate-limit.

  All rows are organization-scoped. A publish broadcasts `{:notification, seq}`
  on `notifications:<org>` so a waiting `poll/3` wakes immediately.
  """

  import Ecto.Query
  require Logger

  alias Therobotplans.Repo
  alias Therobotplans.Schema.Notification

  @pubsub Therobotplans.PubSub
  @max_wait_ms 290_000
  @backstop_ms 5_000
  # At most @rate_limit_count deliveries per recipient per @rate_limit_span_ms.
  @rate_limit_count 1
  @rate_limit_span_ms 300_000
  @rate_limit_ms @rate_limit_span_ms

  # ── Publish ───────────────────────────────────────────────────

  @doc """
  Create notification(s). `attrs` is a map describing one logical notification;
  it is fanned out to every resolved recipient.

  Recipient resolution draws from the union of `:recipient` (a single handle)
  and `:recipients` (a list of handles). (Group→chat-room resolution is not
  included in this MVP — chat is out of scope.)

  Required: `:organization_id`, `:kind`, and at least one resolved recipient.
  Optional: `:project_id`, `:sender`, `:subject_type`, `:subject_id`, `:body`,
  `:payload`, `:deliver_after`, `:dedup_key`.

  When `:dedup_key` is set the insert upserts against the partial unique index
  (one still-unread row per recipient+dedup_key), bumping `seq` and incrementing
  `payload.count` so the item resurfaces rather than duplicating.

  Returns `{:ok, [%Notification{}]}` or `{:error, reason}` if no recipient.
  """
  def notify(attrs) do
    org_id = attrs[:organization_id]
    recipients = resolve_recipients(attrs)

    cond do
      is_nil(org_id) -> {:error, :organization_required}
      recipients == [] -> {:error, :no_recipients}
      true -> {:ok, Enum.flat_map(recipients, &insert_for(attrs, &1, org_id))}
    end
  end

  defp insert_for(attrs, recipient, org_id) do
    base =
      attrs
      |> Map.take([:project_id, :sender, :kind, :subject_type, :subject_id, :body, :payload, :deliver_after, :dedup_key])
      |> Map.put(:organization_id, org_id)
      |> Map.put(:recipient, recipient)

    case do_insert(base) do
      {:ok, row} ->
        Phoenix.PubSub.broadcast(@pubsub, topic(org_id), {:notification, row.seq})
        [row]

      {:error, changeset} ->
        Logger.error("notify insert for #{recipient} failed: #{inspect(changeset.errors)}")
        []
    end
  end

  defp do_insert(%{dedup_key: key} = attrs) when is_binary(key) and key != "" do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert(
      on_conflict:
        from(n in Notification,
          update: [
            set: [
              body: fragment("EXCLUDED.body"),
              sender: fragment("EXCLUDED.sender"),
              subject_type: fragment("EXCLUDED.subject_type"),
              subject_id: fragment("EXCLUDED.subject_id"),
              updated_at: fragment("now()"),
              seq: fragment("nextval('trp_notifications_seq')"),
              payload:
                fragment(
                  "jsonb_set(COALESCE(?, '{}'::jsonb), '{count}', to_jsonb(COALESCE((?->>'count')::int, 1) + 1))",
                  n.payload,
                  n.payload
                )
            ]
          ]
        ),
      conflict_target:
        {:unsafe_fragment,
         ~s|("organization_id", "recipient", "dedup_key") WHERE read = false AND dedup_key IS NOT NULL|},
      returning: true
    )
  end

  defp do_insert(attrs) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert(returning: true)
  end

  # ── Recipient resolution ──────────────────────────────────────

  defp resolve_recipients(attrs) do
    (List.wrap(attrs[:recipient]) ++ List.wrap(attrs[:recipients]))
    |> Enum.map(&to_string/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  # ── Read (cursor pull + Monitor) ──────────────────────────────

  @doc """
  Cursor pull for a recipient. Opts:
    * `:cursor` — only rows with `seq > cursor` (default 0).
    * `:max` — page size (default 50).
    * `:kinds` — keep only these kinds.
    * `:include_future` — include not-yet-due rows (default false).
    * `:auto_read` — mark returned rows read (default false).

  Applies the per-recipient delivery rate-limit: if a non-empty batch was
  delivered within the last window, returns `{:throttled, retry_after_ms}` with
  no rows. On a non-empty delivery, stamps the window.
  """
  def get(org_id, recipient, opts \\ []) do
    deliver(org_id, recipient, opts)
  end

  @doc """
  Monitor variant of `get/3`: if nothing is deliverable now, block until a row is
  published (woken by `notify/1`) or `:wait_ms` elapses, then return.
  """
  def poll(org_id, recipient, opts \\ []) do
    wait_ms = clamp_wait_ms(opts[:wait_ms])

    if wait_ms <= 0 do
      deliver(org_id, recipient, opts)
    else
      Phoenix.PubSub.subscribe(@pubsub, topic(org_id))

      try do
        case deliver(org_id, recipient, opts) do
          {:ok, []} ->
            deadline = System.monotonic_time(:millisecond) + wait_ms
            wait_loop(org_id, recipient, opts, deadline)

          # Throttled or has rows → return immediately; the Monitor re-polls.
          other ->
            other
        end
      after
        Phoenix.PubSub.unsubscribe(@pubsub, topic(org_id))
      end
    end
  end

  defp wait_loop(org_id, recipient, opts, deadline) do
    remaining = deadline - System.monotonic_time(:millisecond)

    if remaining <= 0 do
      deliver(org_id, recipient, opts)
    else
      receive do
        {:notification, _seq} -> :woke
      after
        min(remaining, @backstop_ms) -> :timeout
      end

      case deliver(org_id, recipient, opts) do
        {:ok, []} -> wait_loop(org_id, recipient, opts, deadline)
        other -> other
      end
    end
  end

  # Rate-limited delivery shared by get/poll. Returns {:ok, rows} | {:throttled, ms}.
  defp deliver(org_id, recipient, opts) do
    case rate_limit_remaining(org_id, recipient) do
      ms when ms > 0 ->
        {:throttled, ms}

      _ ->
        rows = pull_rows(org_id, recipient, opts)

        if rows != [] do
          stamp_delivery(org_id, recipient)
          if opts[:auto_read], do: mark_read(org_id, recipient, Enum.map(rows, & &1.id))
        end

        {:ok, rows}
    end
  end

  defp pull_rows(org_id, recipient, opts) do
    cursor = opts[:cursor] || 0
    max = opts[:max] || 50

    query =
      from(n in Notification,
        where:
          n.organization_id == ^org_id and n.recipient == ^recipient and
            n.seq > ^cursor and n.acked == false,
        order_by: [asc: n.seq],
        limit: ^max
      )

    query
    |> maybe_due(opts[:include_future])
    |> maybe_kinds(opts[:kinds])
    |> Repo.all()
  end

  defp maybe_due(query, true), do: query

  defp maybe_due(query, _) do
    now = DateTime.utc_now()
    where(query, [n], is_nil(n.deliver_after) or n.deliver_after <= ^now)
  end

  defp maybe_kinds(query, nil), do: query
  defp maybe_kinds(query, []), do: query
  defp maybe_kinds(query, kinds), do: where(query, [n], n.kind in ^kinds)

  # ── Lifecycle (read / seen / ack / clear) ─────────────────────

  @doc "Mark rows read for a recipient. `ids` is a list of ids, or `:all`."
  def mark_read(org_id, recipient, ids \\ :all),
    do: set_flags(org_id, recipient, ids, read: true, read_at: now())

  @doc "Mark rows seen for a recipient. `ids` is a list of ids, or `:all`."
  def mark_seen(org_id, recipient, ids \\ :all),
    do: set_flags(org_id, recipient, ids, seen: true, seen_at: now())

  @doc "Ack (dismiss) rows for a recipient — removes them from future deliveries."
  def ack(org_id, recipient, ids \\ :all),
    do: set_flags(org_id, recipient, ids, acked: true, acked_at: now())

  @doc "Clear (mark read) rows for a recipient. `ids` is a list of ids, or `:all`."
  def clear(org_id, recipient, ids \\ :all), do: mark_read(org_id, recipient, ids)

  @doc "Notification ids of still-unread rows matching a dedup_key for a recipient."
  def ids_for_dedup(org_id, recipient, dedup_key) do
    from(n in Notification,
      where:
        n.organization_id == ^org_id and n.recipient == ^recipient and
          n.dedup_key == ^dedup_key and n.acked == false,
      select: n.id
    )
    |> Repo.all()
  end

  def ack_dedup(org_id, recipient, dedup_key) do
    {count, _} =
      from(n in Notification,
        where:
          n.organization_id == ^org_id and n.recipient == ^recipient and
            n.dedup_key == ^dedup_key and n.acked == false
      )
      |> Repo.update_all(set: [acked: true, acked_at: now()])

    {:ok, count}
  end

  defp set_flags(org_id, recipient, ids, sets) do
    base =
      from(n in Notification,
        where: n.organization_id == ^org_id and n.recipient == ^recipient
      )

    query = if ids == :all, do: base, else: where(base, [n], n.id in ^List.wrap(ids))
    {count, _} = Repo.update_all(query, set: sets)
    {:ok, count}
  end

  @doc "Count unread, due notifications for a recipient."
  def count(org_id, recipient) do
    now = DateTime.utc_now()

    Repo.aggregate(
      from(n in Notification,
        where:
          n.organization_id == ^org_id and n.recipient == ^recipient and
            n.read == false and n.acked == false and
            (is_nil(n.deliver_after) or n.deliver_after <= ^now)
      ),
      :count,
      :id
    )
  end

  @doc "Total notification rows for an organization (overview stat)."
  def stats(org_id) do
    %{
      notifications:
        Repo.aggregate(from(n in Notification, where: n.organization_id == ^org_id), :count, :id)
    }
  end

  # ── Rate-limit (Redis) ────────────────────────────────────────

  defp rate_limit_remaining(org_id, recipient) do
    case Therobotplans.Redis.command(["PTTL", Therobotplans.Redis.prefix(rl_key(org_id, recipient))]) do
      {:ok, ms} when is_integer(ms) and ms > 0 -> ms
      _ -> 0
    end
  rescue
    _ -> 0
  end

  defp stamp_delivery(org_id, recipient) do
    Therobotplans.Redis.set(rl_key(org_id, recipient), "1", px: @rate_limit_ms)
  rescue
    _ -> :ok
  end

  defp rl_key(org_id, recipient), do: "notif_rl:#{org_id}:#{recipient}"

  # ── Helpers ───────────────────────────────────────────────────

  defp topic(org_id), do: "notifications:" <> to_string(org_id)

  defp clamp_wait_ms(ms) when is_integer(ms) and ms > 0, do: min(ms, @max_wait_ms)
  defp clamp_wait_ms(_), do: 0

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:second)

  @doc "Rate-limit window in ms (exposed for tooling/tests)."
  def rate_limit_ms, do: @rate_limit_ms

  @doc "Rate-limit as a {count, span_ms} window (exposed for tooling/tests)."
  def rate_limit, do: {@rate_limit_count, @rate_limit_span_ms}
end
