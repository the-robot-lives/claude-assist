defmodule StarterWeb.Hologram.Components.ButtonRow do
  @moduledoc "Style-guide button row (`StyleGuideButtonRow`)."
  use Hologram.Component

  prop :class, :string, default: ""

  def template do
    ~HOLO"""
    <div class={"button-row #{@class}"}>
      <slot />
    </div>
    """
  end
end
