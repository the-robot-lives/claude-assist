defmodule Foryou.Schema.Inquiries.InquiryTest do
  use ExUnit.Case, async: true

  alias Foryou.Schema.Inquiries.Inquiry

  test "changeset normalizes and validates inquiry fields" do
    changeset =
      Inquiry.changeset(%Inquiry{}, %{
        name: "Keith",
        email: "  KEITH@Example.COM ",
        message: "Need help with an AI platform.",
        source: "noizu.com-contact",
        page_url: "https://noizu.com/"
      })

    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :email) == "keith@example.com"
  end

  test "changeset rejects missing message and invalid email" do
    changeset =
      Inquiry.changeset(%Inquiry{}, %{
        name: "Keith",
        email: "not-email",
        source: "noizu.com-contact"
      })

    refute changeset.valid?
    assert %{email: [_], message: [_]} = errors_on(changeset)
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
