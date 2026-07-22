defmodule Codefresh.Organizations do
  @moduledoc """
  Context for Codefresh.Organizations
  """
  alias Codefresh.Organizations.Organization, as: Entity
  alias Codefresh.Schema.Organizations.Organization, as: Schema
  alias Codefresh.Accounts.InviteToken, as: InviteTokenSchema
  alias Codefresh.Schema.Authz.ScopedMembership, as: ScopedMembershipSchema
  use Noizu.Repo
  def_repo(entity: Entity)
  import Ecto.Query

  def list(context, options \\ []) do
    settings = Noizu.Entity.Meta.persistence(Entity) |> hd

    Codefresh.Repo.all(Schema)
    |> Enum.map(fn record ->
      {:ok, entity} = Entity.from_record(record, settings, context, options)
      {:ok, entity} = __after_get__(entity, context, options)
      entity
    end)
  end

  def get_organization(id, context, options \\ []), do: get(id, context, options)

  def create_organization_with_owner(attrs, user_id) do
    Codefresh.Repo.transaction(fn ->
      with {:ok, org} <- %Schema{} |> Schema.changeset(attrs) |> Codefresh.Repo.insert(),
           {:ok, _membership} <-
             Codefresh.Authz.ScopedMemberships.add_member(
               "organization",
               org.id,
               user_id,
               "owner"
             ) do
        org
      else
        {:error, reason} -> Codefresh.Repo.rollback(reason)
      end
    end)
  end

  def list_user_organizations(user_id) do
    from(sm in ScopedMembershipSchema,
      join: o in Schema,
      on: o.id == sm.resource_id,
      join: g in Codefresh.Schema.Authz.Group,
      on: g.id == sm.group_id,
      where:
        sm.member_type == "user" and sm.member_id == ^user_id and
          sm.resource_type == "organization",
      where: is_nil(sm.expires_at) or sm.expires_at > ^DateTime.utc_now(),
      select: %{id: o.id, slug: o.slug, name: o.name, role: g.name}
    )
    |> Codefresh.Repo.all()
  end

  def authorize(user_or_session, organization_id, required_role) do
    with {:ok, user_id} <- user_id(user_or_session) do
      Codefresh.Authz.authorize(user_id, "organization", organization_id, required_role)
    end
  end

  def user_id(%Codefresh.Users.Sessions.UserSession{user: {:ref, _, user_id}}), do: {:ok, user_id}

  def user_id(%Codefresh.Users.Sessions.UserSession{user: %Codefresh.Users.User{id: user_id}}),
    do: {:ok, user_id}

  def user_id(%Codefresh.Users.User{id: user_id}), do: {:ok, user_id}
  def user_id(user_id) when is_binary(user_id), do: {:ok, user_id}
  def user_id(_), do: {:error, :not_a_member}

  def list_members(organization_id) do
    Codefresh.Authz.ScopedMemberships.list_for_resource("organization", organization_id)
  end

  def create_invite_token(attrs) do
    Codefresh.Accounts.create_invite_token(attrs)
  end

  def find_active_invite_by_raw_token(raw_token) when is_binary(raw_token) do
    key_prefix = InviteTokenSchema.derive_key_prefix(raw_token)
    now = DateTime.utc_now()

    from(t in InviteTokenSchema,
      where: t.key_prefix == ^key_prefix and is_nil(t.revoked_at),
      where: is_nil(t.expires_at) or t.expires_at > ^now,
      where: is_nil(t.max_uses) or t.use_count < t.max_uses
    )
    |> Codefresh.Repo.all()
    |> Enum.find(fn token ->
      InviteTokenSchema.verify_token(raw_token, token.token_hash)
    end)
    |> case do
      nil -> {:error, :invalid_token}
      token -> {:ok, token}
    end
  end

  def increment_invite_uses(invite_token) do
    Codefresh.Accounts.redeem_invite_token(invite_token)
  end
end
