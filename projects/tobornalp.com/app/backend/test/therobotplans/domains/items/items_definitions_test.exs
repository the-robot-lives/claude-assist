defmodule Therobotplans.Domains.ItemsDefinitionsTest do
  @moduledoc """
  Tri-scope item definitions: global/org/project precedence, tombstone
  (disabled:true) suppression, effective_* collapse to one-per-slug. Ported from
  NPL tickets definition behavior. Requires the DB schema (changelogs 000-028).
  """
  use Therobotplans.DataCase

  alias Therobotplans.Domains.Items.Definitions
  alias Therobotplans.Repo

  @moduletag :db

  setup do
    org_id = insert_org()
    project_id = insert_project(org_id)
    {:ok, org_id: org_id, project_id: project_id}
  end

  test "global definition is visible from every scope", c do
    {:ok, _} = Definitions.create_field(%{slug: "priority", label: "Priority", field_type: "select"})

    assert length(Definitions.list_fields(nil, nil)) == 1
    assert length(Definitions.list_fields(c.org_id, nil)) == 1
    assert length(Definitions.list_fields(c.org_id, c.project_id)) == 1
    assert Definitions.resolve_field(c.org_id, c.project_id, "priority").label == "Priority"
  end

  test "project scope overrides org scope overrides global", c do
    {:ok, _} = Definitions.create_field(%{slug: "severity", label: "Global Severity", field_type: "select"})

    {:ok, _} =
      Definitions.create_field(%{
        organization_id: c.org_id, slug: "severity", label: "Org Severity", field_type: "select"
      })

    {:ok, _} =
      Definitions.create_field(%{
        organization_id: c.org_id, project_id: c.project_id, slug: "severity",
        label: "Project Severity", field_type: "select"
      })

    assert Definitions.resolve_field(c.org_id, c.project_id, "severity").label == "Project Severity"
    assert Definitions.resolve_field(c.org_id, nil, "severity").label == "Org Severity"
    assert Definitions.resolve_field(nil, nil, "severity").label == "Global Severity"
  end

  test "a project-scoped tombstone suppresses an inherited org definition", c do
    {:ok, _} =
      Definitions.create_field(%{
        organization_id: c.org_id, slug: "environment", label: "Env", field_type: "text"
      })

    {:ok, _} =
      Definitions.create_field(%{
        organization_id: c.org_id, project_id: c.project_id, slug: "environment",
        label: "suppressed", field_type: "text", disabled: true
      })

    assert Definitions.resolve_field(c.org_id, nil, "environment").label == "Env"
    assert Definitions.resolve_field(c.org_id, c.project_id, "environment") == nil

    effective = Definitions.effective_fields(c.org_id, c.project_id)
    refute Enum.any?(effective, &(&1.slug == "environment"))
  end

  test "effective_fields returns one row per slug (no duplicates)", c do
    {:ok, _} = Definitions.create_field(%{slug: "component", label: "Global Component", field_type: "text"})
    {:ok, _} = Definitions.create_field(%{organization_id: c.org_id, slug: "component", label: "Org Component", field_type: "text"})

    effective = Definitions.effective_fields(c.org_id, nil)
    assert Enum.count(effective, &(&1.slug == "component")) == 1
    assert hd(Enum.filter(effective, &(&1.slug == "component"))).label == "Org Component"
  end

  # ── fixtures ──
  defp insert_org do
    %{rows: [[raw]]} =
      Repo.query!(
        "INSERT INTO organizations (id, slug, name, inserted_at, updated_at) " <>
          "VALUES (gen_random_uuid(), $1, $2, now(), now()) RETURNING id",
        ["org-#{System.unique_integer([:positive])}" |> String.slice(0, 40), "Org"]
      )

    Ecto.UUID.load!(raw)
  end

  defp insert_project(org_id) do
    %{rows: [[raw]]} =
      Repo.query!(
        "INSERT INTO projects (id, organization_id, slug, name, inserted_at, updated_at) " <>
          "VALUES (gen_random_uuid(), $1, $2, $3, now(), now()) RETURNING id",
        [Ecto.UUID.dump!(org_id), "proj-#{System.unique_integer([:positive])}", "Project"]
      )

    Ecto.UUID.load!(raw)
  end
end
