"use client";

import { useMemo } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import type { Catalog, GameEntry, ScoreKey } from "../lib/catalog";

const scoreLabels: Record<ScoreKey, string> = {
  complexity: "Complexity",
  monetization: "Money",
  novelty: "Novelty",
  marketability: "Market",
  prototype_fit: "Proto",
  production_risk: "Risk"
};

const sortOptions = [
  ["priority", "Priority"],
  ["title", "Title"],
  ["novelty", "Novelty"],
  ["marketability", "Market"],
  ["prototype_fit", "Prototype"],
  ["production_risk", "Risk"]
] as const;

type SortKey = (typeof sortOptions)[number][0];

function priorityScore(game: GameEntry) {
  return (
    game.scores.novelty * 1.4 +
    game.scores.marketability * 1.3 +
    game.scores.monetization * 1.1 +
    game.scores.prototype_fit -
    game.scores.complexity * 0.75 -
    game.scores.production_risk * 0.85
  );
}

function unique(values: string[]) {
  return Array.from(new Set(values)).sort((left, right) => left.localeCompare(right));
}

export function GameBrowser({ catalog }: { catalog: Catalog }) {
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();

  const query = params.get("q") ?? "";
  const grade = params.get("grade") ?? "all";
  const category = params.get("category") ?? "all";
  const tag = params.get("tag") ?? "all";
  const sort = (params.get("sort") ?? "priority") as SortKey;

  const categories = useMemo(
    () => unique(catalog.games.flatMap((game) => game.categories)),
    [catalog.games]
  );
  const tags = useMemo(() => unique(catalog.games.flatMap((game) => game.tags)), [catalog.games]);

  const filtered = useMemo(() => {
    const needle = query.trim().toLowerCase();

    return catalog.games
      .filter((game) => {
        const haystack = [
          game.title,
          game.slug,
          game.description,
          game.genre,
          game.monetization_model,
          ...game.categories,
          ...game.tags
        ]
          .join(" ")
          .toLowerCase();

        return (
          (!needle || haystack.includes(needle)) &&
          (grade === "all" || game.grade === grade) &&
          (category === "all" || game.categories.includes(category)) &&
          (tag === "all" || game.tags.includes(tag))
        );
      })
      .sort((left, right) => {
        if (sort === "title") {
          return left.title.localeCompare(right.title);
        }

        if (sort === "priority") {
          return priorityScore(right) - priorityScore(left);
        }

        return right.scores[sort] - left.scores[sort] || left.title.localeCompare(right.title);
      });
  }, [catalog.games, category, grade, query, sort, tag]);

  function updateParam(key: string, value: string) {
    const next = new URLSearchParams(params.toString());

    if (!value || value === "all") {
      next.delete(key);
    } else {
      next.set(key, value);
    }

    router.replace(`${pathname}?${next.toString()}`, { scroll: false });
  }

  function clearFilters() {
    router.replace(pathname, { scroll: false });
  }

  const gradeCounts = catalog.games.reduce<Record<string, number>>((acc, game) => {
    acc[game.grade] = (acc[game.grade] ?? 0) + 1;
    return acc;
  }, {});

  return (
    <div className="shell">
      <header className="topbar">
        <div>
          <p className="eyebrow">Game Workshop / Flesh</p>
          <h1>Backlog Rubric Browser</h1>
        </div>
        <div className="summary" aria-label="Backlog summary">
          <strong>{catalog.games.length}</strong>
          <span>concepts</span>
        </div>
      </header>

      <section className="rubric">
        <div>
          <h2>Rubric</h2>
          <p>
            Scores are 1-10. Higher is better for monetization, novelty, marketability,
            and prototype fit. Higher is worse for complexity and production risk.
          </p>
        </div>
        <div className="gradeStrip">
          {(["A", "B", "C", "D"] as const).map((letter) => (
            <button
              className={grade === letter ? "grade active" : "grade"}
              key={letter}
              onClick={() => updateParam("grade", grade === letter ? "all" : letter)}
              type="button"
            >
              <b>{letter}</b>
              <span>{gradeCounts[letter] ?? 0}</span>
            </button>
          ))}
        </div>
      </section>

      <section className="filters" aria-label="Backlog filters">
        <label className="search">
          <span>Search</span>
          <input
            value={query}
            onChange={(event) => updateParam("q", event.target.value)}
            placeholder="title, tag, genre, monetization..."
          />
        </label>
        <label>
          <span>Category</span>
          <select value={category} onChange={(event) => updateParam("category", event.target.value)}>
            <option value="all">All categories</option>
            {categories.map((item) => (
              <option key={item} value={item}>
                {item}
              </option>
            ))}
          </select>
        </label>
        <label>
          <span>Tag</span>
          <select value={tag} onChange={(event) => updateParam("tag", event.target.value)}>
            <option value="all">All tags</option>
            {tags.map((item) => (
              <option key={item} value={item}>
                {item}
              </option>
            ))}
          </select>
        </label>
        <label>
          <span>Sort</span>
          <select value={sort} onChange={(event) => updateParam("sort", event.target.value)}>
            {sortOptions.map(([value, label]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </select>
        </label>
        <button className="clear" onClick={clearFilters} type="button">
          Reset
        </button>
      </section>

      <div className="resultMeta">
        <span>{filtered.length} shown</span>
        <span>Generated {catalog.generated_at}</span>
      </div>

      <section className="grid" aria-label="Backlog games">
        {filtered.map((game) => (
          <article className="card" key={game.slug}>
            <div className="cardHead">
              <div>
                <p className="slug">{game.slug}</p>
                <h2>{game.title}</h2>
              </div>
              <span className={`badge grade${game.grade}`}>{game.grade}</span>
            </div>

            <p className="description">{game.description}</p>

            <div className="chips">
              {game.categories.map((item) => (
                <span key={item}>{item}</span>
              ))}
            </div>

            <div className="scores">
              {(Object.keys(scoreLabels) as ScoreKey[]).map((key) => (
                <div className="score" key={key}>
                  <span>{scoreLabels[key]}</span>
                  <meter min={1} max={10} value={game.scores[key]} />
                  <b>{game.scores[key]}</b>
                </div>
              ))}
            </div>

            <p className="rationale">{game.rationale}</p>

            <div className="cardFoot">
              <span>{game.monetization_model}</span>
              <a href={`/readme/${game.slug}`} target="_blank" rel="noreferrer">
                README
              </a>
            </div>
          </article>
        ))}
      </section>
    </div>
  );
}
