defmodule Timely.Sync.ChangesTest do
  @moduledoc """
  The pull loop (SYNC-PROTOCOL sections 5 and 7.1): cursor semantics, paging,
  tombstone delivery, and the tombstone horizon.
  """
  use Timely.DataCase, async: false

  import Timely.TimelyFixtures

  alias Timely.Sync.Changes
  alias Timely.Sync.Mutations
  alias Timely.Sync.Revisions

  setup do
    %{workspace_id: workspace_id, user: user, device: device} = setup_workspace()

    {:ok,
     workspace_id: workspace_id,
     user: user,
     device: device,
     ctx: ctx(workspace_id, user.id, device_id: device.id)}
  end

  describe "bootstrap" do
    test "since=0 returns everything, with every bucket present even when empty", %{
      workspace_id: workspace_id
    } do
      span!(workspace_id, title: "One")

      {:ok, page} = Changes.pull(workspace_id, since: 0)

      assert length(page["changes"]["time_spans"]) == 1
      # Clients iterate a fixed key set, so an empty bucket is `[]` and never
      # absent.
      for bucket <- Timely.Sync.Vocabulary.buckets() do
        assert is_list(page["changes"][bucket])
      end
    end

    test "reports the committed watermark as next_cursor when caught up", %{
      workspace_id: workspace_id
    } do
      span!(workspace_id)
      {:ok, page} = Changes.pull(workspace_id, since: 0)

      assert page["has_more"] == false
      assert page["next_cursor"] == Revisions.committed_watermark(workspace_id)
    end

    test "every row is unambiguously typed by the bucket it sits in", %{
      workspace_id: workspace_id
    } do
      span!(workspace_id)
      screenshot!(workspace_id)

      {:ok, page} = Changes.pull(workspace_id, since: 0)

      # Unlike a mutation result, a pulled row needs no `entity_kind`: the
      # bucket key is the discriminator, and the key set is fixed and complete.
      assert Enum.sort(Map.keys(page["changes"])) ==
               Enum.sort(Timely.Sync.Vocabulary.buckets())

      assert length(page["changes"]["time_spans"]) == 1
      assert length(page["changes"]["screenshots"]) == 1
      assert page["changes"]["clients"] == []
    end

    test "an empty workspace answers a well-formed empty page" do
      # A bare workspace, not the fixture one - `setup_workspace` registers a
      # device, so its counter is already past zero.
      workspace_id = workspace!()

      {:ok, page} = Changes.pull(workspace_id, since: 0)

      assert page["next_cursor"] == 0
      assert page["has_more"] == false
      assert page["changes"]["time_spans"] == []
      assert page["tombstone_horizon_revision"] == 0
      assert is_binary(page["server_time"])
    end
  end

  describe "cursor semantics" do
    test "since is an exclusive lower bound", %{workspace_id: workspace_id} do
      first = span!(workspace_id, title: "First")
      second = span!(workspace_id, title: "Second")

      {:ok, page} = Changes.pull(workspace_id, since: first.server_revision)

      ids = Enum.map(page["changes"]["time_spans"], & &1["id"])
      refute first.id in ids
      assert second.id in ids
    end

    test "rows are ordered by ascending server_revision within a bucket", %{
      workspace_id: workspace_id
    } do
      for n <- 1..5, do: span!(workspace_id, title: "Span #{n}")

      {:ok, page} = Changes.pull(workspace_id, since: 0)

      revisions = Enum.map(page["changes"]["time_spans"], & &1["server_revision"])
      assert revisions == Enum.sort(revisions)
    end

    test "a full loop terminates and delivers every row exactly once", %{
      workspace_id: workspace_id
    } do
      expected = for n <- 1..12, do: span!(workspace_id, title: "Span #{n}").id

      {collected, iterations} = drain(workspace_id, 0, [], 0)

      assert Enum.sort(collected) == Enum.sort(expected)
      assert length(collected) == length(Enum.uniq(collected))
      # Paged rather than delivered in one go, so paging is really exercised.
      assert iterations > 1
    end

    test "the cursor never advances past the committed watermark", %{workspace_id: workspace_id} do
      span!(workspace_id)
      watermark = Revisions.committed_watermark(workspace_id)

      {:ok, page} = Changes.pull(workspace_id, since: 0)

      assert page["next_cursor"] <= watermark
    end
  end

  describe "paging" do
    test "limit caps rows across all buckets combined, not per bucket", %{
      workspace_id: workspace_id
    } do
      for n <- 1..4 do
        span!(workspace_id, title: "Span #{n}")
        screenshot!(workspace_id, file_name: "shot-#{n}.png")
      end

      {:ok, page} = Changes.pull(workspace_id, since: 0, limit: 3)

      total =
        page["changes"]
        |> Map.values()
        |> Enum.map(&length/1)
        |> Enum.sum()

      assert total == 3
      assert page["has_more"] == true
    end

    test "a truncated page resumes exactly where it stopped", %{workspace_id: workspace_id} do
      ids = for n <- 1..6, do: span!(workspace_id, title: "Span #{n}").id

      # Filtered to spans: the workspace also holds the device row registered by
      # `setup_workspace`, and this test is about span paging.
      {:ok, first} = Changes.pull(workspace_id, since: 0, limit: 2, entities: ["time_spans"])

      {:ok, second} =
        Changes.pull(workspace_id, since: first["next_cursor"], limit: 2, entities: ["time_spans"])

      first_ids = Enum.map(first["changes"]["time_spans"], & &1["id"])
      second_ids = Enum.map(second["changes"]["time_spans"], & &1["id"])

      assert length(first_ids) == 2
      assert length(second_ids) == 2
      # No overlap and no gap.
      assert first_ids ++ second_ids == Enum.take(ids, 4)
    end

    test "has_more is false on the exactly-full final page", %{workspace_id: workspace_id} do
      for n <- 1..3, do: span!(workspace_id, title: "Span #{n}")

      {:ok, page} = Changes.pull(workspace_id, since: 0, limit: 3, entities: ["time_spans"])

      assert length(page["changes"]["time_spans"]) == 3
      assert page["has_more"] == false
    end

    test "limit is clamped to the contract's maximum", %{workspace_id: workspace_id} do
      span!(workspace_id)
      assert {:ok, _} = Changes.pull(workspace_id, since: 0, limit: 100_000)
    end
  end

  describe "tombstones" do
    test "are included in the page so clients can apply the delete", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      span = span!(workspace_id, title: "Doomed")

      {:ok, _} =
        Mutations.push(ctx, [
          mutation("time_span", "delete", %{"id" => span.id, "deleted_at" => iso()})
        ])

      {:ok, page} = Changes.pull(workspace_id, since: span.server_revision)

      tombstone = Enum.find(page["changes"]["time_spans"], &(&1["id"] == span.id))
      assert tombstone != nil
      assert tombstone["deleted_at"] != nil
    end

    test "a cursor below the horizon answers cursor_too_old", %{workspace_id: workspace_id} do
      span!(workspace_id)

      # The table enforces current_revision >= tombstone_horizon_revision, so
      # the horizon cannot be advanced past the counter.
      Repo.update_all(
        Timely.Schema.Sync.WorkspaceRevision
        |> Ecto.Query.where(workspace_id: ^workspace_id),
        set: [current_revision: 50, tombstone_horizon_revision: 50]
      )

      assert {:error, :cursor_too_old, 50} = Changes.pull(workspace_id, since: 10)
    end

    test "since=0 is always honoured, because it is the answer to a 410", %{
      workspace_id: workspace_id
    } do
      span!(workspace_id)

      Repo.update_all(
        Timely.Schema.Sync.WorkspaceRevision
        |> Ecto.Query.where(workspace_id: ^workspace_id),
        set: [current_revision: 50, tombstone_horizon_revision: 50]
      )

      # A client that answered 410 by re-bootstrapping must not be met with a
      # second 410.
      assert {:ok, _page} = Changes.pull(workspace_id, since: 0)
    end
  end

  describe "the entities filter" do
    test "narrows the page to the requested buckets", %{workspace_id: workspace_id} do
      span!(workspace_id)
      screenshot!(workspace_id)

      {:ok, page} = Changes.pull(workspace_id, since: 0, entities: ["time_spans"])

      assert length(page["changes"]["time_spans"]) == 1
      assert page["changes"]["screenshots"] == []
    end

    test "parse_entities/1 ignores unknown bucket names" do
      assert Changes.parse_entities("time_spans,wormholes") == ["time_spans"]
      assert Changes.parse_entities("wormholes") == nil
      assert Changes.parse_entities(nil) == nil
      assert Changes.parse_entities("") == nil
    end
  end

  defp drain(workspace_id, cursor, acc, iterations) do
    {:ok, page} = Changes.pull(workspace_id, since: cursor, limit: 5, entities: ["time_spans"])
    ids = Enum.map(page["changes"]["time_spans"], & &1["id"])

    if page["has_more"] do
      drain(workspace_id, page["next_cursor"], acc ++ ids, iterations + 1)
    else
      {acc ++ ids, iterations + 1}
    end
  end
end
