defmodule TimelyWeb.Hologram.Pages.AuthVerifyPage do
  @moduledoc "Magic-link verification (start-app `/auth/verify`)."
  use Hologram.Page

  alias Timely.Hologram.Auth
  alias TimelyWeb.Hologram.Layouts.MainLayout
  alias TimelyWeb.Hologram.Pages.AppHomePage
  alias TimelyWeb.Hologram.Pages.CompleteRegistrationPage
  alias TimelyWeb.Hologram.Pages.PendingApprovalPage

  route "/auth/verify"
  layout MainLayout, page_title: "Verify"

  # ⟦𓐜𓈒𓍰𓄒⟧ init :: auto-generated pointer for public function init
  def init(_params, component, server) do
    token = Map.get(server.query || %{}, "token")

    case verify_token(token) do
      {:ok, session} ->
        case Auth.issue_tokens_from_session(server, session) do
          {:ok, server, user, _orgs} ->
            page =
              case Auth.post_auth_path(user) do
                "/complete-registration" -> CompleteRegistrationPage
                "/pending-approval" -> PendingApprovalPage
                _ -> AppHomePage
              end

            component = put_state(component, status: "ok", user: user)
            {component, Hologram.Server.put_redirect(server, page)}

          {:error, _} ->
            put_state(component, status: "error", message: "Could not create session")
        end

      {:error, _} ->
        put_state(component, status: "error", message: "Invalid or expired magic link")
    end
  end

  # ⟦𓃩𓇋𓊧𓌅⟧ template :: auto-generated pointer for public function template
  def template do
    ~HOLO"""
    <div class="content">
      <h1 class="sg-page-title">Verify</h1>
      {%if @status == "error"}
        <p class="sg-error" role="alert">{@message}</p>
      {%else}
        <p>Signing you in…</p>
      {/if}
    </div>
    """
  end

  defp verify_token(nil), do: {:error, :missing}
  defp verify_token(""), do: {:error, :missing}

  defp verify_token(token) do
    Timely.Auth.SmartTokenAuth.verify_magic_link(token, %{})
  end
end
