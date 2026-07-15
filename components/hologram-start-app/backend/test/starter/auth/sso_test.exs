defmodule Starter.Auth.SSOTest do
  use Starter.DataCase

  alias Starter.Schema.Auth.Providers.Provider
  alias Starter.Schema.Users.User

  setup do
    previous_domains = Application.get_env(:starter, :sso_domains)
    previous_auto_approve = Application.get_env(:starter, :sso_auto_approve_domains)
    previous_policies = Application.get_env(:starter, :sso_domain_policies)

    Application.put_env(:starter, :sso_domains, %{})
    Application.put_env(:starter, :sso_auto_approve_domains, [])
    Application.put_env(:starter, :sso_domain_policies, %{})

    on_exit(fn ->
      Application.put_env(:starter, :sso_domains, previous_domains)
      Application.put_env(:starter, :sso_auto_approve_domains, previous_auto_approve)
      Application.put_env(:starter, :sso_domain_policies, previous_policies)
    end)
  end

  test "auto-provisioned SSO users are pending until profile completion" do
    ensure_provider!("Google", "Google OAuth")
    set_sso_policy("example.com", ["google"], auto_approve: false)
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

  test "auto-approved SSO domain creates active incomplete users" do
    ensure_provider!("Google", "Google OAuth")
    set_sso_policy("example.com", ["google"], auto_approve: true)
    email = "sso-approved-#{System.unique_integer([:positive])}@example.com"

    assert {:ok, session} =
             Starter.Auth.SSO.authenticate_sso("google", %{
               email: email,
               name: %{first: "Ada", last: "Lovelace"},
               sub: "google-approved-#{System.unique_integer([:positive])}"
             })

    assert {:ref, Starter.Users.User, user_id} = session.user

    user = Starter.Repo.get!(User, user_id)
    assert user.status == :active
    assert user.approved_at
    assert user.profile_completed_at == nil
  end

  test "SSO is rejected when the email domain is not available for the provider" do
    ensure_provider!("Google", "Google OAuth")
    set_sso_policy("example.com", ["oidc"], auto_approve: true)

    assert {:error, :sso_not_allowed} =
             Starter.Auth.SSO.authenticate_sso(:google, %{
               email: "sso-disabled-#{System.unique_integer([:positive])}@example.com",
               name: %{first: "Ada", last: "Lovelace"},
               sub: "google-disabled-#{System.unique_integer([:positive])}"
             })
  end

  defp ensure_provider!(title, description) do
    id = UUID.uuid5(:oid, "Starter.Schema.Auth.Providers.Provider@#{title}")

    Starter.Repo.insert!(
      %Provider{id: id, title: title, description: description},
      on_conflict: :nothing,
      conflict_target: :id
    )
  end

  defp set_sso_policy(domain, providers, opts) do
    Application.put_env(:starter, :sso_domain_policies, %{
      domain => %{providers: providers, auto_approve: Keyword.get(opts, :auto_approve, false)}
    })
  end
end
