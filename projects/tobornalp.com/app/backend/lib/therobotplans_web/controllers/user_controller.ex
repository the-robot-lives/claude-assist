defmodule TherobotplansWeb.UserController do
  use TherobotplansWeb, :controller

  alias Therobotplans.Guardian
  alias Therobotplans.Users
  alias Therobotplans.Schema.Users.User, as: UserSchema
  import Ecto.Query, only: [from: 2]

  def show(conn, _params) do
    user = get_current_user(conn)

    conn
    |> put_status(:ok)
    |> json(%{user: serialize_user(user)})
  end

  def update(conn, %{"user" => user_params}) do
    user = get_current_user(conn)
    context = Noizu.Context.system()

    with :ok <- validate_update_params(user, user_params),
         {:ok, updated_user} <- apply_updates(user, user_params, context) do
      conn
      |> put_status(:ok)
      |> json(%{user: serialize_user(updated_user)})
    else
      {:error, :invalid_current_password} ->
        conn |> put_status(:unauthorized) |> json(%{error: "Current password is incorrect"})

      {:error, changeset} when is_struct(changeset, Ecto.Changeset) ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})

      {:error, reason} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: to_string(reason)})
    end
  end

  def update(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "user params required"})
  end

  # Persist cookie-consent preferences on the account (explicit user choice from
  # the consent banner always wins). Stored as jsonb so it survives the apex →
  # app.tobornalp.com hop, where localStorage does not carry over.
  def consent(conn, %{"preferences" => prefs}) when is_map(prefs) do
    user = get_current_user(conn)
    now = DateTime.utc_now()

    {_, _} =
      from(u in UserSchema, where: u.id == ^user.id)
      |> Therobotplans.Repo.update_all(
        set: [consent_preferences: prefs, consent_updated_at: now]
      )

    conn
    |> put_status(:ok)
    |> json(%{consent_preferences: prefs, consent_updated_at: now})
  end

  def consent(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "preferences map required"})
  end

  defp get_current_user(conn) do
    session = Guardian.Plug.current_resource(conn)

    case session.user do
      {:ref, _, id} ->
        {:ok, user} = Users.get_user(id, Noizu.Context.system())
        user

      %Therobotplans.Users.User{} = user ->
        user
    end
  end

  defp validate_update_params(user, params) do
    if params["new_password"] && params["current_password"] do
      {:ok, auth_provider} = Therobotplans.Auth.Providers.login()
      {:ok, auth_provider_id} = Therobotplans.Auth.Providers.Provider.id(auth_provider)

      q =
        from c in Therobotplans.Schema.Users.Credentials.UserCredential,
          where: c.user_id == ^user.id,
          where: c.auth_provider_id == ^auth_provider_id,
          where: c.status == :active,
          limit: 1

      case Therobotplans.Repo.one(q) do
        nil ->
          {:error, :invalid_current_password}

        credential ->
          if Bcrypt.verify_pass(params["current_password"], credential.settings["password"]) do
            :ok
          else
            {:error, :invalid_current_password}
          end
      end
    else
      :ok
    end
  end

  defp apply_updates(user, params, _context) do
    updates = %{}

    updates =
      if params["user_name"], do: Map.put(updates, :user_name, params["user_name"]), else: updates

    updates = if params["email"], do: Map.put(updates, :email, params["email"]), else: updates

    if map_size(updates) > 0 do
      from(u in UserSchema, where: u.id == ^user.id)
      |> Therobotplans.Repo.update_all(set: Enum.to_list(updates))
    end

    if params["new_password"] do
      Therobotplans.Users.Credentials.update_password(user, params["new_password"], Noizu.Context.system())
    end

    {:ok, user} = Users.get_user(user.id, Noizu.Context.system())
    {:ok, user}
  end

  defp serialize_user(user) do
    # Consent lives on the DB schema row, not the versioned entity — read it back.
    row = Therobotplans.Repo.get(UserSchema, user.id)

    %{
      id: user.id,
      email: user.email,
      user_name: user.user_name,
      handle: user.handle,
      status: user.status,
      verified: user.verified,
      consent_preferences: row && row.consent_preferences
    }
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
