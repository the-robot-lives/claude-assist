defmodule Therobotplans.Services.Attach do
  @moduledoc """
  Generic per-entity attachments keyed by (entity_type, entity_id). Items use
  entity_type = "item". Ported from NPL Services.Attach.
  """
  import Ecto.Query

  alias Therobotplans.Repo
  alias Therobotplans.Schema.Attachment

  def add(entity_type, entity_id, attrs) do
    %Attachment{}
    |> Attachment.changeset(Map.merge(attrs, %{entity_type: entity_type, entity_id: entity_id}))
    |> Repo.insert()
  end

  def list(entity_type, entity_id) do
    Attachment
    |> where([a], a.entity_type == ^entity_type and a.entity_id == ^entity_id)
    |> order_by([a], asc: a.inserted_at)
    |> Repo.all()
  end

  def remove(attachment_id) do
    case Repo.get(Attachment, attachment_id) do
      nil -> {:error, :not_found}
      att -> Repo.delete(att)
    end
  end
end
