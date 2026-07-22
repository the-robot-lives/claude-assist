defmodule ForyouWeb.Management.UserController do
  @moduledoc """
  Management CRUD for users (API-key / system-level). Soft-deletes set
  `deleted_at` + `status: :deleted`; index/show hide deleted rows so the
  Terraform provider sees a destroyed resource as absent.

  NOTE: `create` uses raw schema inserts (mirrors the SSO auto-provision path)
  rather than `Foryou.Users.register/4`, because the entity `change/2` macro
  rejects structs passed to `EntityRepo.create` (Protocol.UndefinedError). The
  register/login paths share that bug and are deferred — see TODO.
  """
  use ForyouWeb, :controller

  alias Foryou.Schema.Users.User, as: UserSchema
  alias Foryou.Schema.Users.Credentials.UserCredential, as: CredentialSchema
  alias Foryou.Schema.Versioned.Names.Name, as: NameSchema
  alias Foryou.Schema.Versioned.Descriptions.Description, as: DescriptionSchema
  import Ecto.Query

  @login_provider_id UUID.uuid5(:oid, "Foryou.Schema.Auth.Providers.Provider@Login")

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
    first = name["first"] || ""
    last = name["last"] || ""
    middle = name["middle"] || []
    email = params["email"]
    password = params["password"]
    user_name = params["user_name"]

    handle =
      params["handle"] ||
        (email |> String.split("@") |> hd() |> String.downcase() |> String.replace(~r/[^a-z0-9_]/, "_"))

    result =
      Foryou.Repo.transaction(fn ->
        {:ok, name_row} =
          %NameSchema{first: first, middle: middle, last: last}
          |> Foryou.Repo.insert()

        {:ok, desc_row} =
          %DescriptionSchema{title: "User", body: params["description"] || ""}
          |> Foryou.Repo.insert()

        {:ok, user} =
          %UserSchema{
            user_name: user_name,
            handle: handle,
            name_id: name_row.id,
            description_id: desc_row.id,
            email: email,
            status: :active,
            verified: true,
            flagged: false
          }
          |> Foryou.Repo.insert()

        hashed = Bcrypt.hash_pwd_salt(password)

        {:ok, _cred} =
          %CredentialSchema{
            user_id: user.id,
            auth_provider_id: @login_provider_id,
            status: :active,
            settings: %{"email" => email, "password" => hashed},
            state: %{},
            fingerprint: "#{email}:#{hashed}"
          }
          |> Foryou.Repo.insert()

        user
      end)

    case result do
      {:ok, user} ->
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
