defmodule TimelyWeb.ReportController do
  @moduledoc """
  `GET /api/v1/reports/summary` - the companion report tab's rollup.
  """
  use TimelyWeb, :controller

  import TimelyWeb.TimelyAuth

  alias Timely.Sync.Reports

  @group_by ~w(client project ticket day source none)

  # ⟦𓋴𓅓𓂋𓏏⟧ summary :: Returns the date-range rollup.
  def summary(conn, params) do
    with_workspace(conn, params["workspace_id"], fn {conn, ctx} ->
      with {:ok, from} <- parse_instant(params["from"], "from"),
           {:ok, to} <- parse_instant(params["to"], "to"),
           :ok <- validate_range(from, to),
           {:ok, group_by} <- parse_group_by(params["group_by"]) do
        opts = [
          from: from,
          to: to,
          group_by: group_by,
          time_zone: params["time_zone"] || "UTC",
          include_unreviewed: params["include_unreviewed"] != "false",
          client_id: uuid(params["client_id"]),
          project_id: uuid(params["project_id"]),
          billable: boolean(params["billable"])
        ]

        json(conn, Reports.summary(ctx.workspace_id, opts))
      else
        {:error, message} -> error(conn, 400, "validation_failed", message)
      end
    end)
  end

  defp parse_instant(nil, name), do: {:error, "#{name} is required"}

  defp parse_instant(value, name) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> {:ok, datetime}
      _ -> {:error, "#{name} must be an ISO 8601 instant"}
    end
  end

  defp validate_range(from, to) do
    if DateTime.compare(to, from) == :gt, do: :ok, else: {:error, "to must be after from"}
  end

  defp parse_group_by(nil), do: {:ok, "project"}
  defp parse_group_by(value) when value in @group_by, do: {:ok, value}

  defp parse_group_by(_value),
    do: {:error, "group_by must be one of #{Enum.join(@group_by, ", ")}"}

  defp uuid(nil), do: nil

  defp uuid(value) do
    case Ecto.UUID.cast(value) do
      {:ok, id} -> id
      :error -> nil
    end
  end

  defp boolean("true"), do: true
  defp boolean("false"), do: false
  defp boolean(value) when is_boolean(value), do: value
  defp boolean(_), do: nil
end
