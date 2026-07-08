defmodule Starter.Auth.SSOTest do
  use Starter.DataCase

  alias Starter.Schema.Auth.Providers.Provider
  alias Starter.Schema.Users.User

  test "auto-provisioned SSO users are pending until profile completion" do
    ensure_provider!("Google", "Google OAuth")
    email = "sso-#{System.unique_integer([:positive])}@example.com"

    assert {:ok, session} =
             Starter.Auth.SSO.authenticate_sso(:google, %{
               email: email,
               name: %{first: "Ada", last: "Lovelace"},
               sub: "google-#{System.unique_integer([:positive])}"
             })

    assert {:ref, Starter.Users.User, user_id} = session.user

    user = Starter.Repo.get!(User, user_id)
    assert user.email == email
    assert user.status == :pending
    assert user.verified == true
    assert user.profile_completed_at == nil
    assert user.mobile_phone == nil
  end

  defp ensure_provider!(title, description) do
    id = UUID.uuid5(:oid, "Starter.Schema.Auth.Providers.Provider@#{title}")

    Starter.Repo.insert!(
      %Provider{id: id, title: title, description: description},
      on_conflict: :nothing,
      conflict_target: :id
    )
  end
end
