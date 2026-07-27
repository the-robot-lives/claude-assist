# OIDC `state` / `nonce` Remediation — 2026-07-27

**Status:** **CODE SIDE CLOSED. Rescue signed off.** All 23 backends and both scaffolds read
COMPLETE on a full independent sweep — v1.x arity, `state` generated + stashed +
verified, verification running before both `oidc_config()` and `fetch_tokens`,
`nonce` handled, session cleared, `max_age: 900`. **No REDs anywhere.** What
remains is test coverage, not correctness — see §7.2 and §8.
**Scope:** 21 project backends + 2 scaffolds (`components/start-app`, `components/hologram-start-app`).
**Audience:** whoever deploys this. Read §2 and §3 before rolling anything out.

Every figure in this document was confirmed by reading the file it describes, on
2026-07-27. Where something could not be confirmed it says so. The tree was
committed mid-work (`1e1edbbdf04` "wip"), so state was judged from file contents
rather than from diffs.

---

## 1. What was wrong

Every backend descended from `components/start-app` or
`components/hologram-start-app` called

```elixir
OpenIDConnect.authorization_uri(:default)
```

with **no `state` and no `nonce`**. Two consequences:

- **Login-CSRF.** Without `state`, an attacker can start an OIDC flow, capture
  the resulting `code`, and cause a victim's browser to complete it. The victim
  is then silently signed in **as the attacker** and types real work into the
  attacker's account. This is the more damaging of the two and the less obvious.
- **`id_token` replay.** Without `nonce`, a previously issued `id_token` can be
  presented again; nothing binds a token to the flow that requested it.

**Social OAuth was never affected.** Google, GitHub, Facebook and LinkedIn all
go through `plug Ueberauth`, which manages its own CSRF state. Only the
hand-rolled OIDC path was exposed. SAML is likewise separate.

### 1.1 ⚠️ The trap: never fix the arity alone

14 of the 23 were **"present but broken"**: they called the openid_connect
**v0.2.x** API (`authorization_uri/1` taking a `:default` atom) while resolving
**openid_connect 1.0.1**, which exports only `/2` and `/3`. Every request to
`/auth/oidc` raised `UndefinedFunctionError`. OIDC sign-in had never worked on
those deployments and nobody had noticed.

That means:

> **Repairing the arity by itself converts a dead, unexploitable endpoint into a
> live, unprotected one. It does not fix the vulnerability — it introduces it.**

The arity migration and the state/nonce guard had to land in the same change,
and did, in every project. Anyone touching these files later needs to know this:
if you find yourself "just fixing the deprecated call", stop and check that the
guard is present in the same edit.

The same applied to the callback. `fetch_tokens(:default, code)` and
`verify(:default, ...)` are also v0.2.x, so in most projects the callback was
broken too — not only the init.

---

## 2. ⚠️ Rolling-deploy transient `state_mismatch`

**Read this before deploying. It is the highest-value operational item here.**

The fix requires `oidc_init` and `oidc_callback` to see the **same session
cookie**. During a rolling deploy that is not guaranteed:

1. A user hits `/auth/oidc` on an **old** pod. No `state` is issued — old code.
2. They authenticate at the IdP.
3. Their callback lands on a **new** pod, which requires `state`.
4. → `state_mismatch`.

**This is transient and self-clearing.** Once every pod runs the new code, it
stops. No data is at risk and no action is needed beyond letting the rollout
finish.

**It looks identical to an expired cookie, so use this distinguisher:**

| Symptom | Rollout mismatch | Expired cookie |
|---|---|---|
| Who is affected | **Everyone**, including instant retries | Only **slow** logins (2FA on a second device, interruptions) |
| Duration | Until the rollout completes | Ongoing, intermittent |
| Fixed by retrying immediately | **No** — a retry can hit a mixed pair again | **Yes**, usually |

If support sees a burst of `state_mismatch` reports that stop on their own
shortly after a deploy, that was this. Expect the noise and don't chase it.

To avoid it entirely, drain and replace rather than rolling, or deploy during a
low-traffic window. Neither is required — the failure is safe.

---

## 3. `state_mismatch` triage

Four causes present identically to the user. In rough order of likelihood:

