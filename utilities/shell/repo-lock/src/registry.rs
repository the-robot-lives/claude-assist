//! Lock registry: `registry.flock` discipline, atomic `locks/*.yaml` read-modify-write,
//! the append-only journal, path normalization, and dir-prefix overlap detection.
//!
//! Registry root is `git rev-parse --path-format=absolute --git-common-dir` + `/repo-lock/`
//! — always absolute (a bare `--git-common-dir` can be relative to the caller's cwd), and
//! under the *common* dir so every worktree of the repo shares one lock space.

use std::fs::{self, File, OpenOptions};
use std::io::Write;
use std::os::unix::io::AsRawFd;
use std::path::{Component, Path, PathBuf};
use std::process::Command;

use anyhow::{anyhow, bail, Context, Result};
use uuid::Uuid;

use crate::record::{self, LockKind, LockRecord};

/// An advisory exclusive `flock(2)`, released on drop. Mirrors direnv-config's
/// `store/lock.rs` StoreLock: hold the fd open, let `Drop` release the lock; the
/// sentinel file is never written to or truncated after creation.
pub struct FlockGuard {
    _file: File,
}

fn flock_exclusive(path: &Path) -> Result<FlockGuard> {
    let file = OpenOptions::new()
        .create(true)
        .truncate(false)
        .write(true)
        .open(path)
        .with_context(|| format!("failed to open flock sentinel: {}", path.display()))?;
    let ret = unsafe { libc::flock(file.as_raw_fd(), libc::LOCK_EX) };
    if ret != 0 {
        return Err(std::io::Error::last_os_error())
            .with_context(|| format!("failed to acquire flock: {}", path.display()));
    }
    Ok(FlockGuard { _file: file })
}

pub struct Registry {
    /// `<git-common-dir>/repo-lock`
    pub root: PathBuf,
    /// Canonicalized worktree top-level, for repo-relative path normalization.
    pub repo_root: PathBuf,
}

impl Registry {
    /// Discover the registry for the repo containing the current working directory.
    pub fn discover() -> Result<Registry> {
        let common = git(&["rev-parse", "--path-format=absolute", "--git-common-dir"])
            .context("not inside a git repository (could not resolve --git-common-dir)")?;
        let toplevel = git(&["rev-parse", "--show-toplevel"])
            .context("not inside a git worktree (could not resolve --show-toplevel)")?;
        let root = PathBuf::from(common.trim()).join("repo-lock");
        fs::create_dir_all(root.join("locks"))
            .with_context(|| format!("failed to create registry: {}", root.display()))?;
        let repo_root = fs::canonicalize(toplevel.trim())
            .with_context(|| format!("failed to canonicalize repo root: {}", toplevel.trim()))?;
        Ok(Registry { root, repo_root })
    }

    fn locks_dir(&self) -> PathBuf {
        self.root.join("locks")
    }
    fn flock_path(&self) -> PathBuf {
        self.root.join("registry.flock")
    }
    pub fn mutex_path(&self) -> PathBuf {
        self.root.join("commit.mutex")
    }
    pub fn mutex_owner_path(&self) -> PathBuf {
        self.root.join("commit.mutex.owner")
    }
    fn journal_path(&self) -> PathBuf {
        self.root.join("journal.log")
    }

    /// Take `registry.flock` (LOCK_EX, blocking) for a registry read-modify-write.
    pub fn lock(&self) -> Result<FlockGuard> {
        flock_exclusive(&self.flock_path())
    }

