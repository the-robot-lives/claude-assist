defmodule Therobotplans.MCPServers do
  @moduledoc """
  Catalog of MCP servers exposed on subdomains. Single source of truth shared
  by the config endpoint (`GET /api/v1/auth/mcp/config`) and any client that
  needs to render `claude mcp add` setup commands.

  The `:root` server maps to the bare host (`<host>/mcp`); every other entry is
  served at `<id>.<host>/mcp`. Keep this list in sync with the `host:` scopes
  wired in `TherobotplansWeb.Router`.
  """

  # %{id: label/required/desc}. `id` doubles as the subdomain label (except root).
  @servers [
    %{id: "root", label: "Root MCP", required: true, desc: "All domains + discovery"},
    %{id: "projects", label: "Projects", required: false, desc: "Project management"},
    %{
      id: "items",
      label: "Items",
      required: false,
      desc: "Item tracking — tasks, bugs, todos, epics, boards & definitions"
    },
    %{
      id: "notifications",
      label: "Notifications",
      required: false,
      desc: "Per-recipient notification inbox"
    },
    %{
      id: "goals",
      label: "Goals",
      required: false,
      desc: "OKRs — objectives, key results, check-ins"
    },
    %{
      id: "personal",
      label: "Personal",
      required: false,
      desc: "Personal todos — a user's private todo list (due dates, tags, recurrence)"
    },
    %{
      id: "artifacts",
      label: "Artifacts",
      required: false,
      desc: "Versioned typed content — code, document, image, wiki, config, binary"
    },
    %{id: "wiki", label: "Wiki", required: false, desc: "Wiki — spaces, pages, comments, attachments, reactions"},
    %{id: "review", label: "Review", required: false, desc: "Code/content reviews over artifact revisions — overlays + verdict"}
  ]

  @server_modules %{
    "projects" => Therobotplans.MCP.Projects,
    "items" => Therobotplans.Domains.Items.MCP,
    "notifications" => Therobotplans.Domains.Notifications.MCP,
    "goals" => Therobotplans.Domains.Goals.MCP,
    "personal" => Therobotplans.Domains.Personal.MCP,
    "artifacts" => Therobotplans.Domains.Artifacts.MCP,
    "wiki" => Therobotplans.Domains.Wiki.MCP,
    "review" => Therobotplans.Domains.Review.MCP
  }

  @doc "All configured MCP servers."
  def all, do: @servers

  @doc "MCP servers that can be included in custom scopes."
  def customizable do
    Enum.reject(@servers, &(&1.id == "root"))
  end

  @doc "Resolve a public server id to its MCP server module."
  def server_module(id) when is_binary(id), do: Map.get(@server_modules, id)
  def server_module(_), do: nil

  @doc """
  Returns the MCP servers with full connection URLs, derived from the configured
  host. Suitable for JSON serialization to clients building setup commands.
  """
  def for_host(nil), do: for_host(default_host())

  def for_host(host) when is_binary(host) do
    Enum.map(@servers, fn %{id: id} = s ->
      subdomain = if id == "root", do: host, else: "#{id}.#{host}"
      Map.put(s, :url, "https://#{subdomain}/mcp")
    end)
  end

  defp default_host do
    Application.get_env(:therobotplans, TherobotplansWeb.Endpoint)
    |> case do
      %{url: %{host: host}} when is_binary(host) and host != "" -> host
      kw when is_list(kw) -> kw |> Keyword.get(:url, []) |> Keyword.get(:host, "localhost")
      _ -> System.get_env("PHX_HOST") || "localhost"
    end
  end
end
