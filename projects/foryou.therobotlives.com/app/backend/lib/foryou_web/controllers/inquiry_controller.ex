defmodule ForyouWeb.InquiryController do
  use ForyouWeb, :controller

  alias Foryou.Inquiries

  def create(conn, %{"inquiry" => inquiry_params}) do
    create(conn, inquiry_params)
  end

  def create(conn, params) do
    attrs = %{
      name: params["name"],
      email: params["email"],
      message: params["message"] || params["inquiry"],
      source: params["source"] || "unknown",
      page_url: params["page_url"],
      metadata: metadata(params)
    }

    case Inquiries.create_inquiry(attrs) do
      {:ok, inquiry} ->
        conn
        |> put_status(:created)
        |> json(%{inquiry: %{id: inquiry.id, status: inquiry.status}})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  defp metadata(params) do
    params
    |> Map.take(["user_agent", "campaign", "referrer"])
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
    |> Map.new()
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
