defmodule ForyouWeb.InquiryControllerTest do
  use ForyouWeb.ConnCase

  alias Foryou.Repo
  alias Foryou.Schema.Inquiries.Inquiry

  describe "POST /api/v1/inquiries" do
    test "creates an inquiry", %{conn: conn} do
      conn =
        post(conn, "/api/v1/inquiries", %{
          name: "Keith",
          email: "keith@example.com",
          message: "I need help with infrastructure.",
          source: "noizu.com-contact",
          page_url: "https://noizu.com/"
        })

      response = json_response(conn, 201)
      inquiry = Repo.get!(Inquiry, response["inquiry"]["id"])

      assert response["inquiry"]["status"] == "new"
      assert inquiry.email == "keith@example.com"
      assert inquiry.message == "I need help with infrastructure."
    end

    test "accepts legacy inquiry payload key", %{conn: conn} do
      conn =
        post(conn, "/api/v1/inquiries", %{
          inquiry: %{
            name: "Keith",
            email: "keith@example.com",
            inquiry: "Legacy contact modal text.",
            source: "noizu.com-contact"
          }
        })

      assert %{"inquiry" => %{"id" => _id}} = json_response(conn, 201)
    end

    test "returns validation errors", %{conn: conn} do
      conn =
        post(conn, "/api/v1/inquiries", %{
          name: "",
          email: "bad",
          message: "",
          source: "noizu.com-contact"
        })

      response = json_response(conn, 422)
      assert response["errors"]["email"]
      assert response["errors"]["message"]
    end
  end
end
