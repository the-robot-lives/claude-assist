defmodule Therobotknows.Schema.Canon.EntryTag do
  use Ecto.Schema

  @primary_key false
  @foreign_key_type Ecto.UUID

  schema "entry_tags" do
    belongs_to :entry, Therobotknows.Schema.Canon.Entry, primary_key: true
    belongs_to :tag, Therobotknows.Schema.Canon.Tag, primary_key: true
    field :inserted_at, :utc_datetime_usec
  end
end
