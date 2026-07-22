# verify.md (version: 3)

Copy-pasteable verification per stage. Run from the **repo root**
(`/home/keithbrings/Work/Space/Infra/Noizu`) with the stated env vars set. Every check prints
exactly one `PASS: <name>` or `FAIL: <name> — <reason>` line — paste the full output into your
report's `verify:` list. Requires `yq` (mikefarah, already on PATH) and standard coreutils;
no other dependencies.

`status: done` requires zero `FAIL` lines in your section. A single `FAIL` means
`blocked` (top-up and retry) or `failed` (something is actually broken) — see
`report-format.md`.

No section reads `state/_pipeline.yaml` — that file is off-limits to every stage agent. Any
pipeline-wide value a check needs (repo-lock session, media/eval/styleguide-serve status)
arrives as a spawn param the calling stage template passes through verbatim.

**§C only:** also requires `MEDIA`, `EVAL`, `STYLEGUIDE_SERVE` set to `on`/`off` — your
stage-c-theme.md spawn params (`media`/`eval`/`styleguide_serve`), passed through
verbatim, see its §9.

These snippets run under the pipeline's default shell, **zsh** — unlike bash, zsh does not
word-split an unquoted `$var` expansion, so `for x in $var` silently iterates once over the
whole value instead of splitting it (`for x in $(cmd)` is unaffected — command substitution
still splits normally). Keep new checks zsh-safe: prefer a `while read -r` loop over a
multi-line variable to an unquoted `for`.

---

## §A — README + PM foundation

```bash
#!/usr/bin/env bash
set -uo pipefail
P="projects/$PROJECT"
PM="$P/project-management"
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1 — $2"; }

# 1. README: >=50 lines and not the start-app scaffold stub
if [ -f "$P/README.md" ]; then
  lines=$(wc -l < "$P/README.md")
  heading=$(grep -m1 '^#' "$P/README.md" || true)
  if [ "$lines" -ge 50 ] && [ "$heading" != "# start-app" ]; then
    pass "README (>=50 lines, not start-app stub, $lines lines)"
  else
    fail "README" "$lines lines, heading='$heading'"
  fi
else
  fail "README" "missing"
fi

# 2. personas >= 5
n_personas=$(find "$PM/personas" -maxdepth 1 -name 'P-*.md' 2>/dev/null | wc -l)
[ "$n_personas" -ge 5 ] && pass "personas >=5 ($n_personas)" || fail "personas" "$n_personas found, need >=5"

# 3. stories >= 100 (over-target, e.g. 1000, is a PASS)
n_stories=$(find "$PM/user-stories" -maxdepth 1 -name 'US-*.md' 2>/dev/null | wc -l)
[ "$n_stories" -ge 100 ] && pass "stories >=100 ($n_stories)" || fail "stories" "$n_stories found, need >=100"

# 4. index.yaml counts == file counts
idx_personas=$(yq e '.personas | length' "$PM/personas/index.yaml" 2>/dev/null || echo -1)
[ "$idx_personas" = "$n_personas" ] && pass "personas index.yaml matches file count ($idx_personas)" || fail "personas index" "index=$idx_personas files=$n_personas"
idx_stories=$(yq e '.stories | length' "$PM/user-stories/index.yaml" 2>/dev/null || echo -1)
[ "$idx_stories" = "$n_stories" ] && pass "stories index.yaml matches file count ($idx_stories)" || fail "stories index" "index=$idx_stories files=$n_stories"

# 5. every story's persona cross-refs resolve to a real persona file
bad_refs=0
for f in "$PM"/user-stories/US-*.md; do
  [ -f "$f" ] || continue
  refs=$(awk '/^---$/{c++; next} c==1' "$f" | yq e '.personas[]' - 2>/dev/null)
  # zsh doesn't word-split a bare $refs — read it line-by-line instead (works in bash too)
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    ls "$PM"/personas/"${r}"*.md >/dev/null 2>&1 || bad_refs=$((bad_refs + 1))
  done <<< "$refs"
done
[ "$bad_refs" -eq 0 ] && pass "story persona-refs resolve" || fail "story persona-refs" "$bad_refs unresolved reference(s)"

# 6. screens/components (if present) have a matching README index
for d in screens components; do
  n=$(find "$PM/$d" -maxdepth 1 -name '*.md' ! -name 'README.md' 2>/dev/null | wc -l)
  if [ "$n" -gt 0 ]; then
    if [ -f "$PM/$d/README.md" ]; then pass "$d has README index ($n files)"; else fail "$d README index" "missing, $n files present"; fi
  fi
done

# 7. no leftover non-standard PM location after migration
if [ -d "$P/docs/project-management" ]; then fail "docs/project-management" "still exists — Phase 0.5 migration incomplete"; else pass "no docs/project-management leftover"; fi
```

