defmodule Therobotplans.Auth.SSODomains do
  @moduledoc """
  Normalizes per-domain SSO policy.

  `:sso_domains` controls which providers are available for an email domain:

      %{"example.com" => ["oidc", "google"]}

  `:sso_auto_approve_domains` is an optional list of domains whose new SSO
  registrations should be active immediately. Other SSO registrations are
  created pending approval unless an invite activates them.
  """

  def policies do
    explicit = Application.get_env(:therobotplans, :sso_domain_policies, %{})
    legacy = Application.get_env(:therobotplans, :sso_domains, %{})
    auto_approve = Application.get_env(:therobotplans, :sso_auto_approve_domains, [])

    case explicit do
      value when is_map(value) and map_size(value) > 0 ->
        normalize_explicit_policies(value)

      _ ->
        build_policies(legacy, auto_approve)
    end
  end

  def providers_map do
    policies()
    |> Enum.into(%{}, fn {domain, policy} -> {domain, policy.providers} end)
  end

  def public_policies do
    policies()
    |> Enum.into(%{}, fn {domain, policy} ->
      {domain, %{providers: policy.providers, auto_approve: policy.auto_approve}}
    end)
  end

  def sso_available?(email_or_domain, provider) do
    provider = provider_name(provider)

    case policy_for(email_or_domain) do
      %{providers: providers} -> provider in providers
      nil -> false
    end
  end

  def auto_approve?(email_or_domain, provider) do
    provider = provider_name(provider)

    case policy_for(email_or_domain) do
      %{providers: providers, auto_approve: true} -> provider in providers
      _ -> false
    end
  end

  def registration_status(email_or_domain, provider) do
    if auto_approve?(email_or_domain, provider), do: :active, else: :pending
  end

  def policy_for(email_or_domain) do
    domain = normalize_domain(email_or_domain)
    if domain, do: Map.get(policies(), domain)
  end

  def build_policies(domains, auto_approve_domains) when is_map(domains) do
    auto_approve_set =
      auto_approve_domains
      |> normalize_domain_list()
      |> MapSet.new()

    domains
    |> Enum.reduce(%{}, fn {domain, providers}, acc ->
      domain = normalize_domain(domain)
      providers = normalize_providers(providers)

      if domain && providers != [] do
        Map.put(acc, domain, %{
          providers: providers,
          auto_approve:
            MapSet.member?(auto_approve_set, "*") || MapSet.member?(auto_approve_set, domain)
        })
      else
        acc
      end
    end)
  end

  def build_policies(_, _), do: %{}

  defp normalize_explicit_policies(policies) do
    policies
    |> Enum.reduce(%{}, fn {domain, policy}, acc ->
      domain = normalize_domain(domain)
      policy = normalize_policy(policy)

      if domain && policy.providers != [] do
        Map.put(acc, domain, policy)
      else
        acc
      end
    end)
  end

  defp normalize_policy(providers) when is_list(providers),
    do: %{providers: normalize_providers(providers), auto_approve: false}

  defp normalize_policy(policy) when is_map(policy) do
    providers =
      Map.get(policy, :providers) ||
        Map.get(policy, "providers") ||
        Map.get(policy, :sso_providers) ||
        Map.get(policy, "sso_providers") ||
        []

    auto_approve =
      Map.get(policy, :auto_approve) ||
        Map.get(policy, "auto_approve") ||
        Map.get(policy, :autoApprove) ||
        Map.get(policy, "autoApprove") ||
        false

    %{providers: normalize_providers(providers), auto_approve: truthy?(auto_approve)}
  end

  defp normalize_policy(_), do: %{providers: [], auto_approve: false}

  defp normalize_providers(providers) when is_binary(providers) do
    providers
    |> String.split(",", trim: true)
    |> normalize_providers()
  end

  defp normalize_providers(providers) when is_list(providers) do
    providers
    |> Enum.map(&provider_name/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp normalize_providers(_), do: []

  defp normalize_domain_list(value) when is_binary(value) do
    value
    |> String.split(~r/[,\s;]+/, trim: true)
    |> Enum.map(&normalize_domain/1)
    |> Enum.reject(&is_nil/1)
  end

  defp normalize_domain_list(value) when is_list(value) do
    value
    |> Enum.map(&normalize_domain/1)
    |> Enum.reject(&is_nil/1)
  end

  defp normalize_domain_list(%MapSet{} = value), do: normalize_domain_list(MapSet.to_list(value))
  defp normalize_domain_list(_), do: []

  defp normalize_domain(value) when is_atom(value),
    do: value |> Atom.to_string() |> normalize_domain()

  defp normalize_domain(value) when is_binary(value) do
    value = value |> String.trim() |> String.downcase()

    cond do
      value == "" ->
        nil

      String.contains?(value, "@") ->
        value |> String.split("@") |> List.last() |> normalize_domain()

      true ->
        value
    end
  end

  defp normalize_domain(_), do: nil

  defp provider_name(value) when is_atom(value), do: Atom.to_string(value)
  defp provider_name(value) when is_binary(value), do: value |> String.trim() |> String.downcase()
  defp provider_name(_), do: ""

  defp truthy?(value) when value in [true, "true", "TRUE", "1", 1, "yes", "YES", "on", "ON"],
    do: true

  defp truthy?(_), do: false
end
