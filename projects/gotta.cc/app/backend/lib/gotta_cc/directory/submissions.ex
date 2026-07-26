defmodule GottaCc.Directory.Submissions do
  @moduledoc """
  Context for user-proposed directory submissions, ownership claims, and the
  editorial moderation queue (see changelog 026).

  * Submissions — public users propose a site; editors review, then approve
    (publishing a `directory_sites` row) or reject.
  * Claims — a user proves ownership of an already-listed site via a meta tag
    or DNS TXT record, earning a verified-owner badge on the listing.
  """

  import Ecto.Query
  alias GottaCc.Repo
  alias GottaCc.Schema.Directory.Submission
  alias GottaCc.Schema.Directory.SiteClaim
  alias GottaCc.Schema.Directory.Site, as: SiteSchema
  alias GottaCc.Schema.Directory.Category, as: CategorySchema

  @review_statuses ["pending", "in_review"]

  # ---------------------------------------------------------------------------
  # Submissions
  # ---------------------------------------------------------------------------

  @doc """
  Creates a pending submission for `user_id`, which may be `nil` for an
  anonymous suggestion — those land in the same moderation queue and carry an
  optional `contact_email` instead of a submitter. Derives `domain` from the URL
  when not supplied. Returns `{:ok, submission}` or `{:error, changeset}`.
  """
  def create_submission(user_id, attrs) do
    attrs = normalize_keys(attrs)
    url = normalize_url(attrs["url"])
    domain = attrs["domain"] || derive_domain(url)

    params = %{
      "submitter_id" => user_id,
      "contact_email" => normalize_email(attrs["contact_email"]),
      "name" => attrs["name"],
      "url" => url,
      "domain" => domain,
      "summary" => attrs["summary"],
      "proposed_category_slug" => attrs["category_slug"] || attrs["proposed_category_slug"],
      "tags" => normalize_tags(attrs["tags"]),
      "sug_originality" => attrs["sug_originality"],
      "sug_human_authorship" => attrs["sug_human_authorship"],
      "sug_depth" => attrs["sug_depth"],
      "sug_freshness" => attrs["sug_freshness"],
      "sug_design_quality" => attrs["sug_design_quality"],
      "status" => "pending"
    }

    %Submission{}
    |> Submission.changeset(params)
    |> Repo.insert()
  end

  @doc "Lists a user's own submissions, newest first."
  def list_submissions_for_user(user_id) do
    Repo.all(
      from s in Submission,
        where: s.submitter_id == ^user_id,
        order_by: [desc: s.inserted_at]
    )
  end

  @doc "Fetches a submission by id (any owner). Returns nil if missing."
  def get_submission(id), do: Repo.get(Submission, id)

  @doc "Fetches a submission scoped to its owner. Returns nil if not theirs."
  def get_submission_for_user(id, user_id) do
    Repo.one(
      from s in Submission,
        where: s.id == ^id and s.submitter_id == ^user_id
    )
  end

  @doc """
  Review queue for editors. `:status` filters to a single status; default is the
  open queue (`pending` + `in_review`). Newest first.
  """
  def list_for_review(opts \\ []) do
    base = from(s in Submission, order_by: [desc: s.inserted_at])

    query =
      case opts[:status] do
        nil -> from s in base, where: s.status in ^@review_statuses
        status when is_binary(status) -> from s in base, where: s.status == ^status
      end

    Repo.all(query)
  end

  @doc """
  Approves a submission: resolves the category, inserts a published
  `directory_sites` row (scores + featured from `attrs`), and marks the
  submission `published` with reviewer + published site references. Runs in a
  transaction. Returns `{:ok, %{submission: ..., site: ...}}`.
  """
  def approve_submission(submission_id, reviewer_id, attrs) do
    attrs = normalize_keys(attrs)

    Repo.transaction(fn ->
      submission = Repo.get(Submission, submission_id)

      cond do
        is_nil(submission) ->
          Repo.rollback(:not_found)

        submission.status in ["approved", "published", "rejected"] ->
          Repo.rollback(:already_reviewed)

        true ->
          category_slug = attrs["category_slug"] || submission.proposed_category_slug

          case resolve_category(category_slug) do
            nil ->
              Repo.rollback(:category_not_found)

            category ->
              scores = normalize_keys(attrs["scores"] || %{})

              site_params = %{
                "slug" => unique_slug(derive_slug(submission.domain)),
                "name" => submission.name,
                "url" => submission.url,
                "domain" => submission.domain,
                "summary" => attrs["summary"] || submission.summary || submission.name,
                "category_id" => category.id,
                "tags" => submission.tags || [],
                "originality" => score(scores, "originality", submission.sug_originality),
                "human_authorship" =>
                  score(scores, "human_authorship", submission.sug_human_authorship),
                "depth" => score(scores, "depth", submission.sug_depth),
                "freshness" => score(scores, "freshness", submission.sug_freshness),
                "design_quality" =>
                  score(scores, "design_quality", submission.sug_design_quality),
                "featured" => truthy(attrs["featured"]),
                "status" => "published"
              }

              with {:ok, site} <-
                     %SiteSchema{} |> SiteSchema.changeset(site_params) |> Repo.insert(),
                   {:ok, updated} <-
                     submission
                     |> Submission.changeset(%{
                       "status" => "published",
                       "reviewer_id" => reviewer_id,
                       "reviewer_notes" => attrs["reviewer_notes"],
                       "published_site_id" => site.id
                     })
                     |> Repo.update() do
                %{submission: updated, site: site}
              else
                {:error, changeset} -> Repo.rollback(changeset)
              end
          end
      end
    end)
  end

  @doc "Rejects a submission with a reviewer note."
  def reject_submission(submission_id, reviewer_id, reason) do
    case Repo.get(Submission, submission_id) do
      nil ->
        {:error, :not_found}

      submission ->
        submission
        |> Submission.changeset(%{
          "status" => "rejected",
          "reviewer_id" => reviewer_id,
          "reviewer_notes" => reason
        })
        |> Repo.update()
    end
  end

  # ---------------------------------------------------------------------------
  # Claims
  # ---------------------------------------------------------------------------

  @doc """
  Creates (or refreshes) a pending ownership claim for `site_id`/`user_id` using
  `method` (`"meta_tag"` | `"dns_txt"`). Idempotent per (site,user): an existing
  pending/rejected claim is re-tokenized rather than duplicated.
  """
  def create_claim(site_id, user_id, method) do
    token = generate_token()

    existing =
      Repo.one(
        from c in SiteClaim,
          where: c.site_id == ^site_id and c.user_id == ^user_id
      )

    case existing do
      nil ->
        %SiteClaim{}
        |> SiteClaim.changeset(%{
          "site_id" => site_id,
          "user_id" => user_id,
          "method" => method,
          "token" => token,
          "status" => "pending"
        })
        |> Repo.insert()

      %SiteClaim{status: "verified"} = claim ->
        {:ok, claim}

      %SiteClaim{} = claim ->
        claim
        |> SiteClaim.changeset(%{"method" => method, "token" => token, "status" => "pending"})
        |> Repo.update()
    end
  end

  @doc "Lists a user's own claims, newest first."
  def list_claims_for_user(user_id) do
    Repo.all(
      from c in SiteClaim,
        where: c.user_id == ^user_id,
        order_by: [desc: c.inserted_at]
    )
  end

  @doc "Fetches a claim scoped to its owner. Returns nil if not theirs."
  def get_claim_for_user(id, user_id) do
    Repo.one(from c in SiteClaim, where: c.id == ^id and c.user_id == ^user_id)
  end

  @doc """
  Verifies a pending claim by checking the site for the token. `meta_tag` fetches
  the homepage and looks for `<meta name="gotta-cc" content="TOKEN">`; `dns_txt`
  resolves the domain's TXT records for `gotta-cc=TOKEN`. On success the claim is
  marked `verified` and the site's owner badge is set. Never raises.
  """
  def verify_claim(claim_id, user_id) do
    case get_claim_for_user(claim_id, user_id) do
      nil ->
        {:error, :not_found}

      %SiteClaim{status: "verified"} = claim ->
        {:ok, claim}

      %SiteClaim{} = claim ->
        site = Repo.get(SiteSchema, claim.site_id)

        result =
          case claim.method do
            "meta_tag" -> verify_meta_tag(site, claim.token)
            "dns_txt" -> verify_dns_txt(site, claim.token)
            _ -> {:error, :unsupported_method}
          end

        case result do
          :ok -> mark_verified(claim)
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp mark_verified(claim) do
    now = DateTime.utc_now()

    Repo.transaction(fn ->
      {:ok, updated} =
        claim
        |> SiteClaim.changeset(%{"status" => "verified", "verified_at" => now})
        |> Repo.update()

      from(s in SiteSchema, where: s.id == ^claim.site_id)
      |> Repo.update_all(set: [claimed_by_user_id: claim.user_id, claim_verified: true])

      updated
    end)
  end

  # ---------------------------------------------------------------------------
  # Verification internals
  # ---------------------------------------------------------------------------

  defp verify_meta_tag(nil, _token), do: {:error, :site_not_found}

  defp verify_meta_tag(%SiteSchema{url: url}, token) do
    try do
      case Req.get(url,
             max_redirects: 3,
             receive_timeout: 8_000,
             connect_options: [timeout: 8_000],
             retry: false
           ) do
        {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
          if meta_tag_present?(to_string(body), token),
            do: :ok,
            else: {:error, :not_found_on_page}

        {:ok, %Req.Response{status: status}} ->
          {:error, {:http_status, status}}

        {:error, reason} ->
          {:error, {:http_error, inspect(reason)}}
      end
    rescue
      e -> {:error, {:http_error, Exception.message(e)}}
    end
  end

  defp meta_tag_present?(html, token) do
    # Match a <meta> tag carrying name="gotta-cc" and content="<token>" in either
    # attribute order, tolerant of single/double quotes and extra whitespace.
    name_first =
      ~r/<meta[^>]*\bname\s*=\s*['"]gotta-cc['"][^>]*\bcontent\s*=\s*['"]#{Regex.escape(token)}['"]/i

    content_first =
      ~r/<meta[^>]*\bcontent\s*=\s*['"]#{Regex.escape(token)}['"][^>]*\bname\s*=\s*['"]gotta-cc['"]/i

    Regex.match?(name_first, html) or Regex.match?(content_first, html)
  end

  defp verify_dns_txt(nil, _token), do: {:error, :site_not_found}

  defp verify_dns_txt(%SiteSchema{domain: domain}, token) do
    try do
      records =
        domain
        |> to_string()
        |> String.to_charlist()
        |> :inet_res.lookup(:in, :txt)
        |> Enum.map(fn parts -> parts |> List.flatten() |> to_string() end)

      needle = "gotta-cc=#{token}"

      if Enum.any?(records, fn r -> String.contains?(r, needle) or String.contains?(r, token) end),
        do: :ok,
        else: {:error, :not_found_on_dns}
    rescue
      e -> {:error, {:dns_error, Exception.message(e)}}
    catch
      _, reason -> {:error, {:dns_error, inspect(reason)}}
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp resolve_category(nil), do: nil

  defp resolve_category(slug) when is_binary(slug) do
    Repo.one(from c in CategorySchema, where: c.slug == ^slug)
  end

  defp derive_domain(url) when is_binary(url) do
    host =
      case URI.parse(url) do
        %URI{host: h} when is_binary(h) and h != "" -> h
        _ -> url |> String.replace(~r{^https?://}i, "") |> String.split("/") |> List.first()
      end

    host
    |> to_string()
    |> String.downcase()
    |> String.replace_prefix("www.", "")
  end

  defp derive_domain(_), do: ""

  # Visitors routinely type "example.com". Assume https so the row stores a
  # dereferenceable URL and `derive_domain/1` can parse a host out of it.
  defp normalize_url(url) when is_binary(url) do
    trimmed = String.trim(url)

    cond do
      trimmed == "" -> trimmed
      Regex.match?(~r{^https?://}i, trimmed) -> trimmed
      true -> "https://" <> trimmed
    end
  end

  defp normalize_url(url), do: url

  defp normalize_email(email) when is_binary(email) do
    case email |> String.trim() |> String.downcase() do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_email(_), do: nil

  defp derive_slug(domain) do
    domain
    |> to_string()
    |> String.downcase()
    |> String.replace_prefix("www.", "")
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  defp unique_slug(base) do
    base = if base == "", do: "site", else: base

    if slug_taken?(base) do
      Enum.reduce_while(2..1000, base, fn n, _acc ->
        candidate = "#{base}-#{n}"
        if slug_taken?(candidate), do: {:cont, candidate}, else: {:halt, candidate}
      end)
    else
      base
    end
  end

  defp slug_taken?(slug) do
    Repo.exists?(from s in SiteSchema, where: s.slug == ^slug)
  end

  defp generate_token do
    "gotta-cc-" <> (:crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false))
  end

  defp score(scores, key, fallback) do
    case Map.get(scores, key) do
      nil -> fallback || 0
      "" -> fallback || 0
      v when is_integer(v) -> v
      v when is_binary(v) -> String.to_integer(v)
      v -> v
    end
  end

  defp truthy(true), do: true
  defp truthy("true"), do: true
  defp truthy(_), do: false

  defp normalize_tags(nil), do: []
  defp normalize_tags(tags) when is_list(tags), do: tags
  defp normalize_tags(tags) when is_binary(tags),
    do: tags |> String.split(",", trim: true) |> Enum.map(&String.trim/1)

  defp normalize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end

  defp normalize_keys(_), do: %{}
end
