defmodule StarterWeb.Hologram.Components.Card do
  @moduledoc "Style-guide card (`StyleGuideCard`) — `card` / `card-title` / `card-body`."
  use Hologram.Component

  prop :variant, :string, default: nil
  prop :title, :string, default: nil
  prop :body, :string, default: nil
  prop :id_label, :string, default: nil

  def template do
    ~HOLO"""
    <div class={card_class(@variant)}>
      {%if @id_label}
        <div class="card-id">{@id_label}</div>
      {/if}
      {%if @title}
        <div class="card-title">{@title}</div>
      {/if}
      {%if @body}
        <div class="card-body">{@body}</div>
      {/if}
      <slot />
    </div>
    """
  end

  def card_class(nil), do: "card"
  def card_class(""), do: "card"
  def card_class(variant), do: "card card-#{variant}"
end
