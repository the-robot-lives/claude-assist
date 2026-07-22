//! Pre-commit hook: wrap-and-chain installer, plus the `hook run` entry point the
//! installed hook calls back into.
//!
//! Install never overwrites an unmanaged `pre-commit`: it renames it to
//! `pre-commit.chained`, invoked first by the managed hook. Re-running is idempotent —
//! the managed-marker comment is detected and an existing chain left in place.
//!
//! `hook run` makes two checks on every commit: (1) reject if any staged path is locked
//! by another session; (2) a non-blocking `commit.mutex` probe rejecting if another
//! session currently holds it — unless we are inside our own session's `exec`
//! (`REPO_LOCK_IN_EXEC` matches), in which case the probe is skipped.

use std::fs;
use std::os::unix::fs::PermissionsExt;
use std::path::PathBuf;
use std::process::Command;

use anyhow::{bail, Context, Result};
use uuid::Uuid;

use crate::record::LockKind;
use crate::registry::{self, Registry};
use crate::{mutex, session};

/// Idempotent managed-hook marker comment (mirrors `doc-pointers`' marker precedent).
const MANAGED_MARKER: &str = "# repo-lock-managed-hook";

/// `hook install` — wrap-and-chain the pre-commit hook.
// ⟦𓃰𓈰𓌓𓏕⟧ install :: `hook install` — wrap-and-chain the pre-commit hook.
pub fn install() -> Result<()> {
    let git_dir = git_absolute_dir()?;
    let hooks_dir = git_dir.join("hooks");
    fs::create_dir_all(&hooks_dir)
        .with_context(|| format!("failed to create {}", hooks_dir.display()))?;
    let hook = hooks_dir.join("pre-commit");
    let chained = hooks_dir.join("pre-commit.chained");

    if hook.exists() {
        let existing = fs::read_to_string(&hook).unwrap_or_default();
        if existing.contains(MANAGED_MARKER) {
            // Already ours — idempotent. Refresh the body (keeps the binary path current)
            // but leave any existing chain untouched.
            write_managed_hook(&hook)?;
            println!(
                "repo-lock: pre-commit already managed; refreshed {}{}",
                hook.display(),
                if chained.exists() {
                    " (chained hook preserved)"
                } else {
                    ""
                }
            );
            return Ok(());
        }
        // Unmanaged hook present — preserve it as the chained hook.
        if chained.exists() {
            bail!(
                "{} exists but is not managed by repo-lock, and {} already exists — \
                 refusing to clobber; resolve by hand",
                hook.display(),
                chained.display()
            );
        }
        fs::rename(&hook, &chained).with_context(|| {
            format!("failed to preserve existing hook as {}", chained.display())
        })?;
        make_executable(&chained)?;
        write_managed_hook(&hook)?;
        println!(
            "repo-lock: preserved existing pre-commit as {} and installed managed hook",
            chained.display()
        );
        return Ok(());
    }

    write_managed_hook(&hook)?;
    println!(
        "repo-lock: installed managed pre-commit hook {}",
        hook.display()
    );
    Ok(())
}

fn write_managed_hook(hook: &PathBuf) -> Result<()> {
    let bin = std::env::current_exe()
        .ok()
        .map(|p| p.display().to_string())
        .unwrap_or_else(|| "repo-lock".to_string());
    let body = format!(
        "#!/bin/sh\n\
         {MANAGED_MARKER}\n\
         # Installed by `repo-lock hook install`. Regenerated on reinstall.\n\
         hookdir=\"$(CDPATH= cd -- \"$(dirname -- \"$0\")\" && pwd)\"\n\
         chained=\"$hookdir/pre-commit.chained\"\n\
         if [ -x \"$chained\" ]; then\n\
         \x20   \"$chained\" \"$@\" || exit $?\n\
         fi\n\
         exec {} hook run\n",
        shell_quote(&bin)
    );
    fs::write(hook, body).with_context(|| format!("failed to write {}", hook.display()))?;
    make_executable(hook)?;
    Ok(())
}

