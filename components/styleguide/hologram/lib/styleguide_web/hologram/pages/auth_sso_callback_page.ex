defmodule StyleguideWeb.Hologram.Pages.AuthSsoCallbackPage do
  @moduledoc """
  Completes Authentik SSO on the Hologram side and sends the user to `/app`.

  Phoenix `/auth/oidc/callback` mints a one-time code and redirects here.
  We write Hologram cookies then client-navigate to the dashboard.
  """
  use Hologram.Page

  alias Styleguide.Auth
  alias Styleguide.Auth.SSOCode
  alias StyleguideWeb.Hologram.Layouts.MainLayout

  route "/auth/sso-callback"
  layout MainLayout, page_title: "Signing in…"

  def init(_params, component, server) do
    code = query(server, "code")
    error = query(server, "error")

    cond do
      is_binary(error) and error != "" ->
        put_state(component, status: "error", message: "SSO failed: #{error}", email: "")

      is_binary(code) and code != "" ->
        case SSOCode.exchange(code) do
          {:ok, user} ->
            server = Auth.put_user_cookies_hologram(server, user)

            component =
              put_state(component,
                status: "ok",
                email: user.email,
                message: "Signed in as #{user.email}."
              )

            # Cookie ops from init are flushed on this response; navigate to /app next.
            # put_redirect from page init is not applied as HTTP 302 by Hologram 0.10 —
            # use client redirect in the template.
            {component, server}

          {:error, _} ->
            put_state(component,
              status: "error",
              email: "",
              message: "Invalid or expired SSO code. Please sign in again."
            )
        end

      true ->
        put_state(component,
          status: "error",
          email: "",
          message: "Missing SSO code. Please sign in again."
        )
    end
  end

  def template do
    ~HOLO"""
    <div class="content login-page">
      <h1 class="login-title">Signing in…</h1>
      {%if @status == "error"}
        <p class="sg-error" role="alert">{@message}</p>
        <p><a href="/login" class="btn btn-outline">Back to log in</a></p>
      {%else}
        <p class="app-muted">{@message} Opening dashboard…</p>
        <p><a href="/app" class="btn btn-black" id="sg-sso-continue">Continue to dashboard</a></p>
        <script>
          window.location.replace("/app");
        </script>
      {/if}
    </div>
    """
  end

  defp query(server, key) do
    q = Map.get(server, :query) || %{}
    Map.get(q, key)
  end
end
