defmodule StarterWeb.Hologram.Components.StatusIndicator do
  @moduledoc "StyleGuideStatusIndicator."
  use Hologram.Component

  prop :status, :string, default: "info"
  prop :label, :string, default: ""
  prop :desc, :string, default: ""

  def template do
    ~HOLO"""
    <div class="status-item">
      <div class={"status-indicator #{@status}"}></div>
      <div class="status-text"><strong>{@label}</strong> {@desc}</div>
    </div>
    """
  end
end
