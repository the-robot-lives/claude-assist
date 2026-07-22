//! `REPO_LOCK_SESSION` resolution.
//!
//! Mutating commands (`acquire`, `release`, `heartbeat`, `break`, `exec`, and the
//! pre-commit hook's lock-reject decision) require a session identity and **fail closed**
//! when it is unset — a silent auto-generated fallback would mask exactly the
//! harness-wiring bug it should surface. Read-only commands (`list`, `status`, `check`,
//! `doctor`) tolerate an unset session and treat the caller as anonymous, so every
//! existing lock reads as foreign.

use anyhow::{bail, Context, Result};
use uuid::Uuid;

/// Env var carrying the session UUID (intended to be the tobor session UUID).
pub const SESSION_ENV: &str = "REPO_LOCK_SESSION";
/// Env var set on an `exec` child so nested `exec`s / the hook recognize a self-held mutex.
pub const IN_EXEC_ENV: &str = "REPO_LOCK_IN_EXEC";

const FAIL_CLOSED: &str = "\
REPO_LOCK_SESSION is not set — refusing to run a registry-mutating command.

This is fail-closed by design: a mutating repo-lock command needs a session identity
so other sessions' locks can be told apart from your own. There is no auto-generated
fallback, because that would silently hide a missing harness wiring step.

Fix: have your harness export the session UUID before invoking repo-lock, e.g. in a
session-start hook:

    export REPO_LOCK_SESSION=\"$TOBOR_SESSION_UUID\"   # a v4 UUID

NEVER source REPO_LOCK_SESSION from a committed/shared .envrc: every session would then
share one identity, every lock would look self-owned to every caller, and repo-lock
would silently no-op.";

/// Fail-closed session identity for mutating commands.
// ⟦𓇆𓐣𓌾𓁈⟧ require :: Fail-closed session identity for mutating commands.
pub fn require() -> Result<Uuid> {
    match std::env::var(SESSION_ENV) {
        Ok(raw) if !raw.trim().is_empty() => parse(raw.trim()),
        _ => bail!("{FAIL_CLOSED}"),
    }
}

/// Anonymous-tolerant session for read-only commands. `None` == anonymous caller.
/// A set-but-malformed value is still an error — it signals a broken harness wiring.
// ⟦𓍥𓁟𓄛𓅩⟧ optional :: Anonymous-tolerant session for read-only commands.
pub fn optional() -> Result<Option<Uuid>> {
    match std::env::var(SESSION_ENV) {
        Ok(raw) if !raw.trim().is_empty() => Ok(Some(parse(raw.trim())?)),
        _ => Ok(None),
    }
}

/// Session UUID currently advertised in `REPO_LOCK_IN_EXEC`, if any (best-effort parse).
// ⟦𓅣𓉩𓄛𓐜⟧ in_exec :: Session UUID currently advertised in `REPO_LOCK_IN_EXEC`, if any (best-effort parse).
pub fn in_exec() -> Option<Uuid> {
    std::env::var(IN_EXEC_ENV)
        .ok()
        .and_then(|v| Uuid::parse_str(v.trim()).ok())
}

fn parse(raw: &str) -> Result<Uuid> {
    Uuid::parse_str(raw).with_context(|| format!("{SESSION_ENV} must be a UUID; got {raw:?}"))
}
