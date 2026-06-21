defmodule TheRobotRemembers.Memory.Seeds do
  @moduledoc """
  A simulated memory payload for tests and demos. The set is deliberately structured into
  emotional clusters (frustrated / triumphant / calm-focused / anxious) with overlapping domains
  and tangents, so retrieval behaviour is assertable:

    * `recall_by_emotion/3` from a frustrated state should surface the frustrated cluster ahead of
      the triumphant one (even across unrelated content).
    * the Weaver should link within-cluster (emotional) and within-domain (contextual) memories.
  """
  alias TheRobotRemembers.Memory

  @payload [
    # ── frustrated cluster (negative valence, high arousal, low dominance) ──
    %{
      content: "Spent four hours chasing a Postgres deadlock at 2am; every fix made it worse.",
      context: "debugging the connection pool under production load",
      reflection: "exhausted, frustrated, and a little defeated",
      tangent: "reminds me of the DNS outage we fought last winter",
      valence: -0.7, arousal: 0.75, dominance: 0.25, domain: "debugging"
    },
    %{
      content: "The NTP time server kept drifting and nothing I tried would hold it steady.",
      context: "late-night infrastructure firefight",
      reflection: "stuck and frustrated, going in circles",
      tangent: "feels like that deadlock night all over again",
      valence: -0.55, arousal: 0.68, dominance: 0.3, domain: "infra"
    },
    %{
      content: "Merge conflict hell after the long-lived branch finally came back.",
      context: "rebasing three weeks of divergent work",
      reflection: "irritated and tense",
      valence: -0.5, arousal: 0.6, dominance: 0.35, domain: "debugging"
    },

    # ── triumphant cluster (positive valence, high dominance) ──
    %{
      content: "Shipped the 2.0 release and the live demo went off without a hitch.",
      context: "launch day in front of the whole company",
      reflection: "elated, proud, on top of the world",
      tangent: "the opposite of that awful deadlock night",
      valence: 0.9, arousal: 0.65, dominance: 0.85, domain: "release"
    },
    %{
      content: "Closed the enterprise deal we'd chased for six months.",
      context: "final negotiation call",
      reflection: "triumphant and relieved",
      valence: 0.85, arousal: 0.6, dominance: 0.8, domain: "sales"
    },

    # ── calm-focused cluster (neutral/positive valence, low arousal, mid-high dominance) ──
    %{
      content: "Quiet morning refactoring the recall pipeline; everything fell into place.",
      context: "deep work before anyone else was online",
      reflection: "calm, focused, in flow",
      tangent: "the kind of morning I wish every day started with",
      valence: 0.45, arousal: 0.2, dominance: 0.7, domain: "debugging"
    },
    %{
      content: "Wrote the architecture doc while sipping coffee; ideas connected cleanly.",
      context: "planning the memory service",
      reflection: "settled and clear-headed",
      valence: 0.4, arousal: 0.25, dominance: 0.65, domain: "design"
    },

    # ── anxious cluster (negative valence, high arousal, low dominance, social) ──
    %{
      content: "Waiting for the security audit results, refreshing my inbox every minute.",
      context: "the day before the compliance review",
      reflection: "anxious and on edge",
      tangent: "same knot in my stomach as before the big demo",
      valence: -0.4, arousal: 0.7, dominance: 0.3, domain: "security"
    },
    %{
      content: "Pushed a hotfix to prod with my heart pounding, hoping it wouldn't make things worse.",
      context: "incident response, customers affected",
      reflection: "scared but determined",
      valence: -0.35, arousal: 0.8, dominance: 0.4, domain: "infra"
    },

    # ── collaborative-warm (positive valence, oxytocin-flavored, social) ──
    %{
      content: "Paired with Sam all afternoon and we cracked the gnarly caching bug together.",
      context: "pair programming session",
      reflection: "grateful and energized by the collaboration",
      tangent: "reminds me why I love working on a team",
      collaborators: ["sam"],
      valence: 0.7, arousal: 0.5, dominance: 0.6, domain: "debugging"
    }
  ]

  # ── Large-scale generator ───────────────────────────────────────
  # Memories are agent-bound: the generator produces `remember/2` attrs (content/mood/context/
  # collaborators/domain/occurred_at); the owning agent comes from the context passed to
  # `remember/2`. The "users" below are collaborators the agent worked with.

  @users ~w(alice bob carol dave erin frank grace heidi ivan judy)

  # Task archetypes with a mood center {valence, arousal, dominance} and content material.
  @tasks [
    %{domain: "debugging", v: -0.35, a: 0.62, d: 0.42,
      objs: ["a Postgres deadlock", "a race condition", "a memory leak", "a flaky test", "a null-pointer crash", "a connection-pool stall"],
      verbs: ["chased down", "wrestled with", "finally cornered", "kept hitting", "bisected"]},
    %{domain: "incident", v: -0.55, a: 0.82, d: 0.35,
      objs: ["a prod outage", "a cascading failure", "a data-corruption scare", "an expired cert", "a runaway query"],
      verbs: ["scrambled on", "paged in for", "firefought", "triaged", "rolled back"]},
    %{domain: "release", v: 0.8, a: 0.62, d: 0.82,
      objs: ["the 2.0 launch", "the mobile rollout", "the API v3 cutover", "the beta release", "the GA milestone"],
      verbs: ["shipped", "launched", "cut over", "rolled out", "landed"]},
    %{domain: "design", v: 0.42, a: 0.24, d: 0.66,
      objs: ["the recall pipeline", "the schema", "the event bus", "the auth flow", "the caching layer"],
      verbs: ["sketched out", "refactored", "diagrammed", "thought through", "cleaned up"]},
    %{domain: "review", v: 0.12, a: 0.42, d: 0.52,
      objs: ["the migration PR", "a tricky diff", "the API contract", "the test plan", "a security patch"],
      verbs: ["reviewed", "left comments on", "approved", "pushed back on", "paired over"]},
    %{domain: "sales", v: 0.5, a: 0.6, d: 0.7,
      objs: ["the enterprise deal", "the renewal", "a tough demo", "the pricing call", "the pilot"],
      verbs: ["closed", "pitched", "negotiated", "rescued", "ran"]},
    %{domain: "research", v: 0.45, a: 0.3, d: 0.6,
      objs: ["embedding models", "a ranking idea", "a new index type", "a decay curve", "a fusion strategy"],
      verbs: ["prototyped", "benchmarked", "read up on", "experimented with", "evaluated"]},
    %{domain: "mentoring", v: 0.62, a: 0.46, d: 0.6,
      objs: ["the onboarding", "a hard concept", "their first PR", "a career chat", "debugging skills"],
      verbs: ["walked through", "coached on", "unblocked", "celebrated", "paired on"]},
    %{domain: "security", v: -0.4, a: 0.7, d: 0.32,
      objs: ["the audit findings", "a suspected breach", "a leaked key", "the pen-test report", "an injection attempt"],
      verbs: ["sweated over", "investigated", "locked down", "waited on", "remediated"]},
    %{domain: "ops", v: -0.1, a: 0.5, d: 0.5,
      objs: ["the cluster upgrade", "a noisy alert", "capacity planning", "the backup restore", "a cost spike"],
      verbs: ["handled", "tuned", "chased", "automated", "babysat"]}
  ]

  @reflections %{
    neg: ["exhausted and frustrated", "stuck and going in circles", "tense and irritable", "drained", "anxious and on edge", "scared but determined"],
    neu: ["focused", "heads-down", "matter-of-fact", "steady", "a bit restless"],
    pos: ["calm and in flow", "energized", "proud and relieved", "grateful for the team", "quietly satisfied", "elated"]
  }

  @doc """
  Generate `count` deterministic, varied `remember/2` attrs spanning `days` of a simulated year
  starting 2025-01-01. Seeded by `seed` for reproducibility. Memories are agent-bound at write
  time via the context passed to `remember/2`.

  Opts: `:count` (default 1024), `:days` (default 365), `:seed` (default 42).
  """
  def generate(opts \\ []) do
    count = opts[:count] || 1024
    days = opts[:days] || 365
    seed = opts[:seed] || 42
    :rand.seed(:exsss, {seed, seed * 7 + 1, seed * 13 + 3})
    start = ~U[2025-01-01 00:00:00Z]

    for i <- 1..count, do: gen_one(i, start, days)
  end

  defp gen_one(i, start, days) do
    task = Enum.random(@tasks)
    user = Enum.random(@users)
    obj = Enum.random(task.objs)
    verb = Enum.random(task.verbs)

    v = clampf(task.v + jitter(0.4), -1.0, 1.0)
    a = clampf(task.a + jitter(0.3), 0.0, 1.0)
    d = clampf(task.d + jitter(0.3), 0.0, 1.0)

    occurred = DateTime.add(start, :rand.uniform(days * 86_400) - 1, :second)
    collaborators = if :rand.uniform() < 0.75, do: Enum.uniq([user | maybe_second_user()]), else: []

    %{
      content: "#{String.capitalize(verb)} #{obj} with #{user}.",
      context: "#{task.domain} work — #{verb} #{obj}",
      reflection: reflection_for(v),
      tangent: tangent_for(task, obj),
      valence: v,
      arousal: a,
      dominance: d,
      domain: task.domain,
      topic: obj,
      collaborators: collaborators,
      occurred_at: occurred,
      content_type: :episodic,
      # tag the index in environment for traceability
      environment: %{"seq" => i}
    }
  end

  defp maybe_second_user do
    if :rand.uniform() < 0.35, do: [Enum.random(@users)], else: []
  end

  defp reflection_for(v) do
    cond do
      v < -0.2 -> Enum.random(@reflections.neg)
      v < 0.25 -> Enum.random(@reflections.neu)
      true -> Enum.random(@reflections.pos)
    end
  end

  defp tangent_for(task, obj) do
    if :rand.uniform() < 0.5 do
      other = Enum.random(@tasks)
      "reminds me of #{Enum.random(other.objs)}"
    else
      "another #{task.domain} day, like #{obj}"
    end
  end

  # uniform jitter in [-spread/2, spread/2]
  defp jitter(spread), do: (:rand.uniform() - 0.5) * spread
  defp clampf(x, lo, hi), do: x |> max(lo) |> min(hi)

  @doc "The raw hand-authored simulated payload (small; for fast unit tests)."
  def payload, do: @payload

  @doc """
  Seed the payload for an owner. Returns the list of `{:ok, result}` from `remember/2`.
  With `Oban testing: :inline`, this also runs embedding + Weaver linking synchronously.
  """
  def seed(context, payload \\ @payload) do
    Enum.map(payload, fn attrs -> Memory.remember(attrs, context) end)
  end
end
