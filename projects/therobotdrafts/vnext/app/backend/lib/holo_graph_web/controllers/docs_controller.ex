defmodule HoloGraphWeb.DocsController do
  use HoloGraphWeb, :controller

  alias HoloGraph.Docs
  alias HoloGraph.Docs.GraphDocument

  def index(conn, _params) do
    json(conn, %{data: Docs.list_summaries(), meta: %{source: "fixture"}})
  end

  def show(conn, %{"id" => id}) do
    case Docs.get_document(id) do
      {:ok, document} ->
        json(conn, %{data: GraphDocument.to_map(document), meta: %{source: "fixture"}})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: %{code: "not_found", message: "Document not found"}})
    end
  end

  def import_fixture(conn, params) do
    fixture = params["fixture"] || params["slug"] || params["id"]

    case Docs.import_fixture(fixture, params) do
      {:ok, document} ->
        conn
        |> put_status(:created)
        |> json(%{data: GraphDocument.to_map(document), meta: %{imported: true, source: "fixture"}})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: %{code: "not_found", message: "Fixture not found"}})

      {:error, :invalid_fixture} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: %{code: "bad_request", message: "Invalid fixture"}})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: %{code: "invalid_document", message: inspect(reason)}})
    end
  end
end
