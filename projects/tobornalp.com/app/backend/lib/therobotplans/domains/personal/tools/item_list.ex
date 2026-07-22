defmodule Therobotplans.Domains.Personal.Tools.ItemList do
  use Noizu.MCP.Server.Tool,
    name: "Personal.Item.List",
    description: "List the acting user's personal todos in an organization, grouped by due bucket.",
    hidden: true,
    category: "Personal",
    annotations: [read_only_hint: true]

  input do
    field :organization, :string,
      required: true,
      description: "Organization slug or UUID (required)"

    field :status, :string, description: "Filter by status (e.g. open)"
    field :tag, :string, description: "Filter by tag (comma-separated = AND)"
    field :q, :string, description: "Title contains"
    field :group, :string, description: "'grouped' (default) or 'all'"
    field :tz, :string, description: "IANA timezone for bucketing (default UTC)"
  end

  alias Therobotplans.Domains.Personal
  alias Therobotplans.Domains.Personal.Recurrence
  alias Therobotplans.MCP.{Args, Resolve}

  @impl true
  def call(args, ctx) do
    org_ref = Args.get(args, :organization)
    user_id = Resolve.current_user_id(ctx)

    cond do
      is_nil(user_id) ->
        {:error, "Not authenticated"}

      is_nil(Resolve.organization_id(org_ref)) ->
        {:error, "Organization '#{org_ref}' not found"}

      true ->
        org_id = Resolve.organization_id(org_ref)
        tz = Args.get(args, :tz)
        today = Recurrence.today_in_zone(tz)

        opts =
          [tz: tz]
          |> put_if(:status, Args.get(args, :status))
          |> put_if(:q, Args.get(args, :q))
          |> put_if(:tag, split_tags(Args.get(args, :tag)))

        case Args.get(args, :group) do
          "all" ->
            items = Personal.list_items(org_id, user_id, opts)
            {:ok, %{items: Enum.map(items, &row(&1, today)), count: length(items)}}

          _ ->
            grouped = Personal.list_grouped(org_id, user_id, opts)
            {:ok, %{groups: Map.new(grouped, fn {b, its} -> {b, Enum.map(its, &row(&1, today))} end)}}
        end
    end
  end

  defp row(item, today) do
    %{
      id: item.id,
      title: item.title,
      status: item.status,
      priority: item.priority,
      due_date: item.due_date,
      tags: item.tags || [],
      overdue: Personal.overdue?(item, today),
      bucket: Personal.bucket_for(item, today)
    }
  end

  defp split_tags(nil), do: nil
  defp split_tags(""), do: nil
  defp split_tags(t) when is_binary(t), do: String.split(t, ",", trim: true)

  defp put_if(opts, _k, nil), do: opts
  defp put_if(opts, _k, ""), do: opts
  defp put_if(opts, _k, []), do: opts
  defp put_if(opts, k, v), do: Keyword.put(opts, k, v)
end
