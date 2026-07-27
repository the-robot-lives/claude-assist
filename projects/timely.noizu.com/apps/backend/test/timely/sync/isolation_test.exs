defmodule Timely.Sync.IsolationTest do
  @moduledoc """
  Cross-workspace isolation.

  Every one of these asserts the same thing from a different angle: a user must
  never read or write another workspace's rows. The isolation lives in the query
  layer - `Timely.Sync.Workspace.scope/2` - rather than in a post-fetch
  comparison, because a query that fetches by primary key and *then* checks
  `workspace_id` has already read the other tenant's row.
  """
  use Timely.DataCase, async: false

  import Timely.TimelyFixtures

  alias Timely.Schema.Evidence.Screenshot
  alias Timely.Schema.Tracking.TimeSpan
  alias Timely.Sync.Blobs
  alias Timely.Sync.Changes
  alias Timely.Sync.Devices
  alias Timely.Sync.Mutations
  alias Timely.Sync.Reports
  alias Timely.Sync.Workspace

  setup do
    Blobs.Memory.reset()

    # Two workspaces, two users, no overlap at all.
    alice_ws = workspace!()
    alice = user!()
    member!(alice.id, alice_ws, "owner")

    mallory_ws = workspace!()
    mallory = user!()
    member!(mallory.id, mallory_ws, "owner")

    {:ok,
     alice_ws: alice_ws,
     alice: alice,
     mallory_ws: mallory_ws,
     mallory: mallory,
     alice_ctx: ctx(alice_ws, alice.id)}
  end

  describe "authorization" do
    test "a non-member is refused", %{alice_ws: alice_ws, mallory: mallory} do
      assert {:error, :not_a_member} = Workspace.authorize(mallory.id, alice_ws)
    end

    test "a member is admitted", %{alice_ws: alice_ws, alice: alice} do
      assert {:ok, _membership} = Workspace.authorize(alice.id, alice_ws)
    end

    test "an anonymous caller is refused", %{alice_ws: alice_ws} do
      assert {:error, :not_a_member} = Workspace.authorize(nil, alice_ws)
    end

    test "a garbage workspace id is refused rather than crashing", %{alice: alice} do
      assert {:error, :not_a_member} = Workspace.authorize(alice.id, "not-a-uuid")
    end

    test "insufficient role is distinguished from non-membership", %{mallory_ws: ws} do
      viewer = user!()
      member!(viewer.id, ws, "viewer")

      assert {:ok, _} = Workspace.authorize(viewer.id, ws, "viewer")
      assert {:error, :insufficient_role} = Workspace.authorize(viewer.id, ws, "admin")
    end
  end

  describe "reads" do
    test "a pull never returns another workspace's rows", %{
      alice_ws: alice_ws,
      mallory_ws: mallory_ws
    } do
      mine = span!(alice_ws, title: "Mine")
      theirs = span!(mallory_ws, title: "Theirs")

      {:ok, page} = Changes.pull(alice_ws, since: 0)
      ids = Enum.map(page["changes"]["time_spans"], & &1["id"])

      assert mine.id in ids
      refute theirs.id in ids
    end

    test "a pull from an empty workspace stays empty even when the neighbour is busy", %{
      alice_ws: alice_ws,
      mallory_ws: mallory_ws
    } do
      for n <- 1..10, do: span!(mallory_ws, title: "Theirs #{n}")

      {:ok, page} = Changes.pull(alice_ws, since: 0)

      assert page["changes"]["time_spans"] == []
      # The revision counter is per workspace, so the neighbour's traffic does
      # not even move Alice's watermark.
      assert page["next_cursor"] == 0
    end

    test "fetch_live and fetch_any are workspace-scoped", %{
      alice_ws: alice_ws,
      mallory_ws: mallory_ws
    } do
      theirs = span!(mallory_ws, title: "Theirs")

      assert Workspace.fetch_live(TimeSpan, alice_ws, theirs.id) == nil
      assert Workspace.fetch_any(TimeSpan, alice_ws, theirs.id) == nil
      # And it is genuinely there, so the nil above is scoping and not absence.
      assert Workspace.fetch_live(TimeSpan, mallory_ws, theirs.id) != nil
    end

    test "a report never counts another workspace's time", %{
      alice_ws: alice_ws,
      mallory_ws: mallory_ws
    } do
      start = DateTime.utc_now() |> DateTime.add(-3600, :second)

      span!(mallory_ws,
        title: "Theirs",
        start_at: start,
        end_at: DateTime.add(start, 3600, :second),
        is_billable: true
      )

      summary =
        Reports.summary(alice_ws,
          from: DateTime.add(start, -3600, :second),
          to: DateTime.utc_now()
        )

      assert summary["totals"]["elapsed_seconds"] == 0
      assert summary["totals"]["span_count"] == 0
    end
  end

  describe "writes" do
    test "a mutation cannot reach into another workspace by id", %{
      alice_ctx: alice_ctx,
      mallory_ws: mallory_ws
    } do
      theirs = span!(mallory_ws, title: "Theirs")

      {:ok, [result]} =
        Mutations.push(alice_ctx, [
          mutation("time_span", "update", %{
            "id" => theirs.id,
            "title" => "hijacked",
            "start" => iso(-3600),
            "updated_at" => iso()
          })
        ])

      # The row is invisible to Alice's scoped lookup, so the update cannot land
      # on it; the id already exists globally, so it cannot be created either.
      assert result["status"] == "rejected"
      assert result["reason"] == "workspace_mismatch"
      assert Repo.get(TimeSpan, theirs.id).title == "Theirs"
    end

    test "a delete cannot tombstone another workspace's row", %{
      alice_ctx: alice_ctx,
      mallory_ws: mallory_ws
    } do
      theirs = span!(mallory_ws, title: "Theirs")

      {:ok, [result]} =
        Mutations.push(alice_ctx, [
          mutation("time_span", "delete", %{"id" => theirs.id, "deleted_at" => iso()})
        ])

      # Answered as a no-op against a row Alice cannot see, and the real row is
      # untouched.
      assert result["status"] == "applied"
      assert result["entity"] == nil
      assert Repo.get(TimeSpan, theirs.id).deleted_at == nil
    end

    test "a device in another workspace cannot be updated", %{
      alice_ws: alice_ws,
      alice: alice,
      mallory_ws: mallory_ws,
      mallory: mallory
    } do
      theirs = device!(mallory_ws, mallory.id, platform: "android")

      # Scoped lookup in Alice's workspace simply does not find it.
      assert {:error, :not_found} =
               Devices.update(alice_ws, alice.id, theirs.id, %{"name" => "hijacked"})
    end

    test "a device belonging to another user in the same workspace cannot be updated", %{
      alice_ws: alice_ws,
      alice: alice
    } do
      colleague = user!()
      member!(colleague.id, alice_ws, "member")
      theirs = device!(alice_ws, colleague.id, platform: "ios")

      assert {:error, :not_device_owner} =
               Devices.update(alice_ws, alice.id, theirs.id, %{"name" => "hijacked"})
    end

    test "registering a device id claimed by another user is refused", %{
      alice_ws: alice_ws,
      alice: alice
    } do
      colleague = user!()
      member!(colleague.id, alice_ws, "member")
      theirs = device!(alice_ws, colleague.id, platform: "ios")

      # Adopting it would attribute one person's captured workday to another's
      # device row, and `origin_device_id` is an LWW input.
      assert {:error, :not_device_owner} =
               Devices.register(alice_ws, alice.id, %{
                 "device_id" => theirs.id,
                 "platform" => "macos",
                 "name" => "Stolen",
                 "app_version" => "1.0.0"
               })
    end
  end

  describe "blobs" do
    test "bytes cannot be read from another workspace", %{
      alice_ws: alice_ws,
      mallory_ws: mallory_ws,
      mallory: mallory
    } do
      set_policy!(mallory_ws, %{"screenshot_upload_allowed" => true})
      device = device!(mallory_ws, mallory.id, local_only_screenshots: false)
      screenshot = screenshot!(mallory_ws)
      {:ok, _} = Blobs.upload(mallory_ws, screenshot.id, device.id, "THEIRPIXELS")

      assert {:error, :not_available} = Blobs.download(alice_ws, screenshot.id)
      assert {:ok, "THEIRPIXELS", _} = Blobs.download(mallory_ws, screenshot.id)
    end

    test "bytes cannot be uploaded to another workspace's screenshot", %{
      alice_ws: alice_ws,
      alice: alice,
      mallory_ws: mallory_ws
    } do
      set_policy!(alice_ws, %{"screenshot_upload_allowed" => true})
      alice_device = device!(alice_ws, alice.id, local_only_screenshots: false)
      theirs = screenshot!(mallory_ws)

      assert {:error, :not_found} =
               Blobs.upload(alice_ws, theirs.id, alice_device.id, "PNGBYTES")

      assert Repo.get(Screenshot, theirs.id).upload_state == "local_only"
    end
  end

  describe "the mutation ledger" do
    test "one workspace's policy does not leak into another's gate", %{
      alice_ws: alice_ws,
      mallory_ws: mallory_ws
    } do
      set_policy!(mallory_ws, %{"sync_vision_raw_response" => true})

      refute Timely.Sync.Policy.raw_response_allowed?(alice_ws)
      assert Timely.Sync.Policy.raw_response_allowed?(mallory_ws)
    end
  end
end
