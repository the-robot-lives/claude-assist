defmodule GottaCcWeb.DirectoryModerationController do
  use GottaCcWeb, :controller

  alias GottaCc.Guardian
  alias GottaCc.Directory.Submissions

  def index(conn, params) do
    opts =
      case params["status"] do
        s when is_binary(s) and s != "" -> [status: s]
        _ -> []
      end

    submissions = Submissions.list_for_review(opts)
    json(conn, %{submissions: Enum.map(submissions, &submission_to_json/1)})
  end

  def approve(conn, %{"id" => id} = params) do
    reviewer = get_current_user(conn)
    attrs = params["approval"] || Map.drop(params, ["id"])

    case Submissions.approve_submission(id, reviewer.id, attrs) do
      {:ok, %{submission: submission, site: site}} ->
        json(conn, %{
          submission: submission_to_json(submission),
          site: site_to_json(site)
        })

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Submission not found"})

      {:error, :already_reviewed} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "Submission already reviewed"})

      {:error, :category_not_found} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Could not resolve a category. Provide a valid category_slug."})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})

      {:error, reason} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: to_string(reason)})
    end
  end

  def reject(conn, %{"id" => id} = params) do
    reviewer = get_current_user(conn)
    reason = params["reason"] || params["reviewer_notes"]

    case Submissions.reject_submission(id, reviewer.id, reason) do
      {:ok, submission} ->
        json(conn, %{submission: submission_to_json(submission)})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Submission not found"})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  # --- helpers -------------------------------------------------------------

  defp get_current_user(conn) do
    session = Guardian.Plug.current_resource(conn)

    case session.user do
      {:ref, _, id} ->
        {:ok, user} = GottaCc.Users.get_user(id, Noizu.Context.system())
        user

      %GottaCc.Users.User{} = user ->
        user
    end
  end

  defp submission_to_json(submission) do
    %{
      id: submission.id,
      name: submission.name,
      url: submission.url,
      domain: submission.domain,
      summary: submission.summary,
      proposed_category_slug: submission.proposed_category_slug,
      tags: submission.tags,
      status: submission.status,
      reviewer_notes: submission.reviewer_notes,
      submitter_id: submission.submitter_id,
      submitter_email: submitter_email(submission.submitter_id),
      published_site_slug: published_site_slug(submission),
      suggested_scores: %{
        originality: submission.sug_originality,
        human_authorship: submission.sug_human_authorship,
        depth: submission.sug_depth,
        freshness: submission.sug_freshness,
        design_quality: submission.sug_design_quality
      },
      inserted_at: submission.inserted_at
    }
  end

  defp submitter_email(nil), do: nil

  defp submitter_email(user_id) do
    case GottaCc.Repo.get(GottaCc.Schema.Users.User, user_id) do
      nil -> nil
      user -> user.email
    end
  end

  defp published_site_slug(%{published_site_id: nil}), do: nil

  defp published_site_slug(%{published_site_id: site_id}) do
    case GottaCc.Repo.get(GottaCc.Schema.Directory.Site, site_id) do
      nil -> nil
      site -> site.slug
    end
  end

  defp site_to_json(site) do
    %{
      id: site.id,
      slug: site.slug,
      name: site.name,
      url: site.url,
      domain: site.domain,
      summary: site.summary,
      tags: site.tags,
      status: site.status,
      featured: site.featured,
      scores: %{
        originality: site.originality,
        human_authorship: site.human_authorship,
        depth: site.depth,
        freshness: site.freshness,
        design_quality: site.design_quality,
        overall: overall_to_integer(site.overall_score)
      }
    }
  end

  defp overall_to_integer(nil), do: 0

  defp overall_to_integer(score) do
    score |> Decimal.round(0) |> Decimal.to_integer()
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
