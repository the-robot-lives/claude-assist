defmodule GottaCcWeb.DirectoryClaimController do
  use GottaCcWeb, :controller

  alias GottaCc.Guardian
  alias GottaCc.Users
  alias GottaCc.Directory
  alias GottaCc.Directory.Submissions

  @valid_methods ["meta_tag", "dns_txt"]

  def create(conn, %{"slug" => slug} = params) do
    user = get_current_user(conn)
    method = params["method"] || "meta_tag"

    cond do
      method not in @valid_methods ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "method must be one of: #{Enum.join(@valid_methods, ", ")}"})

      true ->
        case Directory.get_site_by_slug(slug) do
          nil ->
            conn |> put_status(:not_found) |> json(%{error: "Site not found"})

          site ->
            case Submissions.create_claim(site.id, user.id, method) do
              {:ok, claim} ->
                conn
                |> put_status(:created)
                |> json(%{claim: claim_to_json(claim, site.slug, true)})

              {:error, changeset} ->
                conn
                |> put_status(:unprocessable_entity)
                |> json(%{errors: format_errors(changeset)})
            end
        end
    end
  end

  def verify(conn, %{"id" => id}) do
    user = get_current_user(conn)

    case Submissions.verify_claim(id, user.id) do
      {:ok, claim} ->
        json(conn, %{claim: %{id: claim.id, status: claim.status, verified_at: claim.verified_at}})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Claim not found"})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Verification failed", reason: reason_to_string(reason)})
    end
  end

  def index(conn, _params) do
    user = get_current_user(conn)
    claims = Submissions.list_claims_for_user(user.id)
    json(conn, %{claims: Enum.map(claims, &claim_to_json(&1, site_slug(&1), true))})
  end

  # --- helpers -------------------------------------------------------------

  defp get_current_user(conn) do
    session = Guardian.Plug.current_resource(conn)

    case session.user do
      {:ref, _, id} ->
        {:ok, user} = Users.get_user(id, Noizu.Context.system())
        user

      %GottaCc.Users.User{} = user ->
        user
    end
  end

  defp claim_to_json(claim, slug, include_token?) do
    base = %{
      id: claim.id,
      site_slug: slug,
      method: claim.method,
      status: claim.status,
      verified_at: claim.verified_at,
      instructions: instructions(claim, slug)
    }

    if include_token?, do: Map.put(base, :token, claim.token), else: base
  end

  defp instructions(%{method: "meta_tag", token: token}, _slug) do
    %{
      method: "meta_tag",
      detail:
        "Add this tag inside the <head> of your site's homepage, then click verify.",
      snippet: ~s(<meta name="gotta-cc" content="#{token}">)
    }
  end

  defp instructions(%{method: "dns_txt", token: token}, _slug) do
    %{
      method: "dns_txt",
      detail:
        "Add a DNS TXT record at your domain root with this value, then click verify.",
      snippet: "gotta-cc=#{token}"
    }
  end

  defp site_slug(claim) do
    case GottaCc.Repo.get(GottaCc.Schema.Directory.Site, claim.site_id) do
      nil -> nil
      site -> site.slug
    end
  end

  defp reason_to_string(reason) when is_binary(reason), do: reason
  defp reason_to_string(reason) when is_atom(reason), do: to_string(reason)
  defp reason_to_string(reason), do: inspect(reason)

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
