defmodule Foryou.Workers.SignupEmailWorker do
  @moduledoc """
  Sends signup lifecycle emails (double-opt-in confirmation / single-opt-in
  receipt). Uses the list's `settings.sender_identity` when set, else the
  platform default sender. Links point at the public confirm/unsubscribe
  endpoints so they work without a login.
  """
  use Oban.Worker, queue: :mailer, max_attempts: 3

  alias Foryou.Signups
  alias Foryou.Lists

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => type, "signup_id" => signup_id, "list_id" => list_id}}) do
    with %{} = signup <- Signups.get_signup(signup_id),
         %{} = list <- Lists.get_list(list_id) do
      send_email(type, signup, list)
      :ok
    else
      _ -> :ok
    end
  end

  def enqueue(type, signup_id, list_id) do
    %{"type" => type, "signup_id" => signup_id, "list_id" => list_id}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  defp send_email("signup_confirm", signup, list) do
    link = public_url("/api/v1/public/signups/confirm?token=#{signup.confirm_token}")
    name = list.name

    base_email(list)
    |> SendGrid.Email.add_to(signup.email)
    |> SendGrid.Email.put_subject("Confirm your subscription to #{name}")
    |> SendGrid.Email.put_text("Confirm your subscription to #{name}: #{link}")
    |> SendGrid.Email.put_html("""
    <h2>Confirm your subscription</h2>
    <p>Please confirm you'd like to receive #{name} updates.</p>
    <p><a href="#{link}" style="display:inline-block;padding:12px 24px;background:#000;color:#fff;text-decoration:none;border-radius:4px;">Confirm subscription</a></p>
    <p>Or copy this link: #{link}</p>
    <p><em>If you didn't request this, you can ignore this email.</em></p>
    """)
    |> Foryou.Mailer.send()
  end

  defp send_email("signup_receipt", signup, list) do
    unsub = public_url("/api/v1/public/signups/unsubscribe?token=#{signup.unsub_token}")
    name = list.name

    base_email(list)
    |> SendGrid.Email.add_to(signup.email)
    |> SendGrid.Email.put_subject("You're subscribed to #{name}")
    |> SendGrid.Email.put_text("You're subscribed to #{name}. Unsubscribe any time: #{unsub}")
    |> SendGrid.Email.put_html("""
    <h2>You're subscribed</h2>
    <p>You've been added to #{name}.</p>
    <p><a href="#{unsub}">Unsubscribe</a> at any time.</p>
    """)
    |> Foryou.Mailer.send()
  end

  defp send_email(_type, _signup, _list), do: :ok

  # Build a SendGrid.Email with from set to the list's sender identity or the
  # platform default.
  defp base_email(list) do
    case sender_identity(list) do
      {name, address} ->
        %SendGrid.Email{} |> SendGrid.Email.put_from(address, name)

      nil ->
        Foryou.Mailer.from()
    end
  end

  defp sender_identity(list) do
    with %{} = si <- list.settings["sender_identity"],
         address when is_binary(address) <- si["from_email"] || si[:from_email] do
      {si["from_name"] || si[:from_name] || list.name, address}
    else
      _ -> nil
    end
  end

  defp public_url(path) do
    base =
      case Application.get_env(:foryou, :public_base_url) do
        url when is_binary(url) -> String.trim_trailing(url, "/")
        _ -> ForyouWeb.Endpoint.url()
      end

    base <> path
  end
end
