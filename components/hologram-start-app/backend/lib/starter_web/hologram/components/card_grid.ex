defmodule StarterWeb.Hologram.Components.CardGrid do
  use Hologram.Component
  prop :class, :string, default: ""

  # ⟦𓆵𓁑𓄗𓐬⟧ template :: auto-generated pointer for public function template
  def template do
    ~HOLO"""
    <div class={"card-grid #{@class}"}><slot /></div>
    """
  end
end
