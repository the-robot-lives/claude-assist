# GitHub API Integration Implementation Plan
## NoizuPromptLingo Project

**Status:** Proposed Design  
**Date:** 2026-06-21  
**Scope:** Integrate `noizu_github` ~0.5.0 with GitHub token/repo entities, expose via MCP server (`github.` subdomain) + REST endpoints + sidebar browser page.

---

## Executive Summary

- Add `noizu_github` hex dependency (`~> 0.5.0`) and minimal config placeholder
- Create `NoizuPromptLingua.Github.Client` wrapper that resolves repos enforces ACL via `can_access?/3`, then calls GitHub API with mapped tokens
- Add helper `get_repo/2` to `NoizuPromptLingua.Github` to load a single repo by UUID or full_name within an org
- Build MCP domain server under `domains/github/` with tools for repos, branches, PRs, issues, comments
- Wire MCP server to router (`github.` host), MCPServers catalog, root aggregator, and application supervisor
- Create non-admin REST controller under `/api/v1/organizations/:org_id/github/` for frontend operations (read/write)
- Add frontend: app-nav entry (GitHub icon: `CodeBracketIcon`), api.ts methods, and 3 org-scoped pages (repo list, repo detail, PR detail)
- **Decision point:** MCP tools accept explicit `caller_user_id` input (matching existing pattern where `_ctx` provides no identity)

---

## Phase 1: Foundation (Client + Repo Helper)

### File: `backend/lib/noizu_prompt_lingua/mix.exs`

**Add to deps list:**

```elixir
{:noizu_github, "~> 0.5.0"},
```

**Location:** In `deps/0` function, after existing noizu deps (around line 93, after `{:noizu_mcp, "~> 0.1.3"}`)

**After changes:** Run `mix deps.get`

---

### File: `backend/config/dev.exs` (and `test.exs`, `prod.exs`)

**Add minimal config placeholder:**

```elixir
# GitHub API client — token passed per-call via options[:token]
config :noizu_github, NoizuLabs.Github.Config, 
  api_key: nil,  # Placeholder; we always pass options[:token] from mapped repo tokens
  owner: nil,
  repo: nil
```

**Location:** Near other `config :noizu_*` entries (after `config :noizu_sendgrid` around line 26)

---

### File: `backend/lib/noizu_prompt_lingua/entities/github.ex`

**Goal:** Add `get_repo/2` helper and augment with Client wrapper module

**Change 1: Add `get_repo/2` function (after `list_repos/1`, around line 97):**

```elixir
@doc """
Get a single repo by UUID or repo_full_name within an organization.
Preloads the mapped token. Returns nil if not found.
"""
def get_repo(organization_id, repo_id_or_full_name) do
  case Ecto.UUID.cast(repo_id_or_full_name) do
    {:ok, uuid} ->
      RepoSchema
      |> where([r], r.organization_id == ^organization_id and r.id == ^uuid)
      |> preload([:token])
      |> Repo.one()

    :error ->
      RepoSchema
      |> where([r], r.organization_id == ^organization_id and r.repo_full_name == ^repo_id_or_full_name)
      |> preload([:token])
      |> Repo.one()
  end
end
```

**Change 2: Add `RepoSchema` alias at top (after `MembershipSchema` alias):**

```elixir
alias NoizuPromptLingua.Schema.GithubRepo, as: RepoSchema
```

**Change 3: Append Client module at bottom (after `role_group_id/1`):**

