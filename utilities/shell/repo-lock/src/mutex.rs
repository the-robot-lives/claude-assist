//! `commit.mutex` — the repo-wide mutex that serializes the whole stage+commit ritual
//! for `exec`, plus the non-blocking probe the pre-commit hook uses.
//!
//! `commit.mutex` is a separate flock sentinel from `registry.flock` so a long-held
//! `exec` never blocks unrelated file/dir lock operations. Because `flock(2)` is released
//! when the fd closes, the mutex is held for exactly the lifetime of the guard's fd — for
//! the whole wrapped child process, then released on drop. `REPO_LOCK_IN_EXEC` lets a
//! nested `exec` (or the hook firing inside one) recognize a self-held mutex and pass
//! through instead of deadlocking.

use std::fs::{self, File, OpenOptions};
use std::os::unix::io::AsRawFd;
use std::path::Path;
use std::thread;
use std::time::{Duration as StdDuration, Instant};

use anyhow::{bail, Context, Result};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::record::{self, Holder};

/// Held `commit.mutex` guard. Dropping it closes the fd (releasing the flock) and clears
/// the owner sidecar file.
pub struct MutexGuard {
    _file: File,
    owner_path: std::path::PathBuf,
}

impl Drop for MutexGuard {
    fn drop(&mut self) {
        let _ = fs::remove_file(&self.owner_path);
    }
}

/// Best-effort record of who currently holds `commit.mutex`, for the hook to report.
/// Advisory only: flock ownership is authoritative; a stale owner file (holder crashed)
/// is ignored because the probe below re-acquires cleanly when the flock is actually free.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MutexOwner {
    pub session: String,
    pub handle: String,
    #[serde(default, alias = "handle_hex")]
    pub handle_fallback: String,
    pub host: String,
    pub pid: u32,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub label: Option<String>,
    pub since: String,
}

/// Acquire `commit.mutex`. Blocks indefinitely when `timeout` is `None`; otherwise polls
/// with `LOCK_NB` until acquired or the deadline elapses.
pub fn acquire(
    mutex_path: &Path,
    owner_path: &Path,
    session: Uuid,
    label: Option<String>,
    timeout: Option<StdDuration>,
) -> Result<MutexGuard> {
    let file = OpenOptions::new()
        .create(true)
        .truncate(false)
        .write(true)
        .open(mutex_path)
        .with_context(|| format!("failed to open commit.mutex: {}", mutex_path.display()))?;
    let fd = file.as_raw_fd();

    match timeout {
        None => {
            let ret = unsafe { libc::flock(fd, libc::LOCK_EX) };
            if ret != 0 {
                return Err(std::io::Error::last_os_error())
                    .context("failed to acquire commit.mutex");
            }
        }
        Some(limit) => {
            let deadline = Instant::now() + limit;
            loop {
                let ret = unsafe { libc::flock(fd, libc::LOCK_EX | libc::LOCK_NB) };
                if ret == 0 {
                    break;
                }
                let err = std::io::Error::last_os_error();
                if err.raw_os_error() != Some(libc::EWOULDBLOCK) {
                    return Err(err).context("failed to acquire commit.mutex");
                }
                if Instant::now() >= deadline {
                    bail!(
                        "timed out after {:?} waiting for commit.mutex{}",
                        limit,
                        describe_owner(owner_path)
                    );
                }
                thread::sleep(StdDuration::from_millis(100));
            }
        }
    }

    let holder = Holder::current(session);
    let owner = MutexOwner {
        session: holder.session,
        handle: holder.handle,
        handle_fallback: holder.handle_fallback,
        host: holder.host,
        pid: holder.pid,
        label,
        since: record::to_rfc3339(record::now()),
    };
    if let Ok(text) = serde_yaml::to_string(&owner) {
        let _ = fs::write(owner_path, text);
    }
    Ok(MutexGuard {
        _file: file,
        owner_path: owner_path.to_path_buf(),
    })
}

/// Non-blocking probe used by the pre-commit hook. `Ok(None)` == free (and any stale owner
/// file is reaped); `Ok(Some(owner))` == currently held by someone else.
pub fn probe(mutex_path: &Path, owner_path: &Path) -> Result<Option<MutexOwner>> {
    let file = OpenOptions::new()
        .create(true)
        .truncate(false)
        .write(true)
        .open(mutex_path)
        .with_context(|| format!("failed to open commit.mutex: {}", mutex_path.display()))?;
    let fd = file.as_raw_fd();
    let ret = unsafe { libc::flock(fd, libc::LOCK_EX | libc::LOCK_NB) };
    if ret == 0 {
        // We got it — nobody holds it. Release immediately and reap any stale owner file.
        unsafe {
            libc::flock(fd, libc::LOCK_UN);
        }
        let _ = fs::remove_file(owner_path);
        return Ok(None);
    }
    let err = std::io::Error::last_os_error();
    if err.raw_os_error() != Some(libc::EWOULDBLOCK) {
        return Err(err).context("failed to probe commit.mutex");
    }
    // Held. Read the (advisory) owner sidecar if present.
    let owner = fs::read_to_string(owner_path)
        .ok()
        .and_then(|t| serde_yaml::from_str::<MutexOwner>(&t).ok());
    Ok(Some(owner.unwrap_or(MutexOwner {
        session: "unknown".into(),
        handle: "????".into(),
        handle_fallback: "U+???? U+???? U+???? U+????".into(),
        host: "unknown".into(),
        pid: 0,
        label: None,
        since: "unknown".into(),
    })))
}

fn describe_owner(owner_path: &Path) -> String {
    match fs::read_to_string(owner_path)
        .ok()
        .and_then(|t| serde_yaml::from_str::<MutexOwner>(&t).ok())
    {
        Some(o) => format!(" (held by {} on {} pid {})", o.handle, o.host, o.pid),
        None => String::new(),
    }
}
