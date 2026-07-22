//! `repo-lock` — advisory file/directory locks + a commit-ritual mutex for the Noizu
//! monorepo. See docs/PROJ-ARCH.md for the full design.

mod glyph;
mod hook;
mod mutex;
mod record;
mod registry;
mod session;

use std::process::{exit, Command};
use std::time::Duration;

use anyhow::{bail, Context, Result};
use clap::{Parser, Subcommand};
use uuid::Uuid;

use record::{Holder, LockKind, LockRecord};
use registry::Registry;

/// Exit code for "locked by another session" — used by `check`, `acquire` conflict.
const EXIT_CONFLICT: i32 = 2;

#[derive(Parser)]
#[command(
    name = "repo-lock",
    version,
    about = "Advisory file/dir locks + commit-ritual mutex for the Noizu monorepo"
)]
struct Cli {
    #[command(subcommand)]
    command: Cmd,
}

#[derive(Subcommand)]
enum Cmd {
    /// Take a file or directory lock. Same-session re-acquire refreshes.
    Acquire {
        /// One or more paths to lock.
        #[arg(required = true)]
        paths: Vec<String>,
        /// Lock the directory subtree (prefix match) rather than a single file.
        #[arg(long)]
        dir: bool,
        /// Time to live before the lock lapses (e.g. 30m, 2h, 1h30m).
        #[arg(long, default_value = "30m")]
        ttl: String,
        /// One-line note describing why the lock is held.
        #[arg(long)]
        intent: Option<String>,
    },
    /// Drop held lock(s).
    Release {
        paths: Vec<String>,
        /// Release every lock held by this session.
        #[arg(long)]
        all: bool,
    },
    /// Show registry contents. Works with REPO_LOCK_SESSION unset (anonymous view).
    List {
        #[arg(long)]
        mine: bool,
        #[arg(long)]
        others: bool,
        #[arg(long)]
        stale: bool,
        /// Show the codepoint-sequence handle (`U+131B4 …`) instead of the unicode glyph.
        #[arg(long)]
        ascii: bool,
    },
    /// Show lock state for specific path(s). Works unset.
    Status {
        #[arg(required = true)]
        paths: Vec<String>,
    },
    /// Silent; exit 0 free / 2 locked-by-other. For scripts and hooks. Works unset.
    Check {
        #[arg(required = true)]
        paths: Vec<String>,
    },
    /// Refresh expires_at before it lapses. Fails (re-acquire) if the record is gone.
    Heartbeat {
        paths: Vec<String>,
        /// Refresh every lock held by this session.
        #[arg(long)]
        all: bool,
    },
    /// Clear a lock. Expired/dead-pid locks break freely; others need --force.
    Break {
        path: String,
        #[arg(long)]
        force: bool,
    },
    /// Run a command holding commit.mutex — guards the whole stage+commit ritual.
    Exec {
        /// Note recorded as the mutex owner label.
        #[arg(long)]
        label: Option<String>,
        /// Give up after this long instead of blocking (e.g. 30s, 5m).
        #[arg(long)]
        timeout: Option<String>,
        /// The command to run, after `--`.
        #[arg(trailing_var_arg = true, allow_hyphen_values = true)]
        cmd: Vec<String>,
    },
    /// Manage the pre-commit hook.
    Hook {
        #[command(subcommand)]
        action: HookAction,
    },
    /// Registry sanity check: orphaned yaml, expired/dead-pid locks, journal tail.
    Doctor,
}

#[derive(Subcommand)]
enum HookAction {
    /// Install the managed pre-commit hook (wrap-and-chain, idempotent).
    Install,
    /// Internal: run the commit-time checks. Invoked by the installed hook.
    Run,
}

fn main() {
    let cli = Cli::parse();
    match dispatch(cli.command) {
        Ok(code) => exit(code),
        Err(e) => {
            eprintln!("repo-lock: {e:#}");
            exit(1);
        }
    }
}

fn dispatch(cmd: Cmd) -> Result<i32> {
    match cmd {
        Cmd::Acquire {
            paths,
            dir,
            ttl,
            intent,
        } => acquire(paths, dir, ttl, intent),
        Cmd::Release { paths, all } => release(paths, all),
        Cmd::List {
            mine,
            others,
            stale,
            ascii,
        } => list(mine, others, stale, ascii),
        Cmd::Status { paths } => status(paths),
        Cmd::Check { paths } => check(paths),
        Cmd::Heartbeat { paths, all } => heartbeat(paths, all),
        Cmd::Break { path, force } => break_lock(path, force),
        Cmd::Exec {
            label,
            timeout,
            cmd,
        } => exec(label, timeout, cmd),
        Cmd::Hook { action } => match action {
            HookAction::Install => {
                hook::install()?;
                Ok(0)
            }
            HookAction::Run => {
                let session = session::require()?;
                let reg = Registry::discover()?;
                hook::run(&reg, session)
            }
        },
        Cmd::Doctor => doctor(),
    }
}

