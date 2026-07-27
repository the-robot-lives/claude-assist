defmodule Timely.Sync.PrivacyTest do
  @moduledoc """
  SYNC-PROTOCOL section 10: the screenshot double gate and the
  `raw_response` gate that treats a verbatim transcription of the pixels as
  image-equivalent.

  Both gates default closed, and both are a logical AND of a workspace flag and
  a device flag, so a device can only ever tighten them. These tests care most
  about the *default* and *closed* paths, because those are the ones a privacy
  promise is actually made of.
  """
  use Timely.DataCase, async: false

  import Timely.TimelyFixtures

  alias Timely.Schema.Evidence.VisionAnalysis
  alias Timely.Sync.Blobs
  alias Timely.Sync.Devices
  alias Timely.Sync.Mutations
  alias Timely.Sync.Policy
  alias Timely.Sync.Workspace

  setup do
    Blobs.Memory.reset()
    %{workspace_id: workspace_id, user: user, device: device} = setup_workspace()

    {:ok,
     workspace_id: workspace_id,
     user: user,
     device: device,
     ctx: ctx(workspace_id, user.id, device_id: device.id)}
  end

  defp open_both_gates(workspace_id, user_id, device) do
    set_policy!(workspace_id, %{"screenshot_upload_allowed" => true})
    {:ok, device} = Devices.update(workspace_id, user_id, device.id, %{"local_only_screenshots" => false})
    device
  end

  describe "defaults" do
    test "a workspace with no policy row behaves as the most restrictive policy", %{
      workspace_id: workspace_id
    } do
      policy = Policy.workspace_policy(workspace_id)

      assert policy["screenshot_upload_allowed"] == false
      assert policy["sync_vision_raw_response"] == false
      assert policy["default_local_only_screenshots"] == true
    end

    test "a device defaults to local_only_screenshots", %{device: device} do
      assert device.local_only_screenshots == true
    end
  end

  describe "the screenshot blob double gate" do
    test "is closed by default and names both sides", %{
      workspace_id: workspace_id,
      device: device
    } do
      screenshot = screenshot!(workspace_id)

      assert {:error, :forbidden, gates} =
               Blobs.upload(workspace_id, screenshot.id, device.id, "PNGBYTES")

      assert gates["workspace_upload_allowed"] == false
      assert gates["device_local_only"] == true
    end

    test "the workspace flag alone is not enough", %{
      workspace_id: workspace_id,
      device: device
    } do
      set_policy!(workspace_id, %{"screenshot_upload_allowed" => true})
      screenshot = screenshot!(workspace_id)

      assert {:error, :forbidden, gates} =
               Blobs.upload(workspace_id, screenshot.id, device.id, "PNGBYTES")

      assert gates["workspace_upload_allowed"] == true
      assert gates["device_local_only"] == true
    end

    test "the device flag alone is not enough - a device cannot loosen the workspace", %{
      workspace_id: workspace_id,
      user: user,
      device: device
    } do
      {:ok, _} = Devices.update(workspace_id, user.id, device.id, %{"local_only_screenshots" => false})
      screenshot = screenshot!(workspace_id)

      assert {:error, :forbidden, gates} =
               Blobs.upload(workspace_id, screenshot.id, device.id, "PNGBYTES")

      assert gates["workspace_upload_allowed"] == false
      assert gates["device_local_only"] == false
    end

    test "both open lets the bytes through and bumps the metadata revision", %{
      workspace_id: workspace_id,
      user: user,
      device: device
    } do
      device = open_both_gates(workspace_id, user.id, device)
      screenshot = screenshot!(workspace_id)

      assert {:ok, uploaded} =
               Blobs.upload(workspace_id, screenshot.id, device.id, "PNGBYTES")

      assert uploaded.upload_state == "uploaded"
      assert uploaded.blob_byte_size == byte_size("PNGBYTES")
      # Bumped so the metadata change reaches other devices through the pull.
      assert uploaded.server_revision > screenshot.server_revision

      assert {:ok, "PNGBYTES", _} = Blobs.download(workspace_id, screenshot.id)
    end

    test "a rejected body is not retained", %{workspace_id: workspace_id, device: device} do
      screenshot = screenshot!(workspace_id)

      assert {:error, :forbidden, _} =
               Blobs.upload(workspace_id, screenshot.id, device.id, "SECRETPIXELS")

      # Nothing was written anywhere: not to the store, not to the row.
      assert {:error, :not_available} = Blobs.download(workspace_id, screenshot.id)
      assert Repo.get(Timely.Schema.Evidence.Screenshot, screenshot.id).upload_state == "local_only"
    end

    test "a missing metadata row is a 404, not a create", %{
      workspace_id: workspace_id,
      user: user,
      device: device
    } do
      device = open_both_gates(workspace_id, user.id, device)

      # "the server will not create a metadata row from a blob".
      assert {:error, :not_found} = Blobs.upload(workspace_id, uuid7(), device.id, "PNGBYTES")
    end

    test "an unknown or revoked device is a closed gate, not an open one", %{
      workspace_id: workspace_id
    } do
      set_policy!(workspace_id, %{"screenshot_upload_allowed" => true})
      screenshot = screenshot!(workspace_id)

      assert {:error, :forbidden, gates} =
               Blobs.upload(workspace_id, screenshot.id, uuid7(), "PNGBYTES")

      assert gates["device_local_only"] == true
    end

    test "a content hash mismatch is refused", %{
      workspace_id: workspace_id,
      user: user,
      device: device
    } do
      device = open_both_gates(workspace_id, user.id, device)
      screenshot = screenshot!(workspace_id)

      assert {:error, :hash_mismatch} =
               Blobs.upload(workspace_id, screenshot.id, device.id, "PNGBYTES",
                 expected_hash: String.duplicate("0", 64)
               )
    end

    test "download of a never-uploaded screenshot is the normal path", %{
      workspace_id: workspace_id
    } do
      screenshot = screenshot!(workspace_id)
      assert {:error, :not_available} = Blobs.download(workspace_id, screenshot.id)
    end

    test "revoking the workspace flag purges stored bytes but keeps metadata", %{
      workspace_id: workspace_id,
      user: user,
      device: device
    } do
      device = open_both_gates(workspace_id, user.id, device)
      screenshot = screenshot!(workspace_id)
      {:ok, _} = Blobs.upload(workspace_id, screenshot.id, device.id, "PNGBYTES")

      Blobs.revoke_workspace_blobs(workspace_id)

      row = Repo.get(Timely.Schema.Evidence.Screenshot, screenshot.id)
      assert row.upload_state == "purged"
      assert row.blob_storage_key == nil
      # The timeline does not develop holes.
      assert row.deleted_at == nil
      assert {:error, :not_available} = Blobs.download(workspace_id, screenshot.id)
    end
  end

  describe "the raw_response gate" do
    test "withholds raw_response by default and says so", %{ctx: ctx, workspace_id: workspace_id} do
      screenshot = screenshot!(workspace_id)
      id = uuid7()

      result =
        push_one(ctx, %{
          "id" => id,
          "screenshot_id" => screenshot.id,
          "analyzed_at" => iso(-60),
          "model" => "gpt-4o",
          "status_update" => "Editing the timeline canvas",
          "evidence" => "Xcode with TimelineView.swift open",
          "inferred_project" => "Redesign",
          "inferred_task" => "Keyboard navigation",
          "confidence" => 0.9,
          "raw_response" => "The screen shows an email from the bank about account 12345",
          "updated_at" => iso()
        })

      assert result["status"] == "applied"

      row = Workspace.fetch_live(VisionAnalysis, workspace_id, id)
      # Never stored, not merely never returned - a withheld transcription that
      # sits in the database is still a transcription that leaked.
      assert row.raw_response == nil
      # Distinguishes "policy suppressed this" from "the source never had it".
      assert row.raw_response_withheld == true

      # The bounded summaries always sync; the product does not work without them.
      assert row.status_update == "Editing the timeline canvas"
      assert row.evidence == "Xcode with TimelineView.swift open"
      assert row.inferred_project == "Redesign"
      assert row.inferred_task == "Keyboard navigation"
    end

    test "stores raw_response once the workspace opts in", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      set_policy!(workspace_id, %{"sync_vision_raw_response" => true})
      screenshot = screenshot!(workspace_id)
      id = uuid7()

      push_one(ctx, %{
        "id" => id,
        "screenshot_id" => screenshot.id,
        "analyzed_at" => iso(-60),
        "model" => "gpt-4o",
        "status_update" => "Editing",
        "confidence" => 0.9,
        "raw_response" => "verbatim model output",
        "updated_at" => iso()
      })

      row = Workspace.fetch_live(VisionAnalysis, workspace_id, id)
      assert row.raw_response == "verbatim model output"
      assert row.raw_response_withheld == false
    end

    test "an opted-in workspace with no raw_response is 'never had it', not 'withheld'", %{
      ctx: ctx,
      workspace_id: workspace_id
    } do
      set_policy!(workspace_id, %{"sync_vision_raw_response" => true})
      screenshot = screenshot!(workspace_id)
      id = uuid7()

      push_one(ctx, %{
        "id" => id,
        "screenshot_id" => screenshot.id,
        "analyzed_at" => iso(-60),
        "model" => "gpt-4o",
        "status_update" => "Editing",
        "confidence" => 0.9,
        "updated_at" => iso()
      })

      row = Workspace.fetch_live(VisionAnalysis, workspace_id, id)
      assert row.raw_response == nil
      assert row.raw_response_withheld == true
    end
  end

  defp push_one(ctx, payload) do
    {:ok, [result]} =
      Mutations.push(ctx, [mutation("vision_analysis", "create", payload)])

    result
  end
end
