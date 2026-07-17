defmodule HologramApp.Components.IthkuilWord do
  @moduledoc """
  Hologram wrapper for the `<ithkuil-word>` Lit custom element.

  ## STATUS: UNTESTED SCAFFOLD

  This module has never been compiled against a real Hologram project. It is
  a best-effort sketch against the Hologram component/JS-interop surface as
  documented at <https://hologram.page/docs/javascript-interop>; expect to
  adjust sigil names (`~HOLO"..."` vs `~H"..."`), prop macros, and the command
  wiring to the Hologram version actually in use. It is checked in so the
  integration intent (M4 in ../README.md) is concrete and reviewable.

  ## Ownership boundary (normative — see repo README "Decisions")

  * **Hologram owns the host element**: it renders `<ithkuil-word>` into the
    light DOM, sets the element's `model` **property** (never an attribute —
    the render model is structured data), and listens for composed
    CustomEvents that bubble out of the component.
  * **Lit owns the shadow root**: all SVG rendering, mode toggling and
    interaction live inside the web component. Neither runtime touches the
    other's subtree.
  * The browser never computes Ithkuil facts: `latinized` and `integer` in
    the model come from the Elixir codec (`Ithkuil.to_scene/1`), which this
    wrapper calls server-side.

  ## Wiring

  1. Add the codec to the Hologram app's deps: `{:ithkuil, path: "../elixir"}`.
  2. Serve the web component bundle (`../web/`) so `<ithkuil-word>` is defined.
  3. Render this component with a `:coordinate` prop (wire form or canonical
     tuple). The render model is serialized to JSON server-side (camelCase,
     matching web/src/scene.js output) and assigned to the element's `model`
     property by the inline bridge script.
  4. The bridge re-dispatches the component's composed `ithkuil-mode-change`
     CustomEvent into Hologram (placeholder below — replace with the JS
     interop command dispatch of your Hologram version).
  """

  use Hologram.Component

  alias Ithkuil.JSON

  prop :coordinate, :term
  prop :exploded, :boolean, default: false
  prop :dom_id, :string, default: "ithkuil-word-host"

  @impl true
  def init(_props, component, _server) do
    component
  end

  @impl true
  def template do
    ~HOLO"""
    <div class="ithkuil-word-wrapper">
      <ithkuil-word id={@dom_id} exploded={@exploded}></ithkuil-word>
      <script type="application/json" id={"#{@dom_id}-model"}>{model_json(@coordinate)}</script>
      <script>{bridge_script(@dom_id)}</script>
    </div>
    """
  end

  @doc """
  Handle the mode-change notification bridged from the shadow DOM.
  """
  def action(:ithkuil_mode_change, params, component) do
    put_state(component, :exploded, params[:exploded] == true)
  end

  # ------------------------------------------------------------------
  # Server-side model preparation
  # ------------------------------------------------------------------

  @doc """
  Compile the coordinate into the render model and serialize it as the JSON
  shape the Lit component expects (camelCase keys, matching
  web/src/scene.js). Returns `"null"` when the coordinate is invalid — the
  component renders its empty state.
  """
  def model_json(coordinate) do
    case Ithkuil.to_scene(coordinate) do
      {:ok, model} -> JSON.encode(js_model(model))
      {:error, _reason} -> "null"
    end
  end

  defp js_model(model) do
    {:object,
     [
       {"schema", model.schema},
       {"latinized", model.latinized},
       {"integer", model.integer},
       {"coordinate", model.coordinate},
       {"viewBox", model.view_box},
       {"nodes", Enum.map(model.nodes, &js_node/1)}
     ]}
  end

  defp js_node(node) do
    base = [
      {"id", node.id},
      {"kind", node.kind},
      {"path", node.path},
      {"compact", js_placement(node.compact)},
      {"exploded", js_placement(node.exploded)}
    ]

    base =
      case Map.fetch(node, :parent_id) do
        {:ok, parent_id} -> base ++ [{"parentId", parent_id}]
        :error -> base
      end

    base =
      case Map.fetch(node, :socket) do
        {:ok, socket} ->
          base ++
            [
              {"socket",
               {:object,
                [
                  {"id", socket.id},
                  {"name", socket.name},
                  {"occupied", socket.occupied},
                  {"anchor", socket.anchor},
                  {"orbitCenter", socket.orbit_center}
                ]}}
            ]

        :error ->
          base
      end

    {:object, base}
  end

  defp js_placement(p) do
    {:object,
     [
       {"translate", p.translate},
       {"rotate", p.rotate},
       {"scale", p.scale},
       {"visible", p.visible}
     ]}
  end

  # ------------------------------------------------------------------
  # Client-side bridge (Hologram side of the property/event contract)
  # ------------------------------------------------------------------

  # The host element's `model` PROPERTY is set from the adjacent JSON block,
  # and the composed "ithkuil-mode-change" CustomEvent is subscribed to. The
  # dispatch back into Hologram state is left as a clearly-marked TODO: the
  # exact client API (Hologram.Runtime.executeAction / command queue) depends
  # on the Hologram release in use.
  defp bridge_script(dom_id) do
    """
    (function () {
      var host = document.getElementById(#{inline_js_string(dom_id)});
      var data = document.getElementById(#{inline_js_string(dom_id <> "-model")});
      if (!host || !data) return;
      customElements.whenDefined("ithkuil-word").then(function () {
        host.model = JSON.parse(data.textContent);
      });
      host.addEventListener("ithkuil-mode-change", function (event) {
        // Lit dispatches this composed event when the user toggles
        // compact/exploded inside the shadow root. Bridge it into Hologram:
        // TODO(hologram-interop): replace with the documented client dispatch,
        // e.g. Hologram.executeAction(host, "ithkuil_mode_change", event.detail).
        host.dispatchEvent(new CustomEvent("hologram:ithkuil-mode-change", {
          bubbles: true,
          detail: event.detail
        }));
      });
    })();
    """
  end

  defp inline_js_string(s), do: JSON.encode(s)
end
