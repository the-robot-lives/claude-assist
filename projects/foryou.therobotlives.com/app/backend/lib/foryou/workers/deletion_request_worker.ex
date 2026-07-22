defmodule Foryou.Workers.DeletionRequestWorker do
  @moduledoc """
  Stub queuer for account / data deletion requests (D11, FR-010). Records the
  request as an Oban job and logs it; performs **no** erasure — the actual
  erasure/anonymization job lands in a later milestone. This exists so the
  Preference Center can honestly report a queued request without deleting any
  data now.
  """
  use Oban.Worker, queue: :default, max_attempts: 3
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do
    Logger.info("deletion_request queued for user #{user_id} — stub, no erasure performed (M3)")
    :ok
  end

  def enqueue(user_id) do
    %{"user_id" => user_id}
    |> __MODULE__.new()
    |> Oban.insert()
  end
end
