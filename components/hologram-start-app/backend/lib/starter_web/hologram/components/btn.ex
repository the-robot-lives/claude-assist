defmodule StarterWeb.Hologram.Components.Btn do
  @moduledoc """
  Style-guide button primitive (`StyleGuideBtn` from `@noizu/styleguide`).

  Renders the semantic classes produced by the styleguide engine:
  `btn`, `btn-{variant}`, `btn-{size}`.
  """
  use Hologram.Component

  prop :variant, :string, default: "black"
  prop :size, :string, default: nil
  prop :label, :string, default: nil
  prop :type, :string, default: "button"
  prop :disabled, :boolean, default: false
  prop :href, :string, default: nil
  prop :class, :string, default: ""

  def template do
    ~HOLO"""
    {%if @href}
      <a href={@href} class={btn_class(@variant, @size, @class)}>{@label}<slot /></a>
    {%else}
      <button type={@type} class={btn_class(@variant, @size, @class)} disabled={@disabled}>
        {@label}<slot />
      </button>
    {/if}
    """
  end

  def btn_class(variant, size, extra) do
    [
      "btn",
      if(variant && variant != "", do: "btn-#{variant}", else: nil),
      if(size && size != "", do: "btn-#{size}", else: nil),
      extra
    ]
    |> Enum.reject(&(is_nil(&1) or &1 == ""))
    |> Enum.join(" ")
  end
end