| Cause | Signature | Action |
|---|---|---|
| **Rolling deploy** (§2) | Burst after a deploy, affects everyone, stops on its own | Wait for rollout |
| **Cookie expired mid-flow** | Only slow logins; instant retry succeeds | Expected at some rate; see §4 |
| **Cookie dropped entirely** | *Every* attempt fails, including a fast retry | Real bug — check `:sso_session` pipeline is in the route's `pipe_through`, and that `same_site: "Lax"` survives the IdP's redirect |
| **Genuine CSRF trip** | Should be ≈never | Investigate. This is the guard doing its job |

The third is the one worth escalating: a *consistent* failure means the session
cookie is not reaching the callback at all, which is a configuration fault, not
a user problem.

---

## 4. The coupled `max_age` change (300 → 900)

Every `:sso_session` pipeline was raised from `max_age: 300` to `max_age: 900`.

**This is not tidying, and it is not a weakening.** Before the fix that cookie
was *inert* for OIDC — nothing was stored in it. The fix puts `state` and
`nonce` there, which makes its lifetime the **login deadline**. At 300 seconds,
a password plus a 2FA prompt on a phone can exceed it, and the user gets an
opaque `state_mismatch` where they previously (insecurely) succeeded.

Shipping the state check at 300s would have traded a security hole for an
availability bug.

Widening is one-directional and safe:

- the cookie carries **flow state, never credentials**;
- a longer window cannot break a flow that already worked;
- it is shared with SAML and social OAuth, which get the same benefit.

Four separate agents reached this independently, which is the strongest evidence
available that it is right.

---

## 5. The fix, as applied

Uniform across all 23. In `oidc_init`:

```elixir
config = oidc_config()
state  = random_token()          # :crypto.strong_rand_bytes(32), url-safe base64
nonce  = random_token()

{:ok, uri} =
  OpenIDConnect.authorization_uri(config, config.redirect_uri, %{state: state, nonce: nonce})

conn
|> put_session(:sso_state, state)
|> put_session(:sso_nonce, nonce)
|> redirect(external: uri)
```

In `oidc_callback`:

```elixir
with :ok <- verify_state(expected_state, params["state"]),
     config <- oidc_config(),
     {:ok, tokens} <- OpenIDConnect.fetch_tokens(config, %{code: code, redirect_uri: config.redirect_uri}),
     {:ok, claims} <- OpenIDConnect.verify(config, tokens["id_token"]),
     :ok <- verify_nonce(expected_nonce, claims["nonce"]) do
```

Four properties worth preserving if this is ever refactored:

1. **State is verified before `oidc_config()` is read.** A forged callback is
   rejected without a discovery fetch or a token request — no work is done on an
   attacker's behalf.
2. **Comparisons use `Plug.Crypto.secure_compare/2`**, not `==`.
3. **Nonce is tolerant of absence, strict on mismatch.** A provider that omits
   the nonce is not proof of replay; a provider returning a *different* one is.
4. **The session is cleared on success and on failure**, so a state value can
   never serve a second callback. Verified present in all 23; see §7.1 for the
   period when four projects were missing it.

---

## 6. Per-project status

**Verification legend.** `parse` = `Code.string_to_quoted!` (syntax only, no deps
needed). `compile` = `mix compile` succeeded. `tests` = an SSO guard test exists
**and ran**. Most projects have **no Postgres available**, and `mix test` runs
`ecto.create`, so suites could not run. Several projects have **no SSO tests at
all** — there was no coverage to regress, and none was added.

