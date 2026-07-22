defmodule GottaCc.Directory.Site do
  use Noizu.Entities

  @vsn 1.0
  @repo GottaCc.Directory
  @sref "directory.site"
  @persistence ecto_store(GottaCc.Schema.Directory.Site, GottaCc.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol

  def_entity do
    id(:uuid)

    field :slug, nil, :string
    field :name, nil, :string
    field :url, nil, :string
    field :domain, nil, :string
    field :summary, nil, :string

    @config auto: false
    @store name: :category_id
    field :category, nil, GottaCc.Directory.CategoryReference

    field :tags, [], {:array, :string}
    field :originality, 0, :integer
    field :human_authorship, 0, :integer
    field :depth, 0, :integer
    field :freshness, 0, :integer
    field :design_quality, 0, :integer
    field :overall_score, nil, :decimal
    field :featured, false, :boolean
    field :status, "published", :string
    field :time_stamp, nil, Noizu.Entity.TimeStamp
  end

  jason_encoder()
end
