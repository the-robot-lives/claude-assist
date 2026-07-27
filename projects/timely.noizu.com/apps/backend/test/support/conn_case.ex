defmodule TimelyWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import TimelyWeb.ConnCase

      @endpoint TimelyWeb.Endpoint
    end
  end

  setup tags do
    Timely.DataCase.setup_sandbox(tags)
    n = System.unique_integer([:positive])
    remote_ip = {127, rem(div(n, 65_536), 256), rem(div(n, 256), 256), rem(n, 256)}
    {:ok, conn: %{Phoenix.ConnTest.build_conn() | remote_ip: remote_ip}}
  end

  @doc """
  Creates a test user with login credential and returns access/refresh tokens.

  Inserts directly via Ecto schemas (bypasses Noizu entity layer) for speed and
  simplicity. The auth_providers seed must have run (login provider must exist).
  """
  # ⟦𓎱𓀎𓇒𓂁⟧ setup_user_and_token :: Creates a test user with login credential and returns access/refresh tokens.
  def setup_user_and_token(_context \\ %{}) do
    login_provider_id = UUID.uuid5(:oid, "Timely.Schema.Auth.Providers.Provider@Login")

    # Ensure the login auth provider exists (idempotent)
    Timely.Repo.insert!(
      %Timely.Schema.Auth.Providers.Provider{
        id: login_provider_id,
        title: "Login",
        description: "Email and password authentication"
      },
      on_conflict: :nothing,
      conflict_target: :id
    )

    uniq = System.unique_integer([:positive])
    email = "test-#{uniq}@example.com"
    password = "password123"
    hashed = Bcrypt.hash_pwd_salt(password)

    user = %Timely.Schema.Users.User{
      id: Ecto.UUID.generate(),
      email: email,
      user_name: "testuser#{uniq}",
      handle: "test#{uniq}",
      hashed_password: hashed,
      status: :active,
      verified: false,
      flagged: false
    }

    {:ok, user} = Timely.Repo.insert(user)

    credential = %Timely.Schema.Users.Credentials.UserCredential{
      id: Ecto.UUID.generate(),
      user_id: user.id,
      auth_provider_id: login_provider_id,
      status: :active,
      settings: %{"email" => email, "password" => hashed},
      state: %{},
      fingerprint: "#{email}:#{hashed}"
    }

    {:ok, _credential} = Timely.Repo.insert(credential)

    session = %Timely.Schema.Users.Sessions.UserSession{
      id: Ecto.UUID.generate(),
      user_id: user.id,
      status: :active,
      details: %{}
    }

    {:ok, session} = Timely.Repo.insert(session)

    # Build entity-layer session struct for Guardian signing
    session_entity = %Timely.Users.Sessions.UserSession{
      id: session.id,
      user: {:ref, Timely.Users.User, user.id},
      status: :active,
      details: %{}
    }

    {:ok, access_token, _claims} =
      Timely.Guardian.encode_and_sign(session_entity, %{}, token_type: "access", ttl: {1, :hour})

    {:ok, refresh_token, %{"jti" => jti}} =
      Timely.Guardian.encode_and_sign(session_entity, %{}, token_type: "refresh", ttl: {7, :day})

    Timely.Auth.TokenStore.store_refresh_jti(jti)

    %{
      user: user,
      password: password,
      access_token: access_token,
      refresh_token: refresh_token,
      session: session
    }
  end

  @doc """
  Adds a Bearer authorization header to the connection.
  """
  # ⟦𓏘𓇃𓅭𓎇⟧ authenticated_conn :: Adds a Bearer authorization header to the connection.
  def authenticated_conn(conn, access_token) do
    Plug.Conn.put_req_header(conn, "authorization", "Bearer #{access_token}")
  end
end
