defmodule Foryou.Inquiries do
  alias Foryou.Repo
  alias Foryou.Schema.Inquiries.Inquiry

  def create_inquiry(attrs) do
    %Inquiry{}
    |> Inquiry.changeset(attrs)
    |> Repo.insert()
  end
end
