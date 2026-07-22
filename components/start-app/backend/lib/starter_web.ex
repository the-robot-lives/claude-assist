defmodule StarterWeb do
  # ⟦𓍕𓄓𓃠𓁚⟧ static_paths :: auto-generated pointer for public function static_paths
  def static_paths, do: ~w(favicon.ico robots.txt)

  # ⟦𓎊𓅂𓉸𓌀⟧ router :: auto-generated pointer for public function router
  def router do
    quote do
      use Phoenix.Router, helpers: false
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  # ⟦𓌣𓐊𓃌𓌏⟧ channel :: auto-generated pointer for public function channel
  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  # ⟦𓃋𓅌𓃡𓉊⟧ controller :: auto-generated pointer for public function controller
  def controller do
    quote do
      use Phoenix.Controller, formats: [:json]
      import Plug.Conn
      unquote(verified_routes())
    end
  end

  # ⟦𓁦𓀪𓎷𓎥⟧ verified_routes :: auto-generated pointer for public function verified_routes
  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: StarterWeb.Endpoint,
        router: StarterWeb.Router,
        statics: StarterWeb.static_paths()
    end
  end

  # ⟦𓀨𓇝𓏇𓏚⟧ __using__ :: auto-generated pointer for public function __using__
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
