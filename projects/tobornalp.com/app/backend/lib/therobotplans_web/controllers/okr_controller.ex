defmodule TherobotplansWeb.OkrController do
  @moduledoc "REST surface for OKRs (objectives + key results + check-ins)."
  use TherobotplansWeb, :controller

  alias Therobotplans.Domains.Goals
  alias Therobotplans.Authz

  # GET /api/v1/organizations/:org_id/objectives
  def index(conn, %{"org_id" => org_id} = params) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "viewer") do
      opts =
        [
          owner_id: params["owner_id"],
          level: params["level"],
          status: params["status"],
          project_id: params["project_id"]
        ]
        |> Enum.reject(fn {_k, v} -> is_nil(v) end)

      objs = Goals.list_objectives(org_id, opts)
      json(conn, %{objectives: Enum.map(objs, &objective_json/1)})
    else
      err -> handle_error(conn, err)
    end
  end

  # POST /api/v1/organizations/:org_id/objectives
  def create(conn, %{"org_id" => org_id, "objective" => params}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "member") do
      attrs =
        Map.merge(params, %{
          "organization_id" => org_id,
          "owner_id" => params["owner_id"] || user_id
        })

      case Goals.create_objective(attrs) do
        {:ok, o} ->
          conn |> put_status(:created) |> json(%{objective: objective_json(o)})

        {:error, cs} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # GET /api/v1/organizations/:org_id/objectives/:id
  def show(conn, %{"org_id" => _org_id, "id" => id}) do
    case Goals.get_objective(id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "Objective not found"})
      o -> json(conn, %{objective: objective_detail_json(o)})
    end
  end

  def update(conn, %{"org_id" => _org_id, "id" => id, "objective" => attrs}) do
    case Goals.update_objective(id, attrs) do
      {:ok, o} ->
        json(conn, %{objective: objective_json(o)})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Objective not found"})

      {:error, cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
    end
  end

  # POST /api/v1/organizations/:org_id/objectives/:id/key_results
  def create_key_result(conn, %{"id" => objective_id, "key_result" => params}) do
    attrs = Map.put(params, "objective_id", objective_id)

    case Goals.create_key_result(attrs) do
      {:ok, kr} ->
        conn |> put_status(:created) |> json(%{key_result: kr_json(kr)})

      {:error, cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
    end
  end

  # POST /api/v1/organizations/:org_id/objectives/:id/checkins
  def create_checkin(conn, %{"id" => objective_id, "checkin" => params}) do
    user_id = get_user_id(conn)

    attrs =
      Map.merge(params, %{
        "objective_id" => objective_id,
        "author_id" => params["author_id"] || user_id
      })

    case Goals.create_checkin(attrs) do
      {:ok, c} ->
        conn
        |> put_status(:created)
        |> json(%{checkin: %{id: c.id, body: c.body, period: c.period}})

      {:error, cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
    end
  end

  defp objective_json(o) do
    %{
      id: o.id,
      title: o.title,
      level: o.level,
      status: o.status,
      period: o.period,
      owner_id: o.owner_id,
      organization_id: o.organization_id,
      project_id: o.project_id
    }
  end

  defp objective_detail_json(o) do
    Map.merge(objective_json(o), %{
      description: o.description,
      progress: Goals.objective_progress(o.id),
      key_results: Enum.map(o.key_results || [], &kr_json/1),
      checkins:
        Enum.map(
          o.checkins || [],
          &%{id: &1.id, body: &1.body, period: &1.period, inserted_at: &1.inserted_at}
        )
    })
  end

  defp kr_json(kr) do
    %{
      id: kr.id,
      objective_id: kr.objective_id,
      title: kr.title,
      target_value: kr.target_value,
      current_value: kr.current_value,
      auto_progress: kr.auto_progress,
      status: kr.status,
      due_on: kr.due_on
    }
  end

  defp handle_error(conn, err) do
    case err do
      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Not found"})

      {:error, :not_a_member} ->
        conn |> put_status(:forbidden) |> json(%{error: "Not a member of this organization"})

      _ ->
        conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
    end
  end

  defp get_user_id(conn) do
    case Therobotplans.Guardian.Plug.current_resource(conn) do
      %Therobotplans.Users.Sessions.UserSession{user: {:ref, _, id}} -> id
      %Therobotplans.Users.Sessions.UserSession{user: %{id: id}} -> id
      _ -> nil
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
