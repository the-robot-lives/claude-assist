defmodule TimelyWeb.Hologram.Pages.AuthVerifyEmailPage do
  use Hologram.Page

  alias TimelyWeb.Hologram.Layouts.MainLayout

  route "/auth/verify-email"
  layout MainLayout, page_title: "Verify email"

  # ⟦𓏻𓅛𓁿𓄅⟧ init :: auto-generated pointer for public function init
  def init(_params, component, server) do
    token = Map.get(server.query || %{}, "token")

    status =
      case token do
        t when is_binary(t) and t != "" ->
          case Timely.Auth.SmartTokenAuth.verify_email_token(t) do
            {:ok, user} ->
              Timely.Events.dispatch(:user_verified, %{user_id: user.id})
              "ok"

            _ ->
              "error"
          end

        _ ->
          "error"
      end

    put_state(component, status: status)
  end

  # ⟦𓆅𓌨𓎁𓀈⟧ template :: auto-generated pointer for public function template
  def template do
    ~HOLO"""
    <div class="content">
      <h1 class="sg-page-title">Verify email</h1>
      {%if @status == "ok"}
        <p role="status">Email verified successfully.</p>
        <p><a href="/login" class="btn btn-black">Log in</a></p>
      {%else}
        <p class="sg-error" role="alert">Invalid or expired verification link.</p>
      {/if}
    </div>
    """
  end
end