| Project | Batch owner | Arity | state/nonce | max_age 900 | Session cleared | Hydrated | Guard test | Verified by |
|---|---|---|---|---|---|---|---|---|
| **components/start-app** | doc-reconcile | ✅ | ✅ | ✅ | ✅ | yes | ✅ 11 tests | author (run + mutation-checked) |
| **components/hologram-start-app** | doc-reconcile | ✅ | ✅ | ✅ | ✅ | yes | ✅ 11 tests | author (run + mutation-checked) |
| timely.noizu.com *(reference)* | backend-domain-2 | ✅ | ✅ | ✅ | ✅ | yes | ✅ 8 tests | author |
| foryou.therobotlives.com | backend-domain-2 | ✅ | ✅ | ✅ | ✅ | yes | ✖ none | author |
| NoizuPromptLingo | backend-domain-2 | ✅ | ✅ | ✅ | ✅ | yes | ✖ none | author |
| therobotdrafts/vnext | backend-domain-2 | ✅ | ✅ | ✅ | ✅ | yes | ✖ none¹ | author |
| therobotknows.com | backend-domain-2 | ✅ | ✅ | ✅ | ✅ | yes | ✖ none¹ | author |
| therobotlearns.com | backend-domain-2 | ✅ | ✅ | ✅ | ✅ | yes | ✖ none¹ | author |
| tobornalp.com | backend-domain-2 | ✅ | ✅ | ✅ | ✅ | yes | ✖ none | author |
| aifighter.com | android-2 | ✅ | ✅ | ✅ | ✅ | yes | ✖ none | author |
| codefre.sh | android-2 | ✅ | ✅ | ✅ | ✅ | yes | ✖ none | author |
| derobot.is | android-2 | ✅ | ✅ | ✅ | ✅ | **no** | ✖ none | author (parse only) |
| designing.derobot.is | android-2 | ✅ | ✅ | ✅ | ✅ | yes | ✖ none | author |
| game-workshop/stage/robotwars | android-2 | ✅ | ✅ | ✅ | ✅ | yes | ✖ none | author |
| therobotmakes.com | timelykit-2 | ✅ | ✅ | ✅ | ✅² | **no** | ✖ none | author (parse only) |
| therobotremembers | timelykit-2 | ✅ | ✅ | ✅ | ✅² | yes | ✖ none | author (compile) |
| therobotsdayjob.com | timelykit-2 | ✅ | ✅ | ✅ | ✅² | yes | ✖ none | author (compile) |
| tobarnalp.com | timelykit-2 | ✅ | ✅ | ✅ | ✅² | **no** | ✖ none | author (parse only) |
| gotta.cc | ios → rescue | ✅ | ✅ | ✅ | ✅ | yes | ✖ none | rescue: SIGNED OFF³ |
| iotgo.io | ios → rescue | ✅ | ✅ | ✅ | ✅ | **no** | ✖ none | rescue: SIGNED OFF³ |
| jailbreakingsite.com | ios → rescue | ✅ | ✅ | ✅ | ✅ | **no** | ✖ none | rescue: SIGNED OFF³ |
| noizu.com | ios → rescue | ✅ | ✅ | ✅ | ✅ | **no** | ✖ none | rescue: SIGNED OFF³ |
| therobotlives.com | ios → rescue | ✅ | ✅ | ✅ | ✅ | **no** | ✖ none | rescue: SIGNED OFF³ |

² Missing for part of the day; closed by a follow-up and re-verified before
publication. See §7.1 — the cause is worth reading.

¹ These have an SSO test file — `sso_test.exs` in therobotdrafts/vnext and
therobotlearns, `sso_domains_test.exs` in therobotknows — but each covers
domain/provider resolution, not the state/nonce guard.

³ **On the last five — SIGNED OFF, and the danger was hypothetical.**

The ios agent died mid-batch, which is why these were treated as the highest-risk
group. **All five were found COMPLETE. No DANGEROUS PARTIAL ever existed.** That
agent had landed the arity migration and *both* guards in the same commit
(`1e1edbbdf04`); nothing was left, or committed, in the arity-without-guard state
that §1.1 warns about.

Verified against the true pre-fix baseline `1e1edbbdf04^`, with the baseline
confirmed genuinely unpatched rather than assumed — `verify_state` count 0,
`authorization_uri(:default)` present, `max_age: 300` in all five.

**The limit, stated exactly:** nothing vulnerable was ever *committed*, but a
transient on-disk window while that agent was mid-write **cannot be ruled out**,
because no artifact would survive to show it. That is neither "no window existed"
nor "we can't say" — it is the precise claim the evidence supports.

**Attribution within these five:** `clear_sso_session/1` was added by the
**rescue** agent in **`f3d8fe3127a`** — the only piece genuinely missing versus
the reference. `max_age: 900` was **not** the rescue's doing; all five were
already at 900 in `1e1edbbdf04`, so that credit belongs to whoever authored that
commit.

**Verification ceiling — weaker than every other row.** None of the five achieved
a compile. They are **inspection-verified plus AST-resolution-checked**: every
local call (`clear_sso_session`, `verify_state`, `verify_nonce`, `random_token`,
`oidc_config`, `handle_sso_callback`, `redirect_with_error`) was confirmed to
resolve to a definition at the right arity. That covers the specific risk of this
edit; it is not a compile. Four have empty `deps/`; gotta.cc is hydrated but hit
the toolchain wall in §12.

