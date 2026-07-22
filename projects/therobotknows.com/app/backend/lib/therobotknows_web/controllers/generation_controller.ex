defmodule TherobotknowsWeb.GenerationController do
  use TherobotknowsWeb, :controller

  alias Therobotknows.Generations

  def index(conn, %{"universe_id" => universe_id} = params) do
    user_id = user_id(conn)
    page = parse_int(params["page"], 1)
    per = parse_int(params["per_page"], 25)

    case Generations.list(universe_id, user_id, page: page, per_page: per) do
      {:ok, result} -> json(conn, result)
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Universe not found"})
      {:error, :forbidden} -> conn |> put_status(:forbidden) |> json(%{error: "Forbidden"})
    end
  end

  def create(conn, %{"universe_id" => universe_id, "generation" => attrs}) do
    user_id = user_id(conn)

    case Generations.create(universe_id, attrs, user_id) do
      {:ok, gen} ->
        conn |> put_status(:created) |> json(%{generation: gen})

      {:error, :budget_exceeded} ->
        conn
        |> put_status(:payment_required)
        |> json(%{error: "Generation budget exceeded for this period"})

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Universe not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Forbidden"})

      {:error, %Ecto.Changeset{} = cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(cs)})
    end
  end

  def create(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "generation params required"})
  end

  def show(conn, %{"universe_id" => universe_id, "id" => id}) do
    user_id = user_id(conn)

    case Generations.get(universe_id, id, user_id) do
      {:ok, gen} -> json(conn, %{generation: gen})
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
      {:error, :forbidden} -> conn |> put_status(:forbidden) |> json(%{error: "Forbidden"})
    end
  end

  def promote(conn, %{"universe_id" => universe_id, "id" => id}) do
    user_id = user_id(conn)

    case Generations.promote(universe_id, id, user_id) do
      {:ok, gen} -> json(conn, %{generation: gen})
      {:error, :not_ready} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "Generation not complete"})
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
      {:error, :forbidden} -> conn |> put_status(:forbidden) |> json(%{error: "Forbidden"})
      {:error, other} -> conn |> put_status(:unprocessable_entity) |> json(%{error: inspect(other)})
    end
  end

  def discard(conn, %{"universe_id" => universe_id, "id" => id}) do
    user_id = user_id(conn)

    case Generations.discard(universe_id, id, user_id) do
      {:ok, gen} -> json(conn, %{generation: gen})
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "Not found"})
      {:error, :forbidden} -> conn |> put_status(:forbidden) |> json(%{error: "Forbidden"})
    end
  end

  defp user_id(conn) do
    case Therobotknows.Guardian.Plug.current_resource(conn) do
      %Therobotknows.Users.Sessions.UserSession{user: {:ref, _, id}} -> id
      %Therobotknows.Users.Sessions.UserSession{user: %{id: id}} -> id
      _ -> nil
    end
  end

  defp format_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  defp parse_int(nil, d), do: d
  defp parse_int(v, d) when is_binary(v) do
    case Integer.parse(v) do
      {n, _} when n > 0 -> n
      _ -> d
    end
  end
  defp parse_int(v, _d) when is_integer(v) and v > 0, do: v
  defp parse_int(_, d), do: d
end