```elixir
defmodule NoizuPromptLingua.Github.Client do
  @moduledoc """
  GitHub API client wrapper that enforces repo ACL checks and manages token mapping.

  All public functions accept:
    - `caller_user_id`: the user requesting the operation (for ACL)
    - `org_id`: the organization UUID (optional for some read operations, but enforced)
    - `repo_ref`: either the repo UUID or `repo_full_name` ("owner/name")
    - `opts`: keyword list for additional parameters (pagination, filters, etc.)

  Returns:
    - `{:ok, result}` on success (result is a map of GitHub API data)
    - `{:error, :forbidden}` if `can_access?/3` denies the operation
    - `{:error, {:github, status, body}}` if GitHub API returns non-2xx
    - `{:error, :repo_not_found}` if repo cannot be resolved or has no token
  """

  alias NoizuPromptLingua.Schema.GithubRepo
  alias Noizu.Github.Api.{Repos, Pulls, Issues, Git}

  @type repo_ref :: String.t() | Ecto.UUID.t()

  # ── Helper: resolve and authorize ─────────────────────────────────────────

  defp resolve_repo(call_user_id, org_id, repo_ref, acl_level) do
    case NoizuPromptLingua.Github.get_repo(org_id, repo_ref) do
      nil -> {:error, :repo_not_found}
      %GithubRepo{token: nil} -> {:error, :token_not_mapped}
      repo ->
        if NoizuPromptLingua.Github.can_access?(call_user_id, repo, acl_level) do
          {:ok, repo}
        else
          {:error, :forbidden}
        end
    end
  end

  defp split_repo_full_name(full_name) when is_binary(full_name) do
    case String.split(full_name, "/", parts: 2) do
      [owner, name] -> {:ok, owner, name}
      _ -> {:error, :invalid_repo_full_name}
    end
  end

  defp build_opts(repo, extra_opts \\ []) do
    {:ok, owner, name} = split_repo_full_name(repo.repo_full_name)
    [token: repo.token.token, owner: owner, repo: name] ++ extra_opts
  end

  defp normalize_github_result(result) do
    case result do
      {:ok, struct} when is_struct(struct) -> {:ok, struct_to_map(struct)}
      {:ok, %{items: items, links: links} = map} when is_map(map) ->
        {:ok, %{items: Enum.map(items, &struct_to_map/1), links: links}}
      {:ok, map} when is_map(map) -> {:ok, struct_to_map(map)}
      {:error, %Finch.Response{status: status, body: body}} ->
        {:error, {:github, status, body}}
      _ -> result
    end
  end

  defp struct_to_map(struct) when is_struct(struct) do
    Map.from_struct(struct)
  end
  defp struct_to_map(other), do: other

  # ── Repos (organization-scoped) ───────────────────────────────────────────

  @doc """
  List repos for an organization that the caller has read access to.
  This queries our local DB, not GitHub API.
  """
  def list_repos(call_user_id, org_id) do
    repos = NoizuPromptLingua.Github.list_repos(org_id)
    filtered = Enum.filter(repos, fn repo ->
      NoizuPromptLingua.Github.can_access?(call_user_id, repo, :read)
    end)
    {:ok,
      %{
        count: length(filtered),
        repos:
          Enum.map(filtered, fn repo ->
            repo
            |> struct_to_map()
            |> Map.put(:token_preview, mask_token(repo.token))
          end)
      }
    }
  end

  defp mask_token(nil), do: nil
  defp mask_token(token) when is_binary(token) do
    len = byte_size(token)
    if len <= 4, do: String.duplicate("•", len), else: String.slice(token, 0, 4) <> String.duplicate("•", len - 4)
  end

  # ── Branches ───────────────────────────────────────────────────────────────

  @doc """
  List branches for a repo. ACL: read.
  """
  def list_branches(call_user_id, org_id, repo_ref, opts \\ []) do
    with {:ok, repo} <- resolve_repo(call_user_id, org_id, repo_ref, :read),
         github_opts = build_opts(repo, Keyword.take(opts, [:page, :per_page])),
         {:ok, result} <- normalize_github_result(Repos.list_branches(github_opts)) do
      {:ok, result}
    end
  end

  @doc """
  Get a specific branch. ACL: read.
  """
  def get_branch(call_user_id, org_id, repo_ref, branch_name, opts \\ []) do
    with {:ok, repo} <- resolve_repo(call_user_id, org_id, repo_ref, :read),
         github_opts = build_opts(repo),
         {:ok, result} <- normalize_github_result(Repos.get_branch(branch_name, github_opts)) do
      {:ok, result}
    end
  end

  @doc """
  Create a branch from a commit SHA. ACL: write.
  Ref format is `refs/heads/<branch_name>`.
  """
  def create_branch(call_user_id, org_id, repo_ref, branch_name, from_sha, opts \\ []) do
    with {:ok, repo} <- resolve_repo(call_user_id, org_id, repo_ref, :write),
         ref = "refs/heads/#{branch_name}",
         github_opts = build_opts(repo),
         body = %{ref: ref, sha: from_sha},
         {:ok, result} <- normalize_github_result(Git.create_ref(body, github_opts)) do
      {:ok, result}
    end
  end

  # ── Pull Requests ─────────────────────────────────────────────────────────

  @doc """
  List pull requests for a repo. ACL: read.
  """
  def list_pulls(call_user_id, org_id, repo_ref, opts \\ []) do
    with {:ok, repo} <- resolve_repo(call_user_id, org_id, repo_ref, :read),
         github_opts = build_opts(repo, Keyword.take(opts, [:state, :head, :base, :sort, :direction, :page, :per_page])),
         {:ok, result} <- normalize_github_result(Pulls.list(github_opts)) do
      {:ok, result}
    end
  end

  @doc """
  Get a specific pull request. ACL: read.
  """
  def get_pull(call_user_id, org_id, repo_ref, pull_number, opts \\ []) do
    with {:ok, repo} <- resolve_repo(call_user_id, org_id, repo_ref, :read),
         github_opts = build_opts(repo),
         {:ok, result} <- normalize_github_result(Pulls.get(pull_number, github_opts)) do
      {:ok, result}
    end
  end

  @doc """
  Create a pull request. ACL: write.
  """
  def create_pull(call_user_id, org_id, repo_ref, body, opts \\ []) do
    with {:ok, repo} <- resolve_repo(call_user_id, org_id, repo_ref, :write),
         github_opts = build_opts(repo),
         {:ok, result} <- normalize_github_result(Pulls.create(body, github_opts)) do
      {:ok, result}
    end
  end

  @doc """
  Merge a pull request. ACL: write.
  """
  def merge_pull(call_user_id, org_id, repo_ref, pull_number, body, opts \\ []) do
    with {:ok, repo} <- resolve_repo(call_user_id, org_id, repo_ref, :write),
         github_opts = build_opts(repo),
         {:ok, result} <- normalize_github_result(Pulls.merge(pull_number, body, github_opts)) do
      {:ok, result}
    end
  end

  @doc """
  List comments on a pull request. ACL: read.
  """
  def list_pull_comments(call_user_id, org_id, repo_ref, pull_number, opts \\ []) do
    with {:ok, repo} <- resolve_repo(call_user_id, org_id, repo_ref, :read),
         github_opts = build_opts(repo, Keyword.take(opts, [:page, :per_page])),
         {:ok, result} <- normalize_github_result(Pulls.list_comments(pull_number, github_opts)) do
      {:ok, result}
    end
  end

  @doc """
  Create a comment on a pull request. ACL: write.
  """
  def comment_pull(call_user_id, org_id, repo_ref, pull_number, body) do
    with {:ok, repo} <- resolve_repo(call_user_id, org_id, repo_ref, :write),
         github_opts = build_opts(repo),
         {:ok, result} <- normalize_github_result(Pulls.create_review_comment(pull_number, body, github_opts)) do
      {:ok, result}
    end
  end

  # ── Issues ───────────────────────────────────────────────────────────────

  @doc """
  List issues for a repo. ACL: read.
  Note: `list_for_repo/1` returns issues AND pull requests by default.
  Pass state/filters to differentiate.
  """
  def list_issues(call_user_id, org_id, repo_ref, opts \\ []) do
    with {:ok, repo} <- resolve_repo(call_user_id, org_id, repo_ref, :read),
         github_opts = build_opts(repo, Keyword.take(opts, [:state, :assignee, :creator, :labels, :sort, :direction, :page, :per_page])),
         {:ok, result} <- normalize_github_result(Issues.list_for_repo(github_opts)) do
      {:ok, result}
    end
  end

  @doc """
  Get a specific issue. ACL: read.
  """
  def get_issue(call_user_id, org_id, repo_ref, issue_number, opts \\ []) do
    with {:ok, repo} <- resolve_repo(call_user_id, org_id, repo_ref, :read),
         github_opts = build_opts(repo),
         {:ok, result} <- normalize_github_result(Issues.get(issue_number, github_opts)) do
      {:ok, result}
    end
  end

  @doc """
  Create an issue. ACL: write.
  """
  def create_issue(call_user_id, org_id, repo_ref, body) do
    with {:ok, repo} <- resolve_repo(call_user_id, org_id, repo_ref, :write),
         github_opts = build_opts(repo),
         {:ok, result} <- normalize_github_result(Issues.create(body, github_opts)) do
      {:ok, result}
    end
  end

  @doc """
  Create a comment on an issue. ACL: write.
  """
  def comment_issue(call_user_id, org_id, repo_ref, issue_number, body) do
    with {:ok, repo} <- resolve_repo(call_user_id, org_id, repo_ref, :write),
         github_opts = build_opts(repo),
         {:ok, result} <- normalize_github_result(Issues.create_comment(issue_number, body, github_opts)) do
      {:ok, result}
    end
  end

  defp list_comments_for_repo(repo_ref, opts \\ []) do
    with {:ok, _repo} <- resolve_repo(nil, nil, repo_ref, :read),  # No caller check for utility
         github_opts = build_opts(_repo, Keyword.take(opts, [:page, :per_page])),
         {:ok, result} <- normalize_github_result(Issues.list_comments_for_repo(github_opts)) do
      {:ok, result}
    end
  end
end
```

**Note:** Add necessary aliases at module top (`alias Ecto.Query` if not present) and import `Ecto.Query`.

---

## Phase 2: MCP Domain Server (+ Router Wiring)

### Directory Structure

Create:
- `backend/lib/noizu_prompt_lingua/domains/github/`
- `backend/lib/noizu_prompt_lingua/domains/github/tools/`

---

### File: `backend/lib/noizu_prompt_lingua/domains/github/mcp.ex`

