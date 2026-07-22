defmodule StarterWeb.Hologram.Components.CardGrid do
  use Hologram.Component
  prop :class, :string, default: ""

  def template do
    ~HOLO"""
    <div class={"card-grid #{@class}"}><slot /></div>
    """
  end
end
