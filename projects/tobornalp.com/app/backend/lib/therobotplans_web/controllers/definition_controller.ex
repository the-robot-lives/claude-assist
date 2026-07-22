defmodule TherobotplansWeb.DefinitionController do
  @moduledoc """
  REST surface for tri-scoped item type/field definitions. Lists effective
  (resolved) definitions for an org/project context, and allows create/update.
  """
  use TherobotplansWeb, :controller

  alias Therobotplans.Domains.Items.Definitions
  alias Therobotplans.Authz

  # GET /api/v1/organizations/:org_id/definitions/fields[?project_id=]
  def index_fields(conn, %{"org_id" => org_id} = params) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "viewer") do
      fields = Definitions.effective_fields(org_id, blank_to_nil(params["project_id"]))
      json(conn, %{fields: Enum.map(fields, &field_to_json/1)})
    else
      err -> handle_error(conn, err)
    end
  end

  def create_field(conn, %{"org_id" => org_id, "field" => params}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "member") do
      attrs =
        Map.merge(params, %{
          "organization_id" => org_id,
          "project_id" => blank_to_nil(params["project_id"])
        })

      case Definitions.create_field(attrs) do
        {:ok, f} ->
          conn |> put_status(:created) |> json(%{field: field_to_json(f)})

        {:error, cs} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # GET /api/v1/organizations/:org_id/definitions/fields/:id
  def show_field(conn, %{"org_id" => org_id, "id" => id}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "viewer") do
      case Definitions.get_field(id) do
        nil -> conn |> put_status(:not_found) |> json(%{error: "Field not found"})
        f -> json(conn, %{field: field_to_json(f)})
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # PUT/PATCH /api/v1/organizations/:org_id/definitions/fields/:id
  def update_field(conn, %{"org_id" => org_id, "id" => id, "field" => params}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "member") do
      attrs =
        Map.merge(params, %{
          "organization_id" => org_id,
          "project_id" => blank_to_nil(params["project_id"])
        })

      case Definitions.update_field(id, attrs) do
        {:ok, f} ->
          json(conn, %{field: field_to_json(f)})

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Field not found"})

        {:error, cs} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # DELETE /api/v1/organizations/:org_id/definitions/fields/:id
  def delete_field(conn, %{"org_id" => org_id, "id" => id}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "member") do
      case Definitions.delete_field(id) do
        {:ok, _f} ->
          send_resp(conn, :no_content, "")

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Field not found"})

        {:error, cs} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # GET /api/v1/organizations/:org_id/definitions/types[?project_id=]
  def index_types(conn, %{"org_id" => org_id} = params) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "viewer") do
      types = Definitions.effective_types(org_id, blank_to_nil(params["project_id"]))
      json(conn, %{types: Enum.map(types, &type_to_json/1)})
    else
      err -> handle_error(conn, err)
    end
  end

  def create_type(conn, %{"org_id" => org_id, "type" => params}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "member") do
      attrs =
        Map.merge(params, %{
          "organization_id" => org_id,
          "project_id" => blank_to_nil(params["project_id"])
        })

      case Definitions.create_type(attrs) do
        {:ok, t} ->
          conn |> put_status(:created) |> json(%{type: type_to_json(t)})

        {:error, cs} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # GET /api/v1/organizations/:org_id/definitions/types/:id
  def show_type(conn, %{"org_id" => org_id, "id" => id}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "viewer") do
      case Definitions.get_type(id) do
        nil -> conn |> put_status(:not_found) |> json(%{error: "Type not found"})
        t -> json(conn, %{type: type_to_json(t)})
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # PUT/PATCH /api/v1/organizations/:org_id/definitions/types/:id
  def update_type(conn, %{"org_id" => org_id, "id" => id, "type" => params}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "member") do
      attrs =
        Map.merge(params, %{
          "organization_id" => org_id,
          "project_id" => blank_to_nil(params["project_id"])
        })

      case Definitions.update_type(id, attrs) do
        {:ok, t} ->
          json(conn, %{type: type_to_json(t)})

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Type not found"})

        {:error, cs} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # DELETE /api/v1/organizations/:org_id/definitions/types/:id
  def delete_type(conn, %{"org_id" => org_id, "id" => id}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "member") do
      case Definitions.delete_type(id) do
        {:ok, _t} ->
          send_resp(conn, :no_content, "")

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "Type not found"})

        {:error, cs} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # POST /api/v1/organizations/:org_id/definitions/types/:id/fields
  # Body: {"field_id": "...", "required": false, "position": 0}
  def add_field(conn, %{"org_id" => org_id, "id" => type_id} = params) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "member") do
      case params["field_id"] do
        nil ->
          conn |> put_status(:bad_request) |> json(%{error: "Missing field_id"})

        field_id ->
          opts =
            []
            |> maybe_put_opt(:required, params["required"])
            |> maybe_put_opt(:position, params["position"])

          case Definitions.add_field_to_type(type_id, field_id, opts) do
            {:ok, _tf} ->
              type = Definitions.get_type(type_id)
              conn |> put_status(:created) |> json(%{type: type_to_json(type)})

            {:error, cs} ->
              conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
          end
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # DELETE /api/v1/organizations/:org_id/definitions/types/:id/fields/:field_id
  def remove_field(conn, %{"org_id" => org_id, "id" => type_id, "field_id" => field_id}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "member") do
      case Definitions.remove_field_from_type(type_id, field_id) do
        {:ok, _count} ->
          type = Definitions.get_type(type_id)
          json(conn, %{type: type_to_json(type)})

        err ->
          handle_error(conn, err)
      end
    else
      err -> handle_error(conn, err)
    end
  end

  defp field_to_json(f) do
    %{
      id: f.id,
      slug: f.slug,
      label: f.label,
      field_type: f.field_type,
      organization_id: f.organization_id,
      project_id: f.project_id,
      options: f.options,
      default_value: f.default_value,
      description: f.description,
      disabled: f.disabled
    }
  end

  defp type_to_json(t) do
    %{
      id: t.id,
      slug: t.slug,
      name: t.name,
      description: t.description,
      organization_id: t.organization_id,
      project_id: t.project_id,
      icon: t.icon,
      status_workflow: t.status_workflow,
      disabled: t.disabled,
      fields: Definitions.type_field_list(t)
    }
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(v), do: v

  defp maybe_put_opt(opts, _key, nil), do: opts
  defp maybe_put_opt(opts, key, value), do: Keyword.put(opts, key, value)

  defp handle_error(conn, err) do
    case err do
      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Organization not found"})

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
