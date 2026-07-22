defmodule Foryou.Forms do
  @moduledoc """
  Context for form definitions, versions, and submissions.

  The current `definition` is denormalized onto the `forms` row for cheap reads
  (what the Terraform provider reads/writes). Saving a changed definition also
  mints an immutable `form_versions` row and advances `current_version_id`.
  """
  alias Foryou.Schema.Forms.{Form, FormVersion, FormSubmission}
  import Ecto.Query

  def list_forms do
    from(f in Form, where: is_nil(f.deleted_at), order_by: f.inserted_at)
    |> Foryou.Repo.all()
  end

  def get_form(id), do: Foryou.Repo.get(Form, id)

  def create_form(attrs) do
    %Form{} |> Form.changeset(attrs) |> Foryou.Repo.insert()
  end

  def update_form(%Form{} = form, attrs) do
    form |> Form.changeset(attrs) |> Foryou.Repo.update()
  end

  def delete_form(%Form{} = form) do
    form |> Form.changeset(%{deleted_at: now(), status: "archived"}) |> Foryou.Repo.update()
  end

  @doc """
  Persists `definition` as a new immutable version and points the form's
  `current_version_id` + denormalized `definition` at it. Runs in a transaction.
  """
  def save_definition(%Form{} = form, definition, published_by \\ nil) do
    next = next_version_number(form.id)

    Foryou.Repo.transaction(fn ->
      with {:ok, version} <-
             %FormVersion{}
             |> FormVersion.changeset(%{
               form_id: form.id,
               version: next,
               definition: definition,
               published_by: published_by
             })
             |> Foryou.Repo.insert(),
           {:ok, updated} <-
             form
             |> Form.changeset(%{current_version_id: version.id, definition: definition})
             |> Foryou.Repo.update() do
        %{form: updated, version: version}
      else
        {:error, reason} -> Foryou.Repo.rollback(reason)
      end
    end)
  end

  def list_versions(form_id) do
    from(v in FormVersion, where: v.form_id == ^form_id, order_by: [desc: v.version])
    |> Foryou.Repo.all()
  end

  def list_submissions(form_id) do
    from(s in FormSubmission, where: s.form_id == ^form_id, order_by: [desc: s.inserted_at])
    |> Foryou.Repo.all()
  end

  def create_submission(attrs) do
    %FormSubmission{} |> FormSubmission.changeset(attrs) |> Foryou.Repo.insert()
  end

  defp next_version_number(form_id) do
    count = from(v in FormVersion, where: v.form_id == ^form_id, select: count(v.id)) |> Foryou.Repo.one()
    count + 1
  end

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:microsecond)
end