    /// Read every lock record in the registry (skips atomic-write temp files).
    /// Unparseable files are surfaced as errors alongside the good records.
    pub fn read_all(&self) -> Result<Vec<LockRecord>> {
        let mut out = Vec::new();
        let dir = self.locks_dir();
        for entry in
            fs::read_dir(&dir).with_context(|| format!("failed to read {}", dir.display()))?
        {
            let entry = entry?;
            let name = entry.file_name();
            let name = name.to_string_lossy();
            if name.starts_with('.') || !name.ends_with(".yaml") {
                continue; // temp files begin with '.'
            }
            let text = fs::read_to_string(entry.path())
                .with_context(|| format!("failed to read {}", entry.path().display()))?;
            let rec: LockRecord = serde_yaml::from_str(&text)
                .with_context(|| format!("corrupt lock record: {}", entry.path().display()))?;
            out.push(rec);
        }
        out.sort_by(|a, b| a.path.cmp(&b.path));
        Ok(out)
    }

    /// Lenient scan for `doctor`: returns parseable records plus a list of problem files
    /// (unreadable or corrupt) rather than failing on the first bad record.
    pub fn scan_lenient(&self) -> (Vec<LockRecord>, Vec<String>) {
        let mut good = Vec::new();
        let mut bad = Vec::new();
        if let Ok(rd) = fs::read_dir(self.locks_dir()) {
            for entry in rd.flatten() {
                let name = entry.file_name().to_string_lossy().into_owned();
                if name.starts_with('.') || !name.ends_with(".yaml") {
                    continue;
                }
                match fs::read_to_string(entry.path()) {
                    Ok(text) => match serde_yaml::from_str::<LockRecord>(&text) {
                        Ok(rec) => good.push(rec),
                        Err(e) => bad.push(format!("{name}: {e}")),
                    },
                    Err(e) => bad.push(format!("{name}: {e}")),
                }
            }
        }
        good.sort_by(|a, b| a.path.cmp(&b.path));
        (good, bad)
    }

    /// Atomically write a lock record: temp file in the same dir, then rename into place.
    pub fn write(&self, rec: &LockRecord) -> Result<()> {
        let final_path = self
            .locks_dir()
            .join(format!("{}.yaml", record::path_hash(&rec.path)));
        let tmp = self.locks_dir().join(format!(
            ".{}.{}.tmp",
            record::path_hash(&rec.path),
            Uuid::new_v4()
        ));
        let yaml = serde_yaml::to_string(rec).context("failed to serialize lock record")?;
        fs::write(&tmp, yaml).with_context(|| format!("failed to write {}", tmp.display()))?;
        fs::rename(&tmp, &final_path)
            .with_context(|| format!("failed to install {}", final_path.display()))?;
        Ok(())
    }

    /// Remove the record for a repo-relative path. Returns true if a file was removed.
    pub fn remove(&self, rel_path: &str) -> Result<bool> {
        let path = self
            .locks_dir()
            .join(format!("{}.yaml", record::path_hash(rel_path)));
        match fs::remove_file(&path) {
            Ok(()) => Ok(true),
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(false),
            Err(e) => Err(e).with_context(|| format!("failed to remove {}", path.display())),
        }
    }

    /// Append a timestamped line to the journal (best-effort; never fatal).
    pub fn journal(&self, line: &str) {
        let entry = format!("{} {}\n", record::to_rfc3339(record::now()), line);
        if let Ok(mut f) = OpenOptions::new()
            .create(true)
            .append(true)
            .open(self.journal_path())
        {
            let _ = f.write_all(entry.as_bytes());
        }
    }

    /// Last `n` journal lines (for `doctor`).
    pub fn journal_tail(&self, n: usize) -> Vec<String> {
        match fs::read_to_string(self.journal_path()) {
            Ok(text) => {
                let lines: Vec<String> = text.lines().map(|s| s.to_string()).collect();
                let start = lines.len().saturating_sub(n);
                lines[start..].to_vec()
            }
            Err(_) => Vec::new(),
        }
    }

