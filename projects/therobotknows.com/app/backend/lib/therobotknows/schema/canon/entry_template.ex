defmodule Therobotknows.Schema.Canon.EntryTemplate do
  use Ecto.Schema

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "entry_templates" do
    field :type, :string
    field :name, :string
    field :fields, Therobotknows.Schema.Canon.JsonStringList, default: []
    field :body_skeleton, :string, default: ""
    field :inserted_at, :utc_datetime_usec
  end
end