---

## §B — Theme treatises

```bash
#!/usr/bin/env bash
set -uo pipefail
P="projects/$PROJECT"
TD="$P/design/theme"
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1 — $2"; }

# similitude matrix + E recorded
if [ -f "$TD/THEMES.md" ] && grep -q "E *=" "$TD/THEMES.md"; then
  pass "similitude matrix + E recorded in THEMES.md"
else
  fail "THEMES.md" "missing or E= not recorded"
fi

# treatise count (>=1; the exact "ceil(7-E) new" arithmetic is a Stage B judgment call,
# not re-derivable here — this just confirms treatises actually got written)
n_treatise=$(find "$TD" -maxdepth 1 -name 'treatise-*.md' 2>/dev/null | wc -l)
[ "$n_treatise" -ge 1 ] && pass "treatise count ($n_treatise)" || fail "treatise count" "0 found"

# every treatise has exactly the 10 canonical numbered sections
for f in "$TD"/treatise-*.md; do
  [ -f "$f" ] || continue
  n_sections=$(grep -cE '^## [0-9]+\.' "$f")
  if [ "$n_sections" -eq 10 ]; then pass "$(basename "$f") has 10 sections"; else fail "$(basename "$f") sections" "found $n_sections, need 10"; fi
done

# allocation.yaml — schema: version, inventory_total, unique[]{screen,theme}, overlap[]{screen,themes[]}
ALLOC="$P/design/asset-prompts/screens/allocation.yaml"
if [ -f "$ALLOC" ]; then
  u=$(yq e '.unique | length' "$ALLOC" 2>/dev/null || echo 0)
  o=$(yq e '.overlap | length' "$ALLOC" 2>/dev/null || echo 0)
  inv=$(find "$P/project-management/screens" -maxdepth 1 -name '*.md' ! -name 'README.md' 2>/dev/null | wc -l)
  if { [ "$u" -ge 30 ] && [ "$u" -le 40 ]; } || [ "$u" -eq "$inv" ]; then
    pass "allocation unique set size ($u, inventory=$inv)"
  else
    fail "allocation unique set" "u=$u inventory=$inv — need 30<=u<=40 or ==inventory"
  fi
  if [ "$o" -ge 2 ] && [ "$o" -le 5 ]; then pass "allocation overlap pairs ($o)"; else fail "allocation overlap pairs" "$o found, need 2-5"; fi
  # ids resolve: every screen named in unique/overlap exists in the screens inventory
  bad_ids=0
  for s in $(yq e '.unique[].screen' "$ALLOC" 2>/dev/null) $(yq e '.overlap[].screen' "$ALLOC" 2>/dev/null); do
    ls "$P"/project-management/screens/"${s}"* >/dev/null 2>&1 || bad_ids=$((bad_ids + 1))
  done
  [ "$bad_ids" -eq 0 ] && pass "allocation screen ids resolve" || fail "allocation screen ids" "$bad_ids unresolved"
  # per-theme totals 5-8 (unique assignments count 1x, overlap count 1x per theme listed)
  bad_theme_counts=0
  for t in $(yq e '(.unique[].theme, .overlap[].themes[])' "$ALLOC" 2>/dev/null | sort -u); do
    cnt=$(yq e "([.unique[] | select(.theme == \"$t\")] | length) + ([.overlap[] | select(.themes[] == \"$t\")] | length)" "$ALLOC")
    if [ "$cnt" -ge 5 ] && [ "$cnt" -le 8 ]; then pass "theme $t: $cnt screens (5-8 OK)"; else fail "theme $t screen count" "$cnt, need 5-8"; bad_theme_counts=$((bad_theme_counts+1)); fi
  done
else
  fail "allocation.yaml" "missing"
fi
```

