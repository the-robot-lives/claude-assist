defmodule Foryou.Workers.InquirySignupWorker do
  @moduledoc """
  Inquiries dual-write (US-088): after an inquiry commits, add a signup to the
  configured default inquiry list (`FORYOU_DEFAULT_INQUIRY_LIST_ID`, D16). The
  inquiry is the source of truth — this is best-effort; Oban retries then
  dead-letters without ever losing the inquiry. No-op when no default list is
  configured.
  """
  use Oban.Worker, queue: :default, max_attempts: 3

  alias Foryou.{Lists, Signups}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"email" => email} = args}) do
    with list_id when is_binary(list_id) <- default_list_id(),
         %{} = list <- Lists.get_list(list_id) do
      values =
        %{"email" => email}
        |> maybe_put("name", args["name"])
        |> maybe_put("message", args["message"])

      meta = %{source: args["source"] || "inquiry", suppress_email: false}
      Signups.add_signup(list, values, meta, Noizu.Context.system())
      :ok
    else
      _ -> :ok
    end
  end

  @doc "Enqueue the dual-write for a committed inquiry."
  def enqueue(%{email: email} = attrs) when is_binary(email) do
    %{
      "email" => email,
      "name" => attrs[:name],
      "message" => attrs[:message],
      "source" => attrs[:source]
    }
    |> __MODULE__.new()
    |> Oban.insert()
  rescue
    _ -> {:error, :enqueue_failed}
  end

  def enqueue(_), do: :ok

  defp default_list_id do
    Application.get_env(:foryou, :default_inquiry_list_id) ||
      System.get_env("FORYOU_DEFAULT_INQUIRY_LIST_ID")
  end

  defp maybe_put(map, _k, nil), do: map
  defp maybe_put(map, _k, ""), do: map
  defp maybe_put(map, k, v), do: Map.put(map, k, v)
end
