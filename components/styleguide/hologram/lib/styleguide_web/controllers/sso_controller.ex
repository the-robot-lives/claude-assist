defmodule StyleguideWeb.SSOController do
  @moduledoc """
  Authentik OIDC redirect flow.

  * `GET /auth/oidc` — start authorization
  * `GET /auth/oidc/callback` — exchange code, mint one-time SSO code, redirect to
    Hologram `/auth/sso-callback` which sets cookies and sends the user to **`/app`**
  """
  use StyleguideWeb, :controller

  alias Styleguide.Auth
  alias Styleguide.Auth.SSOCode

  def oidc_init(conn, _params) do
    if Auth.oidc_enabled?() do
      config = Auth.oidc_config()

      if is_map(config) do
        state = Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)
        redirect_uri = config[:redirect_uri] || config["redirect_uri"] || Map.get(config, :redirect_uri)

        case OpenIDConnect.authorization_uri(config, redirect_uri, %{state: state}) do
          {:ok, uri} ->
            conn
            |> put_session(:oidc_state, state)
            |> redirect(external: uri)

          {:error, reason} ->
            redirect(conn, to: "/login?error=oidc_init&detail=#{encode_error(reason)}")
        end
      else
        redirect(conn, to: "/login?error=sso_misconfigured")
      end
    else
      redirect(conn, to: "/login?error=sso_disabled")
    end
  end

  def oidc_callback(conn, %{"code" => code} = params) do
    config = Auth.oidc_config()
    expected = get_session(conn, :oidc_state)
    state = Map.get(params, "state")

    cond do
      not Auth.oidc_enabled?() or not is_map(config) ->
        redirect(conn, to: "/login?error=sso_disabled")

      is_binary(expected) and is_binary(state) and expected != state ->
        redirect(conn, to: "/login?error=oidc_state")

      true ->
        redirect_uri = config[:redirect_uri] || config["redirect_uri"] || Map.get(config, :redirect_uri)

        with {:ok, tokens} <-
               OpenIDConnect.fetch_tokens(config, %{code: code, redirect_uri: redirect_uri}),
             id_token when is_binary(id_token) <- tokens["id_token"] || tokens[:id_token],
             {:ok, claims} <- OpenIDConnect.verify(config, id_token) do
          email = claims["email"] || claims[:email]
          given = claims["given_name"] || claims[:given_name] || ""
          family = claims["family_name"] || claims[:family_name] || ""
          name = String.trim("#{given} #{family}")
          name = if name == "", do: claims["name"] || claims[:name] || email, else: name
          sub = to_string(claims["sub"] || claims[:sub] || "")

          if is_binary(email) and email != "" do
            user = %{email: email, name: name || email, sub: sub}
            {:ok, sso_code} = SSOCode.create(user)

            conn
            |> delete_session(:oidc_state)
            # Plug cookies (backup) + one-time code for Hologram cookie write
            |> Auth.put_user_cookies(user)
            |> put_session(:sg_user_email, email)
            # NEVER send users to /style-guide here — always Hologram complete → /app
            |> redirect(to: "/auth/sso-callback?code=#{URI.encode_www_form(sso_code)}")
          else
            redirect(conn, to: "/login?error=oidc_no_email")
          end
        else
          _ ->
            redirect(conn, to: "/login?error=oidc_failed")
        end
    end
  end

  def oidc_callback(conn, _params) do
    redirect(conn, to: "/login?error=oidc_failed")
  end

  def logout(conn, _params) do
    conn
    |> Auth.clear_user_cookies()
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end

  defp encode_error(reason) do
    reason
    |> inspect()
    |> String.slice(0, 80)
    |> URI.encode_www_form()
  end
end
