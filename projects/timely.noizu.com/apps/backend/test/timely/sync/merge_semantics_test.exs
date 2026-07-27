defmodule Timely.Sync.MergeSemanticsTest do
  @moduledoc """
  What an `op: "update"` payload does to columns whose keys it does **not**
  contain.

  The answer is **merge only the keys present**: the write goes through
  `schema.changeset/2`, which is `Ecto.Changeset.cast/3`, and `cast` records a
  change only for keys actually present in the attrs map. An absent key is not
  "set to null", it is "not mentioned", and the stored value survives.

  This is load-bearing for two clients that behave differently. A client that
  omits `end` on an ordinary edit cannot accidentally reopen a span that another
  device closed - `Map.has_key?(payload, "end")` is false, so the reopen guard
  cannot fire and the edit merges cleanly. A client that always serializes the
  full document sends `"end": null` instead, which is an accurate statement of
  "my copy shows this open" and is only *rejected* when the server's copy is
  closed and the base revision is stale.

  The exceptions are envelope fields the server owns outright, asserted at the
  bottom so nobody has to infer the rule from silence.
  """
  use Timely.DataCase, async: false

  import Timely.TimelyFixtures

  alias Timely.Schema.Tracking.TimeSpan
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

  defp push_one!(ctx, mutation) do
    {:ok, [result]} = Mutations.push(ctx, [mutation])
    result
  end

  describe "absent keys are left untouched" do
    test "omitting `end` on a span the server has CLOSED preserves the close", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      # The exact scenario a full-document client cannot express and an
      # omitting client can: another device closed this span, and this device
      # only wants to change the title.
      span =
        span!(workspace_id,
          title: "Morning work",
          start_at: ~U[2026-07-27 09:00:00.000000Z],
          end_at: ~U[2026-07-27 10:00:00.000000Z]
        )

      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "update",
            %{
              "id" => span.id,
              "title" => "Morning work, retitled",
              "start" => "2026-07-27T09:00:00.000000Z",
              "updated_at" => iso()
            },
            # Deliberately stale: this is the case that WOULD be rejected if the
            # client had sent an explicit `"end": null`.
            base_revision: span.server_revision - 1
          )
        )

      assert result["status"] == "applied"
      assert result["reason"] == nil

      row = Workspace.fetch_live(TimeSpan, workspace_id, span.id)
      assert row.title == "Morning work, retitled"
      # The remote close survived. Nothing reopened.
      assert row.end_at == ~U[2026-07-27 10:00:00.000000Z]
    end

    test "omitting `end` on an OPEN span leaves it open", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      span = span!(workspace_id, title: "Running timer", end_at: nil)

      result =
        push_one!(
          ctx,
          mutation("time_span", "update", %{
            "id" => span.id,
            "title" => "Running timer, retitled",
            "start" => DateTime.to_iso8601(span.start_at),
            "updated_at" => iso()
          })
        )

      assert result["status"] == "applied"
      assert Workspace.fetch_live(TimeSpan, workspace_id, span.id).end_at == nil
    end

    test "omitted scalar fields are not nulled", %{ctx: ctx, workspace_id: workspace_id} do
      span =
        span!(workspace_id,
          title: "Billable work",
          is_billable: true,
          project_name: "Redesign",
          client_name: "Acme"
        )

      Repo.update_all(
        Ecto.Query.where(TimeSpan, id: ^span.id),
        set: [notes: "context worth keeping"]
      )

      # A payload naming only `title` must not wipe notes, is_billable, or the
      # resolved names.
      push_one!(
        ctx,
        mutation("time_span", "update", %{
          "id" => span.id,
          "title" => "Renamed",
          "start" => DateTime.to_iso8601(span.start_at),
          "updated_at" => iso()
        })
      )

      row = Workspace.fetch_live(TimeSpan, workspace_id, span.id)
      assert row.title == "Renamed"
      assert row.notes == "context worth keeping"
      assert row.is_billable == true
    end

    test "a partial update does not wipe the taxonomy references it never mentions", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      # Resolution (6.1) runs on every span write, and its step 5 - "*_id absent
      # and *_name empty means the reference is genuinely null" - is about a
      # client that HAS no reference. It must not fire for a payload that simply
      # does not mention the reference at all, or an ordinary title edit from an
      # omitting client silently unassigns the span's client and project.
      client_id = Timely.Sync.Canon.client_id(workspace_id, "Acme")
      project_id = Timely.Sync.Canon.project_id(workspace_id, "Acme", "Redesign")

      {:ok, _} =
        Mutations.push(ctx, [
          mutation("time_span", "create", %{
            "id" => uuid7(),
            "title" => "Assigned work",
            "client_name" => "Acme",
            "project_name" => "Redesign",
            "start" => iso(-3600),
            "end" => iso(-60),
            "updated_at" => iso(-60)
          })
        ])

      span = Repo.one(Ecto.Query.where(TimeSpan, title: "Assigned work"))
      assert span.client_id == client_id
      assert span.project_id == project_id

      push_one!(
        ctx,
        mutation("time_span", "update", %{
          "id" => span.id,
          "title" => "Assigned work, retitled",
          "updated_at" => iso()
        })
      )

      row = Workspace.fetch_live(TimeSpan, workspace_id, span.id)
      assert row.title == "Assigned work, retitled"
      assert row.client_id == client_id
      assert row.client_name == "Acme"
      assert row.project_id == project_id
      assert row.project_name == "Redesign"
    end

    test "an explicitly empty name DOES clear the reference", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      # The other half of the rule: a client that means "this span has no client"
      # says so, and absence must not be the only way to express it.
      {:ok, _} =
        Mutations.push(ctx, [
          mutation("time_span", "create", %{
            "id" => uuid7(),
            "title" => "Unassign me",
            "client_name" => "Globex",
            "start" => iso(-3600),
            "end" => iso(-60),
            "updated_at" => iso(-60)
          })
        ])

      span = Repo.one(Ecto.Query.where(TimeSpan, title: "Unassign me"))
      assert span.client_id != nil

      push_one!(
        ctx,
        mutation("time_span", "update", %{
          "id" => span.id,
          "title" => "Unassign me",
          "client_name" => "",
          "updated_at" => iso()
        })
      )

      row = Workspace.fetch_live(TimeSpan, workspace_id, span.id)
      assert row.client_id == nil
      assert row.client_name == ""
    end

    test "the rule is uniform across entity kinds, not special-cased for time_span", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      client_id = Timely.Sync.Canon.client_id(workspace_id, "Acme")

      push_one!(
        ctx,
        mutation("client", "create", %{
          "id" => client_id,
          "name" => "Acme",
          "notes" => "primary account",
          "updated_at" => iso(-60)
        })
      )

      push_one!(
        ctx,
        mutation("client", "update", %{
          "id" => client_id,
          "name" => "Acme",
          "updated_at" => iso()
        })
      )

      assert Repo.get(Timely.Schema.Taxonomy.Client, client_id).notes == "primary account"
    end
  end

  describe "explicit null IS a value" do
    test "\"end\": null on a span the server also shows OPEN applies without a fight", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      # A full-document client says "my copy is open" about a span that IS open.
      # The reopen guard is conditioned on the SERVER's row being closed, so it
      # never fires here regardless of base_revision.
      span = span!(workspace_id, title: "Running timer", end_at: nil)

      result =
        push_one!(
          ctx,
          mutation(
            "time_span",
            "update",
            %{
              "id" => span.id,
              "title" => "Running timer, retitled",
              "start" => DateTime.to_iso8601(span.start_at),
              "end" => nil,
              "updated_at" => iso()
            },
            base_revision: span.server_revision - 5
          )
        )

      assert result["status"] == "applied"
      assert Workspace.fetch_live(TimeSpan, workspace_id, span.id).end_at == nil
    end

    test "an explicit null on a nullable field does clear it", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      span = span!(workspace_id, title: "Locked", locked_at: DateTime.utc_now())

      push_one!(
        ctx,
        mutation(
          "time_span",
          "update",
          %{
            "id" => span.id,
            "start" => DateTime.to_iso8601(span.start_at),
            "locked_at" => nil,
            "updated_at" => iso()
          },
          # `locked_at` is not merely nullable, it is guarded: row 11 lets an
          # admin clear a lock only from a CURRENT base_revision, so that a
          # deliberate reopen is distinguishable from one by an actor who never
          # saw the approval. This test is about null-as-a-value, so it supplies
          # the freshness the guard requires rather than working around it.
          base_revision: span.server_revision
        )
      )

      assert Workspace.fetch_live(TimeSpan, workspace_id, span.id).locked_at == nil
    end
  end

  describe "the exceptions: envelope fields the server owns" do
    test "origin_device_id is overwritten with the pushing device when omitted", %{
      ctx: ctx,
      workspace_id: workspace_id,
      device: device
    } do
      original = uuid7()
      span = span!(workspace_id, title: "Authored elsewhere", origin_device_id: original)

      push_one!(
        ctx,
        mutation("time_span", "update", %{
          "id" => span.id,
          "title" => "Edited here",
          "start" => DateTime.to_iso8601(span.start_at),
          "updated_at" => iso()
        })
      )

      # Not a merge exception by accident: origin_device_id means "the device
      # that last authored this row", so the pushing device is the right answer
      # and an omitted value must not preserve a stale one. It is also the LWW
      # tie-break key, so a stale value here would corrupt conflict resolution.
      assert Workspace.fetch_live(TimeSpan, workspace_id, span.id).origin_device_id == device.id
    end

    test "updated_at, updated_at_effective and server_revision are always server-set", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      span = span!(workspace_id, title: "Any span")

      result =
        push_one!(
          ctx,
          mutation("time_span", "update", %{
            "id" => span.id,
            "title" => "Edited",
            "start" => DateTime.to_iso8601(span.start_at),
            "updated_at" => iso()
          })
        )

      row = Workspace.fetch_live(TimeSpan, workspace_id, span.id)
      assert row.server_revision > span.server_revision
      assert result["entity"]["server_revision"] == row.server_revision
      assert row.updated_at_effective != nil
    end
  end
end