```elixir
defmodule NoizuPromptLingua.Domains.Github.MCP do
  @moduledoc """
  GitHub integration MCP server. Provides tools to browse repositories, manage
  branches, and interact with pull requests and issues. All operations are scoped
  to an organization and enforce repo ACL via the can_access/3 checks.
  """
  use Noizu.MCP.Server,
    name: "tobor_github",
    version: "0.1.0",
    instructions:
      "GitHub operations within an organization. Use the caller_user_id parameter " <>
        "to identify the requesting user; all repo access is verified against its ACL. " <>
        "Pass repo as either the UUID or the full repo_full_name (e.g. \"owner/name\")."

  # Discovery
  tool NoizuPromptLingua.Domains.Github.Tools.Overview, category: "GitHub"

  # Repos
  tool NoizuPromptLingua.Domains.Github.Tools.RepoList, category: "GitHub"

  # Branches
  tool NoizuPromptLingua.Domains.Github.Tools.BranchList, category: "GitHub"
  tool NoizuPromptLingua.Domains.Github.Tools.BranchGet, category: "GitHub"
  tool NoizuPromptLingua.Domains.Github.Tools.BranchCreate, category: "GitHub"

  # Pull Requests
  tool NoizuPromptLingua.Domains.Github.Tools.PullList, category: "GitHub.Pulls"
  tool NoizuPromptLingua.Domains.Github.Tools.PullGet, category: "GitHub.Pulls"
  tool NoizuPromptLingua.Domains.Github.Tools.PullCreate, category: "GitHub.Pulls"
  tool NoizuPromptLingua.Domains.Github.Tools.PullMerge, category: "GitHub.Pulls"
  tool NoizuPromptLingua.Domains.Github.Tools.PullComment, category: "GitHub.Pulls"

  # Issues
  tool NoizuPromptLingua.Domains.Github.Tools.IssueList, category: "GitHub.Issues"
  tool NoizuPromptLingua.Domains.Github.Tools.IssueGet, category: "GitHub.Issues"
  tool NoizuPromptLingua.Domains.Github.Tools.IssueCreate, category: "GitHub.Issues"
  tool NoizuPromptLingua.Domains.Github.Tools.IssueComment, category: "GitHub.Issues"

  # Discovery tools
  tool NoizuPromptLingua.Tools.ToolSummary, category: "Discovery"
  tool NoizuPromptLingua.Tools.ToolSearch, category: "Discovery"
  tool NoizuPromptLingua.Tools.ToolDefinition, category: "Discovery"
  tool NoizuPromptLingua.Tools.ToolCall, category: "Discovery"
  tool NoizuPromptLingua.Tools.ToolHelp, category: "Discovery"
end
```

---

### File: `backend/lib/noizu_prompt_lingua/domains/github/tools/overview.ex`

```elixir
defmodule NoizuPromptLingua.Domains.Github.Tools.Overview do
  use Noizu.MCP.Server.Tool,
    name: "Github.Overview",
    description: "Overview of available GitHub tools and permissions model.",
    hidden: false,
    category: "GitHub"

  @impl true
  def call(_args, _ctx) do
    {:ok, %{
      description: "GitHub integration provides read/write operations on org-scoped repos.",
      acl_model: """
      Each repo has a default_acl (private|org_read|org_write). Additionally,
      group grants (scoped_memberships with member_type='group') can grant read
      or write access to specific groups. A user gets access if they:
        1. Have org membership AND default_acl permits the requested level, OR
        2. Are a member of a group that's been granted the requested level.
      """,
      tools: [
        %{category: "Repos", tools: ["RepoList"]},
        %{category: "Branches", tools: ["BranchList", "BranchGet", "BranchCreate"]},
        %{category: "Pull Requests", tools: ["PullList", "PullGet", "PullCreate", "PullMerge", "PullComment"]},
        %{category: "Issues", tools: ["IssueList", "IssueGet", "IssueCreate", "IssueComment"]}
      ],
      required_inputs: [
        %{name: "caller_user_id", description: "UUID of the requesting user", required: true},
        %{name: "organization", description: "Organization slug or UUID", required: true},
        %{name: "repo", description: "Repo UUID or full_name (owner/name)", required: true}
      ]
    }}
  end
end
```

---

### File: `backend/lib/noizu_prompt_lingua/domains/github/tools/repo_list.ex`

```elixir
defmodule NoizuPromptLingua.Domains.Github.Tools.RepoList do
  use Noizu.MCP.Server.Tool,
    name: "Github.RepoList",
    description: "List repositories the caller has read access to within an organization. Reads from local DB.",
    hidden: true,
    category: "GitHub",
    annotations: [read_only_hint: true]

  alias NoizuPromptLingua.MCP.{Args, Resolve}
  alias NoizuPromptLingua.Github.Client

  input do
    field :caller_user_id, :string, description: "UUID of the requesting user"
    field :organization, :string, description: "Organization slug or UUID"
  end

  @impl true
  def call(args, _ctx) do
    caller_user_id = Args.get(args, :caller_user_id)
    org_id = Resolve.organization_id(Args.get(args, :organization))

    case {caller_user_id, org_id} do
      {nil, _} -> {:error, :caller_user_id_required}
      {_, nil} -> {:error, :organization_not_found}
      {user_id, org} when is_binary(user_id) and is_binary(org) ->
        with {:ok, user_uuid} <- parse_uuid(user_id),
             {:ok, result} <- Client.list_repos(user_uuid, org) do
          {:ok, result}
        else
          :error -> {:error, :invalid_uuid}
          error -> error
        end
    end
  end

  defp parse_uuid(str) do
    case Ecto.UUID.cast(str) do
      {:ok, uuid} -> {:ok, uuid}
      :error -> :error
    end
  end
end
```

---

### File: `backend/lib/noizu_prompt_lingua/domains/github/tools/branch_create.ex`

```elixir
defmodule NoizuPromptLingua.Domains.Github.Tools.BranchCreate do
  use Noizu.MCP.Server.Tool,
    name: "Github.BranchCreate",
    description: "Create a new branch from a commit SHA in a repo. Requires write access.",
    hidden: false,
    category: "GitHub"

  alias NoizuPromptLingua.MCP.{Args, Resolve}
  alias NoizuPromptLingua.Github.Client

  input do
    field :caller_user_id, :string, description: "UUID of the requesting user", required: true
    field :organization, :string, description: "Organization slug or UUID", required: true
    field :repo, :string, description: "Repo UUID or full_name (owner/name)", required: true
    field :branch_name, :string, description: "Name of the branch to create", required: true
    field :from_sha, :string, description: "Commit SHA to branch from", required: true
  end

  @impl true
  def call(args, _ctx) do
    caller_user_id = Args.get(args, :caller_user_id)
    org_id = Resolve.organization_id(Args.get(args, :organization))
    repo_ref = Args.get(args, :repo)
    branch_name = Args.get(args, :branch_name)
    from_sha = Args.get(args, :from_sha)

    with {:ok, user_uuid} <- parse_uuid(caller_user_id),
         {:ok, org} <- ensure_org(org_id),
         {:ok, result} <- Client.create_branch(user_uuid, org, repo_ref, branch_name, from_sha) do
      {:ok, result}
    else
      :error -> {:error, :invalid_uuid}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_uuid(str) do
    case Ecto.UUID.cast(str) do
      {:ok, uuid} -> {:ok, uuid}
      :error -> :error
    end
  end

  defp ensure_org(nil), do: {:error, :organization_not_found}
  defp ensure_org(org_id), do: {:ok, org_id}
end
```

