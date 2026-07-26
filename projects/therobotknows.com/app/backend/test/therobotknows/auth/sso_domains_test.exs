defmodule Therobotknows.Auth.SSODomainsTest do
  use ExUnit.Case, async: false

  alias Therobotknows.Auth.SSODomains

  setup do
    prior = %{
      domains: Application.get_env(:therobotknows, :sso_domains, %{}),
      auto_approve: Application.get_env(:therobotknows, :sso_auto_approve_domains, []),
      policies: Application.get_env(:therobotknows, :sso_domain_policies, %{})
    }

    on_exit(fn ->
      Application.put_env(:therobotknows, :sso_domains, prior.domains)
      Application.put_env(:therobotknows, :sso_auto_approve_domains, prior.auto_approve)
      Application.put_env(:therobotknows, :sso_domain_policies, prior.policies)
    end)

    :ok
  end

  defp configure(domains, auto_approve) do
    Application.put_env(:therobotknows, :sso_domains, domains)
    Application.put_env(:therobotknows, :sso_auto_approve_domains, auto_approve)
    Application.put_env(:therobotknows, :sso_domain_policies, %{})
  end

  test "empty config denies every domain" do
    configure(%{}, [])

    refute SSODomains.sso_available?("someone@example.com", :oidc)
    assert SSODomains.policy_for("someone@example.com") == nil
  end

  test "unlisted domain is denied even when other domains are allowed" do
    configure(%{"noizu.com" => ["oidc"]}, ["noizu.com"])

    refute SSODomains.sso_available?("attacker@evil.com", :oidc)
    refute SSODomains.auto_approve?("attacker@evil.com", :oidc)
  end

  test "listed domain is limited to its configured providers" do
    configure(%{"noizu.com" => ["oidc"]}, [])

    assert SSODomains.sso_available?("keith@noizu.com", :oidc)
    refute SSODomains.sso_available?("keith@noizu.com", :github)
  end

  test "domain matching is case insensitive and accepts bare domains" do
    configure(%{"Noizu.com" => ["OIDC"]}, [])

    assert SSODomains.sso_available?("Keith@NOIZU.com", :oidc)
    assert SSODomains.sso_available?("noizu.com", "oidc")
  end

  test "auto approve grants :active, otherwise pending" do
    configure(%{"noizu.com" => ["oidc"], "partner.com" => ["oidc"]}, ["noizu.com"])

    assert SSODomains.auto_approve?("keith@noizu.com", :oidc)
    assert SSODomains.registration_status("keith@noizu.com", :oidc) == :active

    refute SSODomains.auto_approve?("someone@partner.com", :oidc)
    assert SSODomains.registration_status("someone@partner.com", :oidc) == SSODomains.pending_status()
  end

  test "wildcard auto approve applies to every listed domain" do
    configure(%{"noizu.com" => ["oidc"], "partner.com" => ["oidc"]}, ["*"])

    assert SSODomains.registration_status("keith@noizu.com", :oidc) == :active
    assert SSODomains.registration_status("someone@partner.com", :oidc) == :active
    # still fail-closed for domains that are not listed at all
    assert SSODomains.registration_status("attacker@evil.com", :oidc) == SSODomains.pending_status()
    refute SSODomains.sso_available?("attacker@evil.com", :oidc)
  end

  test "public_policies and providers_map expose normalized config" do
    configure(%{"Noizu.com" => ["oidc", "google"]}, ["noizu.com"])

    assert SSODomains.providers_map() == %{"noizu.com" => ["oidc", "google"]}

    assert SSODomains.public_policies() == %{
             "noizu.com" => %{providers: ["oidc", "google"], auto_approve: true}
           }
  end

  test "explicit sso_domain_policies take precedence over the legacy map" do
    configure(%{"legacy.com" => ["oidc"]}, [])

    Application.put_env(:therobotknows, :sso_domain_policies, %{
      "explicit.com" => %{providers: ["oidc"], auto_approve: true}
    })

    refute SSODomains.sso_available?("user@legacy.com", :oidc)
    assert SSODomains.registration_status("user@explicit.com", :oidc) == :active
  end
end
