defmodule Foryou.Workers.SignupReconcileWorker do
  @moduledoc """
  Reconcile-on-login (US-050): links prior anonymous signups to a user account
  by email. Fire-and-forget — enqueued from `Foryou.Users.register` and
  `Foryou.Auth.SSO.authenticate_sso`. Only claims rows with `user_id IS NULL`.
  """
  use Oban.Worker, queue: :default, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id, "email" => email}}) do
    Foryou.Signups.reconcile_user(user_id, email)
    :ok
  end

  @doc "Fire-and-forget enqueue; ignores failures so it never blocks auth."
  def enqueue(user_id, email) when is_binary(user_id) and is_binary(email) do
    %{"user_id" => user_id, "email" => email}
    |> __MODULE__.new()
    |> Oban.insert()
  rescue
    _ -> {:error, :enqueue_failed}
  end

  def enqueue(_, _), do: :ok
end