**Note:** Create remaining tool files following this pattern. The signature patterns are:

- **BranchList/Get:** `list_branches/4`, `get_branch/5` — ACL read
- **PullList/Get/Create/Merge:** `list_pulls/4`, `get_pull/5`, `create_pull/4`, `merge_pull/5` — ACL read/write as appropriate
- **PullComment:** `comment_pull/4` — ACL write
- **IssueList/Get/Create:** `list_issues/4`, `get_issue/5`, `create_issue/4` — ACL read/write
- **IssueComment:** `comment_issue/4` — ACL write

Each tool follows the same structure: parse UUIDs, resolve org, call Client, normalize errors.

---

### File: `backend/lib/noizu_prompt_lingua/mcp.ex`

**Add to tool registrations (after Session tools, before Discovery):**

```elixir
# Tools are registered on the MCP server; do NOT add duplicate tool entries here
# Domain tools are NOT duplicated on root aggregator — only the domain server is mounted
# at its subdomain. Keep this server for cross-domain utilities (NPL, Discovery) only.
```

**Actual change:** The root aggregator already has NPL and Discovery. Domain tools ( Organizations, Projects, Sessions, and soon GitHub ) live in their subdomain servers. The root aggregator's tools are duplicated from domain servers only if needed for a unified cross-domain listing — but `MCPServers` already lists each subdomain separately. **No changes needed to root aggregator.**

---

### File: `backend/lib/noizu_prompt_lingua/mcp_servers.ex`

**Add to `@servers` list (after "wiki", before closing bracket):**

```elixir
%{id: "github", label: "GitHub", required: false, desc: "GitHub integration — repos, branches, PRs, issues"},
```

---

### File: `backend/lib/noizu_prompt_lingua_web/router.ex`

**Add MCP subdomain scope (after the wiki scope, around line 294):**

```elixir
scope "/", host: "github." do
  forward "/mcp", Noizu.MCP.Transport.StreamableHTTP.Plug,
    NoizuPromptLinguaWeb.MCPConfig.plug_opts(NoizuPromptLingua.Domains.Github.MCP)
end
```

---

### File: `backend/lib/noizu_prompt_lingua/application.ex`

**Add to children list (after `NoizuPromptLingua.Domains.Wiki.MCP`, before Endpoint, around line 53):**

```elixir
NoizuPromptLingua.Domains.Github.MCP,
```

**Note:** `noizu_github` starts its own Finch pool via its Application module when added to deps — no manual child registration needed.

---

## Phase 3: REST Controller + Routes

### File: `backend/lib/noizu_prompt_lingua_web/controllers/github_controller.ex`

**Create new controller:**