fn acquire(paths: Vec<String>, dir: bool, ttl: String, intent: Option<String>) -> Result<i32> {
    let session = session::require()?;
    let reg = Registry::discover()?;
    let ttl_dur = record::parse_ttl(&ttl)?;
    let kind = if dir { LockKind::Dir } else { LockKind::File };
    let now = record::now();
    let holder = Holder::current(session);

    // Normalize everything up front so a bad path fails before we touch the registry.
    let mut norm = Vec::new();
    for p in &paths {
        let (rel, _abs) = reg.normalize(p)?;
        norm.push(rel);
    }

    let _guard = reg.lock()?;
    let existing = reg.read_all()?;

    // Overlap check: a lock held by another session that isn't expired blocks us.
    let mut conflict = false;
    for rel in &norm {
        for rec in &existing {
            if rec.is_expired(now) || rec.holder.session == session.to_string() {
                continue;
            }
            if registry::overlaps(rel, kind, &rec.path, rec.kind) {
                eprintln!(
                    "repo-lock: {} is locked by {} ({}) via {} — {} (expires {})",
                    rel,
                    rec.holder.handle,
                    rec.holder.handle_fallback,
                    rec.path,
                    rec.intent.as_deref().unwrap_or("(no intent)"),
                    rec.expires_at
                );
                conflict = true;
            }
        }
    }
    if conflict {
        return Ok(EXIT_CONFLICT);
    }

    for rel in &norm {
        // Same-session re-acquire preserves the original acquired_at.
        let acquired_at = existing
            .iter()
            .find(|r| r.path == *rel && r.holder.session == session.to_string())
            .map(|r| r.acquired_at.clone())
            .unwrap_or_else(|| record::to_rfc3339(now));
        let rec = LockRecord {
            path: rel.clone(),
            kind,
            holder: holder.clone(),
            acquired_at,
            refreshed_at: record::to_rfc3339(now),
            expires_at: record::to_rfc3339(now + ttl_dur),
            ttl: ttl.clone(),
            intent: intent.clone(),
        };
        reg.write(&rec)?;
        reg.journal(&format!(
            "acquire path={} kind={} session={} handle={} host={} pid={} ttl={}",
            rel,
            kind.as_str(),
            session,
            holder.handle_fallback,
            holder.host,
            holder.pid,
            ttl
        ));
        println!(
            "locked {} [{}] as {} (expires {})",
            rel,
            kind.as_str(),
            holder.handle,
            rec.expires_at
        );
    }
    Ok(0)
}

fn release(paths: Vec<String>, all: bool) -> Result<i32> {
    let session = session::require()?;
    let reg = Registry::discover()?;
    let _guard = reg.lock()?;
    let existing = reg.read_all()?;

    if all {
        let mut n = 0;
        for rec in &existing {
            if rec.holder.session == session.to_string() {
                reg.remove(&rec.path)?;
                reg.journal(&format!(
                    "release path={} session={} (--all)",
                    rec.path, session
                ));
                println!("released {}", rec.path);
                n += 1;
            }
        }
        if n == 0 {
            println!("no locks held by this session");
        }
        return Ok(0);
    }

    if paths.is_empty() {
        bail!("release needs <path>... or --all");
    }
    let mut code = 0;
    for p in &paths {
        let (rel, _) = reg.normalize(p)?;
        match existing.iter().find(|r| r.path == rel) {
            Some(rec) if rec.holder.session == session.to_string() => {
                reg.remove(&rel)?;
                reg.journal(&format!("release path={} session={}", rel, session));
                println!("released {}", rel);
            }
            Some(rec) => {
                eprintln!(
                    "repo-lock: {} is held by another session ({}); use `break` to override",
                    rel, rec.holder.handle
                );
                code = 1;
            }
            None => println!("no lock held on {rel}"),
        }
    }
    Ok(code)
}

