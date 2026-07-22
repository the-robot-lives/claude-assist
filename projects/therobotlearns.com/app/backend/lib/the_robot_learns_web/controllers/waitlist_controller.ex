defmodule TheRobotLearnsWeb.WaitlistController do
  use TheRobotLearnsWeb, :controller

  alias TheRobotLearns.Waitlist

  # Public: POST /api/v1/waitlist  {email, invite, focus}
  def create(conn, params) do
    case Waitlist.signup(params) do
      {:ok, signup} ->
        conn |> put_status(:ok) |> json(%{status: signup.status})

      {:error, :invalid_email} ->
        unprocessable(conn, "A valid email address is required.")

      {:error, :invalid_focus} ->
        unprocessable(conn, "A focus is required and must be at most 64 characters.")

      {:error, :invalid_invite} ->
        unprocessable(conn, "The invite code is not in a valid format.")

      {:error, changeset} when is_struct(changeset, Ecto.Changeset) ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  # Admin: GET /api/v1/admin/waitlist
  def index(conn, params) do
    page = String.to_integer(Map.get(params, "page", "1"))
    per_page = String.to_integer(Map.get(params, "per_page", "50"))

    result = Waitlist.list(page: page, per_page: per_page)

    conn
    |> put_status(:ok)
    |> json(%{
      signups: result.signups,
      total: result.total,
      page: result.page,
      per_page: result.per_page
    })
  end

  defp unprocessable(conn, message) do
    conn |> put_status(:unprocessable_entity) |> json(%{error: message})
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
