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
  Signups for a list. Opts: `:status` (filter), `:limit` (default 50),
  `:offset` (default 0). Offset/limit pagination (D6).
  """
  def list_signups(list_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    q =
      from(s in Signup,
        where: s.list_id == ^list_id,
        order_by: [desc: s.inserted_at],
        limit: ^limit,
        offset: ^offset
      )

    q =
      case Keyword.get(opts, :status) do
        nil -> q
        status -> from(s in q, where: s.status == ^status)
      end

    Repo.all(q)
  end

  def count_signups(list_id, opts \\ []) do
    q = from(s in Signup, where: s.list_id == ^list_id, select: count(s.id))

    q =
      case Keyword.get(opts, :status) do
        nil -> q
        status -> from(s in q, where: s.status == ^status)
      end

    Repo.one(q)
  end

  @doc "All signups for a user (reconciled by user_id), with the list preloaded."
  def list_signups_for_user(user_id) do
    from(s in Signup, where: s.user_id == ^user_id, order_by: [desc: s.inserted_at])
    |> Repo.all()
    |> Repo.preload(:list)
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

    case Ecto.Adapters.SQL.query(Repo, sql, [user_id, email]) do
      {:ok, %{num_rows: n}} -> {n, nil}
      _ -> {0, nil}
    end
  end

  def reconcile_user(_, _), do: {0, nil}

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
end