fn list(mine: bool, others: bool, stale: bool, ascii: bool) -> Result<i32> {
    let me = session::optional()?;
    let reg = Registry::discover()?;
    let now = record::now();
    let _guard = reg.lock()?;
    let mut records = reg.read_all()?;

    records.retain(|rec| {
        let is_mine = rec.is_mine(me);
        let is_stale = rec.is_expired(now) || rec.holder_dead_here();
        if mine && !is_mine {
            return false;
        }
        if others && is_mine {
            return false;
        }
        if stale && !is_stale {
            return false;
        }
        true
    });

    if records.is_empty() {
        println!("no locks");
        return Ok(0);
    }
    for rec in &records {
        let handle = rec.holder.display(ascii);
        let mark = if rec.is_mine(me) { "*" } else { " " };
        let state = if rec.is_expired(now) {
            "EXPIRED"
        } else if rec.holder_dead_here() {
            "DEAD-PID"
        } else {
            "active"
        };
        println!(
            "{} {} [{}] {} {} {} exp={}  {}",
            mark,
            rec.path,
            rec.kind.as_str(),
            handle,
            state,
            rec.holder.host,
            rec.expires_at,
            rec.intent.as_deref().unwrap_or("")
        );
    }
    Ok(0)
}

fn status(paths: Vec<String>) -> Result<i32> {
    let me = session::optional()?;
    let reg = Registry::discover()?;
    let now = record::now();
    let _guard = reg.lock()?;
    let records = reg.read_all()?;

    for p in &paths {
        let (rel, _) = reg.normalize(p)?;
        let hits: Vec<&LockRecord> = records
            .iter()
            .filter(|rec| {
                !rec.is_expired(now)
                    && registry::overlaps(&rel, LockKind::File, &rec.path, rec.kind)
            })
            .collect();
        if hits.is_empty() {
            println!("{rel}: free");
        } else {
            for rec in hits {
                let who = if rec.is_mine(me) {
                    "you"
                } else {
                    "another session"
                };
                println!(
                    "{}: locked by {} [{}] via {} exp={}  {}",
                    rel,
                    rec.holder.handle,
                    who,
                    rec.path,
                    rec.expires_at,
                    rec.intent.as_deref().unwrap_or("")
                );
            }
        }
    }
    Ok(0)
}

fn check(paths: Vec<String>) -> Result<i32> {
    let me = session::optional()?;
    let reg = Registry::discover()?;
    let now = record::now();
    let _guard = reg.lock()?;
    let records = reg.read_all()?;

    let mut locked = false;
    for p in &paths {
        let (rel, _) = reg.normalize(p)?;
        for rec in &records {
            if rec.is_expired(now) || rec.is_mine(me) {
                continue;
            }
            if registry::overlaps(&rel, LockKind::File, &rec.path, rec.kind) {
                eprintln!(
                    "repo-lock: {} locked by {} ({})",
                    rel, rec.holder.handle, rec.holder.handle_fallback
                );
                locked = true;
            }
        }
    }
    Ok(if locked { EXIT_CONFLICT } else { 0 })
}

fn heartbeat(paths: Vec<String>, all: bool) -> Result<i32> {
    let session = session::require()?;
    let reg = Registry::discover()?;
    let now = record::now();
    let _guard = reg.lock()?;
    let records = reg.read_all()?;

    let targets: Vec<LockRecord> = if all {
        records
            .iter()
            .filter(|r| r.holder.session == session.to_string())
            .cloned()
            .collect()
    } else {
        if paths.is_empty() {
            bail!("heartbeat needs <path>... or --all");
        }
        let mut v = Vec::new();
        for p in &paths {
            let (rel, _) = reg.normalize(p)?;
            match records.iter().find(|r| r.path == rel) {
                Some(r) if r.holder.session == session.to_string() => v.push(r.clone()),
                Some(_) => bail!(
                    "{rel} is held by another session — cannot heartbeat; re-acquire if it is yours"
                ),
                None => bail!("no lock on {rel} to refresh — re-acquire it"),
            }
        }
        v
    };

    if targets.is_empty() {
        println!("no locks to heartbeat");
        return Ok(0);
    }
    for mut rec in targets {
        let ttl = record::parse_ttl(&rec.ttl).unwrap_or_else(|_| chrono::Duration::minutes(30));
        rec.refreshed_at = record::to_rfc3339(now);
        rec.expires_at = record::to_rfc3339(now + ttl);
        reg.write(&rec)?;
        reg.journal(&format!(
            "heartbeat path={} session={} exp={}",
            rec.path, session, rec.expires_at
        ));
        println!("refreshed {} (expires {})", rec.path, rec.expires_at);
    }
    Ok(0)
}

