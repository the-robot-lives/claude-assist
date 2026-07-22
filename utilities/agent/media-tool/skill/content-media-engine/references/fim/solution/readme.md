# README — The project front door and billboard

A README is the first (often only) file a visitor reads about a project. It does two jobs at
once: it's a **billboard** — in five seconds, what is this and should I care? — and a **door**
— the fastest path to installing, running, and getting help. It lives at the repo root and
renders on GitHub/GitLab as the project's landing page. Good READMEs answer *what, why, how do
I use it* above the fold and get out of the way. Bad READMEs bury the one-line description
under badges, open with the author's life story, or omit the install step entirely. The reader
is deciding, in under a minute, whether to adopt, star, contribute, or close the tab.

**Output form**: markdown (`README.md`), rendered by the forge; may include badges, code, ToC
**Typical length**: 100–400 lines; long enough to onboard, short enough to scan
**Routed via**: `text_format: readme` (chat-type generation)

## Genre Conventions & Structure

Order matters — the top of the file is the billboard; everything below is progressive
disclosure for readers who've decided to stay.

1. **Project name + one-line description** — the single most important line. "A fast, minimal
   HTTP router for Go." The reader must grasp what this is in one sentence.
2. **Badges (optional, restrained)** — build status, version, license, coverage. A tidy row,
   not a wall. Badges are trust signals, not decoration.
3. **Why / value prop (1–2 sentences or a short bullet list)** — what problem it solves and why
   choose it over alternatives.
4. **Install** — the copy-paste command(s). `npm install x`, `pip install x`, `go get x`.
5. **Minimal usage / quickstart** — the smallest complete example that shows it working. The
   "hello world" that proves value in one code block.
6. **Key features** — a short bullet list of what it does (not an exhaustive manual).
7. **Configuration / options** — the common knobs, or a link to fuller docs.
8. **Links to docs** — full documentation, API reference, examples, changelog.
9. **Contributing** — how to get involved, or a link to `CONTRIBUTING.md`.
10. **License** — the license name (and a link to the `LICENSE` file).
11. **Optional**: badges of support, project structure tree, roadmap, acknowledgments, FAQ.

For anything but a tiny project, add a **table of contents** after the intro so long READMEs
stay navigable.

## Hard Constraints

- **The one-line description is present and near the very top** — the billboard line, before
  any long prose. A reader who reads only one line must understand the project.
- **Install instructions are copy-paste-runnable** — the exact command, correct package name,
  no placeholders left unfilled.
- **At least one minimal, runnable usage example** — real code that works as written, showing
  the core value.
- **License is stated.** An unlicensed public repo is legally unusable by others; name the
  license explicitly.
- **Above-the-fold answers what + why + how-to-install** before deep detail — don't make the
  reader scroll past history/philosophy to find the install command.
- **Links, not full manuals** — a README points to docs; it doesn't reproduce the whole user
  guide. Keep it a door, not the building.
- **Renders correctly as GitHub-Flavored Markdown** — tables, fenced code with language tags,
  relative links to repo files that resolve.

## How-To (worked recipes)

### How to write the one-line description
Name the category + the differentiator, concretely. No mission statement.
> ❌ "This project aims to revolutionize the way developers think about state management."
> ✅ "A 1 KB state manager for React with no boilerplate and no context providers."

*Note:* if you can't say what it is in one line, the reader can't either — sharpen the line
before writing anything else.

### How to write a minimal usage block that sells the project
Show the smallest complete example that produces a real result.
> ```js
> import { create } from "tinystore";
> const useCount = create(() => ({ n: 0, inc: (s) => ({ n: s.n + 1 }) }));
> // in a component:
> const { n, inc } = useCount();
> ```
> Three lines to a working store — no provider, no reducer.

*Note:* the usage block *is* the pitch. Choose the example that best shows why the project is
nicer than the alternative, and keep it runnable.

### How to keep badges from becoming a wall
Pick the few that signal health and legitimacy; drop vanity badges.
> `![build](…)` `![npm](…)` `![license: MIT](…)`  — build, version, license. Stop there.

*Note:* rows of 12 badges read as noise and push the important content below the fold. Three to
five, one line.

### How to decide what belongs in the README vs. the docs
README = billboard + door. Everything exhaustive lives in `/docs` and gets a link.
> In README: one-line what, why, install, one usage example, key features, links.
> In docs (linked): full API, every config option, tutorials, architecture, FAQ.

*Note:* when a section grows past a screen, move it to docs and leave a link. The README should
stay scannable.

### How to write a features list that's actually scannable
Lead each bullet with the capability in bold, then a few words of payoff. Parallel structure,
no paragraphs.
> - **Zero-config** — works out of the box; no setup file required.
> - **Type-safe** — full TypeScript types, inferred from your schema.
> - **1 KB gzipped** — no runtime dependencies.
> - **Framework-agnostic** — React, Vue, and vanilla adapters included.

*Note:* 4–7 bullets. Beyond that it's a manual; link to the full feature docs.