```elixir
defmodule NoizuPromptLinguaWeb.GithubController do
  use NoizuPromptLinguaWeb, :controller

  import Ecto.Query
  alias NoizuPromptLingua.Github.Client
  alias NoizuPromptLingua.{Organizations, Repo}

  # ── Helpers ───────────────────────────────────────────────────────────────

  defp get_user_id(conn) do
    case NoizuPromptLingua.Guardian.Plug.current_resource(conn) do
      %NoizuPromptLingua.Users.Sessions.UserSession{user: {:ref, _, id}} -> id
      %NoizuPromptLingua.Users.Sessions.UserSession{user: %{id: id}} -> id
      _ -> nil
    end
  end

  defp resolve_org_id(org_ref) do
    case Organizations.resolve_org_id(org_ref) do
      {:ok, id} -> id
      _ -> nil
    end
  end

  defp handle_error(conn, err) do
    case err do
      {:error, :repo_not_found} -> conn |> put_status(:not_found) |> json(%{error: "Repository not found"})
      {:error, :token_not_mapped} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "No token mapped to this repository"})
      {:error, :forbidden} -> conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
      {:error, :invalid_uuid} -> conn |> put_status(:bad_request) |> json(%{error: "Invalid UUID format"})
      {:error, :invalid_repo_full_name} -> conn |> put_status(:bad_request) |> json(%{error: "Invalid repo_full_name (expected owner/name)"})
      {:error, {:github, status, body}} ->
        conn
        |> put_status(status)
        |> json(%{error: "GitHub API error", status: status, github_error: body})
      _ -> conn |> put_status(:internal_server_error) |> json(%{error: "Unknown error"})
    end
  end

  # ── Repos (read from DB) ───────────────────────────────────────────────

  def index(conn, %{"org_id" => org_ref}) do
    user_id = get_user_id(conn)
    org_id = resolve_org_id(org_ref)

    case {user_id, org_id} do
      {nil, _} -> conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized"})
      {_, nil} -> conn |> put_status(:not_found) |> json(%{error: "Organization not found"})
      {user, org} ->
        case Client.list_repos(user, org) do
          {:ok, result} -> conn |> put_status(:ok) |> json(result)
          error -> handle_error(conn, error)
        end
    end
  end

  # ── Pull Requests ─────────────────────────────────────────────────────────

  def list_pulls(conn, %{"org_id" => org_ref, "repo_id" => repo_ref} = params) do
    user_id = get_user_id(conn)
    org_id = resolve_org_id(org_ref)

    handle_github_call(conn, user_id, org_id, repo_ref, fn resolved_repo ->
      opts = Keyword.take(params, ["state", "head", "base", "sort", "direction", "page", "per_page"])
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      Client.list_pulls(user_id, org_id, resolved_repo.id, opts)
    end)
  end

  def get_pull(conn, %{"org_id" => org_ref, "repo_id" => repo_ref, "pull_number" => pull_number}) do
    user_id = get_user_id(conn)
    org_id = resolve_org_id(org_ref)

    handle_github_call(conn, user_id, org_id, repo_ref, fn resolved_repo ->
      Client.get_pull(user_id, org_id, resolved_repo.id, String.to_integer(pull_number))
    end)
  end

  def create_pull(conn, %{"org_id" => org_ref, "repo_id" => repo_ref, "pull" => pull_params}) do
    user_id = get_user_id(conn)
    org_id = resolve_org_id(org_ref)
    body = Map.take(pull_params, ["title", "body", "head", "base"])

    handle_github_call(conn, user_id, org_id, repo_ref, fn resolved_repo ->
      Client.create_pull(user_id, org_id, resolved_repo.id, body)
    end)
  end

  def merge_pull(conn, %{"org_id" => org_ref, "repo_id" => repo_ref, "pull_number" => pull_number, "pull" => merge_params}) do
    user_id = get_user_id(conn)
    org_id = resolve_org_id(org_ref)
    body = Map.take(merge_params, ["commit_title", "commit_message", "merge_method"])

    handle_github_call(conn, user_id, org_id, repo_ref, fn resolved_repo ->
      Client.merge_pull(user_id, org_id, resolved_repo.id, String.to_integer(pull_number), body)
    end)
  end

  def list_pull_comments(conn, %{"org_id" => org_ref, "repo_id" => repo_ref, "pull_number" => pull_number} = params) do
    user_id = get_user_id(conn)
    org_id = resolve_org_id(org_ref)

    handle_github_call(conn, user_id, org_id, repo_ref, fn resolved_repo ->
      opts = Keyword.take(params, ["page", "per_page"]) |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      Client.list_pull_comments(user_id, org_id, resolved_repo.id, String.to_integer(pull_number), opts)
    end)
  end

  def create_pull_comment(conn, %{"org_id" => org_ref, "repo_id" => repo_ref, "pull_number" => pull_number, "comment" => comment_params}) do
    user_id = get_user_id(conn)
    org_id = resolve_org_id(org_ref)
    body = Map.take(comment_params, ["body"])

    handle_github_call(conn, user_id, org_id, repo_ref, fn resolved_repo ->
      Client.comment_pull(user_id, org_id, resolved_repo.id, String.to_integer(pull_number), body)
    end)
  end

  # ── Issues ───────────────────────────────────────────────────────────────

  def list_issues(conn, %{"org_id" => org_ref, "repo_id" => repo_ref} = params) do
    user_id = get_user_id(conn)
    org_id = resolve_org_id(org_ref)

    handle_github_call(conn, user_id, org_id, repo_ref, fn resolved_repo ->
      opts = Keyword.take(params, ["state", "assignee", "creator", "labels", "sort", "direction", "page", "per_page"])
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      Client.list_issues(user_id, org_id, resolved_repo.id, opts)
    end)
  end

  def get_issue(conn, %{"org_id" => org_ref, "repo_id" => repo_ref, "issue_number" => issue_number}) do
    user_id = get_user_id(conn)
    org_id = resolve_org_id(org_ref)

    handle_github_call(conn, user_id, org_id, repo_ref, fn resolved_repo ->
      Client.get_issue(user_id, org_id, resolved_repo.id, String.to_integer(issue_number))
    end)
  end

  def create_issue(conn, %{"org_id" => org_ref, "repo_id" => repo_ref, "issue" => issue_params}) do
    user_id = get_user_id(conn)
    org_id = resolve_org_id(org_ref)
    body = Map.take(issue_params, ["title", "body", "labels", "assignees"])

    handle_github_call(conn, user_id, org_id, repo_ref, fn resolved_repo ->
      Client.create_issue(user_id, org_id, resolved_repo.id, body)
    end)
  end

  def create_issue_comment(conn, %{"org_id" => org_ref, "repo_id" => repo_ref, "issue_number" => issue_number, "comment" => comment_params}) do
    user_id = get_user_id(conn)
    org_id = resolve_org_id(org_ref)
    body = Map.take(comment_params, ["body"])

    handle_github_call(conn, user_id, org_id, repo_ref, fn resolved_repo ->
      Client.comment_issue(user_id, org_id, resolved_repo.id, String.to_integer(issue_number), body)
    end)
  end

  # ── Branches ─────────────────────────────────────────────────────────────

  def list_branches(conn, %{"org_id" => org_ref, "repo_id" => repo_ref} = params) do
    user_id = get_user_id(conn)
    org_id = resolve_org_id(org_ref)

    handle_github_call(conn, user_id, org_id, repo_ref, fn resolved_repo ->
      opts = Keyword.take(params, ["page", "per_page"]) |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      Client.list_branches(user_id, org_id, resolved_repo.id, opts)
    end)
  end

  def create_branch(conn, %{"org_id" => org_ref, "repo_id" => repo_ref, "branch" => branch_params}) do
    user_id = get_user_id(conn)
    org_id = resolve_org_id(org_ref)
    branch_name = branch_params["name"]
    from_sha = branch_params["from_sha"]

    handle_github_call(conn, user_id, org_id, repo_ref, fn resolved_repo ->
      Client.create_branch(user_id, org_id, resolved_repo.id, branch_name, from_sha)
    end)
  end

  # ── Helper: dispatch with repo resolution ───────────────────────────────

  defp handle_github_call(conn, user_id, org_id, repo_ref, callback) do
    case {user_id, org_id} do
      {nil, _} -> conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized"})
      {_, nil} -> conn |> put_status(:not_found) |> json(%{error: "Organization not found"})
      {user, org} ->
        case NoizuPromptLingua.Github.get_repo(org, repo_ref) do
          nil -> conn |> put_status(:not_found) |> json(%{error: "Repository not found"})
          repo ->
            case callback.(repo) do
              {:ok, result} -> conn |> put_status(:ok) |> json(result)
              error -> handle_error(conn, error)
            end
        end
    end
  end
end
```

---

### File: `backend/lib/noizu_prompt_lingua_web/router.ex`

**Add GitHub REST scope (after the wiki scope block ends, around line 340):**

```elixir
# GitHub: org-scoped read/write operations (authenticated, org-member)
scope "/api/v1/organizations/:org_id/github", NoizuPromptLinguaWeb do
  pipe_through [:api, :authenticated]

  # Repos (read from our DB)
  get "/", GithubController, :index

  # Repos scoped operations (GitHub API)
  scope "/repos/:repo_id" do
    # Pull Requests
    get "/pulls", GithubController, :list_pulls
    get "/pulls/:pull_number", GithubController, :get_pull
    post "/pulls", GithubController, :create_pull
    put "/pulls/:pull_number/merge", GithubController, :merge_pull
    get "/pulls/:pull_number/comments", GithubController, :list_pull_comments
    post "/pulls/:pull_number/comments", GithubController, :create_pull_comment

    # Issues
    get "/issues", GithubController, :list_issues
    get "/issues/:issue_number", GithubController, :get_issue
    post "/issues", GithubController, :create_issue
    post "/issues/:issue_number/comments", GithubController, :create_issue_comment

    # Branches
    get "/branches", GithubController, :list_branches
    post "/branches", GithubController, :create_branch
  end
end
```

---

## Phase 4: Frontend Integration

### File: `frontend/src/components/app-nav.tsx`

**Add to NAV array (before Authz entry, around line 43):**

```elixir
{ href: '/github', Icon: CodeBracketIcon, label: 'GitHub', orgScoped: true },
```

**Import CodeBracketIcon at top (add to import list, around line 8):**

```typescript
CodeBracketIcon,
```

---

### File: `frontend/src/lib/api.ts`

**Add types (after existing type definitions, around line 72):**

