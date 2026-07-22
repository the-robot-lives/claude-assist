defmodule Therobotplans.Services.Comment do
  @moduledoc """
  Generic per-entity comments keyed by (entity_type, entity_id). Items use
  entity_type = "item". Ported from NPL Services.Comment.
  """
  import Ecto.Query

  alias Therobotplans.Repo
  alias Therobotplans.Schema.Comment

  def add(entity_type, entity_id, attrs) do
    %Comment{}
    |> Comment.changeset(Map.merge(attrs, %{entity_type: entity_type, entity_id: entity_id}))
    |> Repo.insert()
    |> case do
      {:ok, comment} = ok ->
        # Best-effort notification fan-out. Phase 2 (Notifications) wires the real
        # dispatch; until then this is a guarded no-op that MUST never raise into
        # the caller's write path.
        try do
          maybe_dispatch_comment(comment)
        rescue
          _ -> :ok
        catch
          _, _ -> :ok
        end

        ok

      other ->
        other
    end
  end

  def list(entity_type, entity_id, opts \\ []) do
    Comment
    |> where([c], c.entity_type == ^entity_type and c.entity_id == ^entity_id)
    |> order_by([c], asc: c.inserted_at)
    |> limit(^(opts[:limit] || 50))
    |> Repo.all()
  end

  @doc "Fetch a single comment by id (any entity_type — caller scopes by org)."
  def get(id), do: Repo.get(Comment, id)

  @doc "Delete a comment by id. Returns {:error, :not_found} when absent."
  def delete(id) do
    case Repo.get(Comment, id) do
      nil -> {:error, :not_found}
      comment -> Repo.delete(comment)
    end
  end

  defp maybe_dispatch_comment(comment) do
    case Code.ensure_loaded?(Therobotplans.Domains.Notifications.Dispatch) do
      true -> apply(Therobotplans.Domains.Notifications.Dispatch, :comment, [comment])
      false -> :ok
    end
  end
end
