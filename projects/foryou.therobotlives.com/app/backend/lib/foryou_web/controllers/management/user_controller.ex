defmodule ForyouWeb.Management.UserController do
  @moduledoc """
  Management CRUD for users (API-key / system-level). Soft-deletes set
  `deleted_at` + `status: :deleted`; index/show hide deleted rows so the
  Terraform provider sees a destroyed resource as absent.
  """
  use ForyouWeb, :controller

  alias Foryou.Schema.Users.User, as: UserSchema
  alias Foryou.Users
  import Ecto.Query

  def index(conn, _params) do
    users =
      from(u in UserSchema, where: is_nil(u.deleted_at), order_by: u.inserted_at)
      |> Foryou.Repo.all()

    json(conn, %{users: Enum.map(users, &serialize/1)})
  end

  def show(conn, %{"id" => id}) do
    with %UserSchema{} = user <- Foryou.Repo.get(UserSchema, id),
         true <- is_nil(user.deleted_at) do
      json(conn, %{user: serialize(user)})
    else
      _ -> conn |> put_status(:not_found) |> json(%{error: "not found"})
    end
  end

  def create(conn, %{"user" => params}) do
    name = params["name"] || %{}

    details = %{
      user_name: params["user_name"],
      handle: params["handle"],
      name: %{first: name["first"] || "", last: name["last"] || "", middle: name["middle"]},
      description: params["description"]
    }

    auth = {:login, {params["email"], params["password"]}}

    case Users.register(details, auth, Noizu.Context.system()) do
      {:ok, {user, _credential}} ->
        conn |> put_status(:created) |> json(%{user: serialize(user)})

      {:error, %Ecto.Changeset{} = cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})

      {:error, reason} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: inspect(reason)})
    end
  end

  def update(conn, %{"id" => id, "user" => params}) do
    with %UserSchema{} = user <- Foryou.Repo.get(UserSchema, id) do
      castable = Map.take(params, ["user_name", "handle", "email", "status", "verified", "flagged"])

      case user |> UserSchema.changeset(castable) |> Foryou.Repo.update() do
        {:ok, updated} -> json(conn, %{user: serialize(updated)})
        {:error, cs} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
      end
    else
      _ -> conn |> put_status(:not_found) |> json(%{error: "not found"})
    end
  end

  def delete(conn, %{"id" => id}) do
    with %UserSchema{} = user <- Foryou.Repo.get(UserSchema, id) do
      now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

      case user |> UserSchema.changeset(%{status: :deleted, deleted_at: now}) |> Foryou.Repo.update() do
        {:ok, _} -> conn |> send_resp(:no_content, "")
        {:error, cs} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
      end
    else
      _ -> conn |> put_status(:not_found) |> json(%{error: "not found"})
    end
  end

  defp serialize(%UserSchema{} = u) do
    %{
      id: u.id,
      user_name: u.user_name,
      handle: u.handle,
      email: u.email,
      status: u.status,
      verified: u.verified,
      flagged: u.flagged
    }
  end

  defp format_errors(cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
    end)
  end
end
