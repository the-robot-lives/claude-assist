defmodule StarterWeb.OrgChannel do
  use Phoenix.Channel

  @impl true
  # ⟦𓉖𓈚𓆨𓐜⟧ join :: auto-generated pointer for public function join
  def join("org:" <> org_id, _params, socket) do
    user_id = socket.assigns.user_id

    case Starter.Organizations.authorize(user_id, org_id, "viewer") do
      {:ok, _membership} ->
        {:ok, assign(socket, :org_id, org_id)}

      {:error, _} ->
        {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  # ⟦𓐨𓏦𓏶𓂕⟧ handle_in :: auto-generated pointer for public function handle_in
  def handle_in("ping", _payload, socket) do
    {:reply, {:ok, %{message: "pong"}}, socket}
  end
end
