defmodule GottaCcWeb.DirectorySubmissionController do
  use GottaCcWeb, :controller

  alias GottaCc.Guardian
  alias GottaCc.Users
  alias GottaCc.Directory.Submissions

  @doc """
  Accepts a site suggestion. Reachable without an account: when no session is
  present the submission is stored with a nil submitter and whatever
  `contact_email` the visitor chose to leave. Signed-in callers are still
  attributed so the row shows up under `/my-submissions`.
  """
  def create(conn, params) do
    user = maybe_current_user(conn)
    attrs = params["submission"] || params

    case Submissions.create_submission(user && user.id, attrs) do
      {:ok, submission} ->
        conn
        |> put_status(:created)
        |> json(%{submission: submission_to_json(submission)})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def index(conn, _params) do
    user = get_current_user(conn)
    submissions = Submissions.list_submissions_for_user(user.id)
    json(conn, %{submissions: Enum.map(submissions, &submission_to_json/1)})
  end

  def show(conn, %{"id" => id}) do
    user = get_current_user(conn)

    case Submissions.get_submission_for_user(id, user.id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "Submission not found"})
      submission -> json(conn, %{submission: submission_to_json(submission)})
    end
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

  # `create/2` runs behind an optional-auth pipeline, so there may be no session.
  defp maybe_current_user(conn) do
    case Guardian.Plug.current_resource(conn) do
      nil -> nil
      _session -> get_current_user(conn)
    end
  end

  def submission_to_json(submission) do
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

  defp published_site_slug(%{published_site_id: nil}), do: nil

  defp published_site_slug(%{published_site_id: site_id}) do
    case GottaCc.Repo.get(GottaCc.Schema.Directory.Site, site_id) do
      nil -> nil
      site -> site.slug
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
