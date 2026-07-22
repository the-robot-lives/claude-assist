defmodule GottaCc.Schema.Directory.Site do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "directory_sites" do
    field :slug, :string
    field :name, :string
    field :url, :string
    field :domain, :string
    field :summary, :string
    belongs_to :category, GottaCc.Schema.Directory.Category, type: Ecto.UUID
    field :tags, {:array, :string}, default: []
    field :originality, :integer
    field :human_authorship, :integer
    field :depth, :integer
    field :freshness, :integer
    field :design_quality, :integer
    # Generated columns — read-only from Ecto's perspective.
    field :overall_score, :decimal, read_after_writes: true
    field :search_vector, :map, virtual: true
    field :featured, :boolean, default: false
    field :status, :string, default: "published"

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(site, attrs) do
    site
    |> cast(attrs, [
      :slug, :name, :url, :domain, :summary, :category_id, :tags,
      :originality, :human_authorship, :depth, :freshness, :design_quality,
      :featured, :status
    ])
    |> validate_required([:slug, :name, :url, :domain, :summary, :category_id])
    |> validate_inclusion(:status, ["published", "draft", "hidden"])
    |> validate_number(:originality, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_number(:human_authorship, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_number(:depth, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_number(:freshness, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_number(:design_quality, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> unique_constraint(:slug)
  end
end
