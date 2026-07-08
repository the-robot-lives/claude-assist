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