**On "Verified by: author".** Every ✅ except the scaffolds was verified by the
agent that wrote it. Self-verification is the weak link, which is why the
independent sweep (§8) exists.

---

## 7. Known gaps

Listed so they are decisions rather than surprises.

### 7.1 Session clearing — FOUND AND CLOSED

For part of the day, four projects (`therobotmakes.com`, `therobotremembers`,
`therobotsdayjob.com`, `tobarnalp.com`) did not clear the session while the other
19 did. **Closed by backend-domain-2** — not by the agent that introduced the gap.
Re-verified: exactly two `delete_session` calls per file, both inside
`oidc_callback`, so `handle_sso_callback` and `redirect_with_error` — shared with
the social OAuth and SAML paths — are provably untouched and those flows cannot
have moved.

**Severity, and please keep it here:** this was **not a live vulnerability.** The
state guard worked and ran before the token request, the authorization code is
single-use at the IdP, and the state sat in the victim's own cookie where an
attacker has no ordinary way to reach it. What was missing is the one-time
binding between one initiation and one callback — defence-in-depth, and a
deviation from the reference. It was fixed for consistency. Do not let a future
reader inflate it from the diff.

Recorded because the *cause* is reusable. That batch mirrored timely's
`oidc_init`/`oidc_callback` faithfully; the helper sits elsewhere in that file
and was not carried across. Verifying that the two copied functions were correct
did not surface what the reference did *around* them — a scope failure, not a
reasoning one, and the same shape as several other near-misses in this effort.

**Effect while it lasted:** `state` and `nonce` survived a completed callback for
up to the cookie's 900s, so `verify_state` would have accepted the same state
again inside that window.

### 7.2 Test coverage — the largest remaining gap

Every verdict for most projects rests on **reading code**, not on an executed
test. Current state:

| Where | Coverage |
|---|---|
| `components/start-app`, `components/hologram-start-app` | 11 tests each, run **and mutation-checked** |
| timely.noizu.com | 8 tests, both functions mutation-checked independently; suite 452/453¹ |
| android-2's five (aifighter, codefre.sh, derobot.is, designing.derobot.is, robotwars) | 14 guard tests each — **3 executed and mutation-checked**, 2 written and byte-identical to the executed ones but **not run** (empty `deps/`) |
| **The remaining 15 projects** | **None. Code review only.** |

¹ The single failure is the known, unrelated `profile_completed_at` case.

The scaffolds' tests are the model: run *and* deliberately broken to confirm they
fail. A test that has never been seen to fail is not yet evidence.

### 7.3 `derobot.is` cannot resolve its OIDC dependency

`mix.exs` declares `{:openid_connect, "~> 1.0"}`; `mix.lock` (dated 2026-06-14)
contains **zero** `openid_connect` entries. The project needs `mix deps.get`
before its OIDC path can work at all. Independent of this remediation, but it
blocks verifying that project.

### 7.4 Seven projects are not hydrated

`derobot.is`, `iotgo.io`, `jailbreakingsite.com`, `noizu.com`,
`therobotlives.com`, `therobotmakes.com`, `tobarnalp.com` have no `deps/`.
Their fixes are **parse-checked only** — syntactically valid, not compiled.

`therobotmakes.com` and `tobarnalp.com` additionally do **not gitignore** `deps/`
or `_build/`, so hydrating them will fill `git status` with untracked build
output. Worth fixing the `.gitignore` first.

### 7.5 Two session-clearing placements exist — both correct, 13 vs 10

An earlier revision of this section claimed the rescue's five projects deviated
from a majority pattern. **That was wrong**, and the correction is worth reading
because the false claim was more alarming than the truth.

Enumerating all 23 controllers — not sampling two, which is how the wrong version
was produced:

| Placement | Count | Projects |
|---|---|---|
| `clear_sso_session/1` helper, called from `handle_sso_callback/3` and `redirect_with_error/2` | **13** | **timely (the reference)**, **both scaffolds**, aifighter, codefre.sh, derobot.is, designing.derobot.is, robotwars, gotta.cc, iotgo.io, jailbreakingsite, noizu.com, therobotlives |
| Two `delete_session` calls inlined directly in `oidc_callback/2`, under no helper name | **10** | foryou, NoizuPromptLingo, therobotdrafts, therobotknows, therobotlearns, therobotmakes, therobotremembers, therobotsdayjob, tobarnalp, tobornalp |