### How to show project structure without dumping the whole tree
If structure helps orientation, show the top level only, annotated.
> ```
> src/       # library source
> examples/  # runnable usage examples
> docs/      # full documentation
> ```

*Note:* a 200-line `tree` dump helps no one; show the handful of directories a newcomer needs.

### How to structure a README for a repo people will contribute to
Add the contributor-facing sections after the user-facing ones.
> ## Contributing
> PRs welcome. See **[CONTRIBUTING.md](CONTRIBUTING.md)** for dev setup and the test command.
> ## License
> MIT © 2026 Your Name — see [LICENSE](LICENSE).

*Note:* link `CONTRIBUTING.md`/`LICENSE` rather than inlining them; keep the README focused on adoption.

## Do's and Don'ts

### ✅ Do
- Put a sharp one-line description at the very top.
- Answer what / why / install above the fold.
- Give a copy-paste install command with the correct package name.
- Include one minimal, runnable usage example that shows the core value.
- Keep badges to a restrained row of trust signals.
- Add a table of contents once the file gets long.
- Link to full docs, contributing guide, and license instead of inlining everything.
- State the license explicitly.

### ❌ Don't
- **Bury the one-liner** under a badge wall or a personal narrative.
- **Omit install or usage** — the two things every visitor came for.
- **Reproduce the entire manual** — the README becomes unscannable; link instead.
- **Leave placeholders** (`npm install <your-package-here>`) in a published README.
- **Skip the license** — it makes the code legally unusable by others.
- **Over-badge** — 12 shields signal insecurity, not quality.
- **Write aspirational fiction** — documenting features that don't exist yet as if they ship today.
- **Open with "In today's world of software…"** — say what the project *is*, immediately.

## Tone, Voice & Register

Confident, concrete, welcoming. Third person for the description ("A fast router…"),
second-person imperative for instructions ("Install with…", "Run…"). Present tense. Plain,
specific language — concrete capabilities beat adjectives ("1 KB, zero dependencies" beats
"lightweight and powerful"). Friendly but not salesy; the README informs a decision, it doesn't
hard-sell. Match the project's seriousness: a fun side-project can be playful; a security
library should read sober and precise.

## Platform / Placement Constraints

- **GitHub/GitLab rendering**: GitHub-Flavored Markdown — fenced code with language tags,
  tables, task lists, and relative links to repo files (`LICENSE`, `docs/`). Images/badges load
  from URLs; keep them few and fast.
- **Above the fold**: the forge shows the top of the README on the repo page — the one-liner,
  key value, and (ideally) install must be visible without scrolling.
- **Package registries**: npm/PyPI/crates.io render the README on the package page — so the
  install command and usage double as the registry listing; make them accurate for that context.
- **Relative links**: link to other repo files with relative paths so they work on the forge and
  in clones; avoid absolute links to a branch that may be renamed.
- **Accessibility**: badges and images need alt text; don't encode essential info in an image
  only (a diagram is fine, but the key facts should also be in text).

## Common Pitfalls & Anti-patterns

- **No one-line description** — the reader can't tell what the project is.
- **Badge wall** pushing real content below the fold.
- **Missing/placeholder install or usage** — the visitor can't try it.
- **README-as-manual** — thousands of lines that should be in `/docs`.
- **No license** — legally unusable, and a red flag to adopters.
- **Aspirational features** documented as shipped.
- **AI-tells**: "In today's fast-paced development ecosystem…", "This powerful and flexible
  library seamlessly…", "delve into", tri-colon adjective strings ("fast, modern, and
  intuitive"), an inflated intro paragraph before the one-liner, and em-dash overuse. Also:
  inventing badges, benchmark numbers, or a package name that doesn't match the real one. Lead
  with what it is; verify the install command and package name are real.

## Prep-Agent Notes (media-tool specific)

Given a raw creative brief, the prep agent should:
1. **Distill the one-line description** — category + differentiator, ≤ ~15 words — and place it
   at the top.
2. **Extract the value prop** (problem solved, why-vs-alternatives) into 1–2 sentences or a
   short bullet list.
3. **Produce the install command** from the stated ecosystem/package name; if the exact name
   isn't given, mark a placeholder and flag it rather than invent a real-looking package.
4. **Write one minimal, runnable usage example** that best demonstrates the core value.
5. **List key features** as a short bullet set (not an exhaustive manual).
6. **Add links** to docs, contributing, changelog, and **state the license**.
7. **Insert a ToC** if the assembled README exceeds roughly a screen.
8. Apply `prompt.system` voice (serious vs. playful, brand tone) to register; keep install/usage
   accuracy non-negotiable. Output is plain text/markdown via the chat provider path.

## See Also
- `getting-started.md` — the fuller quickstart a README's usage section links to
- `user-manual.md` — the complete docs the README points into
- `api-reference.md` — the hosted reference linked from the README
- `technical-blog.md` — long-form narrative vs. the README's billboard brevity
- `../use-case/document-processing.md` — publishing/rendering docs from the repo
