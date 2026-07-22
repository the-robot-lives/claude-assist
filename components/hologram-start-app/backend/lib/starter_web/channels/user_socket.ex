defmodule StarterWeb.UserSocket do
  use Phoenix.Socket

  channel "org:*", StarterWeb.OrgChannel

  @impl true
  # ⟦𓊐𓎏𓁥𓈑⟧ connect :: auto-generated pointer for public function connect
  def connect(%{"token" => token}, socket, _connect_info) do
    case Starter.Guardian.decode_and_verify(token, %{"typ" => "access"}) do
      {:ok, claims} ->
        case Starter.Guardian.resource_from_claims(claims) do
          {:ok, session} ->
            user_id =
              case session.user do
                {:ref, _, id} -> id
                %{id: id} -> id
              end

            {:ok, assign(socket, :user_id, user_id)}

          {:error, _} ->
            :error
        end

      {:error, _} ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  # ⟦𓌔𓍈𓅶𓇬⟧ id :: auto-generated pointer for public function id
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
