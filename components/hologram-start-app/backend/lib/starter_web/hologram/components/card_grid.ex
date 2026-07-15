defmodule StarterWeb.Hologram.Components.CardGrid do
  @moduledoc "Style-guide card grid (`StyleGuideCardGrid`)."
  use Hologram.Component

  prop :class, :string, default: ""

  def template do
    ~HOLO"""
    <div class={"card-grid #{@class}"}>
      <slot />
    </div>
    """
  end
end