---

## §C — Per-theme render, reflect, implement (run once per theme; set `THEME=<slug>`)

```bash
#!/usr/bin/env bash
set -uo pipefail
P="projects/$PROJECT"
PROMPT_DIR="$P/design/asset-prompts/screens/$THEME"
THEME_DIR="$P/design/theme/theme-$THEME"
TREATISE="$P/design/theme/treatise-$THEME.md"
ALLOC="$P/design/asset-prompts/screens/allocation.yaml"
PROJ_STATE="docs/pipelines/project-uplift/state/$PROJECT.yaml"
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1 — $2"; }

# prompt count == this theme's allocation slice
n_prompts=$(find "$PROMPT_DIR" -maxdepth 1 -name '*.media.prompt' 2>/dev/null | wc -l)
expected=$(yq e "([.unique[] | select(.theme == \"$THEME\")] | length) + ([.overlap[] | select(.themes[] == \"$THEME\")] | length)" "$ALLOC" 2>/dev/null || echo -1)
[ "$n_prompts" = "$expected" ] && pass "prompt count matches allocation ($n_prompts)" || fail "prompt count" "have $n_prompts, allocation says $expected"

# prompt.text <=4000 chars; aspect_ratio == 16:9
bad_len=0; bad_aspect=0
for f in "$PROMPT_DIR"/*.media.prompt; do
  [ -f "$f" ] || continue
  len=$(yq e '.prompt.text' "$f" | wc -c)
  [ "$len" -le 4000 ] || bad_len=$((bad_len + 1))
  ar=$(yq e '.output.dimensions.aspect_ratio' "$f")
  [ "$ar" = "16:9" ] || bad_aspect=$((bad_aspect + 1))
done
[ "$bad_len" -eq 0 ] && pass "all prompt.text <=4000 chars" || fail "prompt.text length" "$bad_len over limit"
[ "$bad_aspect" -eq 0 ] && pass "all aspect_ratio == 16:9" || fail "aspect_ratio" "$bad_aspect not 16:9"

# PNG per prompt, unless media is off (deferred is the expected/passing state then)
media_status="${MEDIA:?set MEDIA=on/off — your stage-c-theme.md media spawn param, see verify.md header}"
if [ "$media_status" = "on" ]; then
  missing_png=0
  for f in "$PROMPT_DIR"/*.media.prompt; do
    [ -f "$f" ] || continue
    base="${f%.media.prompt}"
    [ -f "${base}.png" ] || missing_png=$((missing_png + 1))
  done
  [ "$missing_png" -eq 0 ] && pass "PNG exists per prompt" || fail "PNG per prompt" "$missing_png missing"
else
  pass "media off — renders deferred (expected)"
fi

# eval scores recorded, only if eval is actually on
eval_status="${EVAL:?set EVAL=on/off — your stage-c-theme.md eval spawn param, see verify.md header}"
if [ "$eval_status" = "on" ]; then
  avg=$(yq e ".stage_c.themes.${THEME}.avg_eval" "$PROJ_STATE" 2>/dev/null)
  { [ "$avg" != "null" ] && [ -n "$avg" ]; } && pass "eval scores recorded (avg=$avg)" || fail "eval scores" "not recorded despite eval:on"
else
  pass "eval off — score recording skipped (expected)"
fi

# theme dir has the required facets
for req in style-guide.meta.yaml style-guide.vars.yaml branding.yaml style-guide.color-modes.yaml; do
  [ -f "$THEME_DIR/$req" ] && pass "theme has $req" || fail "theme facet" "$req missing"
done

# base-theme correct
base=$(yq e '."base-theme" // .base_theme' "$THEME_DIR/style-guide.meta.yaml" 2>/dev/null)
[ "$base" = "theme-style-guide" ] && pass "base-theme == theme-style-guide" || fail "base-theme" "got '$base'"

# serve validation — 0 hard errors. Two acceptable log sources depending on which path ran
# (see your STYLEGUIDE_SERVE spawn param for which one applies):
#  - npx path:    /tmp/serve-$THEME.log, grep for "✗"
#  - legacy path: /tmp/generate-css-$THEME.log, exit code of `npm run generate-css` with
#                 STYLEGUIDE_CONFIG_ROOT=<repo>/$P/design/theme (see stage-c template §5)
serve_mode="${STYLEGUIDE_SERVE:?set STYLEGUIDE_SERVE=on/off — your stage-c-theme.md spawn param, see verify.md header}"
if [ "$serve_mode" = "on" ] && [ -f "/tmp/serve-$THEME.log" ]; then
  n_x=$(grep -c "✗" "/tmp/serve-$THEME.log" || true)
  [ "$n_x" -eq 0 ] && pass "npx serve log: 0 ✗" || fail "npx serve log" "$n_x ✗ found"
elif [ -f "/tmp/generate-css-$THEME.log" ]; then
  if grep -qiE "error|exception" "/tmp/generate-css-$THEME.log"; then
    fail "legacy generate-css log" "error/exception present"
  else
    pass "legacy generate-css: no errors (note: no ⚠-level nuance on this path)"
  fi
else
  fail "serve validation" "no log found at either expected path — did §5 validation run?"
fi

# conformance note exists
[ -f "$P/design/theme/conformance-$THEME.md" ] && pass "conformance note exists" || fail "conformance note" "missing"

# treatise flipped to status: full after the render/reflect pass
status=$(awk '/^---$/{c++; next} c==1' "$TREATISE" | yq e '.status' - 2>/dev/null)
[ "$status" = "full" ] && pass "treatise status: full" || fail "treatise status" "got '$status', need full"
```

