defmodule Timely.TimelyFixtures do
  @moduledoc """
  Fixtures for the Timely sync suite.

  Rows are inserted directly through Ecto rather than through the entity layer:
  these tests are about the sync protocol, and going the long way round would
  make every one of them depend on machinery it is not trying to exercise.

  Membership is the exception - it is written through the real PBAC tables
  (`scoped_memberships` joined to the seeded system `groups`), because
  cross-workspace isolation is one of the things under test and a faked
  membership would prove nothing.
  """

  alias Timely.Repo
  alias Timely.Schema.Devices.Device
  alias Timely.Schema.Evidence.Screenshot
  alias Timely.Schema.Evidence.VisionAnalysis
  alias Timely.Schema.Settings.Setting
  alias Timely.Schema.Tracking.TimeSpan
  alias Timely.Sync.Revisions

  @group_ids %{
    "owner" => "a1b2c3d4-e5f6-5a7b-8c9d-0e1f2a3b4c5d",
    "admin" => "b2c3d4e5-f6a7-5b8c-9d0e-1f2a3b4c5d6e",
    "member" => "c3d4e5f6-a7b8-5c9d-0e1f-2a3b4c5d6e7f",
    "viewer" => "d4e5f6a7-b8c9-5d0e-1f2a-3b4c5d6e7f80"
  }

  @doc "Creates an organization, which is what a Timely workspace is."
  # ⟦𓅱𓋴𓎡𓋴⟧ workspace! :: Creates a workspace (organization).
  def workspace!(attrs \\ %{}) do
    uniq = System.unique_integer([:positive])
    id = attrs[:id] || Ecto.UUID.generate()
    now = DateTime.utc_now()

    Repo.insert_all(
      "organizations",
      [
        %{
          id: Ecto.UUID.dump!(id),
          slug: attrs[:slug] || "ws-#{uniq}",
          name: attrs[:name] || "Workspace #{uniq}",
          settings: %{},
          inserted_at: now,
          updated_at: now
        }
      ]
    )

    Revisions.ensure_counter!(id)
    id
  end

  @doc "Creates a user."
  # ⟦𓅱𓋴𓂋𓋴⟧ user! :: Creates a user.
  def user!(attrs \\ %{}) do
    uniq = System.unique_integer([:positive])

    {:ok, user} =
      Repo.insert(%Timely.Schema.Users.User{
        id: attrs[:id] || Ecto.UUID.generate(),
        email: attrs[:email] || "timely-#{uniq}@example.com",
        user_name: "timely#{uniq}",
        handle: "t#{uniq}",
        status: :active,
        verified: true,
        flagged: false
      })

    user
  end

  @doc "Grants a user a role in a workspace through the real PBAC tables."
  # ⟦𓅓𓃀𓂋𓋴⟧ member! :: Grants a PBAC role in a workspace.
  def member!(user_id, workspace_id, role \\ "owner") do
    Repo.insert_all(
      "scoped_memberships",
      [
        %{
          id: Ecto.UUID.dump!(Ecto.UUID.generate()),
          group_id: Ecto.UUID.dump!(Map.fetch!(@group_ids, role)),
          resource_type: "organization",
          resource_id: Ecto.UUID.dump!(workspace_id),
          member_type: "user",
          member_id: Ecto.UUID.dump!(user_id),
          created_at: DateTime.utc_now()
        }
      ]
    )

    :ok
  end

  @doc """
  The usual starting point: a workspace, an owner, and a registered macOS
  capture device.
  """
  # ⟦𓋴𓏏𓅱𓊪⟧ setup_workspace :: Workspace, owner and capture device.
  def setup_workspace(opts \\ []) do
    workspace_id = workspace!()
    user = user!()
    member!(user.id, workspace_id, Keyword.get(opts, :role, "owner"))
    device = device!(workspace_id, user.id, platform: "macos", is_capture_agent: true)

    %{workspace_id: workspace_id, user: user, device: device}
  end

  @doc "Inserts a device row directly."
  # ⟦𓂧𓆑𓋴𓏏⟧ device! :: Inserts a device row.
  def device!(workspace_id, user_id, opts \\ []) do
    now = DateTime.utc_now()

    {:ok, device} =
      Repo.transaction(fn ->
        Repo.insert!(%Device{
          id: Keyword.get(opts, :id, uuid7()),
          workspace_id: workspace_id,
          user_id: user_id,
          platform: Keyword.get(opts, :platform, "macos"),
          name: Keyword.get(opts, :name, "Test Device"),
          app_version: "1.0.0",
          local_only_screenshots: Keyword.get(opts, :local_only_screenshots, true),
          is_capture_agent: Keyword.get(opts, :is_capture_agent, false),
          last_sync_revision: 0,
          created_at: now,
          updated_at: now,
          updated_at_effective: now,
          server_revision: Revisions.allocate!(workspace_id)
        })
      end)

    device
  end

  @doc "Writes or replaces the workspace policy document."
  # ⟦𓊪𓃭𓋴𓏏⟧ set_policy! :: Writes the workspace policy document.
  def set_policy!(workspace_id, document) do
    now = DateTime.utc_now()

    {:ok, row} =
      Repo.transaction(fn ->
        existing =
          Repo.get_by(Setting, workspace_id: workspace_id, kind: "workspace_policy")

        attrs = %{
          "id" => workspace_id,
          "workspace_id" => workspace_id,
          "kind" => "workspace_policy",
          "document" => Map.merge(Setting.policy_defaults(), document),
          "created_at" => (existing && existing.created_at) || now,
          "updated_at" => now,
          "updated_at_effective" => now,
          "server_revision" => Revisions.allocate!(workspace_id)
        }

        (existing || %Setting{})
        |> Setting.changeset(attrs)
        |> Repo.insert_or_update!()
      end)

    row
  end

  @doc "Inserts a time span directly, bypassing the mutation engine."
  # ⟦𓋴𓊪𓈖𓏏⟧ span! :: Inserts a time span row.
  def span!(workspace_id, opts \\ []) do
    now = DateTime.utc_now()
    start_at = Keyword.get(opts, :start_at, now)

    {:ok, span} =
      Repo.transaction(fn ->
        Repo.insert!(%TimeSpan{
          id: Keyword.get(opts, :id, uuid7()),
          workspace_id: workspace_id,
          title: Keyword.get(opts, :title, "Work"),
          canonical_title: Timely.Sync.Canon.canon(Keyword.get(opts, :title, "Work")),
          client_id: Keyword.get(opts, :client_id),
          project_id: Keyword.get(opts, :project_id),
          client_name: Keyword.get(opts, :client_name, ""),
          project_name: Keyword.get(opts, :project_name, ""),
          start_at: start_at,
          end_at: Keyword.get(opts, :end_at),
          source: Keyword.get(opts, :source, "timer"),
          is_billable: Keyword.get(opts, :is_billable, false),
          review_state: Keyword.get(opts, :review_state, "unreviewed"),
          review_reasons: [],
          locked_at: Keyword.get(opts, :locked_at),
          created_at: now,
          updated_at: Keyword.get(opts, :updated_at, now),
          updated_at_effective: Keyword.get(opts, :updated_at_effective, now),
          server_revision: Revisions.allocate!(workspace_id),
          origin_device_id: Keyword.get(opts, :origin_device_id)
        })
      end)

    span
  end

  @doc "Inserts a screenshot metadata row directly."
  # ⟦𓋴𓎡𓋴𓏏⟧ screenshot! :: Inserts a screenshot metadata row.
  def screenshot!(workspace_id, opts \\ []) do
    now = DateTime.utc_now()

    {:ok, screenshot} =
      Repo.transaction(fn ->
        Repo.insert!(%Screenshot{
          id: Keyword.get(opts, :id, uuid7()),
          workspace_id: workspace_id,
          span_id: Keyword.get(opts, :span_id),
          captured_at: Keyword.get(opts, :captured_at, now),
          file_name: Keyword.get(opts, :file_name, "timely-test.png"),
          active_app_name: Keyword.get(opts, :active_app_name, "Xcode"),
          upload_state: Keyword.get(opts, :upload_state, "local_only"),
          created_at: now,
          updated_at: now,
          updated_at_effective: now,
          server_revision: Revisions.allocate!(workspace_id),
          origin_device_id: Keyword.get(opts, :origin_device_id)
        })
      end)

    screenshot
  end

  @doc "Inserts a vision analysis row directly."
  # ⟦𓆓𓋴𓈖𓏏⟧ vision_analysis! :: Inserts a vision analysis row.
  def vision_analysis!(workspace_id, screenshot_id, opts \\ []) do
    now = DateTime.utc_now()

    {:ok, analysis} =
      Repo.transaction(fn ->
        Repo.insert!(%VisionAnalysis{
          id: Keyword.get(opts, :id, uuid7()),
          workspace_id: workspace_id,
          screenshot_id: screenshot_id,
          analyzed_at: now,
          model: "gpt-4o",
          status_update: Keyword.get(opts, :status_update, "Editing the timeline canvas"),
          evidence: Keyword.get(opts, :evidence, "Xcode with TimelineView.swift open"),
          confidence: 0.9,
          raw_response: Keyword.get(opts, :raw_response),
          raw_response_withheld: Keyword.get(opts, :raw_response_withheld, true),
          created_at: now,
          updated_at: now,
          updated_at_effective: now,
          server_revision: Revisions.allocate!(workspace_id)
        })
      end)

    analysis
  end

  @doc "Builds the request context the mutation engine reads."
  # ⟦𓎡𓏏𓐍𓋴⟧ ctx :: Builds a mutation request context.
  def ctx(workspace_id, user_id, opts \\ []) do
    %{
      workspace_id: workspace_id,
      user_id: user_id,
      device_id: Keyword.get(opts, :device_id),
      admin: Keyword.get(opts, :admin, true),
      atomic: Keyword.get(opts, :atomic, false),
      now: Keyword.get(opts, :now, DateTime.utc_now()),
      blob_url_builder: nil
    }
  end

  @doc "Builds one wire mutation."
  # ⟦𓅓𓏏𓈖𓋴⟧ mutation :: Builds one wire mutation.
  def mutation(kind, op, payload, opts \\ []) do
    %{
      "mutation_id" => Keyword.get(opts, :mutation_id, uuid7()),
      "entity" => kind,
      "op" => op,
      "base_revision" => Keyword.get(opts, :base_revision),
      "payload" => payload
    }
  end

  @doc """
  A UUIDv7. The protocol asks for time-ordered ids on event-like entities, and
  the LWW tie-break sorts on `origin_device_id` lexically, so tests that care
  about ordering need ids that actually order.
  """
  # ⟦𓅱𓅱𓋴𓆑⟧ uuid7 :: Generates a UUIDv7.
  def uuid7 do
    <<random_a::12, random_b::62, _::bitstring>> = :crypto.strong_rand_bytes(16)
    timestamp = System.system_time(:millisecond)

    <<timestamp::big-unsigned-48, 7::4, random_a::12, 2::2, random_b::62>>
    |> Base.encode16(case: :lower)
    |> String.replace(~r/(.{8})(.{4})(.{4})(.{4})(.{12})/, "\\1-\\2-\\3-\\4-\\5")
  end

  @doc "An ISO 8601 instant `seconds` from now."
  # ⟦𓋴𓆑𓏏𓋴⟧ iso :: ISO 8601 instant offset from now.
  def iso(seconds \\ 0) do
    DateTime.utc_now() |> DateTime.add(seconds, :second) |> DateTime.to_iso8601()
  end
end
