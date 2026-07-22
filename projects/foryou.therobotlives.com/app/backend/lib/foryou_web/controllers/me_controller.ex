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

    %{
      id: s.id,
      email: s.email,
      status: s.status,
      attribs: s.attribs,
      contact_prefs: s.contact_prefs,
      pause_until: s.pause_until,
      source: s.source,
      inserted_at: s.inserted_at,
      list:
        list &&
          %{id: list.id, name: list.name, public_slug: list.public_slug, kind: list.kind}
    }
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
