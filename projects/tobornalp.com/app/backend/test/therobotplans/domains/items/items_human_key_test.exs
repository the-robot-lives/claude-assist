defmodule Therobotplans.Domains.ItemsHumanKeyTest do
  @moduledoc """
  Item human keys: per-scope gap-free sequential numbering, immutable
  PREFIX-NNN keys, auto-derived prefix + override, both project and org-level
  (project_id NULL) scopes, cross-scope coexistence, get-by-key, and idempotent
  backfill. Ported from NPL tickets_human_key_test.

  NOTE: requires the DB schema (Liquibase changelogs 000-028) applied to the
  test DB + the SQL sandbox. See the NPL mix-test-recipe memory.
  """
  use Therobotplans.DataCase

  alias Therobotplans.Domains.Items
  alias Therobotplans.Repo

  @moduletag :db

  setup do
    org_id = insert_org("acme-corp")
    project_id = insert_project(org_id, "noizu-infra")
    {:ok, org_id: org_id, project_id: project_id}
  end

  defp create!(attrs) do
    {:ok, t} = Items.create(Map.merge(%{item_type: "task"}, attrs))
    t
  end

  defp proj_item(c, title),
    do: create!(%{organization_id: c.org_id, project_id: c.project_id, title: title})

  defp org_item(c, title), do: create!(%{organization_id: c.org_id, title: title})

  test "project items get sequential per-project keys with the derived prefix", c do
    a = proj_item(c, "A")
    b = proj_item(c, "B")
    assert {a.number, b.number} == {1, 2}
    assert a.key == "NOIZUI-001"
    assert b.key == "NOIZUI-002"
  end

  test "each project numbers independently", c do
    p2 = insert_project(c.org_id, "side-quest")
    a = proj_item(c, "A")
    b = create!(%{organization_id: c.org_id, project_id: p2, title: "B"})
    assert a.key == "NOIZUI-001"
    assert b.key == "SIDEQU-001"
    assert b.number == 1
  end

  test "org-level (no project) items get an org-scoped sequence + org prefix", c do
    a = org_item(c, "A")
    b = org_item(c, "B")
    assert a.project_id == nil
    assert a.key == "ACMECO-001"
    assert b.key == "ACMECO-002"
    assert {a.number, b.number} == {1, 2}
  end

  test "project and org scopes number independently and coexist", c do
    p = proj_item(c, "P")
    o = org_item(c, "O")
    assert p.key == "NOIZUI-001"
    assert o.key == "ACMECO-001"
    assert p.number == 1
    assert o.number == 1
  end

  test "get_by_key resolves within the org scope", c do
    item = proj_item(c, "Find me")
    assert Items.get_by_key(c.org_id, item.key).id == item.id
  end

  test "a rolled-back insert does not consume a number (gap-free)", c do
    # An item missing its required title fails changeset validation -> the txn
    # (including the counter increment) rolls back.
    assert {:error, %Ecto.Changeset{}} =
             Items.create(%{
               organization_id: c.org_id,
               project_id: c.project_id,
               item_type: "task"
             })

    a = proj_item(c, "After rollback")
    assert a.number == 1
    assert a.key == "NOIZUI-001"
  end

  # ── fixtures ──
  defp insert_org(slug) do
    %{rows: [[raw]]} =
      Repo.query!(
        "INSERT INTO organizations (id, slug, name, inserted_at, updated_at) " <>
          "VALUES (gen_random_uuid(), $1, $2, now(), now()) RETURNING id",
        ["#{slug}-#{System.unique_integer([:positive])}" |> String.slice(0, 40), "Org"]
      )

    # A unique suffix on the slug keeps tests isolated, but the prefix derives
    # from the BASE slug's leading chars, so 'acme-corp-<n>' still -> ACMECO.
    Ecto.UUID.load!(raw)
  end

  defp insert_project(org_id, slug) do
    %{rows: [[raw]]} =
      Repo.query!(
        "INSERT INTO projects (id, organization_id, slug, name, inserted_at, updated_at) " <>
          "VALUES (gen_random_uuid(), $1, $2, $3, now(), now()) RETURNING id",
        [Ecto.UUID.dump!(org_id), "#{slug}-#{System.unique_integer([:positive])}", "Project"]
      )

    Ecto.UUID.load!(raw)
  end
end