```typescript
export interface GithubRepoSummary {
  id: string;
  repo_full_name: string;
  default_acl: "private" | "org_read" | "org_write";
  token_preview: string | null;
  inserted_at: string;
}

export interface GithubPullRequest {
  id: number;
  number: number;
  title: string;
  state: "open" | "closed";
  user: { login: string };
  head: { ref: string; sha: string };
  base: { ref: string };
  created_at: string;
  updated_at: string;
}

export interface GithubIssue {
  id: number;
  number: number;
  title: string;
  state: "open" | "closed";
  user: { login: string };
  assignees: Array<{ login: string }>;
  labels: Array<{ name: string }>;
  created_at: string;
  updated_at: string;
}

export interface GithubComment {
  id: number;
  user: { login: string };
  body: string;
  created_at: string;
  updated_at: string;
}
```

**Add API methods to `api` object (after admin github methods, around line 816):**

```typescript
// GitHub: org-scoped operations
listGithubRepos(orgId: string) {
  return request<{ repos: GithubRepoSummary[] }>(`/api/v1/organizations/${orgId}/github`);
},

listGithubPulls(orgId: string, repoId: string, opts?: { state?: "open" | "closed"; page?: number }) {
  const qs = new URLSearchParams(opts as Record<string, string>);
  return request<{ items: GithubPullRequest[]; count: number }>(
    `/api/v1/organizations/${orgId}/github/repos/${repoId}/pulls${qs.toString() ? `?${qs.toString()}` : ""}`
  );
},

getGithubPull(orgId: string, repoId: string, pullNumber: number) {
  return request<GithubPullRequest>(
    `/api/v1/organizations/${orgId}/github/repos/${repoId}/pulls/${pullNumber}`
  );
},

createGithubPull(orgId: string, repoId: string, data: { title: string; head: string; base: string; body?: string }) {
  return request<GithubPullRequest>(
    `/api/v1/organizations/${orgId}/github/repos/${repoId}/pulls`,
    { method: "POST", body: JSON.stringify({ pull: data }) }
  );
},

mergeGithubPull(orgId: string, repoId: string, pullNumber: number, data?: { commit_title?: string; merge_method?: "merge" | "squash" | "rebase" }) {
  return request<{ merged: boolean; message: string }>(
    `/api/v1/organizations/${orgId}/github/repos/${repoId}/pulls/${pullNumber}/merge`,
    { method: "PUT", body: JSON.stringify({ pull: data || {} }) }
  );
},

listGithubPullComments(orgId: string, repoId: string, pullNumber: number, opts?: { page?: number }) {
  const qs = new URLSearchParams(opts as Record<string, string>);
  return request<{ items: GithubComment[]; count: number }>(
    `/api/v1/organizations/${orgId}/github/repos/${repoId}/pulls/${pullNumber}/comments${qs.toString() ? `?${qs.toString()}` : ""}`
  );
},

createGithubPullComment(orgId: string, repoId: string, pullNumber: number, body: string) {
  return request<GithubComment>(
    `/api/v1/organizations/${orgId}/github/repos/${repoId}/pulls/${pullNumber}/comments`,
    { method: "POST", body: JSON.stringify({ comment: { body } }) }
  );
},

listGithubIssues(orgId: string, repoId: string, opts?: { state?: "open" | "closed"; page?: number }) {
  const qs = new URLSearchParams(opts as Record<string, string>);
  return request<{ items: GithubIssue[]; count: number }>(
    `/api/v1/organizations/${orgId}/github/repos/${repoId}/issues${qs.toString() ? `?${qs.toString()}` : ""}`
  );
},

getGithubIssue(orgId: string, repoId: string, issueNumber: number) {
  return request<GithubIssue>(
    `/api/v1/organizations/${orgId}/github/repos/${repoId}/issues/${issueNumber}`
  );
},

createGithubIssue(orgId: string, repoId: string, data: { title: string; body?: string; labels?: string[]; assignees?: string[] }) {
  return request<GithubIssue>(
    `/api/v1/organizations/${orgId}/github/repos/${repoId}/issues`,
    { method: "POST", body: JSON.stringify({ issue: data }) }
  );
},

createGithubIssueComment(orgId: string, repoId: string, issueNumber: number, body: string) {
  return request<GithubComment>(
    `/api/v1/organizations/${orgId}/github/repos/${repoId}/issues/${issueNumber}/comments`,
    { method: "POST", body: JSON.stringify({ comment: { body } }) }
  );
},

listGithubBranches(orgId: string, repoId: string, opts?: { page?: number }) {
  const qs = new URLSearchParams(opts as Record<string, string>);
  return request<{ items: Array<{ name: string; commit: { sha: string } }> }>(
    `/api/v1/organizations/${orgId}/github/repos/${repoId}/branches${qs.toString() ? `?${qs.toString()}` : ""}`
  );
},

createGithubBranch(orgId: string, repoId: string, name: string, fromSha: string) {
  return request<{ ref: string; object: { sha: string } }>(
    `/api/v1/organizations/${orgId}/github/repos/${repoId}/branches`,
    { method: "POST", body: JSON.stringify({ branch: { name, from_sha: fromSha } }) }
  );
},
```

---

### File: `frontend/src/app/app/[orgId]/github/page.tsx`

**Create new repo list page:**

```typescript
'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { toast } from 'sonner';
import { useOrgId } from '@/context/org';
import { api, type GithubRepoSummary, GithubPullRequest, GithubIssue } from '@/lib/api';
import { CodeBracketIcon, PullRequestIcon, IssueOpenedIcon, PlusIcon } from '@heroicons/react/24/outline';

export default function GithubPage() {
  const { orgId, loading: orgLoading } = useOrgId();
  const [repos, setRepos] = useState<GithubRepoSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [repoPulls, setRepoPulls] = useState<Record<string, GithubPullRequest[]>>({});
  const [repoIssues, setRepoIssues] = useState<Record<string, GithubIssue[]>>({});

  useEffect(() => {
    if (!orgId) return;
    setLoading(true);
    api.listGithubRepos(orgId)
      .then((data) => {
        setRepos(data.repos || []);
        
        // Fetch open PRs/issues counts for each repo
        const pullPromises = data.repos.map(async (repo) => {
          try {
            const pulls = await api.listGithubPulls(orgId, repo.id, { state: 'open', page: 1 });
            return [repo.id, pulls.items || []];
          } catch {
            return [repo.id, []];
          }
        });
        
        const issuePromises = data.repos.map(async (repo) => {
          try {
            const issues = await api.listGithubIssues(orgId, repo.id, { state: 'open', page: 1 });
            return [repo.id, issues.items || []];
          } catch {
            return [repo.id, []];
          }
        });

        Promise.all([...pullPromises, ...issuePromises]).then((results) => {
          const pullMap: Record<string, GithubPullRequest[]> = {};
          const issueMap: Record<string, GithubIssue[]> = {};
          results.slice(0, results.length / 2).forEach(([id, items]) => { pullMap[id as string] = items as GithubPullRequest[]; });
          results.slice(results.length / 2).forEach(([id, items]) => { issueMap[id as string] = items as GithubIssue[]; });
          setRepoPulls(pullMap);
          setRepoIssues(issueMap);
        });
      })
      .catch(() => toast.error('Failed to load repositories'))
      .finally(() => setLoading(false));
  }, [orgId]);

  if (orgLoading || loading) return <div className="sg-loading-spinner" />;

  return (
    <div className="page-container">
      <header className="page-header">
        <h1>GitHub Repositories</h1>
      </header>

      {repos.length === 0 ? (
        <div className="empty-state">
          <CodeBracketIcon className="empty-state__icon" />
          <h2>No repositories configured</h2>
          <p>Ask an admin to add repositories to this organization.</p>
        </div>
      ) : (
        <div className="projects-grid">
          {repos.map((repo) => {
            const openPulls = repoPulls[repo.id]?.length ?? 0;
            const openIssues = repoIssues[repo.id]?.length ?? 0;
            
            return (
              <Link
                key={repo.id}
                href={`/app/${orgId}/github/${repo.id}`}
                className="project-card"
              >
                <div className="project-card__header">
                  <CodeBracketIcon className="project-card__icon" />
                  <h3 className="project-card__title">{repo.repo_full_name}</h3>
                </div>
                <div className="project-card__body">
                  <dl className="project-card__fields">
                    <div>
                      <dt>Default ACL</dt>
                      <dd>{repo.default_acl}</dd>
                    </div>
                    <div>
                      <dt>Open PRs</dt>
                      <dd>{openPulls}</dd>
                    </div>
                    <div>
                      <dt>Open Issues</dt>
                      <dd>{openIssues}</dd>
                    </div>
                  </dl>
                </div>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
```

