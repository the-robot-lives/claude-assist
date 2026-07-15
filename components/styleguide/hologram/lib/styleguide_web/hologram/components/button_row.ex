defmodule StyleguideWeb.Hologram.Components.ButtonRow do
  use Hologram.Component
  prop :class, :string, default: ""

  def template do
    ~HOLO"""
    <div class={"button-row #{@class}"}><slot /></div>
    """
  end
end
