defmodule Foryou.Schema.Lists.ListAttribute do
  @moduledoc """
  A typed field on a List — the no-migration attribute model. Values submitted
  against an attribute are stored on `signups.attribs` keyed by `slug`. At most
  one `is_identity` (email) attribute per list backs `signups.email`; deprecating
  an attribute (`status='deprecated'`) hides it from the form but keeps stored
  values on historical signups.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @types ~w(email string text int float date guid select multiselect)
  @statuses ~w(active deprecated)

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "list_attributes" do
    belongs_to :list, Foryou.Schema.Lists.List, type: Ecto.UUID
    field :slug, :string
    field :name, :string
    field :type, :string
    field :required, :boolean, default: false
    field :is_identity, :boolean, default: false
    field :options, {:array, :map}
    field :validation, :map
    field :sort_order, :integer, default: 0
    field :status, :string, default: "active"
    timestamps(type: :utc_datetime_usec, inserted_at: :inserted_at, updated_at: :updated_at)
  end

  def changeset(attr, attrs) do
    attr
    |> cast(attrs, [:list_id, :slug, :name, :type, :required, :is_identity,
                    :options, :validation, :sort_order, :status])
    |> validate_required([:list_id, :slug, :name, :type])
    |> validate_inclusion(:type, @types)
    |> validate_inclusion(:status, @statuses)
    |> validate_identity_is_email()
    |> unique_constraint(:slug, name: :uq_list_attributes_list_slug)
    |> unique_constraint(:is_identity, name: :uq_list_attributes_identity_per_list)
    |> foreign_key_constraint(:list_id)
  end

  defp validate_identity_is_email(changeset) do
    case {get_field(changeset, :is_identity), get_field(changeset, :type)} do
      {true, type} when type != "email" ->
        add_error(changeset, :is_identity, "identity attribute must be of type email")

      _ ->
        changeset
    end
  end
end