---

### File: `frontend/src/app/app/[orgId]/github/[repoId]/page.tsx`

**Create repo detail page with PRs/Issues lists:**

```typescript
'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { toast } from 'sonner';
import { useOrgId, useParams } from '@/context/org'; // Note: adjust import path based on actual org context
import { api, type GithubRepoSummary, GithubPullRequest, GithubIssue } from '@/lib/api';
import { PullRequestIcon, IssueOpenedIcon, PlusIcon } from '@heroicons/react/24/outline';

interface RepoParams {
  orgId: string;
  repoId: string;
}

type Tab = 'pulls' | 'issues';

export default function GithubRepoPage() {
  const params = useParams<RepoParams>();
  const { orgId } = useOrgId();
  const repoId = params.repoId;
  
  const [tab, setTab] = useState<Tab>('pulls');
  const [repo, setRepo] = useState<GithubRepoSummary | null>(null);
  const [pulls, setPulls] = useState<GithubPullRequest[]>([]);
  const [issues, setIssues] = useState<GithubIssue[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!orgId || !repoId) return;
    setLoading(true);
    Promise.all([
      api.listGithubRepos(orgId).then(data => data.repos.find(r => r.id === repoId) || null),
      api.listGithubPulls(orgId, repoId, { state: 'open', page: 1 }).then(data => data.items || []),
      api.listGithubIssues(orgId, repoId, { state: 'open', page: 1 }).then(data => data.items || []),
    ])
      .then(([r, p, i]) => {
        setRepo(r);
        setPulls(p);
        setIssues(i);
      })
      .catch(() => toast.error('Failed to load repository'))
      .finally(() => setLoading(false));
  }, [orgId, repoId]);

  if (loading) return <div className="sg-loading-spinner" />;

  if (!repo) {
    return <div className="empty-state">Repository not found</div>;
  }

  return (
    <div className="page-container">
      <header className="page-header">
        <Link href={`/app/${orgId}/github`} className="page-header__back">← Back</Link>
        <h1>{repo.repo_full_name}</h1>
      </header>

      <div className="tabs">
        <button
          className={`tabs__tab${tab === 'pulls' ? ' is-active' : ''}`}
          onClick={() => setTab('pulls')}
        >
          <PullRequestIcon className="tabs__icon" />
          Pull Requests
        </button>
        <button
          className={`tabs__tab${tab === 'issues' ? ' is-active' : ''}`}
          onClick={() => setTab('issues')}
        >
          <IssueOpenedIcon className="tabs__icon" />
          Issues
        </button>
      </div>

      <div className="tabs__content">
        {tab === 'pulls' && <PullsList orgId={orgId} repoId={repoId} pulls={pulls} />}
        {tab === 'issues' && <IssuesList orgId={orgId} repoId={repoId} issues={issues} />}
      </div>
    </div>
  );
}

function PullsList({ orgId, repoId, pulls }: { orgId: string; repoId: string; pulls: GithubPullRequest[] }) {
  if (pulls.length === 0) {
    return <div className="empty-state">No open pull requests</div>;
  }

  return (
    <div className="list-group">
      {pulls.map((pr) => (
        <Link
          key={pr.id}
          href={`/app/${orgId}/github/${repoId}/pulls/${pr.number}`}
          className="list-group__item"
        >
          <PullRequestIcon className="list-group__icon" />
          <div className="list-group__content">
            <div className="list-group__title">#{pr.number} - {pr.title}</div>
            <div className="list-group__meta">
              by {pr.user.login} · {new Date(pr.created_at).toLocaleDateString()}
            </div>
            <div className="list-group__badge">{pr.head.ref} → {pr.base.ref}</div>
          </div>
        </Link>
      ))}
    </div>
  );
}

function IssuesList({ orgId, repoId, issues }: { orgId: string; repoId: string; issues: GithubIssue[] }) {
  if (issues.length === 0) {
    return <div className="empty-state">No open issues</div>;
  }

  return (
    <div className="list-group">
      {issues.map((issue) => (
        <Link
          key={issue.id}
          href={`/app/${orgId}/github/${repoId}/issues/${issue.number}`}
          className="list-group__item"
        >
          <IssueOpenedIcon className="list-group__icon" />
          <div className="list-group__content">
            <div className="list-group__title">#{issue.number} - {issue.title}</div>
            <div className="list-group__meta">
              by {issue.user.login} · {new Date(issue.created_at).toLocaleDateString()}
            </div>
            {issue.labels.length > 0 && (
              <div className="list-group__badges">
                {issue.labels.map(label => (
                  <span key={label.name} className="badge">{label.name}</span>
                ))}
              </div>
            )}
          </div>
        </Link>
      ))}
    </div>
  );
}
```

---

### File: `frontend/src/app/app/[orgId]/github/[repoId]/pulls/[pullNumber]/page.tsx`

**Create PR detail page with comments:**

