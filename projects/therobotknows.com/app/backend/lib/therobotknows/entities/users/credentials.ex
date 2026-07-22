defmodule Therobotknows.Users.Credentials do
  @moduledoc """
  Context for Therobotknows.Users.Credentials
  """
  alias Therobotknows.Users.Credentials.UserCredential, as: Entity
  alias Therobotknows.Schema.Users.Credentials.UserCredential, as: Schema
  use Noizu.Repo
  import Ecto.Query, only: [from: 2]
  require Logger

  def_repo(entity: Therobotknows.Users.Credentials.UserCredential)

  def list(context, options \\ []) do
    settings = Noizu.Entity.Meta.persistence(Entity) |> hd

    Therobotknows.Repo.all(Schema)
    |> Enum.map(fn record ->
      {:ok, entity} = Entity.from_record(record, settings, context, options)
      {:ok, entity} = __after_get__(entity, context, options)
      entity
    end)
  end

  def get_credential(id, context, options \\ []), do: get(id, context, options)

  # ---------------------------------------------------------------------------
  # Registration
  # ---------------------------------------------------------------------------

  def register(user, {:login, {email, password}}, context, _options) do
    {:ok, auth_provider} = Therobotknows.Auth.Providers.login()

    {:ok, description} =
      %Therobotknows.Versioned.Strings.String{
        content: "",
        time_stamp: Noizu.Entity.TimeStamp.now()
      }
      |> Therobotknows.EntityRepo.create(context)

    {:ok, description_ref} = Noizu.EntityReference.Protocol.ref(description)

    hashed_password = Bcrypt.hash_pwd_salt(password)

    {:ok, credential} =
      %Therobotknows.Users.Credentials.UserCredential{
        user: user,
        auth_provider: auth_provider,
        description: description_ref,
        status: :active,
        settings: %{
          email: email,
          password: hashed_password
        },
        state: %{},
        fingerprint: "#{email}:#{hashed_password}",
        time_stamp: Noizu.Entity.TimeStamp.now()
      }
      |> Therobotknows.EntityRepo.create(context)

    {:ok, credential}
  end

  # ---------------------------------------------------------------------------
  # Authentication
  # ---------------------------------------------------------------------------

  def authenticate({:login, {email, password}}, context, options) do
    {:ok, auth_provider} = Therobotknows.Auth.Providers.login()
    {:ok, auth_provider_id} = Therobotknows.Auth.Providers.Provider.id(auth_provider)

    with :valid <- valid_login?(email, password) do
      q =
        from u in Schema,
          where: u.auth_provider_id == ^auth_provider_id,
          where: u.status == :active,
          where: u.settings["email"] == ^email,
          select: u

      try do
        case Therobotknows.Repo.all(q) do
          [] ->
            {:error, :invalid_credentials}

          [credential] ->
            if Bcrypt.verify_pass(password, credential.settings["password"]) do
              with {:ok, credential_entity} <-
                     Therobotknows.Users.Credentials.UserCredential.entity(credential.id, context),
                   {:ok, user} <- Noizu.EntityReference.Protocol.entity(credential_entity.user, context) do
                %Therobotknows.Users.Sessions.UserSession{
                  user: user,
                  credential: credential_entity,
                  status: :active,
                  details: %{},
                  time_stamp: Noizu.Entity.TimeStamp.now()
                }
                |> Therobotknows.EntityRepo.create(context, options)
              end
            else
              {:error, {:login, :invalid_credentials}}
            end

          _error ->
            {:error, {:login, :internal_error}}
        end
      rescue
        # Fail closed: any unexpected DB/query error (e.g. undefined_table on
        # an unapplied Liquibase changelog) must never surface as a raised
        # exception (500) from an auth endpoint — treat it as a failed login.
        e ->
          Logger.error(
            "Credentials.authenticate query failed: #{Exception.format(:error, e, __STACKTRACE__)}"
          )

          {:error, :invalid_credentials}
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Password Update
  # ---------------------------------------------------------------------------

  def update_password(user, new_password, context) do
    {:ok, auth_provider} = Therobotknows.Auth.Providers.login()
    {:ok, auth_provider_id} = Therobotknows.Auth.Providers.Provider.id(auth_provider)

    email =
      case user do
        %{email: e} -> e
        _ -> nil
      end

    q =
      from c in Schema,
        where: c.user_id == ^user.id,
        where: c.auth_provider_id == ^auth_provider_id,
        where: c.status == :active,
        limit: 1

    case Therobotknows.Repo.one(q) do
      nil ->
        {:error, :credential_not_found}

      credential ->
        hashed = Bcrypt.hash_pwd_salt(new_password)

        credential
        |> Ecto.Changeset.change(%{
          settings: %{"email" => email || credential.settings["email"], "password" => hashed},
          fingerprint: "#{email || credential.settings["email"]}:#{hashed}"
        })
        |> Therobotknows.Repo.update()
    end
  end

  # ---------------------------------------------------------------------------
  # Validation Helpers
  # ---------------------------------------------------------------------------

  def standardize_email(email) do
    email
    |> String.trim()
    |> String.downcase()
  end

  def valid_login?(email, password) do
    email = standardize_email(email)
    password = String.trim(password)

    cond do
      String.length(email) < 3 -> {:error, :invalid_email}
      String.length(password) < 6 -> {:error, :invalid_password}
      :else -> :valid
    end
  end

  def login_available?(email, _context, _options \\ nil) do
    q =
      from u in Schema,
        where: u.settings["email"] == ^email,
        select: u

    case Therobotknows.Repo.all(q) do
      [] -> :valid
      [_ | _] -> {:error, {:login, :registered}}
      error -> {:error, {:login, {:internal, error}}}
    end
  end
end