/// `hook run` — the two commit-time checks. Returns the process exit code.
// ⟦𓇅𓐍𓊕𓈊⟧ run :: `hook run` — the two commit-time checks.
pub fn run(registry: &Registry, session: Uuid) -> Result<i32> {
    let now = crate::record::now();
    let staged = staged_paths(registry)?;

    // Check 1: staged paths locked by another session.
    let conflicts: Vec<String> = {
        let _guard = registry.lock()?;
        let records = registry.read_all()?;
        let mut out = Vec::new();
        for path in &staged {
            for rec in &records {
                if rec.is_expired(now) {
                    continue;
                }
                if rec.holder.session == session.to_string() {
                    continue;
                }
                if registry::overlaps(path, LockKind::File, &rec.path, rec.kind) {
                    let intent = rec.intent.as_deref().unwrap_or("(no intent)");
                    out.push(format!(
                        "  {}  locked by {} ({}, {}) on {} until {} — {}",
                        path,
                        rec.holder.handle,
                        rec.holder.handle_fallback,
                        rec.path,
                        rec.holder.host,
                        rec.expires_at,
                        intent
                    ));
                }
            }
        }
        out
    };

    let mut rejected = false;
    if !conflicts.is_empty() {
        eprintln!("repo-lock: commit blocked — staged paths are locked by another session:");
        for c in &conflicts {
            eprintln!("{c}");
        }
        rejected = true;
    }

    // Check 2: commit.mutex probe — skipped when inside our own session's exec.
    if session::in_exec() != Some(session) {
        if let Some(owner) = mutex::probe(&registry.mutex_path(), &registry.mutex_owner_path())? {
            if owner.session != session.to_string() {
                let label = owner.label.as_deref().unwrap_or("(no label)");
                eprintln!(
                    "repo-lock: commit blocked — commit.mutex held by {} ({}) on {} pid {} since {} — {}",
                    owner.handle, owner.handle_fallback, owner.host, owner.pid, owner.since, label
                );
                eprintln!(
                    "  another session is mid stage+commit ritual; wait or run your commit via `repo-lock exec -- git commit ...`"
                );
                rejected = true;
            }
        }
    }

    if rejected {
        Ok(1)
    } else {
        Ok(0)
    }
}

/// Staged paths, repo-relative, resolved from the repo root regardless of hook cwd.
fn staged_paths(registry: &Registry) -> Result<Vec<String>> {
    let output = Command::new("git")
        .current_dir(&registry.repo_root)
        .args([
            "-c",
            "core.quotepath=false",
            "diff",
            "--cached",
            "--name-only",
        ])
        .output()
        .context("failed to list staged files")?;
    if !output.status.success() {
        bail!(
            "git diff --cached failed: {}",
            String::from_utf8_lossy(&output.stderr).trim()
        );
    }
    Ok(String::from_utf8_lossy(&output.stdout)
        .lines()
        .map(|l| l.trim().to_string())
        .filter(|l| !l.is_empty())
        .collect())
}

fn git_absolute_dir() -> Result<PathBuf> {
    let output = Command::new("git")
        .args(["rev-parse", "--absolute-git-dir"])
        .output()
        .context("git directory not found; cannot install hook")?;
    if !output.status.success() {
        bail!("git directory not found; cannot install hook");
    }
    Ok(PathBuf::from(
        String::from_utf8_lossy(&output.stdout).trim(),
    ))
}

fn make_executable(path: &PathBuf) -> Result<()> {
    let mut perms = fs::metadata(path)
        .with_context(|| format!("failed to stat {}", path.display()))?
        .permissions();
    perms.set_mode(perms.mode() | 0o111);
    fs::set_permissions(path, perms)
        .with_context(|| format!("failed to chmod {}", path.display()))?;
    Ok(())
}

fn shell_quote(value: &str) -> String {
    format!("'{}'", value.replace('\'', "'\\''"))
}
