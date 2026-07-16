//! End-to-end tests driving the compiled `repo-lock` binary against throwaway git repos.

use std::os::unix::fs::PermissionsExt;
use std::path::Path;
use std::process::{Command, Output};
use std::time::Duration;

use tempfile::TempDir;

const BIN: &str = env!("CARGO_BIN_EXE_repo-lock");

// Distinct valid UUIDs standing in for separate harness sessions.
const S1: &str = "11111111-1111-4111-8111-111111111111";
const S2: &str = "22222222-2222-4222-8222-222222222222";

fn git(repo: &Path, args: &[&str]) {
    let status = Command::new("git")
        .current_dir(repo)
        .args(args)
        .status()
        .expect("failed to run git");
    assert!(status.success(), "git {args:?} failed");
}

fn setup_repo() -> TempDir {
    let tmp = TempDir::new().unwrap();
    let repo = tmp.path();
    git(repo, &["init", "-q"]);
    git(repo, &["config", "user.email", "test@example.com"]);
    git(repo, &["config", "user.name", "Test"]);
    git(repo, &["config", "commit.gpgsign", "false"]);
    tmp
}

/// Run the binary with a clean session environment.
fn rl(repo: &Path, session: Option<&str>, args: &[&str]) -> Output {
    let mut c = Command::new(BIN);
    c.current_dir(repo);
    c.env_remove("REPO_LOCK_SESSION");
    c.env_remove("REPO_LOCK_IN_EXEC");
    if let Some(s) = session {
        c.env("REPO_LOCK_SESSION", s);
    }
    c.args(args);
    c.output().expect("failed to run repo-lock")
}

fn code(o: &Output) -> i32 {
    o.status.code().unwrap_or(-1)
}
fn stdout(o: &Output) -> String {
    String::from_utf8_lossy(&o.stdout).into_owned()
}
fn stderr(o: &Output) -> String {
    String::from_utf8_lossy(&o.stderr).into_owned()
}

#[test]
fn acquire_conflict_release() {
    let tmp = setup_repo();
    let repo = tmp.path();

    let o = rl(repo, Some(S1), &["acquire", "a.txt", "--intent", "editing"]);
    assert_eq!(code(&o), 0, "acquire failed: {}", stderr(&o));

    // A second identity is blocked with exit 2.
    let o = rl(repo, Some(S2), &["acquire", "a.txt"]);
    assert_eq!(
        code(&o),
        2,
        "second identity should conflict: {}",
        stdout(&o)
    );

    // check: foreign locked -> 2, own -> 0.
    assert_eq!(code(&rl(repo, Some(S2), &["check", "a.txt"])), 2);
    assert_eq!(code(&rl(repo, Some(S1), &["check", "a.txt"])), 0);

    // Release by the owner, then the second identity can take it.
    assert_eq!(code(&rl(repo, Some(S1), &["release", "a.txt"])), 0);
    assert_eq!(code(&rl(repo, Some(S2), &["acquire", "a.txt"])), 0);
}

#[test]
fn mutating_requires_session_readonly_anonymous() {
    let tmp = setup_repo();
    let repo = tmp.path();

    let o = rl(repo, None, &["acquire", "x.txt"]);
    assert_eq!(code(&o), 1, "mutating without session must fail closed");
    assert!(
        stderr(&o).contains("REPO_LOCK_SESSION"),
        "actionable error expected: {}",
        stderr(&o)
    );

    // Read-only commands work anonymously.
    assert_eq!(code(&rl(repo, None, &["list"])), 0);
    assert_eq!(code(&rl(repo, None, &["status", "x.txt"])), 0);
}

#[test]
fn dir_lock_covers_child() {
    let tmp = setup_repo();
    let repo = tmp.path();
    std::fs::create_dir_all(repo.join("src")).unwrap();

    assert_eq!(
        code(&rl(repo, Some(S1), &["acquire", "src", "--dir"])),
        0,
        "dir acquire failed"
    );

    // A child path (not yet existing on disk) is covered for another session.
    assert_eq!(code(&rl(repo, Some(S2), &["check", "src/main.rs"])), 2);
    assert_eq!(code(&rl(repo, Some(S2), &["acquire", "src/main.rs"])), 2);

    // The owner is not blocked by their own covering dir lock.
    assert_eq!(code(&rl(repo, Some(S1), &["check", "src/main.rs"])), 0);
}

