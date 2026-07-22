defmodule Foryou.Workers.ListmonkImportWorker do
  @moduledoc """
  One-time listmonk backfill import (US-093). Processes a batch of subscriber
  rows into a list via `Foryou.Signups.import_row/2`: dedupe by email,
  subscribed-first, never send opt-in email, never overwrite an existing
  `unsubscribed` row. Each enqueue carries a bounded batch of rows.
  """
  use Oban.Worker, queue: :default, max_attempts: 3

  alias Foryou.{Lists, Signups}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"list_id" => list_id, "rows" => rows}}) when is_list(rows) do
    case Lists.get_list(list_id) do
      nil ->
        :ok

      list ->
        rows
        |> dedupe_by_email()
        |> subscribed_first()
        |> Enum.each(fn row -> Signups.import_row(list, row) end)

        :ok
    end
  end

  @doc "Enqueue an import batch."
  def enqueue(list_id, rows) when is_binary(list_id) and is_list(rows) do
    %{"list_id" => list_id, "rows" => rows}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  defp dedupe_by_email(rows) do
    rows
    |> Enum.reduce({[], MapSet.new()}, fn row, {acc, seen} ->
      email = (row["email"] || row[:email]) |> to_string() |> String.downcase()

      if email == "" or MapSet.member?(seen, email) do
        {acc, seen}
      else
        {[row | acc], MapSet.put(seen, email)}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  defp subscribed_first(rows) do
    Enum.sort_by(rows, fn row ->
      case (row["status"] || row[:status]) |> to_string() do
        "subscribed" -> 0
        "" -> 0
        _ -> 1
      end
    end)
  end
end
