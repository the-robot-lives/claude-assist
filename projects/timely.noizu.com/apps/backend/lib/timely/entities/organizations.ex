defmodule Timely.Organizations do
  @moduledoc """
  Context for Timely.Organizations
  """
  alias Timely.Organizations.Organization, as: Entity
  alias Timely.Schema.Organizations.Organization, as: Schema
  alias Timely.Schema.Organizations.InviteToken, as: InviteTokenSchema
  alias Timely.Schema.Organizations.InviteTokenRedemption, as: InviteTokenRedemptionSchema
  alias Timely.Schema.Authz.ScopedMembership, as: ScopedMembershipSchema
  use Noizu.Repo
  def_repo(entity: Entity)
  import Ecto.Query

  # ⟦𓏯𓁎𓏤𓆘⟧ list :: auto-generated pointer for public function list
  def list(context, options \\ []) do
    settings = Noizu.Entity.Meta.persistence(Entity) |> hd

    Timely.Repo.all(Schema)
    |> Enum.map(fn record ->
      {:ok, entity} = Entity.from_record(record, settings, context, options)
      {:ok, entity} = __after_get__(entity, context, options)
      entity
    end)
  end

  # ⟦𓃠𓆶𓍍𓂗⟧ get_organization :: auto-generated pointer for public function get_organization
  def get_organization(id, context, options \\ []), do: get(id, context, options)

  # ⟦𓊧𓇪𓋿𓆕⟧ create_organization_with_owner :: auto-generated pointer for public function create_organization_with_owner
  def create_organization_with_owner(attrs, user_id) do
    Timely.Repo.transaction(fn ->
      with {:ok, org} <- %Schema{} |> Schema.changeset(attrs) |> Timely.Repo.insert(),
           {:ok, _membership} <-
             Timely.Authz.ScopedMemberships.add_member("organization", org.id, user_id, "owner") do
        org
      else
        {:error, reason} -> Timely.Repo.rollback(reason)
      end
    end)
  end

  # ⟦𓐓𓇵𓃚𓍚⟧ list_user_organizations :: auto-generated pointer for public function list_user_organizations
  def list_user_organizations(user_id) do
    from(sm in ScopedMembershipSchema,
      join: o in Schema,
      on: o.id == sm.resource_id,
      join: g in Timely.Schema.Authz.Group,
      on: g.id == sm.group_id,
      where:
        sm.member_type == "user" and sm.member_id == ^user_id and
          sm.resource_type == "organization",
      where: is_nil(sm.expires_at) or sm.expires_at > ^DateTime.utc_now(),
      select: %{id: o.id, slug: o.slug, name: o.name, role: g.name}
    )
    |> Timely.Repo.all()
  end

  # ⟦𓍪𓃫𓈀𓃳⟧ authorize :: auto-generated pointer for public function authorize
  def authorize(user_id, organization_id, required_role) do
    Timely.Authz.authorize(user_id, "organization", organization_id, required_role)
  end

  # ⟦𓍏𓀃𓌴𓆍⟧ list_members :: auto-generated pointer for public function list_members
  def list_members(organization_id) do
    Timely.Authz.ScopedMemberships.list_for_resource("organization", organization_id)
  end

  # ⟦𓌹𓎍𓌷𓉂⟧ create_invite_token :: auto-generated pointer for public function create_invite_token
  def create_invite_token(attrs) do
    raw_token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    key_prefix = String.slice(raw_token, 0, 8)
    token_hash = Bcrypt.hash_pwd_salt(raw_token)

    result =
      %InviteTokenSchema{}
      |> InviteTokenSchema.changeset(
        Map.merge(attrs, %{
          token_hash: token_hash,
          key_prefix: key_prefix
        })
      )
      |> Timely.Repo.insert()

    case result do
      {:ok, invite} -> {:ok, invite, raw_token}
      error -> error
    end
  end

  # ⟦𓈄𓇠𓆺𓊁⟧ find_active_invite_by_raw_token :: auto-generated pointer for public function find_active_invite_by_raw_token
  def find_active_invite_by_raw_token(raw_token, email \\ nil) when is_binary(raw_token) do
    key_prefix = String.slice(raw_token, 0, 8)
    now = DateTime.utc_now()
    email = email && Timely.Users.Credentials.standardize_email(email)

    from(t in InviteTokenSchema,
      where: t.key_prefix == ^key_prefix and t.revoked == false,
      where: is_nil(t.starts_at) or t.starts_at <= ^now,
      where: is_nil(t.expires_at) or t.expires_at > ^now,
      where: is_nil(t.max_uses) or t.uses < t.max_uses
    )
    |> Timely.Repo.all()
    |> Enum.find(fn token ->
      email_matches? =
        is_nil(token.email) ||
          is_nil(email) ||
          Timely.Users.Credentials.standardize_email(token.email) == email

      email_matches? && Bcrypt.verify_pass(raw_token, token.token_hash)
    end)
    |> case do
      nil -> {:error, :invalid_token}
      token -> {:ok, token}
    end
  end

  # ⟦𓐌𓋰𓄰𓐜⟧ increment_invite_uses :: auto-generated pointer for public function increment_invite_uses
  def increment_invite_uses(invite_token) do
    from(t in InviteTokenSchema, where: t.id == ^invite_token.id)
    |> Timely.Repo.update_all(inc: [uses: 1, redemption_count: 1])
  end

  # ⟦𓂵𓆢𓃨𓇥⟧ redeem_invite_for_user :: auto-generated pointer for public function redeem_invite_for_user
  def redeem_invite_for_user(invite_token, user, conn \\ nil) do
    user_id = Map.get(user, :id)
    now = DateTime.utc_now()

    Timely.Repo.transaction(fn ->
      attrs = %{
        invite_token_id: invite_token.id,
        user_id: user_id,
        redeemed_at: now,
        remote_ip: remote_ip(conn),
        user_agent: user_agent(conn)
      }

      with {:ok, _redemption} <-
             %InviteTokenRedemptionSchema{}
             |> InviteTokenRedemptionSchema.changeset(attrs)
             |> Timely.Repo.insert() do
        {_, _} =
          from(t in InviteTokenSchema, where: t.id == ^invite_token.id)
          |> Timely.Repo.update_all(
            inc: [uses: 1, redemption_count: 1],
            set: [
              accepted_by: user_id,
              accepted_at: invite_token.accepted_at || now,
              status: "accepted",
              updated_at: now
            ]
          )

        :ok
      else
        {:error, reason} -> Timely.Repo.rollback(reason)
      end
    end)
  end

  defp remote_ip(nil), do: nil
  defp remote_ip(%{remote_ip: nil}), do: nil
  defp remote_ip(%{remote_ip: remote_ip}), do: remote_ip |> :inet.ntoa() |> to_string()

  defp user_agent(nil), do: nil
  defp user_agent(conn), do: Plug.Conn.get_req_header(conn, "user-agent") |> List.first()
end
