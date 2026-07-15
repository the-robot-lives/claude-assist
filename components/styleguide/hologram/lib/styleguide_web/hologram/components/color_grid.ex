defmodule StyleguideWeb.Hologram.Components.ColorGrid do
  use Hologram.Component
  prop :class, :string, default: ""

  def template do
    ~HOLO"""
    <div class={"swatch-row #{@class}"}><slot /></div>
    """
  end
end
