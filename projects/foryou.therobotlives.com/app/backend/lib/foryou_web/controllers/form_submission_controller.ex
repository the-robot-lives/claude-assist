defmodule ForyouWeb.FormSubmissionController do
  @moduledoc """
  Public form intake — unauthenticated, rate-limited. Accepts a form payload
  (plus optional email/source metadata) and records a submission against the
  form's current published version.
  """
  use ForyouWeb, :controller

  alias Foryou.Forms

  def submit(conn, %{"form_id" => form_id} = params) do
    payload = params["payload"] || Map.drop(params, ["form_id"])

    case Forms.get_form(form_id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "form not found"})

      form ->
        attrs = %{
          form_id: form.id,
          form_version_id: form.current_version_id,
          payload: payload,
          source: params["source"],
          submitter_email: params["email"],
          submitter_ip: remote_ip(conn),
          status: "new"
        }

        case Forms.create_submission(attrs) do
          {:ok, submission} ->
            conn
            |> put_status(:created)
            |> json(%{submission: %{id: submission.id, status: submission.status}})

          {:error, cs} ->
            conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
        end
    end
  end

  defp remote_ip(conn) do
    case conn.remote_ip do
      {a, b, c, d} -> "#{a}.#{b}.#{c}.#{d}"
      _ -> nil
    end
  end

  defp format_errors(cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
    end)
  end
end
