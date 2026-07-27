defmodule Timely.Sync.ResolverTest do
  @moduledoc """
  SYNC-PROTOCOL 6.1: name-to-id resolution and auto-vivification, the five cases
  in order.

  Auto-vivification is the part that looks lenient and is not: rejecting a span
  because its project has not arrived yet would strand a day of offline capture
  behind one missing taxonomy row.
  """
  use Timely.DataCase, async: false

  import Timely.TimelyFixtures

  alias Timely.Schema.Taxonomy
  alias Timely.Schema.Tracking.TimeSpan
  alias Timely.Sync.Canon
  alias Timely.Sync.Mutations
  alias Timely.Sync.Workspace

  setup do
    %{workspace_id: workspace_id, user: user, device: device} = setup_workspace()

    {:ok,
     workspace_id: workspace_id,
     user: user,
     device: device,
     ctx: ctx(workspace_id, user.id, device_id: device.id)}
  end

  defp span_payload(overrides) do
    Map.merge(
      %{
        "id" => uuid7(),
        "title" => "Work",
        "start" => iso(-3600),
        "end" => iso(-60),
        "source" => "timer",
        "is_billable" => false,
        "updated_at" => iso(-60)
      },
      overrides
    )
  end

  defp push_span(ctx, payload) do
    {:ok, [result]} = Mutations.push(ctx, [mutation("time_span", "create", payload)])
    result
  end

  describe "case 4: auto-vivification" do
    test "creates client and project from names alone and returns them as side effects", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      id = uuid7()

      result =
        push_span(
          ctx,
          span_payload(%{"id" => id, "client_name" => "Acme", "project_name" => "Redesign"})
        )

      assert result["status"] == "applied"

      kinds = Enum.map(result["side_effects"], & &1["entity"])
      assert "client" in kinds
      assert "project" in kinds

      span = Workspace.fetch_live(TimeSpan, workspace_id, id)

      # The ids are the deterministic ones, so an offline device that vivified
      # the same names computes exactly these and their creates merge.
      assert span.client_id == Canon.client_id(workspace_id, "Acme")
      assert span.project_id == Canon.project_id(workspace_id, "Acme", "Redesign")
    end

    test "marks vivified rows auto_created and needs_review", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      push_span(ctx, span_payload(%{"client_name" => "Acme"}))

      client = Repo.get(Taxonomy.Client, Canon.client_id(workspace_id, "Acme"))

      # The server guessed a name boundary the user never confirmed, so it is
      # review work by construction.
      assert client.auto_created == true
      assert client.review_state == "needs_review"
      assert client.name == "Acme"
      assert client.canonical_name == "acme"
    end

    test "two devices vivifying the same name converge on one row", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      push_span(ctx, span_payload(%{"client_name" => "Acme"}))
      push_span(ctx, span_payload(%{"client_name" => "  ACME  "}))

      # Different spellings, same canonical form, same id: one row.
      assert Repo.aggregate(Taxonomy.Client |> Workspace.scope(workspace_id), :count) == 1
    end

    test "a project is scoped to its client, so the same project name under two clients is two rows",
         %{ctx: ctx, workspace_id: workspace_id} do
      push_span(ctx, span_payload(%{"client_name" => "Acme", "project_name" => "Redesign"}))
      push_span(ctx, span_payload(%{"client_name" => "Globex", "project_name" => "Redesign"}))

      assert Repo.aggregate(Taxonomy.Project |> Workspace.scope(workspace_id), :count) == 2
    end

    test "vivifies a ticket under its project", %{ctx: ctx, workspace_id: workspace_id} do
      id = uuid7()

      push_span(
        ctx,
        span_payload(%{
          "id" => id,
          "client_name" => "Acme",
          "project_name" => "Redesign",
          "ticket_name" => "TIM-14"
        })
      )

      span = Workspace.fetch_live(TimeSpan, workspace_id, id)
      assert span.ticket_id == Canon.ticket_id(workspace_id, "Acme", "Redesign", "TIM-14")
    end
  end

  describe "case 3: resolution by canonical name" do
    test "an existing row is reused rather than duplicated", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      existing_id = Canon.client_id(workspace_id, "Acme")

      {:ok, _} =
        Mutations.push(ctx, [
          mutation("client", "create", %{
            "id" => existing_id,
            "name" => "Acme",
            "updated_at" => iso()
          })
        ])

      id = uuid7()
      push_span(ctx, span_payload(%{"id" => id, "client_name" => "acme"}))

      assert Workspace.fetch_live(TimeSpan, workspace_id, id).client_id == existing_id
      assert Repo.aggregate(Taxonomy.Client |> Workspace.scope(workspace_id), :count) == 1
    end
  end

  describe "case 1: an id that resolves" do
    test "is used, and the name is refreshed from the referenced row", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      client_id = Canon.client_id(workspace_id, "Acme")

      {:ok, _} =
        Mutations.push(ctx, [
          mutation("client", "create", %{
            "id" => client_id,
            "name" => "Acme Corporation",
            "updated_at" => iso()
          })
        ])

      id = uuid7()

      push_span(
        ctx,
        span_payload(%{"id" => id, "client_id" => client_id, "client_name" => "stale provenance"})
      )

      span = Workspace.fetch_live(TimeSpan, workspace_id, id)
      assert span.client_id == client_id
      # The stored name is provenance only; the read side shows the current one.
      assert span.client_name == "Acme Corporation"
    end

    test "follows merged_into_id exactly one hop", %{ctx: ctx, workspace_id: workspace_id} do
      winner_id = Canon.client_id(workspace_id, "Acme")
      loser_id = Canon.client_id(workspace_id, "Acme Inc")
      now = DateTime.utc_now()

      for {id, name} <- [{winner_id, "Acme"}, {loser_id, "Acme Inc"}] do
        {:ok, _} =
          Mutations.push(ctx, [
            mutation("client", "create", %{"id" => id, "name" => name, "updated_at" => iso()})
          ])
      end

      # A merge sets merged_into_id on the loser and tombstones it. The winner
      # absorbs nothing automatically; readers follow the pointer.
      Repo.update_all(
        Taxonomy.Client |> Ecto.Query.where(id: ^loser_id),
        set: [merged_into_id: winner_id, deleted_at: now]
      )

      id = uuid7()
      push_span(ctx, span_payload(%{"id" => id, "client_id" => loser_id}))

      assert Workspace.fetch_live(TimeSpan, workspace_id, id).client_id == winner_id
    end
  end

  describe "case 2: a deferred reference" do
    test "is stored rather than rejected, and reported in unresolved_refs", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      # The project has not arrived yet - this is the at-least-once push queue
      # delivering a span before the row it names.
      unknown_project = uuid7()
      id = uuid7()

      result = push_span(ctx, span_payload(%{"id" => id, "project_id" => unknown_project}))

      assert result["status"] == "applied"
      assert "project_id" in result["unresolved_refs"]

      span = Workspace.fetch_live(TimeSpan, workspace_id, id)
      assert span.project_id == unknown_project
      # Surfaced for review so a reference still dangling a day later is visible.
      assert Enum.any?(span.review_reasons, &(&1["code"] == "unresolved_reference"))
    end

    test "an id belonging to another workspace is deferred, not resolved", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      other_ws = workspace!()
      other_user = user!()
      member!(other_user.id, other_ws, "owner")
      other_ctx = ctx(other_ws, other_user.id)
      foreign_client = Canon.client_id(other_ws, "Acme")

      {:ok, _} =
        Mutations.push(other_ctx, [
          mutation("client", "create", %{
            "id" => foreign_client,
            "name" => "Acme",
            "updated_at" => iso()
          })
        ])

      id = uuid7()
      result = push_span(ctx, span_payload(%{"id" => id, "client_id" => foreign_client}))

      assert "client_id" in result["unresolved_refs"]
      # Deferred, never resolved: the row exists, but not in this workspace.
      assert Workspace.fetch_live(TimeSpan, workspace_id, id).client_name == ""
    end
  end

  describe "case 5: an absent reference" do
    test "leaves the reference genuinely null", %{ctx: ctx, workspace_id: workspace_id} do
      id = uuid7()
      result = push_span(ctx, span_payload(%{"id" => id, "client_name" => "", "project_name" => ""}))

      assert result["status"] == "applied"
      assert result["unresolved_refs"] == []

      span = Workspace.fetch_live(TimeSpan, workspace_id, id)
      # Spans with no project are legal and roll up under "Unassigned".
      assert span.client_id == nil
      assert span.project_id == nil
      assert Repo.aggregate(Taxonomy.Client |> Workspace.scope(workspace_id), :count) == 0
    end

    test "a whitespace-only name is not an entity", %{ctx: ctx, workspace_id: workspace_id} do
      push_span(ctx, span_payload(%{"client_name" => "   "}))

      # An empty canonical form is "no reference", not a row named "".
      assert Repo.aggregate(Taxonomy.Client |> Workspace.scope(workspace_id), :count) == 0
    end
  end

  describe "ordering" do
    test "a client and project pushed in the same batch resolve for a following span", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      client_id = Canon.client_id(workspace_id, "Acme")
      project_id = Canon.project_id(workspace_id, "Acme", "Redesign")
      span_id = uuid7()

      # This is the T1 worked example: the creates land first, and the span's
      # project_name resolves by canonical name because the project arrived
      # moments earlier in the same batch.
      {:ok, results} =
        Mutations.push(ctx, [
          mutation("client", "create", %{
            "id" => client_id,
            "name" => "Acme",
            "updated_at" => iso()
          }),
          mutation("project", "create", %{
            "id" => project_id,
            "name" => "Redesign",
            "client_id" => client_id,
            "updated_at" => iso()
          }),
          mutation(
            "time_span",
            "create",
            span_payload(%{
              "id" => span_id,
              "client_name" => "Acme",
              "project_name" => "Redesign"
            })
          )
        ])

      assert Enum.all?(results, &(&1["status"] == "applied"))

      span = Workspace.fetch_live(TimeSpan, workspace_id, span_id)
      assert span.client_id == client_id
      assert span.project_id == project_id

      # Nothing was vivified, because everything resolved.
      assert Repo.aggregate(Taxonomy.Project |> Workspace.scope(workspace_id), :count) == 1
    end
  end
end
