defmodule StyleguideWeb.Hologram.Components.StyleCard do
  @moduledoc "StyleGuideStyleCard — documentation card for principles / notes."
  use Hologram.Component

  prop :title, :string, default: ""
  prop :body, :string, default: ""

  def template do
    ~HOLO"""
    <div class="style-card card">
      <div class="card-title">{@title}</div>
      <div class="card-body">{@body}</div>
      <slot />
    </div>
    """
  end
end