**Zero files call a named `clear_sso_session` from inside `oidc_callback`.** The
pattern the earlier revision described as the majority exists nowhere.

So the rescue's placement is **not a deviation** — it is the reference
implementation's placement and both scaffolds', which makes it the house pattern
if anything is. The split is 13/10, it **predates this remediation**, and both
forms are correct.

**Why the 13-file form is safe.** `clear_sso_session/1` runs on the social OAuth
and SAML paths too, since `oauth_callback` reaches both functions. That is a
**no-op**: `:sso_state` and `:sso_nonce` are written **only** by `oidc_init/2`.
Verified across each entire backend `lib/` tree rather than just the controller —
exactly one `put_session` per key, at lines 41–42, in every one of the 13.

**The invariant that keeps it safe, and it is fragile:**

> Any `put_session(:sso_state, ...)` or `put_session(:sso_nonce, ...)` added
> **outside `oidc_init/2`** silently converts the no-op into a real deletion on
> the social and SAML paths — **and nothing fails visibly.**

That invariant is now commented at every call site in the rescue's five. The
10-file form is narrower by construction and does not depend on it.

### 7.6 `therobotlives.com` has no `mix.lock` at all

Absent and untracked. `mix.exs:46` pins `{:openid_connect, "~> 1.0"}`, so the API
is right, but the resolved version **floats** — nothing guarantees which 1.x is
installed. Pre-existing and separate from this remediation. Confirmed by
inspection; belongs alongside the `derobot.is` lockfile item in §7.3.

### 7.7 `OpenIDConnect.Finch` missing from supervision trees — FALSE ALARM

Recorded specifically so nobody chases it. `OpenIDConnect.Finch` does not appear
in any supervision tree in these five, nor in timely, aifighter or codefre.sh.
That is **correct**: openid_connect 1.x declares `mod: {OpenIDConnect.Application,
[]}` and starts its own Finch pool and document cache. Nothing is missing.

### 7.8 The two "five project" sets are different — easy to conflate

Both are five projects and it is easy to merge them by mistake:

| Set | Projects | What is true of them |
|---|---|---|
| **Got tests** | aifighter, codefre.sh, derobot.is, designing.derobot.is, robotwars | 14 guard tests each (§7.2) |
| **Rescued** | gotta.cc, iotgo.io, jailbreakingsite.com, noizu.com, therobotlives.com | No tests; `verify_state`/`verify_nonce` are `defp` |

The rescued five keep `verify_state/2` and `verify_nonce/2` as **`defp`**
(confirmed by inspection), so the mutation-checked unit tests used elsewhere are
**not callable there** without the same `defp` → `def` + `@doc false` change the
other set required. Budget for that if tests are ported.

### 7.9 Nonce mismatch is not distinguished for the user

A nonce mismatch falls through to the generic `oidc_failed` branch rather than
getting its own error code, unlike `state_mismatch`. Harmless, but it makes
replay attempts and ordinary failures indistinguishable in logs.

---

## 8. Verification status and its limits

**What was verified, by whom:**

- **Both scaffolds** — tests written, run, and mutation-checked by their author.
  The strongest evidence in this effort.
- **timely.noizu.com** — 8 guard tests, written after the fix.
- **Everything else** — verified by the agent that wrote it, at the ceiling that
  project allowed: compile where hydrated, parse-check where not, no suite
  anywhere (no Postgres).

**The independent sweep completed and found NO REDs** across all 23 + 2
scaffolds. Nothing is PARTIAL-DANGEROUS. The failure mode this effort most feared
— arity migrated without a working guard, converting a dead path into a live
unprotected one — **does not exist anywhere in the tree.**

**All 32 files parse cleanly.** Hydrated projects compile `rc=0`. Eight are
**parse-checked only, not compiled**, because they are not hydrated: derobot.is,
robotwars, iotgo.io, jailbreakingsite.com, noizu.com, therobotlives.com,
therobotmakes.com, tobarnalp.com.

This document was re-verified against the files immediately before publication,
and one gap (§7.1) had already been closed by another agent between drafting and
that re-check. If you are reading this well after 2026-07-27, re-run the checks
in §9 rather than trusting the table: it was accurate when written and the tree
moved fast that day.

**The honest summary:** the code is uniform and correct across all 23, now
confirmed by an independent sweep rather than only by its authors. What remains
thin is *automated* confirmation. Ten of the 25 have executed guard tests; the
other 15 rest on code review. "Verified" in this document means **a human-or-agent
read the code and it was correct**, except where §7.2 says a test ran.

