defmodule ForyouWeb.MeController do
  @moduledoc """
  Authenticated self-service surface (Preference Center backend, consumed by
  Chunk E). `/me/signups` lists the caller's reconciled subscriptions;
  `/me/inquiries` UNIONs inquiry-kind signups with legacy `inquiries` rows
  matched by email, tagged `source:"legacy"` (D9); `DELETE /me/signups/:id`
  unsubscribes one of the caller's own signups.
  """
  use ForyouWeb, :controller
  import Ecto.Query

  alias Foryou.{Repo, Signups}
  alias Foryou.Schema.Users.User, as: UserSchema

  def signups(conn, _params) do
    user = current_user(conn)

    rows =
      user.id
      |> Signups.list_signups_for_user()
      |> Enum.map(&serialize_signup/1)

    json(conn, %{signups: rows})
  end

  def inquiries(conn, _params) do
    user = current_user(conn)
    email = user_email(user)

    inquiry_signups =
      from(s in Foryou.Schema.Signups.Signup,
        join: l in Foryou.Schema.Lists.List,
        on: l.id == s.list_id,
        where: s.user_id == ^user.id and l.kind == "inquiry",
        order_by: [desc: s.inserted_at]
      )
      |> Repo.all()
      |> Enum.map(&serialize_signup/1)

    legacy = if email, do: legacy_inquiries(email), else: []

    json(conn, %{inquiries: inquiry_signups ++ legacy})
  end

  def delete_signup(conn, %{"id" => id}) do
    user = current_user(conn)

    case Signups.get_signup(id) do
      %{user_id: uid} = signup when uid == user.id ->
        case Signups.unsubscribe_by_token(signup.unsub_token) do
          {:ok, _} -> send_resp(conn, :no_content, "")
          {:error, _} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "could not unsubscribe"})
        end

      _ ->
        conn |> put_status(:not_found) |> json(%{error: "not found"})
    end
  end

  # PATCH /me/signups/:id — update contact prefs / pause (Chunk E, FR-006).
  def update_signup(conn, %{"id" => id} = params) do
    with_owned_signup(conn, id, fn signup ->
      case Signups.update_prefs(signup, Map.drop(params, ["id"])) do
        {:ok, updated} ->
          json(conn, %{signup: serialize_signup(reload(updated))})

        {:error, :unknown_frequency} ->
          conn |> put_status(:unprocessable_entity) |> json(%{error: "unknown frequency"})

        {:error, :invalid_pause_until} ->
          conn |> put_status(:unprocessable_entity) |> json(%{error: "invalid pause_until"})

        {:error, :list_archived} ->
          conn |> put_status(:conflict) |> json(%{error: "list archived"})

        {:error, _} ->
          conn |> put_status(:unprocessable_entity) |> json(%{error: "could not update preferences"})
      end
    end)
  end

  # POST /me/signups/:id/resubscribe (Chunk E, FR-007 / D15).
  def resubscribe_signup(conn, %{"id" => id}) do
    with_owned_signup(conn, id, fn signup ->
      case Signups.resubscribe(signup) do
        {:ok, updated} ->
          status = if updated.status == "pending_optin", do: :accepted, else: :ok
          conn |> put_status(status) |> json(%{signup: serialize_signup(reload(updated))})

        {:error, :list_archived} ->
          conn |> put_status(:conflict) |> json(%{error: "list archived"})

        {:error, _} ->
          conn |> put_status(:unprocessable_entity) |> json(%{error: "could not re-subscribe"})
      end
    end)
  end

  # POST /me/signups/:id/resume (Chunk E, FR-007).
  def resume_signup(conn, %{"id" => id}) do
    with_owned_signup(conn, id, fn signup ->
      case Signups.resume(signup) do
        {:ok, updated} -> json(conn, %{signup: serialize_signup(reload(updated))})
        {:error, _} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "could not resume"})
      end
    end)
  end

  # GET /me/export — synchronous JSON dump of the caller's data (D11/FR-009).
  def export(conn, _params) do
    user = current_user(conn)
    email = user_email(user)
    %{signups: signups, inquiry_signups: inquiry_signups} = Signups.export_for_user(user.id)
    legacy = if email, do: legacy_inquiries(email), else: []

    payload = %{
      user: %{id: user.id, email: email},
      generated_at: DateTime.utc_now(),
      signups: Enum.map(signups, &serialize_signup/1),
      inquiries: Enum.map(inquiry_signups, &serialize_signup/1) ++ legacy
    }

    conn
    |> put_resp_header("content-disposition", ~s(attachment; filename="foryou-export.json"))
    |> json(payload)
  end

  # POST /me/deletion-request — stub queuer, no immediate erasure (D11/FR-010).
  def deletion_request(conn, _params) do
    user = current_user(conn)
    _ = Signups.request_deletion(user.id)

    conn
    |> put_status(:accepted)
    |> json(%{
      status: "queued",
      message:
        "Your deletion request has been queued. We'll process the erasure of your personal " <>
          "data per policy; some records may be retained where legally required."
    })
  end

  # ── helpers ────────────────────────────────────────────────────

  # Legacy inquiries table (changelog 025) — pre-dual-write rows matched by
  # email, so /me history is complete (D9).
  defp legacy_inquiries(email) do
    sql = """
    SELECT id, name, email, message, source, inserted_at
    FROM inquiries WHERE lower(email) = lower($1) ORDER BY inserted_at DESC
    """

    case Ecto.Adapters.SQL.query(Repo, sql, [email]) do
      {:ok, %{rows: rows}} ->
        Enum.map(rows, fn [id, name, mail, message, src, inserted_at] ->
          %{
            id: uuid(id),
            source: "legacy",
            legacy_source: src,
            name: name,
            email: mail,
            message: message,
            inserted_at: inserted_at
          }
        end)

      _ ->
        []
    end
  end

  defp serialize_signup(s) do
    list = if Ecto.assoc_loaded?(s.list), do: s.list, else: nil
    service = if list && Ecto.assoc_loaded?(list.project), do: list.project, else: nil

    %{
      id: s.id,
      email: s.email,
      status: s.status,
      attribs: s.attribs,
      contact_prefs: s.contact_prefs,
      pause_until: s.pause_until,
      source: s.source,
      inserted_at: s.inserted_at,
      subscribed_at: s.inserted_at,
      can_resubscribe: !!list && list.status == "active",
      list:
        list &&
          %{
            id: list.id,
            name: list.name,
            public_slug: list.public_slug,
            kind: list.kind,
            settings: list_settings(list.settings)
          },
      service:
        service &&
          %{id: service.id, name: service.name, slug: service.slug, branding: branding(service)}
    }
  end

  # Public-safe list settings the Preference Center inherits from (list defaults).
  defp list_settings(settings) when is_map(settings) do
    Map.take(settings, ["contact_prefs", "available_channels", "preference_defaults"])
  end

  defp list_settings(_), do: %{}

  defp branding(%{settings: %{"branding" => b}}) when is_map(b), do: b
  defp branding(%{name: name}), do: %{"name" => name}

  # Fetch a fresh, list+service-preloaded copy for serialization after a write.
  defp reload(%{id: id}), do: Foryou.Signups.get_signup(id) |> Repo.preload(list: :project)

  # Resolve the caller's own signup by id; 404 (no-leak) on foreign/missing id.
  defp with_owned_signup(conn, id, fun) do
    user = current_user(conn)

    case Signups.get_signup(id) do
      %{user_id: uid} = signup when not is_nil(uid) and uid == user.id -> fun.(signup)
      _ -> conn |> put_status(:not_found) |> json(%{error: "not found"})
    end
  end

  defp current_user(conn) do
    case Foryou.Guardian.Plug.current_resource(conn) do
      %Foryou.Users.Sessions.UserSession{user: {:ref, _, id}} -> %{id: id}
      %Foryou.Users.Sessions.UserSession{user: %{id: id}} -> %{id: id}
      _ -> %{id: nil}
    end
  end

  defp user_email(%{id: nil}), do: nil

  defp user_email(%{id: id}) do
    case Repo.get(UserSchema, id) do
      %{email: email} -> email
      _ -> nil
    end
  end

  defp uuid(bin) when is_binary(bin) do
    case Ecto.UUID.load(bin) do
      {:ok, s} -> s
      _ -> bin
    end
  end

  defp uuid(other), do: other
end
