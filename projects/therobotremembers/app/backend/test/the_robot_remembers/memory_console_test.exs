defmodule TheRobotRemembers.MemoryConsoleTest do
  @moduledoc """
  Pure (no-DB) coverage of the memory console's non-DB surface: the MCP auth agent binding
  (`MCP.Auth.resolve_agent`), the MCP mount flag (`Plugs.MCPAuth.required?`), the contract
  node/edge serializers, and the recall_preview tool's param validation. DB-backed behavior
  (subgraph tenant-scoping, side-effect-free preview, mutations) lives in `MemoryApiTest`.
  """
  use ExUnit.Case, async: true

  alias TheRobotRemembers.MCP.Auth
  alias TheRobotRemembers.Memory.Console
  alias TheRobotRemembers.Schema.Memory.{Memory, AssociationEdge}

  describe "MCP.Auth.resolve_agent/2" do
    test "dev-open (no claims) trusts the self-asserted agent, defaulting to local" do
      assert Auth.resolve_agent(%{assigns: %{}}, "aria") == {:ok, "aria"}
      assert Auth.resolve_agent(%{assigns: %{}}, nil) == {:ok, "local"}
    end

    test "authenticated without an agent claim still trusts the self-asserted agent" do
      ctx = %{assigns: %{auth_claims: %{"sub" => "ref.user-session.abc"}}}
      assert Auth.resolve_agent(ctx, "aria") == {:ok, "aria"}
      assert Auth.resolve_agent(ctx, nil) == {:ok, "local"}
    end

    test "an explicit agent claim overrides a missing param and must match a supplied one" do
      ctx = %{assigns: %{auth_claims: %{"agent" => "aria"}}}
      assert Auth.resolve_agent(ctx, nil) == {:ok, "aria"}
      assert Auth.resolve_agent(ctx, "aria") == {:ok, "aria"}
      assert {:error, msg} = Auth.resolve_agent(ctx, "marcus")
      assert msg =~ "may not act as agent 'marcus'"
    end
  end

  describe "Plugs.MCPAuth.required?/0" do
    setup do
      original = Application.get_env(:the_robot_remembers, :mcp_auth)
      on_exit(fn -> Application.put_env(:the_robot_remembers, :mcp_auth, original) end)
      :ok
    end

    test "reflects the config flag (default off in test)" do
      refute TheRobotRemembersWeb.Plugs.MCPAuth.required?()
      Application.put_env(:the_robot_remembers, :mcp_auth, required: true)
      assert TheRobotRemembersWeb.Plugs.MCPAuth.required?()
    end
  end

  describe "serializers" do
    test "node_view/1 emits the contract node shape with rounded floats and iso timestamps" do
      occurred = ~U[2026-07-05 12:00:00.000000Z]

      node =
        Console.node_view(%Memory{
          id: "11111111-1111-1111-1111-111111111111",
          summary: "s",
          content_type: :episodic,
          state: :active,
          compartment: "default",
          salience: 0.8266,
          decay_weight: 0.9,
          pinned: false,
          valence: 0.2,
          arousal: 0.5,
          recall_count: 4,
          occurred_at: occurred
        })

      assert node.id == "11111111-1111-1111-1111-111111111111"
      assert node.content_type == "episodic"
      assert node.state == "active"
      assert node.salience == 0.8266
      assert node.pinned == false
      assert node.occurred_at == "2026-07-05T12:00:00.000000Z"

      assert Map.keys(node) |> Enum.sort() ==
               ~w(arousal compartment content_type decay_weight id occurred_at pinned recall_count salience state summary valence)a
    end

    test "edge_view/1 emits the contract edge shape" do
      edge =
        Console.edge_view(%AssociationEdge{
          id: "22222222-2222-2222-2222-222222222222",
          source_memory_id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
          target_memory_id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
          edge_type: :semantic,
          weight: 0.7001,
          reinforcement_count: 3,
          last_reinforced_at: ~U[2026-07-05 00:00:00.000000Z]
        })

      assert edge.source == "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
      assert edge.target == "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
      assert edge.type == "semantic"
      assert edge.weight == 0.7001
      assert edge.last_reinforced_at == "2026-07-05T00:00:00.000000Z"
    end
  end

  describe "recall_preview tool validation (no DB)" do
    test "rejects a call with neither query nor mood before touching the DB" do
      assert {:error, msg} =
               TheRobotRemembers.MCP.Tools.RecallPreview.call(%{agent: "local"}, %{assigns: %{}})

      assert msg =~ "query and/or a target mood"
    end
  end
end
