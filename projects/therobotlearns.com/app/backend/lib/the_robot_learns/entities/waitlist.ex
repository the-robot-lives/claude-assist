defmodule TheRobotLearns.Waitlist do
  @moduledoc """
  Context for the public marketing waitlist.

  A signup records an email, a chosen focus area, and (optionally) an invite
  code. A signup is promoted to "invited" only when the supplied code resolves
  to a genuinely redeemable invite token — token validity is never leaked back
  to the caller beyond the resulting status.
  """
  import Ecto.Query

  alias TheRobotLearns.Repo
  alias TheRobotLearns.Schema.WaitlistSignup

  # Well-formed public invite code (distinct from the raw invite-token secret).
  @invite_format ~r/^TRL-[A-Z0-9-]{6,}$/i
  @email_format ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/

  @doc """
  Validate and upsert a waitlist signup.

  Returns `{:ok, %WaitlistSignup{}}` or `{:error, reason}` where reason is one
  of `:invalid_email`, `:invalid_focus`, `:invalid_invite`, or an
  `Ecto.Changeset`.
  """
  def signup(params) when is_map(params) do
    with {:ok, email} <- validate_email(params["email"]),
         {:ok, focus} <- validate_focus(params["focus"]),
         {:ok, invite} <- validate_invite(params["invite"]) do
      status = resolve_status(invite)
      source = optional_string(params["source"])
      upsert(email, invite, focus, status, source)
    end
  end

  @doc """
  Paginated listing for admin visibility. Mirrors the admin user listing shape.
  """
  def list(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 50)
    offset = (page - 1) * per_page

    signups =
      from(w in WaitlistSignup,
        order_by: [desc: w.inserted_at],
        limit: ^per_page,
        offset: ^offset,
        select: %{
          id: w.id,
          email: w.email,
          focus: w.focus,
          status: w.status,
          invite_token: w.invite_token,
          source: w.source,
          created_at: w.inserted_at,
          updated_at: w.updated_at
        }
      )
      |> Repo.all()

    total = Repo.aggregate(WaitlistSignup, :count, :id)
    %{signups: signups, total: total, page: page, per_page: per_page}
  end

  # -- validation -------------------------------------------------------------

  defp validate_email(email) when is_binary(email) do
    email = email |> String.trim() |> String.downcase()

    if Regex.match?(@email_format, email) do
      {:ok, email}
    else
      {:error, :invalid_email}
    end
  end

  defp validate_email(_), do: {:error, :invalid_email}

  defp validate_focus(focus) when is_binary(focus) do
    focus = String.trim(focus)

    cond do
      focus == "" -> {:error, :invalid_focus}
      String.length(focus) > 64 -> {:error, :invalid_focus}
      true -> {:ok, focus}
    end
  end

  defp validate_focus(_), do: {:error, :invalid_focus}

  # optional; if present it must be well-formed, but need not exist in the DB
  defp validate_invite(nil), do: {:ok, nil}

  defp validate_invite(invite) when is_binary(invite) do
    invite = String.trim(invite)

    cond do
      invite == "" -> {:ok, nil}
      Regex.match?(@invite_format, invite) -> {:ok, invite}
      true -> {:error, :invalid_invite}
    end
  end

  defp validate_invite(_), do: {:error, :invalid_invite}

  # -- status / persistence ---------------------------------------------------

  defp resolve_status(nil), do: "waitlist"

  defp resolve_status(invite) when is_binary(invite) do
    case TheRobotLearns.Organizations.find_active_invite_by_raw_token(invite) do
      {:ok, _token} -> "invited"
      _ -> "waitlist"
    end
  end

  # Upsert on email; repeat submissions refresh focus/invite but never downgrade
  # an already-"invited" signup back to "waitlist".
  defp upsert(email, invite, focus, status, source) do
    case Repo.get_by(WaitlistSignup, email: email) do
      nil ->
        %WaitlistSignup{}
        |> WaitlistSignup.changeset(%{
          email: email,
          invite_token: invite,
          focus: focus,
          status: status,
          source: source
        })
        |> Repo.insert()

      %WaitlistSignup{} = existing ->
        existing
        |> WaitlistSignup.changeset(%{
          focus: focus,
          invite_token: invite || existing.invite_token,
          status: no_downgrade(existing.status, status),
          source: source || existing.source
        })
        |> Repo.update()
    end
  end

  defp no_downgrade("invited", _new), do: "invited"
  defp no_downgrade(_current, new), do: new

  defp optional_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp optional_string(_), do: nil
end
