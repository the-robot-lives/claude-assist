defmodule Therobotplans.Mailer do
  def send(email) do
    SendGrid.Mail.send(email)
  end

  def from() do
    {name, address} =
      Application.get_env(:therobotplans, :mail_from, {"App", "noreply@localhost"})

    %SendGrid.Email{}
    |> SendGrid.Email.put_from(address, name)
  end
end
