defmodule Codefresh.Accounts do
  @moduledoc """
  Thin account context for auth-adjacent Ecto schemas.

  The app's primary user/org domain still lives in `Codefresh.Users` and
  `Codefresh.Organizations`; this module owns the newer invite and API-token
  schemas used by the M0 auth flows.
  """

  import Ecto.Query, only: [from: 2]

  alias Codefresh.Accounts.{InviteToken, Membership}
  alias Codefresh.Repo
  alias Codefresh.Schema.Users.User

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: String.downcase(email))
  end

  def list_active_invites_for_org(organization_id) do
    now = DateTime.utc_now()

    Repo.all(
      from invite in InviteToken,
        where: invite.organization_id == ^organization_id,
        where: is_nil(invite.revoked_at),
        where: is_nil(invite.expires_at) or invite.expires_at > ^now,
        where: is_nil(invite.max_uses) or invite.use_count < invite.max_uses,
        order_by: [desc: invite.inserted_at]
    )
  end

  def create_invite_token(attrs) when is_map(attrs) do
    raw_token = InviteToken.generate_raw_token()

    attrs =
      attrs
      |> normalize_keys()
      |> Map.put(:raw_token, raw_token)

    case %InviteToken{} |> InviteToken.create_changeset(attrs) |> Repo.insert() do
      {:ok, invite} -> {:ok, invite, raw_token}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def revoke_invite_token(%InviteToken{} = invite) do
    invite
    |> InviteToken.revoke_changeset()
    |> Repo.update()
  end

  def redeem_invite_token(%InviteToken{} = invite) do
    invite
    |> InviteToken.redeem_changeset()
    |> Repo.update()
  end

  def create_membership(attrs) when is_map(attrs) do
    attrs = normalize_keys(attrs)

    case Codefresh.Authz.ScopedMemberships.add_member(
           "organization",
           attrs[:organization_id],
           attrs[:user_id],
           attrs[:role]
         ) do
      {:ok, row} ->
        {:ok,
         %Membership{
           id: row["id"] || row[:id],
           organization_id: attrs[:organization_id],
           user_id: attrs[:user_id],
           role: attrs[:role]
         }}

      {:error, :already_member} ->
        {:error,
         Ecto.Changeset.add_error(
           Membership.changeset(%Membership{}, attrs),
           :user_id,
           "user is already a member of this organization"
         )}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp normalize_keys(attrs) do
    for {key, value} <- attrs, into: %{} do
      {normalize_key(key), value}
    end
  end

  defp normalize_key(key) when is_atom(key), do: key

  defp normalize_key(key) when is_binary(key) do
    String.to_existing_atom(key)
  rescue
    ArgumentError -> String.to_atom(key)
  end
end
