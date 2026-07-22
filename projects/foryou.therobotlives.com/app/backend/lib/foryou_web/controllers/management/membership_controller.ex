defmodule ForyouWeb.Management.MembershipController do
  @moduledoc """
  Management of org memberships (API-key / system-level) — the live PBAC
  `scoped_memberships` model. Membership identity is (org, user); role is one of
  owner/admin/member/viewer.
  """
  use ForyouWeb, :controller

  alias Foryou.Authz.ScopedMemberships

  def index(conn, %{"org_id" => org_id}) do
    members = ScopedMemberships.list_for_resource("organization", org_id)
    json(conn, %{memberships: members})
  end

  def create(conn, %{"org_id" => org_id, "membership" => %{"user_id" => user_id, "role" => role}}) do
    added_by = get_in(conn.assigns, [:current_user, Access.key(:id)])

    case ScopedMemberships.add_member("organization", org_id, user_id, role, added_by) do
      {:ok, membership} -> conn |> put_status(:created) |> json(%{membership: membership})
      {:error, reason} -> conn |> put_status(:unprocessable_entity) |> json(%{error: to_string(reason)})
    end
  end

  def update(conn, %{"org_id" => org_id, "user_id" => user_id, "membership" => %{"role" => role}}) do
    case ScopedMemberships.update_role("organization", org_id, user_id, role) do
      {:ok, membership} -> json(conn, %{membership: membership})
      {:error, reason} -> conn |> put_status(:unprocessable_entity) |> json(%{error: to_string(reason)})
    end
  end

  def delete(conn, %{"org_id" => org_id, "user_id" => user_id}) do
    case ScopedMemberships.remove_member("organization", org_id, user_id) do
      {:ok, _} -> conn |> send_resp(:no_content, "")
      {:error, reason} -> conn |> put_status(:unprocessable_entity) |> json(%{error: to_string(reason)})
    end
  end
end
