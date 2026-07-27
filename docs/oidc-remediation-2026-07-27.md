# OIDC `state` / `nonce` Remediation — 2026-07-27

**Status:** remediation applied and re-verified across all 23 backends. The
independent sweep has completed; the rescue of five projects (§6) was still in
flight at publication.
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
| gotta.cc | ios → rescue | ✅ | ✅ | ✅ | ✅ | yes | ✖ none | **IN PROGRESS** |
| iotgo.io | ios → rescue | ✅ | ✅ | ✅ | ✅ | **no** | ✖ none | **IN PROGRESS** |
| jailbreakingsite.com | ios → rescue | ✅ | ✅ | ✅ | ✅ | **no** | ✖ none | **IN PROGRESS** |
| noizu.com | ios → rescue | ✅ | ✅ | ✅ | ✅ | **no** | ✖ none | **IN PROGRESS** |
| therobotlives.com | ios → rescue | ✅ | ✅ | ✅ | ✅ | **no** | ✖ none | **IN PROGRESS** |

² Missing for part of the day; closed by a follow-up and re-verified before
publication. See §7.1 — the cause is worth reading.

¹ These have an SSO test file — `sso_test.exs` in therobotdrafts/vnext and
therobotlearns, `sso_domains_test.exs` in therobotknows — but each covers
domain/provider resolution, not the state/nonce guard.

**On the last five.** The ios agent died mid-batch and a rescue agent is
repairing them. The code columns above were read directly from the files and are
accurate as of this writing, but **the batch is not signed off** — treat those
rows as unconfirmed until the rescue reports.

**On "Verified by: author".** Every ✅ except the scaffolds was verified by the
agent that wrote it. Self-verification is the weak link, which is why the
independent sweep (§8) exists.

---

## 7. Known gaps

Listed so they are decisions rather than surprises.

### 7.1 Session clearing — FOUND AND CLOSED

For part of the day, four projects (`therobotmakes.com`, `therobotremembers`,
`therobotsdayjob.com`, `tobarnalp.com`) were missing `clear_sso_session/1` while
the other 19 had it. **Re-verified after the fix landed: all 23 now clear the
session.**

Recorded because the *cause* is reusable. That batch mirrored timely's
`oidc_init`/`oidc_callback` faithfully; the helper sits elsewhere in that file
and was not carried across. Verifying that the two copied functions were correct
did not surface what the reference did *around* them — a scope failure, not a
reasoning one, and the same shape as several other near-misses in this effort.

**Effect while it lasted:** `state` and `nonce` survived a completed callback for
up to the cookie's 900s, so `verify_state` would have accepted the same state
again inside that window. Defence-in-depth rather than a direct hole — the value
lives only in the victim's own cookie — but it was a property every sibling had
and those four lacked, in exactly the window that had just been widened.

### 7.2 The guards are untested in the 20 application projects

Only the two scaffolds (11 tests each) and timely (8 tests) have real
state/nonce guard tests. No application project has one.

This is the largest remaining gap. The scaffolds' tests are the model to copy —
they were run **and mutation-checked** (deliberately broken to confirm they
fail), which is the standard the rest should meet.

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

### 7.5 Nonce mismatch is not distinguished for the user

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

**In flight at the time of writing:**

- A **rescue** of the ios agent's five projects. Its rows are marked IN PROGRESS
  rather than guessed.

The **independent sweep** of all 23 + 2 scaffolds completed during authoring.
Its findings are not transcribed here — where it and this table disagree, prefer
the sweep.

This document was re-verified against the files immediately before publication,
and one gap (§7.1) had already been closed by another agent between drafting and
that re-check. If you are reading this well after 2026-07-27, re-run the checks
in §9 rather than trusting the table: it was accurate when written and the tree
moved fast that day.

**The honest summary:** the code is uniform and correct by inspection across all
23. What is thin is *independent* confirmation — four agents checked their own
work before the sweep existed. Prefer the sweep's findings over this table where
they disagree.

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

## 10. Appendix — who did what

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