```typescript
'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { toast } from 'sonner';
import { useOrgId } from '@/context/org';
import { api, type GithubPullRequest, GithubComment } from '@/lib/api';
import { PullRequestIcon, ChatBubbleLeftIcon } from '@heroicons/react/24/outline';

interface PullParams {
  orgId: string;
  repoId: string;
  pullNumber: string;
}

export default function GithubPullPage() {
  const params = useParams<PullParams>();
  const { orgId } = useOrgId();
  const repoId = params.repoId;
  const pullNumber = parseInt(params.pullNumber, 10);
  
  const [pull, setPull] = useState<GithubPullRequest | null>(null);
  const [comments, setComments] = useState<GithubComment[]>([]);
  const [loading, setLoading] = useState(true);
  const [commentBody, setCommentBody] = useState('');
  const [posting, setPosting] = useState(false);

  useEffect(() => {
    if (!orgId || !repoId || !pullNumber) return;
    setLoading(true);
    Promise.all([
      api.getGithubPull(orgId, repoId, pullNumber),
      api.listGithubPullComments(orgId, repoId, pullNumber, { page: 1 })
        .then(data => data.items || []),
    ])
      .then(([p, c]) => {
        setPull(p);
        setComments(c);
      })
      .catch(() => toast.error('Failed to load pull request'))
      .finally(() => setLoading(false));
  }, [orgId, repoId, pullNumber]);

  const postComment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!commentBody.trim()) return;
    setPosting(true);
    try {
      const newComment = await api.createGithubPullComment(orgId!, repoId!, pullNumber, commentBody.trim());
      setComments([...comments, newComment]);
      setCommentBody('');
      toast.success('Comment added');
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Failed to add comment');
    } finally {
      setPosting(false);
    }
  };

  if (loading) return <div className="sg-loading-spinner" />;

  if (!pull) {
    return <div className="empty-state">Pull request not found</div>;
  }

  return (
    <div className="page-container">
      <header className="page-header">
        <Link href={`/app/${orgId}/github/${repoId}`} className="page-header__back">
          ← Back to repository
        </Link>
        <h1>PR #{pull.number}: {pull.title}</h1>
      </header>

      <div className="card">
        <div className="card__header">Details</div>
        <div className="card__body">
          <dl className="card__fields">
            <div>
              <dt>State</dt>
              <dd>{pull.state}</dd>
            </div>
            <div>
              <dt>Author</dt>
              <dd>{pull.user.login}</dd>
            </div>
            <div>
              <dt>Branch</dt>
              <dd>{pull.head.ref} → {pull.base.ref}</dd>
            </div>
            <div>
              <dt>Created</dt>
              <dd>{new Date(pull.created_at).toLocaleString()}</dd>
            </div>
          </dl>
        </div>
      </div>

      <div className="comments">
        <h2 className="comments__header">
          <ChatBubbleLeftIcon className="comments__icon" />
          Comments ({comments.length})
        </h2>

        <form className="wiki-inline-form" onSubmit={postComment}>
          <textarea
            value={commentBody}
            onChange={(e) => setCommentBody(e.target.value)}
            placeholder="Add a comment…"
            rows={4}
          />
          <button
            type="submit"
            className="sg-btn sg-btn--black sg-btn--sm"
            disabled={!commentBody.trim() || posting}
          >
            {posting ? 'Posting…' : 'Comment'}
          </button>
        </form>

        <div className="comments__list">
          {comments.map((comment) => (
            <div key={comment.id} className="comment">
              <div className="comment__header">
                <span className="comment__author">{comment.user.login}</span>
                <span className="comment__date">
                  {new Date(comment.created_at).toLocaleString()}
                </span>
              </div>
              <div className="comment__body">{comment.body}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
```

---

## Phase 5: Testing & Validation

1. **Backend tests:**
   - `mix deps.get` to fetch `noizu_github`
   - Test `NoizuPromptLingua.Github.Client` functions directly in `iex -S mix`
   - Verify ACL: create a repo with `default_acl: "private", create a group grant, test read/write as non-granted user

2. **MCP server:**
   - Start the app, request `/mcp` from `github.tobor.locker/mcp` (adjust host)
   - Confirm `ToolSummary` lists all GitHub tools
   - Call `Github.RepoList` with valid `caller_user_id` and `organization` args

3. **REST endpoints:**
   - Use a REST client with a valid Bearer token (from `/api/v1/auth/mcp/token` or local session JWT)
   - Test GET `/api/v1/organizations/<org_id>/github` (repo list)
   - Test PRs: list, get, comment
   - Test Issues: list, get, create, comment
   - Test 403 when ACL denies

4. **Frontend:**
   - Build and run the frontend
   - Navigate to `/app/<org_id>/github`
   - Verify repo list loads with PR/issue counts
   - Open a repo, toggle between pull/issue tabs
   - Open a PR detail, post a comment

---

## Risks & Gotchas

1. **MCP caller identity:** Tools accept explicit `caller_user_id` (from args), not `_ctx`. This matches existing patterns but means the caller must know their own UUID. Frontend can pass `/api/v1/auth/me` → `id` as the arg. Consider whether this is acceptable or if a ctx-based fix is needed long-term.

2. **Token scopes:** Admin must map GitHub PATs with sufficient scopes (repo for private, depending on operations). Merge operations may require broader scopes.

3. **Rate limiting:** GitHub API has rate limits (5000/hr for authenticated). Consider adding a small backoff or rate-limit header passing through.

4. **Repo_full_name parsing:**
   - Split by `/` with `parts: 2` to handle edge cases.
   - Validate format is "owner/name".

5. **Error normalization:**
   - `noizu_github` returns `{:error, %Finch.Response{}}` on non-2xx.
   - Ensure Client unwraps structs to maps and maps to `{:error, {:github, status, body}}` for consistent error returns.

6. **Database schema constraints:**
   - `github_repos` has unique constraint on `(organization_id, repo_full_name)`.
   - `github_tokens` has unique constraint on `(organization_id, label)`.
   - On token deletion, repos get `token_id: nil` (on_replace: :nilify) — operations will fail with `:token_not_mapped`.

7. **noizu_github supervision:**
   - Library starts its own Finch pool via `Noizu.Github.Application`.
   - Verify in `iex` after `mix deps.get` that `Noizu.Github.Finch` is running: `Process.whereis(Noizu.Github.Finch)`.

8. **Org ID resolution:**
   - REST routes get `org_id` as slug; controllers must resolve via `Organizations.resolve_org_id`.
   - MCP tools accept slug OR UUID; `Resolve.organization_id/1` handles both.

---

## Dependencies Checklist

- [ ] `noizu_github` ~0.5.0 added to `mix.exs`
- [ ] Config placeholder added to `dev.exs`, `test.exs`, `prod.exs`
- [ ] Phoenix app restarts successfully
- [ ] `Noizu.Github.Finch` process running
- [ ] MCP subdomain route added to router (`github.`)
- [ ] MCPServers catalog entry added
- [ ] `NoizuPromptLingua.Domains.Github.MCP` added to application children
- [ ] Frontend app-nav entry added
- [ ] Frontend API methods added
- [ ] Frontend pages created (3 files)
- [ ] Admin config page `/app/admin/github` remains for token/repo mapping

---

## Post-Implementation Checklist

- [ ] Liquibase changelog already exists (027) — no DB migration needed
- [ ] Update `CLAUDE.md` or docs with new GitHub capabilities
- [ ] Write integration tests for Client functions
- [ ] Consider adding a "test connection" button in admin page to verify token scopes
- [ ] Document the three-tier ACL model (private|org_read|org_write + group grants)
- [ ] Add pagination to frontend lists (currently page: 1 only)

---

**End of Plan**