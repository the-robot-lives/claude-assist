defmodule Therobotplans.Services.Reaction do
  @moduledoc """
  Generic per-entity reactions keyed by (entity_type, entity_id). `persona` is
  the reactor (a user id). Idempotent add: re-adding the same
  (entity, emoji, persona) is a no-op. Completes the polymorphic quartet
  (Services.Comment / Attach / Watch / Reaction) backed by changelog 027.
  """
  import Ecto.Query

  alias Therobotplans.Repo
  alias Therobotplans.Schema.Reaction

  @doc """
  Add a reaction. Idempotent: a duplicate (entity_type, entity_id, persona,
  emoji) returns the existing row rather than erroring. Mirrors the NPL
  wiki add_reaction on_conflict semantics, adapted to the trp_reactions shape.
  """
  def add(entity_type, entity_id, persona, emoji) do
    %Reaction{}
    |> Reaction.changeset(%{
      entity_type: entity_type,
      entity_id: entity_id,
      persona: persona,
      emoji: emoji
    })
    |> Repo.insert(
      on_conflict: :nothing,
      conflict_target: [:entity_type, :entity_id, :persona, :emoji]
    )
    |> case do
      {:ok, %Reaction{id: nil}} ->
        {:ok,
         Repo.get_by(Reaction,
           entity_type: entity_type,
           entity_id: entity_id,
           persona: persona,
           emoji: emoji
         )}

      other ->
        other
    end
  end

  def list(entity_type, entity_id) do
    Reaction
    |> where([r], r.entity_type == ^entity_type and r.entity_id == ^entity_id)
    |> order_by([r], asc: r.inserted_at)
    |> Repo.all()
  end

  @doc "Remove a single (entity, persona, emoji) reaction. Returns :ok | {:error, :not_found}."
  def remove(entity_type, entity_id, persona, emoji) do
    {count, _} =
      Reaction
      |> where(
        [r],
        r.entity_type == ^entity_type and r.entity_id == ^entity_id and
          r.persona == ^persona and r.emoji == ^emoji
      )
      |> Repo.delete_all()

    if count > 0, do: :ok, else: {:error, :not_found}
  end
end