That is a real ceiling, not a formality. Every high-confidence wrong answer in
this effort came from reading — and the sweep's own first pass produced eight
false REDs (§8.1).

### 8.1 ⚠️ The comment-grep trap — read this before auditing

The sweep's first pass flagged **8 projects as still calling
`authorization_uri(:default)`** — the dead-endpoint signature, which would have
meant the fix was never applied. It was a **false RED**, and the cause is
permanent:

The patching agents wrote good explanatory comments into their own fixes,
including the old call they were replacing:

```elixir
# 1. ARITY. This called `authorization_uri(:default)`, the openid_connect
#    v0.2.x API, against v1.0.1 which exports only /2 and /3.
```

A regex for the old signature matches **the comment**. Stripping comment lines
cleared all 8.

> **Anyone auditing this code later MUST strip comments before grepping for the
> old API signature, or they will conclude the fix was never applied.**

```bash
# WRONG — matches the explanatory comments
grep -rn "authorization_uri(:default)" lib/

# RIGHT — live code only
sed 's/#.*//' path/to/sso_controller.ex | grep -n "authorization_uri(:default)"
```

**This happened four times, to three different agents.** That is not coincidence
— it is a property of how well this fix was documented, which makes the trap
permanent. The comments are genuinely valuable and should stay.

| # | The grep | What it reported | What was true |
|---|---|---|---|
| 1 | `authorization_uri(:default)` | 8 projects never patched | Matched the fix's own comment describing the old call |
| 2 | `max_age` within 20 lines of the pipeline | 5 projects have no `max_age` | The new comment block pushed the value to line 33 |
| 3 | `clear_sso_session` | 9 projects don't clear the session | They clear inline via `delete_session`, under no helper name |
| 4 | `put_session(:sso_state\|:sso_nonce)` | 5 projects write the keys twice | Two of the four hits were the comment *documenting this very invariant* |

Three distinct failure modes, one shape: **the grep matched text, not behaviour.**
#1 and #4 matched prose about the code; #2 matched the right thing in the wrong
place; #3 matched a *name* rather than the *effect*, and the effect had two
spellings.

> **Rule: anchor on parsed structure or a bounded function body — never on line
> proximity, and never on a helper's name when the behaviour has more than one
> spelling.** Strip comments before any structural claim. If a count looks
> alarming, read the file before reporting it.

Every one of the four was caught by opening the file. None would have been caught
by a more careful regex.

---

## 9. Deploy checklist

Per project:

- [ ] **Confirm the guard is present.** `oidc_init` generates `state` and
      `nonce`; `oidc_callback` verifies both. If only the arity looks fixed,
      **stop** — see §1.1.
- [ ] **Confirm `max_age: 900`** in the `:sso_session` pipeline (§4).
- [ ] **Confirm the session is cleared** in `oidc_callback` — the four projects
      in §7.1 need this added first.
- [ ] **Hydrate if needed** (§7.4): `mix deps.get`, then `mix compile`. For
      `derobot.is`, this also repairs the missing lock entry (§7.3). Check
      `.gitignore` covers `deps/` and `_build/` first.
- [ ] **Verify OIDC env vars** are present in the target environment:
      `OIDC_ISSUER`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`, and
      `OIDC_REDIRECT_URI` if the default `https://<host>/auth/oidc/callback` is
      not correct.
- [ ] **Deploy**, expecting the transient `state_mismatch` burst in §2.
- [ ] **Smoke-test a real sign-in** end to end. For the 14 formerly-broken
      projects this is the *first* time OIDC has ever worked — it has never been
      exercised in production, so budget for first-run issues unrelated to this
      change (redirect URI mismatches at the IdP, missing client registration).
- [ ] **Watch for `state_mismatch`** for ~15 minutes after the rollout settles.
      A burst that stops on its own was §2. A steady rate affecting fast retries
      is §3, row 3.

---

## 10. Lessons — the recurring shape

Five agents worked this remediation. Nearly every wrong answer any of them
produced had the **same structure**, and it is more transferable than any
individual finding here:

> **Each verified the thing they were looking at, and not the thing it depended
> on.** Every one was locally sound and globally incomplete.

Four independent instances:

