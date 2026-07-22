defmodule Therobotknows.Generations do
  @moduledoc "AI generation jobs for canon entries (v0.1 single-entry context)."

  import Ecto.Query
  alias Therobotknows.Repo
  alias Therobotknows.Universes
  alias Therobotknows.Canon
  alias Therobotknows.AI.Budget
  alias Therobotknows.Schema.Generation.Generation
  alias Therobotknows.Schema.Canon.Entry
  alias Therobotknows.Workers.GenerationWorker

  def list(universe_id_or_slug, user_id, opts \\ []) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :viewer) do
      page = Keyword.get(opts, :page, 1)
      per = min(Keyword.get(opts, :per_page, 25), 100)

      q =
        from g in Generation,
          where: g.universe_id == ^universe.id,
          order_by: [desc: g.inserted_at]

      total = Repo.aggregate(q, :count, :id)

      gens =
        q
        |> limit(^per)
        |> offset(^((page - 1) * per))
        |> Repo.all()
        |> Enum.map(&to_map/1)

      {:ok,
       %{
         generations: gens,
         meta: %{page: page, per_page: per, total: total, total_pages: max(1, ceil_div(total, per))}
       }}
    end
  end

  def get(universe_id_or_slug, id, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :viewer),
         %Generation{} = g <- Repo.get_by(Generation, id: id, universe_id: universe.id) do
      {:ok, to_map(g)}
    else
      nil -> {:error, :not_found}
      e -> e
    end
  end

  def create(universe_id_or_slug, attrs, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :editor),
         :ok <- Budget.check_budget(user_id) do
      source_ids =
        Map.get(attrs, "source_entry_ids") || Map.get(attrs, :source_entry_ids) || []

      cs =
        %Generation{}
        |> Generation.changeset(%{
          universe_id: universe.id,
          prompt: Map.get(attrs, "prompt") || Map.get(attrs, :prompt),
          entry_type: Map.get(attrs, "entry_type") || Map.get(attrs, :entry_type) || "concept",
          status: "pending",
          params: Map.get(attrs, "params") || Map.get(attrs, :params) || %{},
          source_entry_ids: source_ids,
          created_by: user_id
        })

      case Repo.insert(cs) do
        {:ok, gen} ->
          _ =
            %{
              "generation_id" => gen.id,
              "universe_id" => universe.id
            }
            |> GenerationWorker.new()
            |> Oban.insert()

          # Synchronous fallback for envs without Oban processing
          maybe_run_inline(gen)

          {:ok, to_map(Repo.get!(Generation, gen.id))}

        error ->
          error
      end
    end
  end

  def promote(universe_id_or_slug, id, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :editor),
         %Generation{status: "complete"} = g <-
           Repo.get_by(Generation, id: id, universe_id: universe.id) do
      body = g.output_body || %{"type" => "text", "text" => ""}

      case Canon.create_entry(
             universe.id,
             %{
               "type" => g.entry_type,
               "status" => "generated",
               "title" => g.output_title || "Generated entry",
               "body" => body,
               "excerpt" => excerpt_from_body(body)
             },
             user_id
           ) do
        {:ok, entry} ->
          g
          |> Generation.changeset(%{
            status: "promoted",
            output_entry_id: entry.id
          })
          |> Repo.update()

          {:ok, Map.put(to_map(Repo.get!(Generation, g.id)), :entry, entry)}

        error ->
          error
      end
    else
      %Generation{} -> {:error, :not_ready}
      nil -> {:error, :not_found}
      e -> e
    end
  end

  def discard(universe_id_or_slug, id, user_id) do
    with {:ok, universe, _role} <- Universes.authorize(universe_id_or_slug, user_id, :editor),
         %Generation{} = g <- Repo.get_by(Generation, id: id, universe_id: universe.id) do
      g
      |> Generation.changeset(%{status: "discarded"})
      |> Repo.update()
      |> case do
        {:ok, updated} -> {:ok, to_map(updated)}
        e -> e
      end
    else
      nil -> {:error, :not_found}
      e -> e
    end
  end

  def run_generation(%Generation{} = gen) do
    gen
    |> Generation.changeset(%{status: "running"})
    |> Repo.update!()

    sources =
      from(e in Entry,
        where: e.id in ^gen.source_entry_ids and is_nil(e.deleted_at)
      )
      |> Repo.all()

    {title, body_text, citations} = synthesize(gen, sources)

    cost = 5 + length(sources) * 2

    gen
    |> Generation.changeset(%{
      status: "complete",
      output_title: title,
      output_body: %{"type" => "text", "text" => body_text},
      citations: citations,
      token_usage: %{"prompt" => 200, "completion" => 400},
      cost_cents: cost
    })
    |> Repo.update!()
    |> tap(fn g -> Budget.record_usage(g.created_by, g.universe_id, g.id, cost, 600) end)
  rescue
    e ->
      gen
      |> Generation.changeset(%{
        status: "failed",
        error_message: Exception.message(e)
      })
      |> Repo.update()
  end

  defp synthesize(gen, sources) do
    source_block =
      sources
      |> Enum.map(fn e ->
        "- #{e.title} (#{e.type}): #{e.excerpt || String.slice(to_string(e.title), 0, 80)}"
      end)
      |> Enum.join("\n")

    citations =
      Enum.map(sources, fn e ->
        %{"entry_id" => e.id, "title" => e.title, "excerpt" => e.excerpt}
      end)

    title =
      gen.prompt
      |> String.split(~r/[\.\n]/, parts: 2)
      |> List.first()
      |> String.slice(0, 120)
      |> then(fn t -> if t == "", do: "Generated #{gen.entry_type}", else: t end)

    body = """
    ## #{title}

    Generated for prompt: #{gen.prompt}

    ### Context used
    #{if source_block == "", do: "_No source entries selected._", else: source_block}

    ### Draft
    This is a v0.1 placeholder generation grounded in the listed canon sources.
    Review carefully before promoting to canon. Genre/tone from the universe config
    should guide further polish in the generation studio.
    """

    {title, body, citations}
  end

  defp maybe_run_inline(%Generation{} = gen) do
    # Always run inline for predictable local/dev behavior; Oban may also pick up the job.
    Task.start(fn -> run_generation(gen) end)
  end

  defp to_map(%Generation{} = g) do
    %{
      id: g.id,
      universe_id: g.universe_id,
      prompt: g.prompt,
      entry_type: g.entry_type,
      status: g.status,
      params: g.params || %{},
      output_title: g.output_title,
      output_body: g.output_body,
      output_entry_id: g.output_entry_id,
      source_entry_ids: g.source_entry_ids || [],
      citations: g.citations || [],
      error_message: g.error_message,
      token_usage: g.token_usage || %{},
      cost_cents: g.cost_cents,
      created_by: g.created_by,
      inserted_at: g.inserted_at,
      updated_at: g.updated_at
    }
  end

  defp excerpt_from_body(%{"text" => t}) when is_binary(t), do: String.slice(t, 0, 200)
  defp excerpt_from_body(_), do: nil

  defp ceil_div(0, _), do: 0
  defp ceil_div(a, b), do: div(a + b - 1, b)
end
