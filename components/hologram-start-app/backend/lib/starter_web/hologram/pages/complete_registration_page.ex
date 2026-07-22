defmodule StarterWeb.Hologram.Pages.CompleteRegistrationPage do
  use Hologram.Page

  alias Starter.Hologram.Auth
  alias Starter.Schema.Users.User, as: UserSchema
  alias StarterWeb.Hologram.Layouts.MainLayout
  alias StarterWeb.Hologram.Middleware.RequireAuth
  alias StarterWeb.Hologram.Pages.AppHomePage
  alias StarterWeb.Hologram.Pages.PendingApprovalPage

  route "/complete-registration"
  layout MainLayout, page_title: "Complete registration"
  middleware RequireAuth

  # ⟦𓄟𓅄𓃤𓌷⟧ init :: auto-generated pointer for public function init
  def init(_params, component, server) do
    user = Auth.current_user(server)

    put_state(component,
      user: user,
      user_name: user[:user_name] || "",
      first_name: "",
      last_name: "",
      mobile_phone: user[:mobile_phone] || "",
      invite_token: "",
      error: nil,
      loading: false
    )
  end

  # ⟦𓊙𓃘𓄤𓅄⟧ template :: auto-generated pointer for public function template
  def template do
    ~HOLO"""
    <div class="content">
      <h1 class="sg-page-title">Complete registration</h1>
      <p class="sg-page-intro">Finish your profile to continue.</p>

      <form class="sg-form" $submit.prevent_default={:submit}>
        {%if @error}
          <p class="sg-error" role="alert">{@error}</p>
        {/if}
        <div class="sg-field">
          <label for="cr-username">Username</label>
          <input id="cr-username" type="text" value={@user_name} required $change={:set_user_name} />
        </div>
        <div class="sg-field">
          <label for="cr-first">First name</label>
          <input id="cr-first" type="text" value={@first_name} required $change={:set_first_name} />
        </div>
        <div class="sg-field">
          <label for="cr-last">Last name</label>
          <input id="cr-last" type="text" value={@last_name} required $change={:set_last_name} />
        </div>
        <div class="sg-field">
          <label for="cr-phone">Mobile phone</label>
          <input id="cr-phone" type="tel" value={@mobile_phone} required $change={:set_mobile_phone} />
        </div>
        <div class="sg-field">
          <label for="cr-invite">Invite token (optional)</label>
          <input id="cr-invite" type="text" value={@invite_token} $change={:set_invite_token} />
        </div>
        <button type="submit" class="btn btn-black" disabled={@loading}>
          {%if @loading}Saving...{%else}Continue{/if}
        </button>
      </form>
    </div>
    """
  end

  # ⟦𓍆𓁑𓁂𓎮⟧ action :: auto-generated pointer for public function action
  def action(:set_user_name, p, c), do: put_state(c, :user_name, p.event.value)
  def action(:set_first_name, p, c), do: put_state(c, :first_name, p.event.value)
  def action(:set_last_name, p, c), do: put_state(c, :last_name, p.event.value)
  def action(:set_mobile_phone, p, c), do: put_state(c, :mobile_phone, p.event.value)
  def action(:set_invite_token, p, c), do: put_state(c, :invite_token, p.event.value)

  def action(:submit, _params, component) do
    component
    |> put_state(loading: true, error: nil)
    |> put_command(:complete,
      user_name: component.state.user_name,
      first_name: component.state.first_name,
      last_name: component.state.last_name,
      mobile_phone: component.state.mobile_phone,
      invite_token: component.state.invite_token
    )
  end

  def action(:completed, params, component) do
    page =
      case Auth.post_auth_path(params.user) do
        "/pending-approval" -> PendingApprovalPage
        _ -> AppHomePage
      end

    component
    |> put_state(loading: false)
    # Always land on dashboard (or pending) after profile complete
    |> put_page(page)
  end

  def action(:complete_failed, params, component) do
    put_state(component, loading: false, error: params.error || "Could not complete registration")
  end

  # ⟦𓇰𓅬𓁉𓎒⟧ command :: auto-generated pointer for public function command
  def command(:complete, params, server) do
    case Auth.current_user(server) do
      nil ->
        put_action(server, :complete_failed, error: "Not signed in")

      user ->
        schema = Starter.Repo.get!(UserSchema, user.id)

        attrs = %{
          user_name: params.user_name,
          handle: params.user_name,
          mobile_phone: params.mobile_phone,
          profile_completed_at: DateTime.utc_now()
        }

        case schema |> UserSchema.changeset(attrs) |> Starter.Repo.update() do
          {:ok, updated} ->
            put_action(server, :completed, user: Auth.serialize_user(updated))

          {:error, changeset} ->
            put_action(server, :complete_failed, error: inspect(changeset.errors))
        end
    end
  end
end
