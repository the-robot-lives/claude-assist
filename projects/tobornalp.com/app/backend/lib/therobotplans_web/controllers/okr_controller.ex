defmodule TherobotplansWeb.OkrController do
  @moduledoc "REST surface for OKRs (objectives + key results + check-ins)."
  use TherobotplansWeb, :controller

  alias Therobotplans.Domains.Goals
  alias Therobotplans.Authz

  # GET /api/v1/organizations/:org_id/objectives  (+ ?parent_id= ?root=true)
  def index(conn, %{"org_id" => org_id} = params) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "viewer") do
      opts =
        [
          owner_id: params["owner_id"],
          level: params["level"],
          status: params["status"],
          project_id: params["project_id"],
          parent_id: params["parent_id"],
          root: params["root"]
        ]
        |> Enum.reject(fn {_k, v} -> is_nil(v) end)

      objs = Goals.list_objectives(org_id, opts)
      json(conn, %{objectives: Enum.map(objs, &objective_json/1)})
    else
      err -> handle_error(conn, err)
    end
  end

  # GET /api/v1/organizations/:org_id/objectives/tree  — nested forest w/ rollup.
  def tree(conn, %{"org_id" => org_id}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "viewer") do
      forest = Goals.objectives_tree(org_id)
      json(conn, %{tree: Enum.map(forest, &tree_node_json/1)})
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

      create_objective_response(conn, attrs)
    else
      err -> handle_error(conn, err)
    end
  end

  # POST /api/v1/organizations/:org_id/objectives/:id/children — ergonomic child create.
  def create_child(conn, %{"org_id" => org_id, "id" => parent_id, "objective" => params}) do
    with_org_objective(conn, org_id, parent_id, "member", fn _parent ->
      user_id = get_user_id(conn)

      attrs =
        Map.merge(params, %{
          "organization_id" => org_id,
          "parent_id" => parent_id,
          "owner_id" => params["owner_id"] || user_id
        })

      create_objective_response(conn, attrs)
    end)
  end

  defp create_objective_response(conn, attrs) do
    case Goals.create_objective(attrs) do
      {:ok, o} ->
        conn |> put_status(:created) |> json(%{objective: objective_json(o)})

      {:error, reason} when reason in [:cycle, :max_depth, :has_children] ->
        okr_error(conn, reason)

      {:error, cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
    end
  end

  # GET /api/v1/organizations/:org_id/objectives/:id
  def show(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_objective(conn, org_id, id, "viewer", fn o ->
      json(conn, %{objective: objective_detail_json(o)})
    end)
  end

  def update(conn, %{"org_id" => org_id, "id" => id, "objective" => attrs}) do
    with_org_objective(conn, org_id, id, "member", fn _o ->
      # Never let a member relocate an objective to a different org via update.
      attrs = Map.drop(attrs, ["organization_id"])

      case Goals.update_objective(id, attrs) do
        {:ok, o} ->
          json(conn, %{objective: objective_json(o)})

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Objective not found"})

        {:error, reason} when reason in [:cycle, :max_depth, :has_children] ->
          okr_error(conn, reason)

        {:error, cs} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
      end
    end)
  end

  # DELETE /api/v1/organizations/:org_id/objectives/:id — FR-10 block-if-children.
  def delete(conn, %{"org_id" => org_id, "id" => id}) do
    with_org_objective(conn, org_id, id, "member", fn _o ->
      case Goals.delete_objective(id) do
        {:ok, _} ->
          send_resp(conn, :no_content, "")

        {:error, :has_children} ->
          okr_error(conn, :has_children)

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Objective not found"})

        {:error, cs} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
      end
    end)
  end

  # POST /api/v1/organizations/:org_id/objectives/:id/key_results
  def create_key_result(conn, %{"org_id" => org_id, "id" => objective_id, "key_result" => params}) do
    with_org_objective(conn, org_id, objective_id, "member", fn _o ->
      attrs = Map.put(params, "objective_id", objective_id)

      case Goals.create_key_result(attrs) do
        {:ok, kr} ->
          conn |> put_status(:created) |> json(%{key_result: kr_json(kr)})

        {:error, cs} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
      end
    end)
  end

  # POST /api/v1/organizations/:org_id/objectives/:id/checkins
  def create_checkin(conn, %{"org_id" => org_id, "id" => objective_id, "checkin" => params}) do
    with_org_objective(conn, org_id, objective_id, "member", fn _o ->
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
    end)
  end

  # GET /api/v1/organizations/:org_id/objectives/:id/checkins
  def list_checkins(conn, %{"org_id" => org_id, "id" => objective_id}) do
    with_org_objective(conn, org_id, objective_id, "viewer", fn _o ->
      checkins = Goals.list_checkins(objective_id)
      json(conn, %{checkins: Enum.map(checkins, &checkin_json/1)})
    end)
  end

  # DELETE /api/v1/organizations/:org_id/checkins/:id  (org resolved via objective)
  def delete_checkin(conn, %{"org_id" => org_id, "id" => checkin_id}) do
    with_org_checkin(conn, org_id, checkin_id, "member", fn _c ->
      case Goals.delete_checkin(checkin_id) do
        {:ok, _} -> send_resp(conn, :no_content, "")
        {:error, :not_found} -> okr_error(conn, :not_found)
      end
    end)
  end

  # PATCH /api/v1/organizations/:org_id/key_results/:id
  def update_key_result(conn, %{"org_id" => org_id, "id" => kr_id, "key_result" => params}) do
    with_org_key_result(conn, org_id, kr_id, "member", fn _kr ->
      # A KR can never be relocated to a different objective via update.
      attrs = Map.drop(params, ["objective_id"])

      case Goals.update_key_result(kr_id, attrs) do
        {:ok, kr} ->
          json(conn, %{key_result: kr_json(kr)})

        {:error, :not_found} ->
          okr_error(conn, :not_found)

        {:error, cs} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
      end
    end)
  end

  # DELETE /api/v1/organizations/:org_id/key_results/:id
  def delete_key_result(conn, %{"org_id" => org_id, "id" => kr_id}) do
    with_org_key_result(conn, org_id, kr_id, "member", fn _kr ->
      case Goals.delete_key_result(kr_id) do
        {:ok, _} -> send_resp(conn, :no_content, "")
        {:error, :not_found} -> okr_error(conn, :not_found)
      end
    end)
  end

  # POST /api/v1/organizations/:org_id/key_results/:id/items  body: {item_id, weight}
  def link_item(conn, %{"org_id" => org_id, "id" => kr_id} = params) do
    with_org_key_result(conn, org_id, kr_id, "member", fn _kr ->
      item_id = params["item_id"]
      weight = parse_weight(params["weight"])

      cond do
        is_nil(item_id) ->
          conn |> put_status(:unprocessable_entity) |> json(%{error: "item_id is required"})

        true ->
          case Goals.link_item(kr_id, item_id, weight) do
            {:ok, link} ->
              conn
              |> put_status(:created)
              |> json(%{link: %{id: link.id, key_result_id: link.key_result_id, item_id: link.item_id, weight: link.weight}})

            {:error, cs} ->
              conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
          end
      end
    end)
  end

  # DELETE /api/v1/organizations/:org_id/key_results/:id/items/:item_id
  def unlink_item(conn, %{"org_id" => org_id, "id" => kr_id, "item_id" => item_id}) do
    with_org_key_result(conn, org_id, kr_id, "member", fn _kr ->
      case Goals.unlink_item(kr_id, item_id) do
        {:ok, _} -> send_resp(conn, :no_content, "")
        {:error, :not_found} -> okr_error(conn, :not_found)
      end
    end)
  end

  # Resolve org, authorize the caller, load the objective, ensure it belongs to
  # the org. Mirrors ItemController.with_org_item/5 — without this any
  # authenticated user could read/edit any org's OKRs by UUID.
  defp with_org_objective(conn, org_id, objective_id, role, fun) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, role),
         obj when not is_nil(obj) <- Goals.get_objective(objective_id),
         true <- obj.organization_id == org_id do
      fun.(obj)
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "Objective not found"})
      false -> conn |> put_status(:not_found) |> json(%{error: "Objective not found"})
      err -> handle_error(conn, err)
    end
  end

  # Resolve org, authorize, load the KR, resolve its objective, ensure the objective
  # belongs to the org. Parallels with_org_objective/5 — blocks cross-org KR probing.
  defp with_org_key_result(conn, org_id, kr_id, role, fun) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, role),
         kr when not is_nil(kr) <- Goals.get_key_result(kr_id),
         obj when not is_nil(obj) <- Goals.get_objective(kr.objective_id),
         true <- obj.organization_id == org_id do
      fun.(kr)
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "Key result not found"})
      false -> conn |> put_status(:not_found) |> json(%{error: "Key result not found"})
      err -> handle_error(conn, err)
    end
  end

  # Same pattern for a check-in: org is resolved through its objective.
  defp with_org_checkin(conn, org_id, checkin_id, role, fun) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, role),
         c when not is_nil(c) <- Goals.get_checkin(checkin_id),
         obj when not is_nil(obj) <- Goals.get_objective(c.objective_id),
         true <- obj.organization_id == org_id do
      fun.(c)
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "Check-in not found"})
      false -> conn |> put_status(:not_found) |> json(%{error: "Check-in not found"})
      err -> handle_error(conn, err)
    end
  end

  # Documented error contract (§6): cycle/depth → 422, has_children → 409, else 404.
  defp okr_error(conn, :cycle), do: conn |> put_status(:unprocessable_entity) |> json(%{error: "cycle"})
  defp okr_error(conn, :max_depth), do: conn |> put_status(:unprocessable_entity) |> json(%{error: "max_depth"})
  defp okr_error(conn, :has_children), do: conn |> put_status(:conflict) |> json(%{error: "has_children"})
  defp okr_error(conn, _), do: conn |> put_status(:not_found) |> json(%{error: "Not found"})

  defp parse_weight(nil), do: Decimal.new("1.0")
  defp parse_weight(%Decimal{} = d), do: d
  defp parse_weight(n) when is_integer(n), do: Decimal.new(n)
  defp parse_weight(n) when is_float(n), do: Decimal.from_float(n)

  defp parse_weight(s) when is_binary(s) do
    case Decimal.parse(s) do
      {d, _} -> d
      :error -> Decimal.new("1.0")
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
      project_id: o.project_id,
      parent_id: o.parent_id,
      rollup_strategy: o.rollup_strategy,
      weight: o.weight,
      sort_order: o.sort_order,
      progress: Goals.progress_for(o)
    }
  end

  defp objective_detail_json(o) do
    Map.merge(objective_json(o), %{
      description: o.description,
      progress: Goals.objective_progress(o.id),
      key_results: Enum.map(o.key_results || [], &kr_json/1),
      checkins: Enum.map(o.checkins || [], &checkin_json/1)
    })
  end

  defp tree_node_json(%{objective: o, progress: progress, children: children}) do
    objective_json(o)
    |> Map.put(:progress, progress)
    |> Map.put(:children, Enum.map(children, &tree_node_json/1))
  end

  defp checkin_json(c) do
    %{id: c.id, body: c.body, period: c.period, inserted_at: c.inserted_at}
  end

  defp kr_json(kr) do
    %{
      id: kr.id,
      objective_id: kr.objective_id,
      title: kr.title,
      unit: kr.unit,
      target_value: kr.target_value,
      current_value: kr.current_value,
      direction: kr.direction,
      weight: kr.weight,
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