#[test]
fn ttl_expiry_then_break() {
    let tmp = setup_repo();
    let repo = tmp.path();

    assert_eq!(
        code(&rl(repo, Some(S1), &["acquire", "b.txt", "--ttl", "1s"])),
        0
    );
    std::thread::sleep(Duration::from_millis(1300));

    // Expired -> reads as free.
    assert_eq!(code(&rl(repo, Some(S2), &["check", "b.txt"])), 0);

    // Expired locks break without --force.
    let o = rl(repo, Some(S2), &["break", "b.txt"]);
    assert_eq!(code(&o), 0, "break expired failed: {}", stderr(&o));
    assert!(stdout(&o).contains("expired"), "{}", stdout(&o));
}

#[test]
fn break_active_live_requires_force() {
    let tmp = setup_repo();
    let repo = tmp.path();

    // The acquire process's parent is this (alive) test process, so the lock is recorded
    // as held by a live pid on this host — i.e. genuinely active, not a crashed session.
    assert_eq!(
        code(&rl(repo, Some(S1), &["acquire", "d.txt", "--ttl", "1h"])),
        0
    );

    // Active + live -> refused without --force.
    let o = rl(repo, Some(S2), &["break", "d.txt"]);
    assert_eq!(
        code(&o),
        1,
        "expected refusal: {} / {}",
        stdout(&o),
        stderr(&o)
    );

    // --force breaks it and journals loudly.
    let o = rl(repo, Some(S2), &["break", "d.txt", "--force"]);
    assert_eq!(code(&o), 0, "force break failed: {}", stderr(&o));
    assert!(stdout(&o).contains("force-broke"), "{}", stdout(&o));
}

#[test]
fn exec_mutex_serializes() {
    let tmp = setup_repo();
    let repo = tmp.path().to_path_buf();
    let log = repo.join("exec.log");

    let spawn = |session: &'static str, tag: char| {
        let repo = repo.clone();
        let logp = log.to_string_lossy().into_owned();
        std::thread::spawn(move || {
            let script = format!(
                "printf 'start{tag}\\n' >> '{logp}'; sleep 0.5; printf 'end{tag}\\n' >> '{logp}'"
            );
            let mut c = Command::new(BIN);
            c.current_dir(&repo);
            c.env_remove("REPO_LOCK_IN_EXEC");
            c.env("REPO_LOCK_SESSION", session);
            c.args(["exec", "--", "sh", "-c", &script]);
            c.output().expect("exec failed")
        })
    };

    let h1 = spawn(S1, 'A');
    // Stagger so A wins the mutex first; B must block until A releases.
    std::thread::sleep(Duration::from_millis(120));
    let h2 = spawn(S2, 'B');

    let o1 = h1.join().unwrap();
    let o2 = h2.join().unwrap();
    assert!(o1.status.success(), "exec A failed: {}", stderr(&o1));
    assert!(o2.status.success(), "exec B failed: {}", stderr(&o2));

    let content = std::fs::read_to_string(&log).unwrap();
    let lines: Vec<&str> = content.lines().collect();
    assert_eq!(lines.len(), 4, "unexpected log: {lines:?}");
    // Serialized: each start is immediately followed by its own end (no interleave).
    assert_eq!(
        lines[0].trim_start_matches("start"),
        lines[1].trim_start_matches("end"),
        "interleaved critical sections: {lines:?}"
    );
    assert_eq!(
        lines[2].trim_start_matches("start"),
        lines[3].trim_start_matches("end"),
        "interleaved critical sections: {lines:?}"
    );
}

