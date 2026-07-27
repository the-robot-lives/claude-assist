defmodule TimelyWeb.Hologram.Components.ColorGrid do
  use Hologram.Component
  prop :class, :string, default: ""

  # ⟦𓏖𓉍𓊊𓀽⟧ template :: auto-generated pointer for public function template
  def template do
    ~HOLO"""
    <div class={"swatch-row #{@class}"}><slot /></div>
    """
  end
end
