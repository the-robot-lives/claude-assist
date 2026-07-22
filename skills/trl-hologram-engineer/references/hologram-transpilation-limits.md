# Hologram Transpilation Limits & Gotchas

What Elixir compiles to JavaScript, what does not, and the documented anti-patterns. This is the reference to consult whenever client code "won't compile" or "doesn't run in the browser."

## The rule

Only **client-reachable code** (reachable from action handlers and templates) is transpiled to JS. That code must live inside the **supported subset**. Server code (commands, `init/3` server work) runs on the BEAM and has no such restriction — so **the fix for most transpilation failures is to move the work into a `command`.**

## Overall coverage

Elixir stdlib transpilation is **~88% complete** (a tracked set of ~1242 functions; hundreds still in progress). Always check `/reference/client-runtime/elixir` for a specific function before relying on it client-side.

## Language features — fully supported (100%)

- **Data types:** Atom, Bitstring, Float, Function, Integer, List, Map, PID, Port, Reference, Tuple.
- **Control flow:** `case`, `cond`, `if`, `unless`, `with`, function clauses.
- **Functions:** anonymous functions, function capture (`&`), local & remote calls.
- **Operators:** arithmetic, boolean, comparison, list (`++`, `--`), string concat (`<>`), pipe (`|>`), match (`=`), pin (`^`), range, membership (`in`), module attribute (`@`), capture (`&`), type (`::`).
- **Advanced:** guards (all contexts), bitstring generators, enumerable generators, comprehension filters, comprehension `:into` / `:reduce`, behaviours, error handling, protocols.

## Partial / unsupported

| Feature | Status | Implication |
|---------|--------|-------------|
| Regex match `=~`, `Regex.*`, `~r/…/` | ~61% / effectively **avoid** | **No regex in client-reachable code.** Use `String` functions or validate in a command. |
| Computed-size bitstring matching | Todo (0%) | Not usable client-side |
| Dynamic-size bitstring matching | Todo (0%) | Not usable client-side |
| UTF match / UTF16 / UTF32 encoding | Todo (0%) | Not usable client-side |
| **Processes** (`spawn`, GenServer, message passing) | **Deferred** | **No OTP processes in the browser.** Do process work in commands. |

## Stdlib module coverage (client runtime, approx.)

| Module | Coverage |
|--------|----------|
| Kernel | ~90% (161 fns) |
| Kernel.SpecialForms | ~96% |
| Atom, Bitwise, Function, Tuple | 100% |
| List | ~98% (42 fns) |
| Map | ~96% (42 fns) |
| Integer | ~95% |
| Keyword | ~93% (50 fns) |
| String | ~92% (76 fns) |
| Float | ~91% |
| Enum | ~78% (112 fns) |

`Enum` at ~78% is the one most likely to surprise you — verify less-common functions (`Enum.chunk_*`, `Enum.zip_*`, etc.) before use.

## Documented gotchas & anti-patterns

1. **Authorization in an action.** Actions cross no trust boundary; a user can invoke them freely. Put authz in a **command** gated by middleware.
2. **Assuming middleware cascades.** It is flat — only the target module's middleware runs. Attach auth to **every** module exposing a command, not just the page. (See [hologram-forms-session-cookies.md](hologram-forms-session-cookies.md).)
3. **Client-side processes.** No `spawn`/GenServer in the browser. Model async client work with tasks derived from JS Promises (`Task.await/1`) or push it to a command.
4. **Regex on the client.** Not supported. Replace with `String.*` or validate server-side.
5. **JS interop during SSR.** Interop functions are **no-ops during SSR** and only work in action-reachable code. Guard interop so it never runs at render time.
6. **Not unit-testing interop.** Interop is not unit-testable — use feature/browser tests.
7. **Missing / colliding `cid`.** Stateful components need a unique `cid`; without it action/command targeting breaks.
8. **Non-atom/string session keys.** Session keys must be atoms or strings; others raise.
9. **Trusting Realtime delivery.** Fire-and-forget, at-most-once, unordered, no replay — never a source of truth.
10. **Relying on an un-transpiled stdlib function.** ~88% coverage means some functions are missing; check `/reference/client-runtime/elixir`.
11. **Pre-1.0 churn.** v0.10.0 — APIs may change between minor versions; pin the version and re-verify on upgrade.

## Diagnostic flow

```
Failure: client code errors / won't compile / doesn't run in browser
  1. Is the code client-reachable (from an action/template)? If not, it's a normal Elixir bug.
  2. Does it use a process? → move to a command (or drop it client-side).
  3. Does it use regex? → String functions, or validate in a command.
  4. Does it call a stdlib fn not in /reference/client-runtime/elixir? → substitute or move server-side.
  5. Is it JS interop running during SSR / outside an action? → guard it to action-reachable code.
  6. Bitstring computed/dynamic/UTF match? → refactor to supported matching or move server-side.
```
