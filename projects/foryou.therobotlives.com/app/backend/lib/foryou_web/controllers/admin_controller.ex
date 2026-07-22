defmodule ForyouWeb.AdminController do
  use ForyouWeb, :controller

  alias Foryou.Repo
  alias Foryou.Schema.Users.User, as: UserSchema
  alias Foryou.Schema.Organizations.Organization, as: OrgSchema
  alias Foryou.Schema.Lists.List, as: ListSchema
  alias Foryou.Schema.Signups.Signup
  alias Foryou.Schema.Projects.Project
  alias Foryou.Schema.Inquiries.Inquiry
  import Ecto.Query

  def list_users(conn, params) do
    page = String.to_integer(Map.get(params, "page", "1"))
    per_page = String.to_integer(Map.get(params, "per_page", "50"))
    offset = (page - 1) * per_page

    users =
      from(u in UserSchema,
        order_by: [desc: u.inserted_at],
        limit: ^per_page,
        offset: ^offset,
        select: %{
          id: u.id,
          email: u.email,
          user_name: u.user_name,
          status: u.status,
          verified: u.verified,
          admin: u.admin,
          created_at: u.inserted_at
        }
      )
      |> Foryou.Repo.all()

    total = Foryou.Repo.aggregate(UserSchema, :count, :id)

    conn |> put_status(:ok) |> json(%{users: users, total: total, page: page, per_page: per_page})
  end

  def show_user(conn, %{"id" => id}) do
    case Foryou.Repo.get(UserSchema, id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "User not found"})

      user ->
        conn |> put_status(:ok) |> json(%{user: %{
          id: user.id,
          email: user.email,
          user_name: user.user_name,
          handle: user.handle,
          status: user.status,
          verified: user.verified,
          admin: user.admin,
          created_at: user.inserted_at
        }})
    end
  end

  def list_organizations(conn, params) do
    page = String.to_integer(Map.get(params, "page", "1"))
    per_page = String.to_integer(Map.get(params, "per_page", "50"))
    offset = (page - 1) * per_page

    orgs =
      from(o in OrgSchema,
        order_by: [desc: o.inserted_at],
        limit: ^per_page,
        offset: ^offset,
        select: %{
          id: o.id,
          slug: o.slug,
          name: o.name,
          created_at: o.inserted_at
        }
      )
      |> Foryou.Repo.all()

    total = Foryou.Repo.aggregate(OrgSchema, :count, :id)

    conn |> put_status(:ok) |> json(%{organizations: orgs, total: total, page: page, per_page: per_page})
  end

  def show_organization(conn, %{"id" => id}) do
    case Foryou.Repo.get(OrgSchema, id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "Organization not found"})

      org ->
        members = Foryou.Organizations.list_members(org.id)
        conn |> put_status(:ok) |> json(%{organization: %{
          id: org.id,
          slug: org.slug,
          name: org.name,
          created_at: org.inserted_at
        }, members: members})
    end
  end

  # ── Signup domain: dashboard overview (US-072/US-099) ──────────

  # GET /api/v1/admin/overview?org_id= — aggregate counts scoped to an org (or
  # global when org_id absent). `rate_limit_hits` is null until telemetry is
  # wired (Q4); the frontend hides the panel gracefully.
  def overview(conn, params) do
    org_id = presence(params["org_id"])
    counts = signup_status_counts(org_id)

    json(conn, %{
      services: count_projects(org_id),
      lists: count_lists(org_id),
      signups: counts.total,
      pending_optin: counts.pending_optin,
      subscribed: counts.subscribed,
      unsubscribed: counts.unsubscribed,
      bounced: counts.bounced,
      recent_signups: recent_signups(org_id, 10),
      signup_volume_24h: signup_volume_24h(org_id),
      rate_limit_hits: nil
    })
  end

  # ── Inquiries review (US-080) ──────────────────────────────────

  def list_inquiries(conn, params) do
    page = String.to_integer(Map.get(params, "page", "1"))
    per_page = String.to_integer(Map.get(params, "per_page", "50"))
    offset = (page - 1) * per_page

    filtered = inquiries_query(params)
    total = Repo.aggregate(filtered, :count, :id)

    inquiries =
      filtered
      |> order_by([i], desc: i.inserted_at)
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()
      |> Enum.map(&serialize_inquiry/1)

    conn
    |> put_status(:ok)
    |> json(%{inquiries: inquiries, total: total, page: page, per_page: per_page})
  end

  def show_inquiry(conn, %{"id" => id}) do
    case Repo.get(Inquiry, id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "Inquiry not found"})
      inquiry -> conn |> put_status(:ok) |> json(%{inquiry: serialize_inquiry(inquiry)})
    end
  end

  # ── Aggregate helpers ──────────────────────────────────────────

  defp count_projects(nil), do: Repo.aggregate(Project, :count, :id)

  defp count_projects(org_id) do
    Repo.one(from p in Project, where: p.organization_id == ^org_id, select: count(p.id))
  end

  defp count_lists(org_id) do
    (from l in ListSchema, as: :l)
    |> scope_org(org_id)
    |> Repo.aggregate(:count, :id)
  end

  defp signup_status_counts(org_id) do
    map =
      signups_base()
      |> scope_org(org_id)
      |> group_by([s: s], s.status)
      |> select([s: s], {s.status, count(s.id)})
      |> Repo.all()
      |> Map.new()

    %{
      total: Enum.reduce(map, 0, fn {_status, c}, acc -> acc + c end),
      pending_optin: Map.get(map, "pending_optin", 0),
      subscribed: Map.get(map, "subscribed", 0),
      unsubscribed: Map.get(map, "unsubscribed", 0),
      bounced: Map.get(map, "bounced", 0)
    }
  end

  defp signup_volume_24h(org_id) do
    since = DateTime.add(DateTime.utc_now(), -24, :hour)

    signups_base()
    |> scope_org(org_id)
    |> where([s: s], s.inserted_at >= ^since)
    |> select([s: s], count(s.id))
    |> Repo.one()
  end

  defp recent_signups(org_id, limit) do
    signups_base()
    |> scope_org(org_id)
    |> order_by([s: s], desc: s.inserted_at)
    |> limit(^limit)
    |> select([s: s, l: l], %{
      id: s.id,
      email: s.email,
      status: s.status,
      list_id: s.list_id,
      list_name: l.name,
      inserted_at: s.inserted_at
    })
    |> Repo.all()
  end

  defp signups_base do
    from s in Signup, as: :s, join: l in ListSchema, as: :l, on: l.id == s.list_id
  end

  defp scope_org(query, nil), do: query

  defp scope_org(query, org_id) do
    from [l: l] in query,
      join: p in Project,
      on: p.id == l.project_id,
      where: p.organization_id == ^org_id
  end

  defp inquiries_query(params) do
    from(i in Inquiry)
    |> filter_eq(:status, presence(params["status"]))
    |> filter_eq(:source, presence(params["source"]))
    |> filter_text(presence(params["q"]))
  end

  defp filter_eq(query, _field, nil), do: query
  defp filter_eq(query, :status, v), do: from(i in query, where: i.status == ^v)
  defp filter_eq(query, :source, v), do: from(i in query, where: i.source == ^v)

  defp filter_text(query, nil), do: query

  defp filter_text(query, term) do
    like = "%#{term}%"
    from i in query, where: ilike(i.email, ^like) or ilike(i.name, ^like) or ilike(i.message, ^like)
  end

  defp serialize_inquiry(i) do
    %{
      id: i.id,
      name: i.name,
      email: i.email,
      message: i.message,
      source: i.source,
      page_url: i.page_url,
      metadata: i.metadata,
      status: i.status,
      created_at: i.inserted_at
    }
  end

  defp presence(nil), do: nil
  defp presence(""), do: nil
  defp presence(v), do: v
end