fn break_lock(path: String, force: bool) -> Result<i32> {
    let session = session::require()?;
    let reg = Registry::discover()?;
    let now = record::now();
    let (rel, _) = reg.normalize(&path)?;
    let _guard = reg.lock()?;
    let records = reg.read_all()?;

    let rec = match records.iter().find(|r| r.path == rel) {
        Some(r) => r.clone(),
        None => {
            eprintln!("repo-lock: no lock on {rel}");
            return Ok(1);
        }
    };

    let expired = rec.is_expired(now);
    let dead = rec.holder_dead_here();
    if !(expired || dead || force) {
        eprintln!(
            "repo-lock: {} is held by an active, live session ({} on {} pid {}); pass --force to break it",
            rel, rec.holder.handle, rec.holder.host, rec.holder.pid
        );
        return Ok(1);
    }

    reg.remove(&rel)?;
    let reason = if expired {
        "expired"
    } else if dead {
        "dead-pid"
    } else {
        "force"
    };
    reg.journal(&format!(
        "break path={} reason={} broken_by={} prev_holder={} prev_host={} prev_pid={}",
        rel, reason, session, rec.holder.handle_fallback, rec.holder.host, rec.holder.pid
    ));
    if reason == "force" {
        println!(
            "warning: force-broke active lock on {} (was held by {} on {} pid {})",
            rel, rec.holder.handle, rec.holder.host, rec.holder.pid
        );
    } else {
        println!("broke {reason} lock on {rel}");
    }
    Ok(0)
}

fn exec(label: Option<String>, timeout: Option<String>, cmd: Vec<String>) -> Result<i32> {
    if cmd.is_empty() {
        bail!("exec needs a command after `--`, e.g. repo-lock exec -- git commit -m ...");
    }
    let session = session::require()?;
    let reg = Registry::discover()?;

    // Reentrancy: already inside our own exec — pass through without re-acquiring.
    if session::in_exec() == Some(session) {
        return run_child(&cmd, session);
    }

    let timeout_dur = match &timeout {
        Some(s) => {
            let d = record::parse_ttl(s)?;
            Some(Duration::from_secs(d.num_seconds().max(0) as u64))
        }
        None => None,
    };
    let _mtx = mutex::acquire(
        &reg.mutex_path(),
        &reg.mutex_owner_path(),
        session,
        label.clone(),
        timeout_dur,
    )?;
    reg.journal(&format!(
        "exec-begin session={} label={} cmd={:?}",
        session,
        label.as_deref().unwrap_or(""),
        cmd.join(" ")
    ));
    let code = run_child(&cmd, session)?;
    reg.journal(&format!("exec-end session={session} code={code}"));
    Ok(code)
}

fn run_child(cmd: &[String], session: Uuid) -> Result<i32> {
    let status = Command::new(&cmd[0])
        .args(&cmd[1..])
        .env(session::IN_EXEC_ENV, session.to_string())
        .status()
        .with_context(|| format!("failed to run {:?}", cmd[0]))?;
    Ok(status.code().unwrap_or(1))
}

fn doctor() -> Result<i32> {
    let reg = Registry::discover()?;
    let now = record::now();
    let _guard = reg.lock()?;

    println!("registry: {}", reg.root.display());
    let (records, bad) = reg.scan_lenient();
    println!("locks: {} record(s)", records.len());

    let expired: Vec<&LockRecord> = records.iter().filter(|r| r.is_expired(now)).collect();
    let dead: Vec<&LockRecord> = records
        .iter()
        .filter(|r| !r.is_expired(now) && r.holder_dead_here())
        .collect();

    if !bad.is_empty() {
        println!("orphaned/corrupt records:");
        for b in &bad {
            println!("  {b}");
        }
    }
    if !expired.is_empty() {
        println!("expired locks (breakable without --force):");
        for r in &expired {
            println!(
                "  {} [{}] {} exp={}",
                r.path,
                r.kind.as_str(),
                r.holder.handle_fallback,
                r.expires_at
            );
        }
    }
    if !dead.is_empty() {
        println!("dead-pid locks (holder gone on this host; breakable without --force):");
        for r in &dead {
            println!(
                "  {} [{}] pid={} host={}",
                r.path,
                r.kind.as_str(),
                r.holder.pid,
                r.holder.host
            );
        }
    }
    if bad.is_empty() && expired.is_empty() && dead.is_empty() {
        println!("no problems detected");
    }

    let tail = reg.journal_tail(10);
    if !tail.is_empty() {
        println!("journal (last {}):", tail.len());
        for l in &tail {
            println!("  {l}");
        }
    }
    Ok(0)
}
