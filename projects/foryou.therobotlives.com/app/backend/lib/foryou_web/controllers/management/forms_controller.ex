defmodule ForyouWeb.Management.FormsController do
  @moduledoc """
  Management CRUD for form definitions (API-key / system-level). A changed
  `definition` is saved as a new immutable version via `Forms.save_definition`.
  Soft-deletes hide the form from index/show.
  """
  use ForyouWeb, :controller

  alias Foryou.Forms
  alias Foryou.Schema.Forms.Form

  def index(conn, _params) do
    json(conn, %{forms: Enum.map(Forms.list_forms(), &serialize/1)})
  end

  def show(conn, %{"id" => id}) do
    case Forms.get_form(id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "not found"})
      form -> json(conn, %{form: serialize(form)})
    end
  end

  def create(conn, %{"form" => params}) do
    attrs =
      params
      |> Map.take(["organization_id", "slug", "name", "status", "definition", "settings"])
      |> Map.put_new("status", "draft")

    case Forms.create_form(attrs) do
      {:ok, form} ->
        form = maybe_save_definition(form, params["definition"])
        conn |> put_status(:created) |> json(%{form: serialize(form)})

      {:error, cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
    end
  end

  def update(conn, %{"id" => id, "form" => params}) do
    case Forms.get_form(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not found"})

      form ->
        form = update_meta(form, params)
        form = maybe_save_definition(form, params["definition"])
        json(conn, %{form: serialize(form)})
    end
  end

  def delete(conn, %{"id" => id}) do
    case Forms.get_form(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not found"})

      form ->
        case Forms.delete_form(form) do
          {:ok, _} -> conn |> send_resp(:no_content, "")
          {:error, cs} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
        end
    end
  end

  def versions(conn, %{"id" => id}) do
    json(conn, %{versions: Forms.list_versions(id)})
  end

  def submissions(conn, %{"id" => id}) do
    json(conn, %{submissions: Forms.list_submissions(id)})
  end

  defp update_meta(form, params) do
    meta = Map.take(params, ["slug", "name", "status", "settings"])

    case meta do
      empty when empty == %{} -> form
      _ -> (case Forms.update_form(form, meta) do {:ok, f} -> f; _ -> form end)
    end
  end

  defp maybe_save_definition(form, definition) when is_map(definition) do
    case Forms.save_definition(form, definition) do
      {:ok, %{form: updated}} -> updated
      _ -> form
    end
  end

  defp maybe_save_definition(form, _), do: form

  defp serialize(%Form{} = f) do
    %{
      id: f.id,
      organization_id: f.organization_id,
      slug: f.slug,
      name: f.name,
      status: f.status,
      definition: f.definition,
      settings: f.settings,
      current_version_id: f.current_version_id
    }
  end

  defp format_errors(cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
    end)
  end
end
