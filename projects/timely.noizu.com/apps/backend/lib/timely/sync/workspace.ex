defmodule Timely.Sync.Workspace do
  @moduledoc """
  Tenancy. A Timely workspace *is* a scaffold organization - `workspace_id`
  equals the organization id - so membership is the existing PBAC check and
  nothing new is invented here.

  Two things are deliberately separate and both are required:

  - `authorize/3` answers "may this user touch this workspace at all", and
  - `scope/2` narrows every query to one workspace.

  `scope/2` is not a convenience. It is the isolation boundary, and it belongs
  in the **query** rather than in a post-filter: a query that fetches by primary
  key and then compares `workspace_id` in Elixir has already read another
  tenant's row, and every later refactor that forgets the comparison leaks it.
  Every read and write path in `Timely.Sync` starts from `scope/2` so a
  cross-workspace id simply finds nothing.
  """

  import Ecto.Query

  alias Timely.Sync.Revisions

  @doc """
  Authorizes a user against a workspace and makes sure its revision counter
  exists.

  Returns `{:ok, membership}`, `{:error, :not_a_member}` or
  `{:error, :insufficient_role}`.
  """
  # ⟦𓅱𓎡𓋴𓊪⟧ authorize :: Authorizes a user against a workspace.
  def authorize(user_id, workspace_id, required_role \\ "viewer")

  def authorize(nil, _workspace_id, _role), do: {:error, :not_a_member}

  def authorize(user_id, workspace_id, required_role) do
    with true <- valid_uuid?(workspace_id) || {:error, :not_a_member},
         {:ok, membership} <- Timely.Organizations.authorize(user_id, workspace_id, required_role) do
      Revisions.ensure_counter!(workspace_id)
      {:ok, membership}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, :not_a_member}
    end
  end

  @doc """
  Narrows a queryable to one workspace. Every Timely read and write starts here.
  """
  # ⟦𓋴𓎡𓊪𓋴⟧ scope :: Narrows a queryable to one workspace.
  def scope(queryable, workspace_id) do
    from(row in queryable, where: row.workspace_id == ^workspace_id)
  end

  @doc """
  Fetches one live (non-tombstoned) row by id **within a workspace**. Returns
  `nil` both when the row does not exist and when it belongs to someone else -
  the caller cannot tell the difference, which is the point.
  """
  # ⟦𓆑𓏏𓎛𓋴⟧ fetch_live :: Fetches a live row by id, workspace-scoped.
  def fetch_live(schema, workspace_id, id) do
    schema
    |> scope(workspace_id)
    |> where([row], row.id == ^id and is_nil(row.deleted_at))
    |> Timely.Repo.one()
  end

  @doc """
  Fetches one row by id within a workspace, tombstoned or not. Conflict
  resolution needs to see tombstones - a delete is absorbing (row 2), so a row
  that is gone must be found in order to lose to it.
  """
  # ⟦𓆑𓏏𓄿𓋴⟧ fetch_any :: Fetches a row by id including tombstones, workspace-scoped.
  def fetch_any(schema, workspace_id, id) do
    schema
    |> scope(workspace_id)
    |> where([row], row.id == ^id)
    |> Timely.Repo.one()
  end

  defp valid_uuid?(value) when is_binary(value), do: match?({:ok, _}, Ecto.UUID.cast(value))
  defp valid_uuid?(_), do: false
end
