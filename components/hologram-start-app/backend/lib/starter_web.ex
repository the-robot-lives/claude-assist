defmodule StarterWeb do
  # ⟦𓇦𓈔𓎟𓎑⟧ static_paths :: auto-generated pointer for public function static_paths
  def static_paths, do: ~w(themes css hologram favicon.ico robots.txt)

  # ⟦𓐆𓋓𓋂𓂰⟧ router :: auto-generated pointer for public function router
  def router do
    quote do
      use Phoenix.Router, helpers: false
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  # ⟦𓇠𓂜𓎄𓊰⟧ channel :: auto-generated pointer for public function channel
  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  # ⟦𓎇𓋾𓃪𓀅⟧ controller :: auto-generated pointer for public function controller
  def controller do
    quote do
      use Phoenix.Controller, formats: [:json]
      import Plug.Conn
      unquote(verified_routes())
    end
  end

  # ⟦𓁼𓎴𓋭𓂯⟧ verified_routes :: auto-generated pointer for public function verified_routes
  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: StarterWeb.Endpoint,
        router: StarterWeb.Router,
        statics: StarterWeb.static_paths()
    end
  end

  # ⟦𓍚𓂧𓈗𓈍⟧ __using__ :: auto-generated pointer for public function __using__
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
