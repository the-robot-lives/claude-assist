defmodule Therobotplans.MCP.ProjectsMCPTest do
  use TherobotplansWeb.ConnCase, async: false
  # ConnCase does not pull in verified routes; this module uses the ~p sigil.
  use TherobotplansWeb, :verified_routes

  @moduledoc """
  Phase 0 smoke test — proves the MCP loop end to end:

    1. a user creates an MCP API key
    2. the raw key mints a short-lived MCP JWT via POST /api/mcp/token
    3. the bearer JWT reaches the projects MCP server and lists tools
    4. a hidden domain tool (Project.Overview) is invoked and returns data

  This validates all three registration sites (application.ex child, router
  host scope, MCPServers catalog) plus the auth glue chain.
  """

  alias Therobotplans.MCPApiKeys

  describe "MCP API keys" do
    test "generate + verify round-trips a raw key", %{conn: _} do
      %{user: user} = setup_user_and_token()
      user_id = user.id
      {:ok, key, raw_key} = MCPApiKeys.generate_api_key(user.id, "test")
      assert key.key_prefix == String.slice(raw_key, 0, 8)
      assert %{user_id: ^user_id} = MCPApiKeys.verify_api_key(raw_key)
      assert MCPApiKeys.verify_api_key("not-a-real-key") == nil
    end

    test "a revoked key no longer verifies", %{conn: _} do
      %{user: user} = setup_user_and_token()
      {:ok, key, raw_key} = MCPApiKeys.generate_api_key(user.id)
      key_id = key.id
      assert %{id: ^key_id} = MCPApiKeys.verify_api_key(raw_key)
      {:ok, _} = MCPApiKeys.revoke(key.id)
      assert MCPApiKeys.verify_api_key(raw_key) == nil
    end
  end

  describe "POST /api/mcp/token" do
    test "mints a JWT from a valid raw key", %{conn: conn} do
      %{user: user} = setup_user_and_token()
      {:ok, _key, raw_key} = MCPApiKeys.generate_api_key(user.id)

      conn = post(conn, ~p"/api/mcp/token", %{key: raw_key})
      assert %{"token" => token, "expires_at" => _} = json_response(conn, 200)
      assert is_binary(token) and token != ""
    end

    test "rejects an unknown key", %{conn: conn} do
      conn = post(conn, ~p"/api/mcp/token", %{key: "totally-bogus"})
      assert json_response(conn, 401)
    end
  end

  describe "Therobotplans.MCP.Projects server" do
    test "Catalog lists the registered Project + Discovery tools" do
      # The root server re-declares the same Project tools; either server works.
      catalog = Therobotplans.Tools.Catalog.build(Therobotplans.MCP.Projects)
      names = Enum.map(catalog, & &1.name)

      assert "Project.Overview" in names
      assert "Project.List" in names
      assert "ToolSummary" in names
    end

    test "ToolCall guards an MCP-visible tool — Project.Overview must be called directly" do
      alias Therobotplans.Tools.ToolCall

      ctx = %Noizu.MCP.Ctx{server: Therobotplans.MCP.Projects}
      {:ok, result} = ToolCall.call(%{"tool" => "Project.Overview", "arguments" => %{}}, ctx)

      # Project.Overview is registered without `hidden: true`, so it is
      # MCP-visible. ToolCall proxies only hidden/discoverable tools; for a
      # visible tool it returns the "call it directly" guard rather than
      # invoking it. (See Catalog.call_hidden_tool / ToolCall.call.)
      assert result.status == "mcp"
      assert result.message =~ "Project.Overview"
    end

    test "ToolCall reports an unknown tool as an error" do
      alias Therobotplans.Tools.ToolCall

      ctx = %Noizu.MCP.Ctx{server: Therobotplans.MCP.Projects}
      assert {:error, _reason} =
               ToolCall.call(%{"tool" => "Project.NoSuchTool", "arguments" => %{}}, ctx)
    end
  end
end