---

## §D — Roadmap

```bash
#!/usr/bin/env bash
set -uo pipefail
P="projects/$PROJECT"
RM="$P/project-management/roadmap"
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1 — $2"; }

[ -f "$RM/00-overview.md" ] && pass "00-overview.md exists" || fail "00-overview.md" "missing"
[ -f "$RM/index.yaml" ] && pass "index.yaml exists" || fail "index.yaml" "missing"

n_milestones=$(find "$RM" -maxdepth 1 -regextype posix-extended -regex '.*/[0-9]+-M[0-9]+-.*\.md' 2>/dev/null | wc -l)
[ "$n_milestones" -ge 4 ] && pass "milestone docs >=4 ($n_milestones)" || fail "milestone docs" "$n_milestones found, need >=4"

bad=0
for f in "$RM"/*-M*-*.md; do
  [ -f "$f" ] || continue
  ok=1
  grep -q '^## Entry criteria' "$f" || ok=0
  grep -q '^## Exit criteria' "$f" || ok=0
  # at least one verifiable gate per doc: a backticked command, "exits 0", "file exists", or an N-stories count
  grep -qE '(exits? 0|file exists|`[^`]+`|[0-9]+ stor(y|ies))' "$f" || ok=0
  if [ "$ok" -eq 1 ]; then pass "$(basename "$f"): Entry/Exit + verifiable gate"; else fail "$(basename "$f")" "missing Entry/Exit criteria or a verifiable gate"; bad=$((bad+1)); fi
done

if [ -f "$RM/story-coverage.md" ]; then
  total_stories=$(find "$P/project-management/user-stories" -maxdepth 1 -name 'US-*.md' 2>/dev/null | wc -l)
  covered=$(grep -oE 'US-[0-9]+' "$RM/story-coverage.md" | sort -u | wc -l)
  pct=$(( total_stories > 0 ? covered * 100 / total_stories : 0 ))
  [ "$pct" -ge 80 ] && pass "story coverage >=80% ($pct%, $covered/$total_stories)" || fail "story coverage" "$pct% ($covered/$total_stories), need >=80%"
else
  fail "story-coverage.md" "missing"
fi
```