    /// Normalize a user-supplied path to a repo-relative, forward-slash string.
    ///
    /// Rejects paths that escape the repo (including via symlink) and any lexical `..`
    /// in the non-existing tail. The path need not exist yet (locking a file about to be
    /// created is legitimate): the deepest existing ancestor is canonicalized — resolving
    /// symlinks — and the remaining components are appended lexically.
    pub fn normalize(&self, user_path: &str) -> Result<(String, PathBuf)> {
        let raw = Path::new(user_path);
        let abs = if raw.is_absolute() {
            raw.to_path_buf()
        } else {
            std::env::current_dir()
                .context("could not read current directory")?
                .join(raw)
        };

        // Split into deepest-existing ancestor + non-existing tail.
        let mut existing = abs.clone();
        let mut tail: Vec<std::ffi::OsString> = Vec::new();
        while !existing.exists() {
            match existing.file_name() {
                Some(name) => {
                    tail.push(name.to_os_string());
                    let parent = existing
                        .parent()
                        .ok_or_else(|| anyhow!("path has no parent: {}", abs.display()))?
                        .to_path_buf();
                    existing = parent;
                }
                None => break,
            }
        }
        tail.reverse();
        // A `..` in the non-existing tail could escape after canonicalization — reject it.
        for comp in &tail {
            if comp == ".." {
                bail!("path contains '..' beyond an existing directory: {user_path}");
            }
        }
        let canon_existing = fs::canonicalize(&existing)
            .with_context(|| format!("could not resolve {}", existing.display()))?;
        let mut resolved = canon_existing;
        for comp in tail {
            resolved.push(comp);
        }

        let rel = resolved.strip_prefix(&self.repo_root).map_err(|_| {
            anyhow!(
                "path is outside the repository ({}): {user_path}",
                self.repo_root.display()
            )
        })?;

        // Lexically reject any residual traversal and normalize to forward slashes.
        let mut parts: Vec<String> = Vec::new();
        for comp in rel.components() {
            match comp {
                Component::Normal(p) => parts.push(p.to_string_lossy().into_owned()),
                Component::CurDir => {}
                _ => bail!("path escapes the repository: {user_path}"),
            }
        }
        let rel_str = if parts.is_empty() {
            ".".to_string() // the repo root itself
        } else {
            parts.join("/")
        };
        Ok((rel_str, resolved))
    }
}

/// Does a lock on `(a_path, a_kind)` overlap a lock on `(b_path, b_kind)`?
///
/// A `dir` lock covers its whole subtree; a `file` lock covers exactly its path.
/// They overlap iff the paths are equal, or one is a directory ancestor of the other.
pub fn overlaps(a_path: &str, a_kind: LockKind, b_path: &str, b_kind: LockKind) -> bool {
    if a_path == b_path {
        return true;
    }
    (a_kind == LockKind::Dir && is_under(b_path, a_path))
        || (b_kind == LockKind::Dir && is_under(a_path, b_path))
}

/// Is `child` inside directory `parent`? `"."` (repo root) is an ancestor of everything.
fn is_under(child: &str, parent: &str) -> bool {
    if parent == "." {
        return child != ".";
    }
    child.starts_with(&format!("{parent}/"))
}

/// Run a git command from the current directory and return trimmed stdout.
fn git(args: &[&str]) -> Result<String> {
    let output = Command::new("git")
        .args(args)
        .output()
        .with_context(|| format!("failed to run git {}", args.join(" ")))?;
    if !output.status.success() {
        bail!(
            "git {} failed: {}",
            args.join(" "),
            String::from_utf8_lossy(&output.stderr).trim()
        );
    }
    Ok(String::from_utf8_lossy(&output.stdout).into_owned())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn overlap_rules() {
        use LockKind::{Dir, File};
        // identical
        assert!(overlaps("a/b", File, "a/b", File));
        // dir covers child file
        assert!(overlaps("a", Dir, "a/b/c", File));
        assert!(overlaps("a/b/c", File, "a", Dir));
        // two files, different paths
        assert!(!overlaps("a/b", File, "a/c", File));
        // dir vs sibling dir
        assert!(!overlaps("a/b", Dir, "a/c", Dir));
        // prefix string but not a path boundary
        assert!(!overlaps("a/b", Dir, "a/bc", File));
        // repo root dir covers everything
        assert!(overlaps(".", Dir, "a/b", File));
    }
}
