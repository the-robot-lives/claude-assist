defmodule ForyouWeb.ManagementController do
  @moduledoc """
  Management surface for the Terraform provider / API-key-authenticated clients.
  Phase 2/3 add user/org/membership/form/api-key sub-controllers under this scope.
  """
  use ForyouWeb, :controller

  def ping(conn, _params) do
    json(conn, %{ok: true})
  end
end
