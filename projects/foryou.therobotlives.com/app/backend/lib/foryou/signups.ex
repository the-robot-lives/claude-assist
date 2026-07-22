defmodule Foryou.Signups do
  @moduledoc """
  Context for signups — public intake, opt-in lifecycle, reconcile-on-login, and
  the listmonk backfill import.

  `add_signup/4` is the single public intake path (endpoint, inquiries dual-write,
  resends). It is idempotent on `(list_id, email)` and never silently re-subscribes
  an explicit opt-out (D15). Emails (double-opt-in confirmation / single-opt-in
  receipt) are enqueued to Oban and use the list's sender identity.
  """
  import Ecto.Query
  alias Foryou.Repo
  alias Foryou.Lists
  alias Foryou.Schema.Lists.List
  alias Foryou.Schema.Signups.Signup
  alias Foryou.Workers.SignupEmailWorker

  @type effect :: :created | :updated | :reactivated | :noopt

  # ── Reads ──────────────────────────────────────────────────────

  def get_signup(id), do: Repo.get(Signup, id)

  def get_by_unsub_token(token), do: Repo.get_by(Signup, unsub_token: token)
  def get_by_confirm_token(token), do: Repo.get_by(Signup, confirm_token: token)

  @doc """
  Signups for a list. Opts: `:status` (filter), `:q` (email substring, case
  -insensitive), `:limit` (default 50), `:offset` (default 0). Offset/limit
  pagination (D6).
  """
  def list_signups(list_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    from(s in Signup,
      where: s.list_id == ^list_id,
      order_by: [desc: s.inserted_at],
      limit: ^limit,
      offset: ^offset
    )
    |> apply_status(Keyword.get(opts, :status))
    |> apply_query(Keyword.get(opts, :q))
    |> Repo.all()
  end

  def count_signups(list_id, opts \\ []) do
    from(s in Signup, where: s.list_id == ^list_id, select: count(s.id))
    |> apply_status(Keyword.get(opts, :status))
    |> apply_query(Keyword.get(opts, :q))
    |> Repo.one()
  end

  @doc """
  An unexecuted, ordered, filtered query over a list's signups — for streamed
  CSV export (D5). Opts: `:status`, `:q` (email substring). No limit/offset.
  """
  def export_query(list_id, opts \\ []) do
    from(s in Signup, where: s.list_id == ^list_id, order_by: [desc: s.inserted_at])
    |> apply_status(Keyword.get(opts, :status))
    |> apply_query(Keyword.get(opts, :q))
  end

  defp apply_status(q, nil), do: q
  defp apply_status(q, ""), do: q
  defp apply_status(q, status), do: from(s in q, where: s.status == ^status)

  defp apply_query(q, nil), do: q
  defp apply_query(q, ""), do: q
  defp apply_query(q, term), do: from(s in q, where: ilike(s.email, ^"%#{term}%"))

  @doc "All signups for a user (reconciled by user_id), with the list + service preloaded."
  def list_signups_for_user(user_id) do
    from(s in Signup, where: s.user_id == ^user_id, order_by: [desc: s.inserted_at])
    |> Repo.all()
    |> Repo.preload(list: :project)
  end

  @doc """
  Inquiry/contact-kind signups for a user, list + service preloaded (Preference
  Center "My inquiries" and the /me export, D9/FR-008).
  """
  def list_inquiry_signups_for_user(user_id) do
    from(s in Signup,
      join: l in List,
      on: l.id == s.list_id,
      where: s.user_id == ^user_id and l.kind in ["inquiry", "contact"],
      order_by: [desc: s.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload(list: :project)
  end

  # ── Public intake (idempotent upsert) ──────────────────────────

  @doc """
  Validate + upsert a signup on `(list_id, email)`.

  Returns `{:ok, signup, effect}` where effect is `:created | :updated |
  :reactivated | :noopt`, or `{:error, reason}` (`:archived`, `:no_email`, or an
  attribute-validation error map). The public controller collapses every result
  to a generic 202 (no-leak); server-side callers (import, dual-write) can act on
  the reason.

  `meta` keys: `:source`, `:submitter_ip`, `:suppress_email` (skip emails).
  """
  @spec add_signup(List.t(), map(), map(), term()) ::
          {:ok, Signup.t(), effect()} | {:error, term()}
  def add_signup(%List{status: "archived"}, _values, _meta, _context), do: {:error, :archived}

  def add_signup(%List{} = list, values, meta, _context) do
    with {:ok, normalized} <- Lists.validate_attributes(list, values),
         email when is_binary(email) <- Lists.identity_email(list, normalized) || :no_email do
      upsert(list, email, normalized, meta)
    else
      :no_email -> {:error, :no_email}
      {:error, reason} -> {:error, reason}
    end
  end

  defp upsert(list, email, normalized, meta) do
    mode = opt_in_mode(list)

    result =
      Repo.transaction(fn ->
        case Repo.get_by(Signup, list_id: list.id, email: email) do
          nil -> do_create(list, email, normalized, meta, mode)
          existing -> do_update(existing, normalized, meta, mode)
        end
      end)

    case result do
      {:ok, {:ok, signup, effect}} ->
        maybe_send_email(signup, list, effect, mode, meta)
        {:ok, signup, effect}

      {:ok, {:error, reason}} ->
        {:error, reason}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp do_create(list, email, normalized, meta, mode) do
    {status, confirm_token, confirm_sent_at} =
      case mode do
        :double -> {"pending_optin", gen_token(), DateTime.utc_now()}
        :single -> {"subscribed", nil, nil}
      end

    attrs = %{
      "list_id" => list.id,
      "email" => email,
      "attribs" => normalized,
      "status" => status,
      "confirm_token" => confirm_token,
      "confirm_sent_at" => confirm_sent_at,
      "unsub_token" => gen_token(),
      "source" => meta[:source],
      "submitter_ip" => meta[:submitter_ip]
    }

    case %Signup{} |> Signup.changeset(attrs) |> Repo.insert() do
      {:ok, signup} -> {:ok, signup, :created}
      {:error, cs} -> Repo.rollback(cs)
    end
  end

  # Existing row. Never downgrade; never clobber an explicit opt-out (D15).
  defp do_update(%Signup{status: "unsubscribed"} = existing, normalized, meta, mode) do
    merged = Map.merge(existing.attribs || %{}, normalized)

    case mode do
      # double opt-in: a fresh confirmation is required to come back
      :double ->
        attrs = %{
          "attribs" => merged,
          "status" => "pending_optin",
          "confirm_token" => gen_token(),
          "confirm_sent_at" => DateTime.utc_now(),
          "source" => meta[:source] || existing.source
        }

        update_row(existing, attrs, :reactivated)

      # single opt-in: stay unsubscribed until an explicit re-subscribe action
      :single ->
        update_row(existing, %{"attribs" => merged}, :noopt)
    end
  end

  defp do_update(%Signup{} = existing, normalized, _meta, _mode) do
    merged = Map.merge(existing.attribs || %{}, normalized)
    update_row(existing, %{"attribs" => merged}, :updated)
  end

  defp update_row(existing, attrs, effect) do
    case existing |> Signup.changeset(attrs) |> Repo.update() do
      {:ok, signup} -> {:ok, signup, effect}
      {:error, cs} -> Repo.rollback(cs)
    end
  end

  defp maybe_send_email(_signup, _list, _effect, _mode, %{suppress_email: true}), do: :ok

  defp maybe_send_email(signup, list, effect, mode, _meta) when effect in [:created, :reactivated] do
    type = if mode == :double, do: "signup_confirm", else: "signup_receipt"
    SignupEmailWorker.enqueue(type, signup.id, list.id)
  end

  defp maybe_send_email(_signup, _list, _effect, _mode, _meta), do: :ok

  # ── Opt-in lifecycle ───────────────────────────────────────────

  @doc "Confirm a double-opt-in signup by token. Idempotent for already-subscribed."
  def confirm_signup(token) when is_binary(token) do
    case get_by_confirm_token(token) do
      nil -> {:error, :invalid}
      %Signup{status: "pending_optin"} = s ->
        s
        |> Signup.changeset(%{"status" => "subscribed", "confirm_token" => nil})
        |> Repo.update()
        |> case do
          {:ok, signup} -> {:ok, signup}
          {:error, _} -> {:error, :invalid}
        end

      %Signup{} = s ->
        {:ok, s}
    end
  end

  def confirm_signup(_), do: {:error, :invalid}

  @doc "Unsubscribe by the stable unsub token. Idempotent."
  def unsubscribe_by_token(token) when is_binary(token) do
    case get_by_unsub_token(token) do
      nil ->
        {:error, :invalid}

      %Signup{status: "unsubscribed"} = s ->
        {:ok, s}

      %Signup{} = s ->
        s
        |> Signup.changeset(%{"status" => "unsubscribed", "confirm_token" => nil})
        |> Repo.update()
        |> case do
          {:ok, signup} -> {:ok, signup}
          {:error, _} -> {:error, :invalid}
        end
    end
  end

  def unsubscribe_by_token(_), do: {:error, :invalid}

  @doc """
  Resend a confirmation. Only acts on a `pending_optin` signup — rotates the
  confirm token (invalidating the prior one) and re-enqueues the email. Any other
  state is a no-op so membership is not leaked.
  """
  def resend_confirmation(%List{} = list, email) when is_binary(email) do
    normalized_email = email |> String.trim() |> String.downcase()

    case Repo.get_by(Signup, list_id: list.id, email: normalized_email) do
      %Signup{status: "pending_optin"} = s ->
        case s
             |> Signup.changeset(%{"confirm_token" => gen_token(), "confirm_sent_at" => DateTime.utc_now()})
             |> Repo.update() do
          {:ok, signup} ->
            SignupEmailWorker.enqueue("signup_confirm", signup.id, list.id)
            {:ok, :sent}

          {:error, _} ->
            {:ok, :noop}
        end

      _ ->
        {:ok, :noop}
    end
  end

  # ── Reconcile-on-login (US-050) ────────────────────────────────

  @doc """
  Claim anonymous signups for a freshly authenticated user by email. Only
  updates rows with `user_id IS NULL` (never reassigns another account's rows).
  Returns `{count, nil}`.
  """
  def reconcile_user(user_id, email) when is_binary(user_id) and is_binary(email) do
    sql = """
    UPDATE signups SET user_id = $1::uuid, updated_at = now()
    WHERE lower(email::text) = lower($2) AND user_id IS NULL
    """

    # Dump the uuid to 16-byte binary — a raw string param to `$1::uuid` raises
    # DBConnection.EncodeError (Postgrex expects the binary uuid format).
    case Ecto.Adapters.SQL.query(Repo, sql, [Ecto.UUID.dump!(user_id), email]) do
      {:ok, %{num_rows: n}} -> {n, nil}
      _ -> {0, nil}
    end
  end

  def reconcile_user(_, _), do: {0, nil}

  # ── Self-service preference management (Preference Center, Chunk E) ──

  @frequencies ~w(immediate daily weekly monthly)

  @doc """
  The list's selectable contact channels — `settings["available_channels"]`,
  falling back to the channel keys of the list-default `contact_prefs`, else
  `["email"]`. Channels outside this set are never enabled on a signup.
  """
  def available_channels(%List{settings: settings}) when is_map(settings) do
    cond do
      is_list(settings["available_channels"]) ->
        Enum.map(settings["available_channels"], &to_string/1)

      is_map(get_in(settings, ["contact_prefs", "channels"])) ->
        settings |> get_in(["contact_prefs", "channels"]) |> Map.keys() |> Enum.map(&to_string/1)

      true ->
        ["email"]
    end
  end

  def available_channels(_), do: ["email"]

  @doc """
  Update a signup's contact preferences and/or `pause_until`. `params` keys
  (string or atom): `"contact_prefs"` (partial override, deep-merged),
  `"pause_until"` (ISO-8601 or null/blank to clear), `"reset_to_default"` (truthy
  → `contact_prefs` reset to `%{}` so the list default is inherited).

  Frequency is validated against #{inspect(@frequencies)}; channels are
  constrained to the list's `available_channels` (unavailable channels forced
  `false`). Returns `{:ok, signup}` or `{:error, reason}` (`:unknown_frequency`,
  `:invalid_pause_until`, `:list_archived`, or a changeset).
  """
  def update_prefs(%Signup{} = signup, params) do
    params = Map.new(params, fn {k, v} -> {to_string(k), v} end)
    list = Repo.get(List, signup.list_id)

    cond do
      list && list.status == "archived" ->
        {:error, :list_archived}

      true ->
        with {:ok, prefs_change} <- resolve_prefs_change(signup, list, params),
             {:ok, pause_change} <- resolve_pause_change(params) do
          attrs = Map.merge(prefs_change, pause_change)

          signup
          |> Signup.changeset(attrs)
          |> Repo.update()
        end
    end
  end

  defp resolve_prefs_change(signup, list, params) do
    cond do
      truthy?(params["reset_to_default"]) ->
        {:ok, %{"contact_prefs" => %{}}}

      is_map(params["contact_prefs"]) ->
        case sanitize_prefs(params["contact_prefs"], list) do
          {:ok, prefs} ->
            {:ok, %{"contact_prefs" => deep_merge(signup.contact_prefs || %{}, prefs)}}

          {:error, reason} ->
            {:error, reason}
        end

      true ->
        {:ok, %{}}
    end
  end

  defp resolve_pause_change(params) do
    case Map.fetch(params, "pause_until") do
      :error -> {:ok, %{}}
      {:ok, nil} -> {:ok, %{"pause_until" => nil}}
      {:ok, ""} -> {:ok, %{"pause_until" => nil}}
      {:ok, %DateTime{} = dt} -> {:ok, %{"pause_until" => dt}}
      {:ok, val} ->
        # Validate parseability, but hand the raw ISO string to the changeset so
        # Ecto pads to the field's usec precision.
        case DateTime.from_iso8601(to_string(val)) do
          {:ok, _dt, _offset} -> {:ok, %{"pause_until" => to_string(val)}}
          _ -> {:error, :invalid_pause_until}
        end
    end
  end

  defp sanitize_prefs(prefs, list) when is_map(prefs) do
    prefs = Map.new(prefs, fn {k, v} -> {to_string(k), v} end)

    case prefs["frequency"] do
      nil -> {:ok, constrain_channels(prefs, list)}
      f when f in @frequencies -> {:ok, constrain_channels(prefs, list)}
      _ -> {:error, :unknown_frequency}
    end
  end

  defp constrain_channels(prefs, list) do
    case prefs["channels"] do
      ch when is_map(ch) ->
        available = available_channels(list)

        constrained =
          Map.new(ch, fn {k, v} -> {to_string(k), to_string(k) in available and v == true} end)

        Map.put(prefs, "channels", constrained)

      _ ->
        prefs
    end
  end

  @doc """
  Re-activate an unsubscribed signup per the list's opt-in mode (D15/FR-007):
  double-opt-in lists go to `pending_optin` with a fresh confirmation email;
  single-opt-in lists go straight to `subscribed`. An already-active/pending
  signup is an idempotent no-op. Archived list → `{:error, :list_archived}`.
  """
  def resubscribe(%Signup{} = signup) do
    list = Repo.get(List, signup.list_id)

    cond do
      is_nil(list) ->
        {:error, :not_found}

      list.status == "archived" ->
        {:error, :list_archived}

      signup.status == "unsubscribed" ->
        case opt_in_mode(list) do
          :double ->
            result =
              signup
              |> Signup.changeset(%{
                "status" => "pending_optin",
                "confirm_token" => gen_token(),
                "confirm_sent_at" => DateTime.utc_now()
              })
              |> Repo.update()

            with {:ok, updated} <- result do
              SignupEmailWorker.enqueue("signup_confirm", updated.id, list.id)
              {:ok, updated}
            end

          :single ->
            signup |> Signup.changeset(%{"status" => "subscribed"}) |> Repo.update()
        end

      true ->
        {:ok, signup}
    end
  end

  @doc "Clear a signup's `pause_until` so contact resumes at prior prefs (FR-007)."
  def resume(%Signup{} = signup) do
    signup |> Signup.changeset(%{"pause_until" => nil}) |> Repo.update()
  end

  @doc """
  Gather the caller's own data for a synchronous export (D11/FR-009): all
  signups plus inquiry/contact-kind signups, list + service preloaded. Legacy
  `inquiries`-table rows (D9) are joined by the controller, which has the email.
  """
  def export_for_user(user_id) do
    %{
      signups: list_signups_for_user(user_id),
      inquiry_signups: list_inquiry_signups_for_user(user_id)
    }
  end

  @doc """
  Queue an account/data deletion request (D11/FR-010). Records the request as an
  Oban job; performs no immediate erasure. Returns `{:ok, job}`.
  """
  def request_deletion(user_id) when is_binary(user_id) do
    Foryou.Workers.DeletionRequestWorker.enqueue(user_id)
  end

  def request_deletion(_), do: {:error, :invalid_user}

  # ── listmonk backfill import (US-093) ──────────────────────────

  @doc """
  Import one backfill row. Direct insert/update with the row's given status;
  never sends opt-in email; never overwrites an existing `unsubscribed` row.
  `row` keys: "email" (required), "status", "attribs", plus provenance folded
  under `attribs["listmonk"]`.
  """
  def import_row(%List{} = list, %{} = row) do
    row = Map.new(row, fn {k, v} -> {to_string(k), v} end)
    email = row["email"] && row["email"] |> to_string() |> String.trim() |> String.downcase()

    cond do
      is_nil(email) or email == "" ->
        {:error, :no_email}

      true ->
        status = normalize_import_status(row["status"])
        attribs = build_import_attribs(row)

        case Repo.get_by(Signup, list_id: list.id, email: email) do
          %Signup{status: "unsubscribed"} = existing ->
            # never resurrect an opt-out; refresh provenance only
            existing
            |> Signup.changeset(%{"attribs" => Map.merge(existing.attribs || %{}, attribs)})
            |> Repo.update()

          %Signup{} = existing ->
            existing
            |> Signup.changeset(%{
              "attribs" => Map.merge(existing.attribs || %{}, attribs),
              "status" => status
            })
            |> Repo.update()

          nil ->
            %Signup{}
            |> Signup.changeset(%{
              "list_id" => list.id,
              "email" => email,
              "attribs" => attribs,
              "status" => status,
              "unsub_token" => gen_token(),
              "source" => "listmonk"
            })
            |> Repo.insert()
        end
    end
  end

  defp build_import_attribs(row) do
    base = row["attribs"] || %{}
    base = if is_map(base), do: base, else: %{}

    provenance =
      row
      |> Map.take(["listmonk_uuid", "listmonk_status", "subscribed_at"])
      |> Map.merge(row["listmonk"] || %{})

    if provenance == %{}, do: base, else: Map.put(base, "listmonk", provenance)
  end

  defp normalize_import_status(status) do
    case status && to_string(status) do
      "unsubscribed" -> "unsubscribed"
      "bounced" -> "bounced"
      "unconfirmed" -> "pending_optin"
      "pending_optin" -> "pending_optin"
      _ -> "subscribed"
    end
  end

  # ── Helpers ────────────────────────────────────────────────────

  @doc "Resolved opt-in mode: `list.settings[\"opt_in_mode\"]` else derived from kind."
  def opt_in_mode(%List{settings: settings, kind: kind}) do
    case settings && settings["opt_in_mode"] do
      "single" -> :single
      "double" -> :double
      _ -> if kind in ["newsletter", "mixed"], do: :double, else: :single
    end
  end

  defp gen_token, do: :crypto.strong_rand_bytes(24) |> Base.url_encode64(padding: false)

  defp truthy?(true), do: true
  defp truthy?("true"), do: true
  defp truthy?(_), do: false

  # Shallow-per-key deep merge: nested maps (e.g. "channels") merge; scalars and
  # lists (e.g. "quiet_periods") replace. Enough for the contact_prefs shape.
  defp deep_merge(base, override) when is_map(base) and is_map(override) do
    Map.merge(base, override, fn
      _k, b, o when is_map(b) and is_map(o) -> Map.merge(b, o)
      _k, _b, o -> o
    end)
  end

  defp deep_merge(_base, override), do: override
end
