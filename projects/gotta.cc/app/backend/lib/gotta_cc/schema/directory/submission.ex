defmodule GottaCc.Schema.Directory.Submission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "directory_submissions" do
    belongs_to :submitter, GottaCc.Schema.Users.User
    field :name, :string
    field :url, :string
    field :domain, :string
    field :summary, :string
    field :proposed_category_slug, :string
    field :tags, {:array, :string}, default: []
    field :sug_originality, :integer
    field :sug_human_authorship, :integer
    field :sug_depth, :integer
    field :sug_freshness, :integer
    field :sug_design_quality, :integer
    field :status, :string, default: "pending"
    belongs_to :reviewer, GottaCc.Schema.Users.User
    field :reviewer_notes, :string
    belongs_to :published_site, GottaCc.Schema.Directory.Site

    timestamps(type: :utc_datetime_usec)
  end

  @statuses ["pending", "in_review", "approved", "rejected", "published"]

  def changeset(submission, attrs) do
    submission
    |> cast(attrs, [
      :submitter_id, :name, :url, :domain, :summary, :proposed_category_slug, :tags,
      :sug_originality, :sug_human_authorship, :sug_depth, :sug_freshness, :sug_design_quality,
      :status, :reviewer_id, :reviewer_notes, :published_site_id
    ])
    |> validate_required([:submitter_id, :name, :url, :domain, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_score(:sug_originality)
    |> validate_score(:sug_human_authorship)
    |> validate_score(:sug_depth)
    |> validate_score(:sug_freshness)
    |> validate_score(:sug_design_quality)
  end

  defp validate_score(changeset, field) do
    validate_number(changeset, field,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    )
  end
end