#[test]
fn nested_exec_passes_through() {
    let tmp = setup_repo();
    let repo = tmp.path();

    // Outer exec holds the mutex; the inner exec from the same session must pass through
    // rather than deadlock on the self-held mutex. --timeout makes a regression fail fast
    // instead of hanging (the pass-through path ignores it entirely).
    let o = rl(
        repo,
        Some(S1),
        &[
            "exec",
            "--",
            BIN,
            "exec",
            "--timeout",
            "5s",
            "--",
            "sh",
            "-c",
            "echo nested-ok",
        ],
    );
    assert!(o.status.success(), "nested exec failed: {}", stderr(&o));
    assert!(stdout(&o).contains("nested-ok"), "{}", stdout(&o));
}

#[test]
fn hook_install_idempotent() {
    let tmp = setup_repo();
    let repo = tmp.path();

    assert_eq!(code(&rl(repo, None, &["hook", "install"])), 0);
    let hook = repo.join(".git/hooks/pre-commit");
    assert!(hook.exists());
    let body = std::fs::read_to_string(&hook).unwrap();
    assert!(body.contains("repo-lock-managed-hook"));
    let mode = std::fs::metadata(&hook).unwrap().permissions().mode();
    assert!(mode & 0o111 != 0, "hook must be executable");

    // Re-running is idempotent and creates no spurious chained hook.
    assert_eq!(code(&rl(repo, None, &["hook", "install"])), 0);
    assert!(!repo.join(".git/hooks/pre-commit.chained").exists());
}

#[test]
fn hook_install_chains_existing() {
    let tmp = setup_repo();
    let repo = tmp.path();
    let hook = repo.join(".git/hooks/pre-commit");
    std::fs::create_dir_all(hook.parent().unwrap()).unwrap();
    std::fs::write(&hook, "#!/bin/sh\necho custom-hook\n").unwrap();
    let mut p = std::fs::metadata(&hook).unwrap().permissions();
    p.set_mode(0o755);
    std::fs::set_permissions(&hook, p).unwrap();

    assert_eq!(code(&rl(repo, None, &["hook", "install"])), 0);
    let chained = repo.join(".git/hooks/pre-commit.chained");
    assert!(
        chained.exists(),
        "existing hook must be preserved as chained"
    );
    let chained_body = std::fs::read_to_string(&chained).unwrap();
    assert!(chained_body.contains("custom-hook"));
    assert!(std::fs::read_to_string(&hook)
        .unwrap()
        .contains("repo-lock-managed-hook"));

    // Idempotent re-run leaves the chained hook untouched (no double-wrap).
    assert_eq!(code(&rl(repo, None, &["hook", "install"])), 0);
    assert_eq!(std::fs::read_to_string(&chained).unwrap(), chained_body);
}

#[test]
fn hook_rejects_foreign_locked_commit() {
    let tmp = setup_repo();
    let repo = tmp.path();
    assert_eq!(code(&rl(repo, None, &["hook", "install"])), 0);

    std::fs::write(repo.join("foo.txt"), "hi").unwrap();
    assert_eq!(code(&rl(repo, Some(S1), &["acquire", "foo.txt"])), 0);
    git(repo, &["add", "foo.txt"]);

    // A commit from a different session staging the foreign-locked path is rejected.
    let out = commit_as(repo, S2);
    assert!(
        !out.status.success(),
        "commit should be rejected; stderr: {}",
        stderr(&out)
    );
    let msg = format!("{}{}", stdout(&out), stderr(&out));
    assert!(msg.contains("locked by another session"), "msg: {msg}");

    // The lock owner is not blocked by their own lock.
    let out = commit_as(repo, S1);
    assert!(
        out.status.success(),
        "owner commit should pass; stderr: {}",
        stderr(&out)
    );
}

fn commit_as(repo: &Path, session: &str) -> Output {
    Command::new("git")
        .current_dir(repo)
        .args(["commit", "-m", "msg"])
        .env_remove("REPO_LOCK_IN_EXEC")
        .env("REPO_LOCK_SESSION", session)
        .output()
        .expect("failed to run git commit")
}
