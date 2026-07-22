defmodule GottaCcWeb.DirectoryCategoryController do
  use GottaCcWeb, :controller

  alias GottaCc.Directory

  def index(conn, _params) do
    categories = Directory.list_categories()
    json(conn, %{categories: Enum.map(categories, &category_to_json/1)})
  end

  defp category_to_json(category) do
    %{
      id: category.id,
      slug: category.slug,
      name: category.name,
      display_order: category.display_order,
      site_count: Map.get(category, :site_count, 0)
    }
  end
end