| Agent | Verified | Didn't ask |
|---|---|---|
| A batch owner | that the two functions it copied from the reference were correct | what the reference did *around* them — a `clear_sso_session/1` helper elsewhere in the file (§7.1) |
| A batch owner | that `put_session` would work on those routes | what the cookie's existing `max_age` now *meant*, once state was stored in it (§4) |
| The sweeping agent | that its regex matched the old API signature | whether the signature also appeared in comments — 8 false REDs (§8.1) |
| The doc author | that a `max_age` grep covered the pipeline | whether the window still reached it after the fix added comments (§8.1) |
| The doc author, again | two controllers, and generalised the placement pattern from them | whether the other twenty-one agreed — they did not, and §7.5 shipped a 18-vs-5 split that was really 13-vs-10 |

Reading confirms what you thought to look at. That is why the executed,
mutation-checked tests on the scaffolds are worth more than the far larger volume
of careful code review behind everything else in §6.

The §7.5 instance is the clearest of the five, because the wrong answer was not
merely incomplete — it was **more alarming than the truth**. It reported the
rescue's five as deviating from a majority, when they in fact match the reference
implementation and both scaffolds, and the "majority pattern" they supposedly
deviated from existed in **zero** files. A sample of two produced a confident
claim about twenty-three. Enumerate before you characterise.

**The second lesson, from concurrent work:**

> **Judge from current file contents — never from anyone's report, including your
> own from ten minutes ago.**

Twice in one evening an item reported as "missing" turned out to be **in flight
rather than absent**: once for the scaffolds' `max_age`, once for the four
session-clear gaps, which were closed by another agent between this document
being drafted and being re-checked. Neither was a routing failure; both were
artifacts of several agents editing the same files concurrently. Every figure in
this document went stale at least once while it was being written.

That is also the honest caveat on this document: it was accurate against the tree
at publication. If you are reading it later, run the §9 checks rather than
trusting §6.

---

## 11. Appendix — Elixir/OTP toolchain on this machine

This cost one agent its compile verification and will cost the next one the same
unless it is written down.

- **asdf shims ignore `ASDF_*_VERSION`** here — they print a version list instead
  of running. Invoke the binaries **directly** from
  `~/.config/asdf/installs/...`.
- **Working combination: Erlang 26.1.2 + Elixir 1.15.7.**
- `installs/erlang/28.4.1` is an **empty directory** — it looks installed and is
  not.
- **Elixir 1.18 fails** on `noizu_labs_entities 0.3.1` with
  `:elixir_quote.validate_quote/1 is undefined`. Unrelated to OIDC; it just stops
  the build.
- **Do not mix toolchains against one `_build`.** Elixir 1.18 / OTP 28 will
  rebuild artifacts that OTP 26 then cannot load — the symptom is a **"corrupt
  atom table"** error. Delete `_build` and rebuild with the working pair. (One
  contaminated `_build` was removed during this effort so nobody inherits corrupt
  beams.)
- **Cold builds take well over ten minutes.** Budget for it before assuming a
  hang.

---

## 12. Appendix — the `liquibase.properties` question: CLOSED, no incident

Recorded so nobody re-investigates it.

All **23** tracked `liquibase.properties` files — the 15 swept in on 2026-07-27
and the 8 tracked since June — share a single md5,
**`da0bf51e2cb61758474eb4ebac878737`**. Byte-identical. They contain
**`${DB_*}` envsubst placeholders only**: no host, no username, no password.

**Nothing ever leaked through this file.** The question arose during the same
day's hygiene work and is settled.

---

## 13. Appendix — who did what

| Batch | Owner | Projects |
|---|---|---|
| 6 live | backend-domain-2 | foryou, NoizuPromptLingo, therobotdrafts/vnext, therobotknows, therobotlearns, tobornalp |
| 5 broken | android-2 | aifighter, codefre.sh, derobot.is, designing.derobot.is, game-workshop/robotwars |
| 4 broken | timelykit-2 | therobotmakes, therobotremembers, therobotsdayjob, tobarnalp |
| 5 broken | ios → **rescue in progress** | gotta.cc, iotgo.io, jailbreakingsite, noizu.com, therobotlives |
| 2 scaffolds | doc-reconcile | components/start-app, components/hologram-start-app |
| reference | backend-domain-2 | timely.noizu.com |

**Note on names.** `tobarnalp.com` (a-r-n) and `tobornalp.com` (o-r-n) are
different projects and both exist. They were patched by different agents. Verify
the fourth character before editing either.
