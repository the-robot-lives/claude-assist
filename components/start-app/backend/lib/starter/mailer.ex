defmodule Starter.Mailer do
  # ⟦𓐓𓏤𓆣𓀤⟧ send :: auto-generated pointer for public function send
  def send(email) do
    SendGrid.Mail.send(email)
  end

  # ⟦𓂄𓋛𓅂𓈉⟧ from :: auto-generated pointer for public function from
  def from() do
    {name, address} = Application.get_env(:starter, :mail_from, {"App", "noreply@localhost"})

    %SendGrid.Email{}
    |> SendGrid.Email.put_from(address, name)
  end
end
