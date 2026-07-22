defmodule Therobotknows.Schema.Canon.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  @entry_types ~w(character location event faction object concept rule)
  @statuses ~w(canon draft generated)

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "entries" do
    field :type, :string
    field :status, :string, default: "draft"
    field :title, :string
    field :slug, :string
    field :excerpt, :string
    field :body, :map, default: %{}
    field :era, :string
    field :region, :string
    field :metadata, :map, default: %{}
    field :word_count, :integer, default: 0
    field :version, :integer, default: 1
    field :created_by, Ecto.UUID
    field :deleted_at, :utc_datetime_usec

    belongs_to :universe, Therobotknows.Schema.Universe.Universe

    many_to_many :tags, Therobotknows.Schema.Canon.Tag,
      join_through: Therobotknows.Schema.Canon.EntryTag,
      on_replace: :delete

    timestamps(type: :utc_datetime_usec)
  end

  def entry_types, do: @entry_types
  def statuses, do: @statuses

  def changeset(entry, attrs) do
    attrs = normalize_attrs(attrs)

    entry
    |> cast(attrs, [
      :universe_id,
      :type,
      :status,
      :title,
      :slug,
      :excerpt,
      :body,
      :era,
      :region,
      :metadata,
      :word_count,
      :version,
      :created_by,
      :deleted_at
    ])
    |> put_word_count()
    |> validate_required([:universe_id, :type, :title, :status])
    |> validate_inclusion(:type, @entry_types)
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint([:universe_id, :slug], name: :uq_entries_universe_slug)
  end

  defp normalize_attrs(attrs) when is_map(attrs) do
    body = Map.get(attrs, :body) || Map.get(attrs, "body")

    cond do
      is_binary(body) ->
        attrs
        |> Map.put(:body, %{"type" => "text", "text" => body})
        |> Map.delete("body")

      true ->
        attrs
    end
  end

  defp normalize_attrs(attrs), do: attrs

  def soft_delete_changeset(entry) do
    change(entry, %{
      deleted_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
    })
  end

  def allowed_transition?(from, to) when from == to, do: true

  def allowed_transition?(from, to) do
    case {from, to} do
      {"draft", "canon"} -> true
      {"draft", "generated"} -> true
      {"generated", "canon"} -> true
      {"generated", "draft"} -> true
      {"canon", "draft"} -> true
      _ -> false
    end
  end

  defp put_word_count(changeset) do
    case get_field(changeset, :body) do
      nil ->
        changeset

      body ->
        text = body_to_text(body)
        words = text |> String.split(~r/\s+/, trim: true) |> length()
        put_change(changeset, :word_count, words)
    end
  end

  defp body_to_text(%{"text" => text}) when is_binary(text), do: text
  defp body_to_text(body) when is_map(body), do: Jason.encode!(body)
  defp body_to_text(body) when is_binary(body), do: body
  defp body_to_text(_), do: ""
end
