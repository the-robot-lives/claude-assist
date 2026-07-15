defmodule Styleguide.ComponentCatalog do
  @moduledoc """
  Catalog data for the Component Browser — categories + entries with demo keys.
  Demo keys are rendered by `StyleguideWeb.Hologram.Sections.ComponentBrowser`.
  """

  @categories [
    %{
      slug: "primitives",
      label: "Primitives",
      description: "Low-level building blocks — buttons, cards, inputs, tokens, indicators.",
      count: 13,
      entries: [
        %{
          id: "btn",
          name: "Btn",
          module: "StyleguideWeb.Hologram.Components.Btn",
          description: "Themed button with variant and size props."
        },
        %{
          id: "button-row",
          name: "ButtonRow",
          module: "StyleguideWeb.Hologram.Components.ButtonRow",
          description: "Horizontal row of buttons with consistent spacing."
        },
        %{
          id: "card",
          name: "Card",
          module: "StyleguideWeb.Hologram.Components.Card",
          description: "Content card with title, body, and optional id label."
        },
        %{
          id: "card-grid",
          name: "CardGrid",
          module: "StyleguideWeb.Hologram.Components.CardGrid",
          description: "Responsive grid container for Card."
        },
        %{
          id: "section-header",
          name: "SectionHeader",
          module: "StyleguideWeb.Hologram.Components.SectionHeader",
          description: "Numbered section header with title and description."
        },
        %{
          id: "type-specimen",
          name: "TypeSpecimen",
          module: "StyleguideWeb.Hologram.Components.TypeSpecimen",
          description: "Typography sample with meta and usage."
        },
        %{
          id: "color-swatch",
          name: "ColorSwatch",
          module: "StyleguideWeb.Hologram.Components.ColorSwatch",
          description: "Color sample tile / inline swatch."
        },
        %{
          id: "color-grid",
          name: "ColorGrid",
          module: "StyleguideWeb.Hologram.Components.ColorGrid",
          description: "Grid wrapper for ColorSwatch children."
        },
        %{
          id: "spacing-scale",
          name: "SpacingScale",
          module: "StyleguideWeb.Hologram.Components.SpacingScale",
          description: "Visual spacing rhythm bars."
        },
        %{
          id: "status-indicator",
          name: "StatusIndicator",
          module: "StyleguideWeb.Hologram.Components.StatusIndicator",
          description: "Status dot with label and description."
        },
        %{
          id: "token-card",
          name: "TokenCard",
          module: "StyleguideWeb.Hologram.Components.TokenCard",
          description: "Token name/value table card."
        },
        %{
          id: "input-field",
          name: "InputField",
          module: "StyleguideWeb.Hologram.Components.InputField",
          description: "Labeled field with design-system chrome."
        },
        %{
          id: "style-card",
          name: "StyleCard",
          module: "StyleguideWeb.Hologram.Components.StyleCard",
          description: "Documentation style card."
        }
      ]
    },
    %{
      slug: "interaction",
      label: "Interaction",
      description: "HUI interactive control patterns (see Interaction → HUI Controls for full suite).",
      count: 3,
      entries: [
        %{
          id: "hui-checkbox",
          name: "HUI Checkbox",
          module: "HUI · checkbox-wrap",
          description: "Semantic checkbox with visual box and label."
        },
        %{
          id: "hui-switch",
          name: "HUI Switch",
          module: "HUI · switch-wrap",
          description: "On/off switch track and thumb."
        },
        %{
          id: "hui-tabs",
          name: "HUI Tabs",
          module: "HUI · tab-list",
          description: "Tab list with selected indicator."
        }
      ]
    },
    %{
      slug: "catalogs",
      label: "Catalogs",
      description: "Large widget catalogs hosted as static demos.",
      count: 1,
      entries: [
        %{
          id: "tailwind-plus",
          name: "Tailwind Plus",
          module: "/style-guide/tailwind-plus",
          description: "686 static HTML widget demos — open the full browser."
        }
      ]
    }
  ]

  def categories do
    Enum.map(@categories, fn cat ->
      Map.put(cat, :count, length(cat.entries))
    end)
  end

  def first_category, do: hd(categories())

  def find_category(slug) do
    Enum.find(categories(), first_category(), &(&1.slug == slug))
  end

  def find_entry(category_slug, entry_id) do
    cat = find_category(category_slug)
    Enum.find(cat.entries, List.first(cat.entries), &(&1.id == entry_id))
  end

  def first_entry_id(category_slug) do
    cat = find_category(category_slug)
    hd(cat.entries).id
  end
end
