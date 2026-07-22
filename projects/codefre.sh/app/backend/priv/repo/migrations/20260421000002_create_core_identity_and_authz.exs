defmodule Codefresh.Repo.Migrations.CreateCoreIdentityAndAuthz do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE resource_type_enum AS ENUM ('organization', 'project')")

    create table(:seed_helper_seeds, primary_key: false) do
      add :seed, :string, primary_key: true
      add :version, :string, primary_key: true
      timestamps(type: :utc_datetime_usec)
    end

    create table(:seed_helper_handles, primary_key: false) do
      add :handle, :string, primary_key: true
      add :value, :text, null: false
      timestamps(type: :utc_datetime_usec)
    end

    create table(:versioned_names, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :first, :string
      add :middle, {:array, :string}, default: []
      add :last, :string
      add :deleted_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create table(:versioned_descriptions, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :title, :string
      add :body, :text
      add :deleted_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create table(:versioned_strings, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :content, :text
      add :deleted_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_name, :string
      add :handle, :string
      add :name_id, references(:versioned_names, type: :uuid, on_delete: :nilify_all)
      add :description_id, references(:versioned_descriptions, type: :uuid, on_delete: :nilify_all)
      add :email, :string, null: false
      add :hashed_password, :string
      add :status, :string, null: false, default: "active"
      add :verified, :boolean, null: false, default: false
      add :flagged, :boolean, null: false, default: false
      add :deleted_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:user_name])
    create unique_index(:users, [:handle])

    create table(:organizations, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :slug, :string, null: false
      add :name, :string, null: false
      add :settings, :map, null: false, default: %{}
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:organizations, [:slug])

    create table(:auth_providers, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :title, :string, null: false
      add :description, :text
      add :settings, :binary
      add :deleted_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create table(:user_credentials, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :auth_provider_id, references(:auth_providers, type: :uuid, on_delete: :restrict), null: false
      add :description_id, references(:versioned_descriptions, type: :uuid, on_delete: :nilify_all)
      add :status, :string, null: false, default: "active"
      add :settings, :map, null: false, default: %{}
      add :state, :map, null: false, default: %{}
      add :fingerprint, :string
      add :deleted_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create index(:user_credentials, [:user_id])
    create index(:user_credentials, [:auth_provider_id])
    create unique_index(:user_credentials, [:fingerprint])

    create table(:user_sessions, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :credential_id, references(:user_credentials, type: :uuid, on_delete: :nilify_all)
      add :status, :string, null: false, default: "active"
      add :details, :map, null: false, default: %{}
      add :deleted_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create index(:user_sessions, [:user_id])

    create table(:groups, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :string, null: false
      add :display_name, :string, null: false
      add :description, :text
      add :is_system, :boolean, null: false, default: true
      timestamps(type: :utc_datetime_usec, inserted_at: :created_at, updated_at: :updated_at)
    end

    create unique_index(:groups, [:name])

    create table(:policies, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :string, null: false
      add :description, :text
      add :policy_document, :map, null: false, default: %{}
      add :is_system, :boolean, null: false, default: false
      add :is_active, :boolean, null: false, default: true
      add :created_by, references(:users, type: :uuid, on_delete: :nilify_all)
      timestamps(type: :utc_datetime_usec, inserted_at: :created_at, updated_at: :updated_at)
    end

    create unique_index(:policies, [:name])

    create table(:group_policies, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :group_id, references(:groups, type: :uuid, on_delete: :delete_all), null: false
      add :policy_id, references(:policies, type: :uuid, on_delete: :delete_all), null: false
      add :priority, :integer, null: false, default: 0
      timestamps(type: :utc_datetime_usec, inserted_at: :created_at, updated_at: false)
    end

    create unique_index(:group_policies, [:group_id, :policy_id])

    create table(:user_policies, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :policy_id, references(:policies, type: :uuid, on_delete: :delete_all), null: false
      add :resource_type, :string
      add :resource_id, :uuid
      add :priority, :integer, null: false, default: 0
      timestamps(type: :utc_datetime_usec, inserted_at: :created_at, updated_at: false)
    end

    create unique_index(:user_policies, [:user_id, :policy_id, :resource_type, :resource_id])

    create table(:scoped_memberships, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :group_id, references(:groups, type: :uuid, on_delete: :restrict), null: false
      add :resource_type, :string, null: false
      add :resource_id, :uuid, null: false
      add :member_type, :string, null: false
      add :member_id, :uuid, null: false
      add :expires_at, :utc_datetime_usec
      add :added_by, references(:users, type: :uuid, on_delete: :nilify_all)
      timestamps(type: :utc_datetime_usec, inserted_at: :created_at, updated_at: false)
    end

    create unique_index(:scoped_memberships, [
             :resource_type,
             :resource_id,
             :member_type,
             :member_id
           ])

    create index(:scoped_memberships, [:member_type, :member_id])

    seed_groups()
    create_authz_functions()
  end

  def down do
    execute("DROP FUNCTION IF EXISTS remove_scoped_member_safe(text, uuid, uuid)")
    execute("DROP FUNCTION IF EXISTS update_scoped_member_role(text, uuid, uuid, text)")
    execute("DROP FUNCTION IF EXISTS add_scoped_member(text, uuid, uuid, text, uuid)")
    execute("DROP FUNCTION IF EXISTS check_user_permission(uuid, text, uuid, text)")
    execute("DROP FUNCTION IF EXISTS get_user_role_in_resource(uuid, text, uuid)")

    drop table(:scoped_memberships)
    drop table(:user_policies)
    drop table(:group_policies)
    drop table(:policies)
    drop table(:groups)
    drop table(:user_sessions)
    drop table(:user_credentials)
    drop table(:auth_providers)
    drop table(:organizations)
    drop table(:users)
    drop table(:versioned_strings)
    drop table(:versioned_descriptions)
    drop table(:versioned_names)
    drop table(:seed_helper_handles)
    drop table(:seed_helper_seeds)

    execute("DROP TYPE IF EXISTS resource_type_enum")
  end

  defp seed_groups do
    execute("""
    INSERT INTO groups (id, name, display_name, description, is_system, created_at, updated_at)
    VALUES
      (gen_random_uuid(), 'owner', 'Owner', 'Full organization/project owner access', TRUE, NOW(), NOW()),
      (gen_random_uuid(), 'admin', 'Admin', 'Administrative access', TRUE, NOW(), NOW()),
      (gen_random_uuid(), 'editor', 'Editor', 'Authoring and execution access', TRUE, NOW(), NOW()),
      (gen_random_uuid(), 'member', 'Member', 'Standard member access', TRUE, NOW(), NOW()),
      (gen_random_uuid(), 'viewer', 'Viewer', 'Read-only access', TRUE, NOW(), NOW()),
      (gen_random_uuid(), 'ci', 'CI', 'Automation token access', TRUE, NOW(), NOW())
    ON CONFLICT (name) DO NOTHING
    """)
  end

  defp create_authz_functions do
    execute("""
    CREATE OR REPLACE FUNCTION get_user_role_in_resource(
      p_user_id uuid,
      p_resource_type text,
      p_resource_id uuid
    ) RETURNS text AS $$
      SELECT g.name
      FROM scoped_memberships sm
      JOIN groups g ON g.id = sm.group_id
      WHERE sm.member_type = 'user'
        AND sm.member_id = p_user_id
        AND sm.resource_type = p_resource_type
        AND sm.resource_id = p_resource_id
        AND (sm.expires_at IS NULL OR sm.expires_at > NOW())
      ORDER BY CASE g.name
        WHEN 'owner' THEN 0
        WHEN 'admin' THEN 1
        WHEN 'editor' THEN 2
        WHEN 'member' THEN 3
        WHEN 'viewer' THEN 4
        WHEN 'ci' THEN 5
        ELSE 99
      END
      LIMIT 1;
    $$ LANGUAGE sql STABLE
    """)

    execute("""
    CREATE OR REPLACE FUNCTION check_user_permission(
      p_user_id uuid,
      p_resource_type text,
      p_resource_id uuid,
      p_action text
    ) RETURNS boolean AS $$
      SELECT get_user_role_in_resource(p_user_id, p_resource_type, p_resource_id) IS NOT NULL;
    $$ LANGUAGE sql STABLE
    """)

    execute("""
    CREATE OR REPLACE FUNCTION add_scoped_member(
      p_resource_type text,
      p_resource_id uuid,
      p_user_id uuid,
      p_role_name text,
      p_added_by uuid DEFAULT NULL
    ) RETURNS scoped_memberships AS $$
    DECLARE
      v_group_id uuid;
      v_membership scoped_memberships;
    BEGIN
      SELECT id INTO v_group_id FROM groups WHERE name = p_role_name;
      IF v_group_id IS NULL THEN
        RAISE EXCEPTION 'invalid_role';
      END IF;

      INSERT INTO scoped_memberships (
        id, group_id, resource_type, resource_id, member_type, member_id, added_by, created_at
      )
      VALUES (
        gen_random_uuid(), v_group_id, p_resource_type, p_resource_id, 'user', p_user_id, p_added_by, NOW()
      )
      ON CONFLICT (resource_type, resource_id, member_type, member_id)
      DO UPDATE SET group_id = EXCLUDED.group_id
      RETURNING * INTO v_membership;

      RETURN v_membership;
    END;
    $$ LANGUAGE plpgsql
    """)

    execute("""
    CREATE OR REPLACE FUNCTION update_scoped_member_role(
      p_resource_type text,
      p_resource_id uuid,
      p_user_id uuid,
      p_role_name text
    ) RETURNS scoped_memberships AS $$
    DECLARE
      v_group_id uuid;
      v_membership scoped_memberships;
    BEGIN
      SELECT id INTO v_group_id FROM groups WHERE name = p_role_name;
      IF v_group_id IS NULL THEN
        RAISE EXCEPTION 'invalid_role';
      END IF;

      UPDATE scoped_memberships
      SET group_id = v_group_id
      WHERE resource_type = p_resource_type
        AND resource_id = p_resource_id
        AND member_type = 'user'
        AND member_id = p_user_id
      RETURNING * INTO v_membership;

      IF v_membership.id IS NULL THEN
        RAISE EXCEPTION 'not_found';
      END IF;

      RETURN v_membership;
    END;
    $$ LANGUAGE plpgsql
    """)

    execute("""
    CREATE OR REPLACE FUNCTION remove_scoped_member_safe(
      p_resource_type text,
      p_resource_id uuid,
      p_user_id uuid
    ) RETURNS scoped_memberships AS $$
    DECLARE
      v_membership scoped_memberships;
    BEGIN
      DELETE FROM scoped_memberships
      WHERE resource_type = p_resource_type
        AND resource_id = p_resource_id
        AND member_type = 'user'
        AND member_id = p_user_id
      RETURNING * INTO v_membership;

      IF v_membership.id IS NULL THEN
        RAISE EXCEPTION 'not_found';
      END IF;

      RETURN v_membership;
    END;
    $$ LANGUAGE plpgsql
    """)
  end
end
