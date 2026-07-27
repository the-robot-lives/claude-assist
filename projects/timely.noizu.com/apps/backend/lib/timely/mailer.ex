defmodule Timely.Mailer do
  # ⟦𓈶𓐫𓎷𓋿⟧ send :: auto-generated pointer for public function send
  def send(email) do
    SendGrid.Mail.send(email)
  end

  # ⟦𓊭𓆙𓊏𓎙⟧ from :: auto-generated pointer for public function from
  def from() do
    {name, address} = Application.get_env(:timely, :mail_from, {"App", "noreply@localhost"})

    %SendGrid.Email{}
    |> SendGrid.Email.put_from(address, name)
  end
end
