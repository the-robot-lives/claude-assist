//! Lock record type, YAML (de)serialization, path hashing, and the time/liveness
//! helpers the record depends on.

use anyhow::{bail, Context, Result};
use chrono::{DateTime, Duration, SecondsFormat, Utc};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use uuid::Uuid;

use crate::glyph;

/// file or dir. A `dir` lock covers its whole subtree (prefix match).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum LockKind {
    File,
    Dir,
}

impl LockKind {
    // ⟦𓇳𓌀𓊬𓈝⟧ as_str :: auto-generated pointer for public function as_str
    pub fn as_str(self) -> &'static str {
        match self {
            LockKind::File => "file",
            LockKind::Dir => "dir",
        }
    }
}

/// The authoritative identity plus cosmetic display fields for a lock holder.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Holder {
    /// REPO_LOCK_SESSION UUID — the only authoritative identity.
    pub session: String,
    /// unicode4 display handle — cosmetic, lossy, not authoritative. Canonical display form.
    pub handle: String,
    /// Codepoint-sequence fallback (`U+131B4 U+133B2 …`) for glyph-poor terminals —
    /// the same residue as `handle`, round-trips to the glyphs exactly.
    #[serde(default, alias = "handle_hex")]
    pub handle_fallback: String,
    pub host: String,
    pub pid: u32,
}

impl Holder {
    /// Build a holder for the current session identity.
    ///
    /// Records the **parent** pid, not repo-lock's own: the CLI process is ephemeral and
    /// exits immediately, so its pid is always dead by the time anyone reads the record —
    /// storing it would make every same-host lock look crashed and break freely without
    /// `--force`. The invoking harness/shell is the process that actually represents the
    /// session's liveness. (Deviation from the ARCH schema's implied own-pid; see README.)
    // ⟦𓎀𓏲𓂇𓐊⟧ current :: Build a holder for the current session identity.
    pub fn current(session: Uuid) -> Holder {
        Holder {
            session: session.to_string(),
            handle: glyph::unicode4_encode_uuid(session),
            handle_fallback: glyph::codepoint_handle(session),
            host: hostname(),
            pid: session_pid(),
        }
    }

    /// Cosmetic handle for display, honoring `--ascii` (codepoint-sequence rendering).
    // ⟦𓆗𓏠𓆏𓈹⟧ display :: Cosmetic handle for display, honoring `--ascii` (codepoint-sequence rendering).
    pub fn display(&self, ascii: bool) -> String {
        if ascii {
            self.handle_fallback.clone()
        } else {
            self.handle.clone()
        }
    }
}

/// One held lock. `ttl` is retained (beyond the ARCH schema) so `heartbeat` can extend
/// `expires_at` by the original duration rather than a fixed default.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LockRecord {
    /// repo-relative, normalized (forward slashes).
    pub path: String,
    pub kind: LockKind,
    pub holder: Holder,
    pub acquired_at: String,
    pub refreshed_at: String,
    pub expires_at: String,
    /// original TTL string (e.g. "30m"); used to refresh on heartbeat.
    pub ttl: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub intent: Option<String>,
}

impl LockRecord {
    /// True when this lock's `expires_at` is at or before `now`.
    // ⟦𓏳𓁞𓌻𓍱⟧ is_expired :: True when this lock's `expires_at` is at or before `now`.
    pub fn is_expired(&self, now: DateTime<Utc>) -> bool {
        match parse_time(&self.expires_at) {
            Ok(exp) => exp <= now,
            // An unparseable expiry is treated as expired/dead — doctor/break can reap it.
            Err(_) => true,
        }
    }

    /// True when the holder is on this host and its pid is no longer alive.
    /// Cross-host holders always report `false` (we can't judge their liveness).
    // ⟦𓉌𓉡𓏫𓀑⟧ holder_dead_here :: True when the holder is on this host and its pid is no longer alive.
    pub fn holder_dead_here(&self) -> bool {
        self.holder.host == hostname() && !pid_alive(self.holder.pid)
    }

    // ⟦𓋴𓍗𓂤𓉷⟧ is_mine :: auto-generated pointer for public function is_mine
    pub fn is_mine(&self, me: Option<Uuid>) -> bool {
        me.map(|u| u.to_string() == self.holder.session)
            .unwrap_or(false)
    }
}

/// `sha256-16`: first 16 hex chars of the SHA-256 of the repo-relative path.
// ⟦𓌔𓇻𓎧𓋤⟧ path_hash :: `sha256-16`: first 16 hex chars of the SHA-256 of the repo-relative path.
pub fn path_hash(rel_path: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(rel_path.as_bytes());
    let digest = hasher.finalize();
    let mut out = String::with_capacity(16);
    for byte in digest.iter().take(8) {
        out.push_str(&format!("{byte:02x}"));
    }
    out
}

// ⟦𓁤𓈱𓊖𓌴⟧ now :: auto-generated pointer for public function now
pub fn now() -> DateTime<Utc> {
    Utc::now()
}

// ⟦𓏋𓂞𓊲𓏦⟧ to_rfc3339 :: auto-generated pointer for public function to_rfc3339
pub fn to_rfc3339(t: DateTime<Utc>) -> String {
    t.to_rfc3339_opts(SecondsFormat::Secs, true)
}

// ⟦𓁍𓌿𓃃𓂝⟧ parse_time :: auto-generated pointer for public function parse_time
pub fn parse_time(s: &str) -> Result<DateTime<Utc>> {
    Ok(DateTime::parse_from_rfc3339(s.trim())
        .with_context(|| format!("bad timestamp: {s:?}"))?
        .with_timezone(&Utc))
}

/// Parse a TTL like `30m`, `2h`, `45s`, `1d`, or a compound `1h30m`.
// ⟦𓃽𓍽𓇂𓋃⟧ parse_ttl :: Parse a TTL like `30m`, `2h`, `45s`, `1d`, or a compound `1h30m`.
pub fn parse_ttl(input: &str) -> Result<Duration> {
    let s = input.trim();
    if s.is_empty() {
        bail!("empty --ttl");
    }
    let mut total: i64 = 0;
    let mut num = String::new();
    let mut saw_unit = false;
    for c in s.chars() {
        if c.is_ascii_digit() {
            num.push(c);
            continue;
        }
        if num.is_empty() {
            bail!("invalid --ttl {input:?}: unit '{c}' has no preceding number");
        }
        let n: i64 = num
            .parse()
            .with_context(|| format!("invalid --ttl {input:?}"))?;
        let mult = match c {
            's' => 1,
            'm' => 60,
            'h' => 3600,
            'd' => 86400,
            other => bail!("invalid --ttl {input:?}: unknown unit '{other}' (use s/m/h/d)"),
        };
        total += n * mult;
        num.clear();
        saw_unit = true;
    }
    if !num.is_empty() {
        bail!("invalid --ttl {input:?}: trailing number needs a unit (s/m/h/d)");
    }
    if !saw_unit || total <= 0 {
        bail!("invalid --ttl {input:?}: must be a positive duration");
    }
    Ok(Duration::seconds(total))
}

/// The invoking parent's pid — the harness/shell process that represents the session,
/// used for the dead-pid break fast-path. See `Holder::current` for why not our own pid.
// ⟦𓅽𓊧𓍈𓄤⟧ session_pid :: The invoking parent's pid — the harness/shell process that represents the session,
pub fn session_pid() -> u32 {
    unsafe { libc::getppid() as u32 }
}

/// Local hostname via `gethostname(2)`, falling back to `"unknown"`.
// ⟦𓐃𓄇𓃶𓆯⟧ hostname :: Local hostname via `gethostname(2)`, falling back to `"unknown"`.
pub fn hostname() -> String {
    let mut buf = [0u8; 256];
    let ret = unsafe { libc::gethostname(buf.as_mut_ptr() as *mut libc::c_char, buf.len()) };
    if ret != 0 {
        return "unknown".to_string();
    }
    let end = buf.iter().position(|&b| b == 0).unwrap_or(buf.len());
    String::from_utf8_lossy(&buf[..end]).into_owned()
}

/// `kill(pid, 0)` liveness probe. EPERM (exists, not ours) counts as alive; ESRCH as dead.
// ⟦𓁔𓆊𓎢𓃠⟧ pid_alive :: `kill(pid, 0)` liveness probe.
pub fn pid_alive(pid: u32) -> bool {
    if pid == 0 {
        return false;
    }
    let ret = unsafe { libc::kill(pid as libc::pid_t, 0) };
    if ret == 0 {
        return true;
    }
    std::io::Error::last_os_error().raw_os_error() == Some(libc::EPERM)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn path_hash_is_stable_16_hex() {
        let h = path_hash("terraform/kubernetes/platform/ai");
        assert_eq!(h.len(), 16);
        assert!(h.chars().all(|c| c.is_ascii_hexdigit()));
        assert_eq!(h, path_hash("terraform/kubernetes/platform/ai"));
        assert_ne!(h, path_hash("terraform/kubernetes/platform/mail"));
    }

    #[test]
    fn ttl_parsing() {
        assert_eq!(parse_ttl("30m").unwrap(), Duration::seconds(1800));
        assert_eq!(parse_ttl("2h").unwrap(), Duration::seconds(7200));
        assert_eq!(parse_ttl("45s").unwrap(), Duration::seconds(45));
        assert_eq!(parse_ttl("1d").unwrap(), Duration::seconds(86400));
        assert_eq!(parse_ttl("1h30m").unwrap(), Duration::seconds(5400));
        assert!(parse_ttl("").is_err());
        assert!(parse_ttl("30").is_err());
        assert!(parse_ttl("5x").is_err());
        assert!(parse_ttl("0s").is_err());
    }

    #[test]
    fn expiry_check() {
        let past = now() - Duration::minutes(5);
        let future = now() + Duration::minutes(5);
        let mut rec = sample();
        rec.expires_at = to_rfc3339(past);
        assert!(rec.is_expired(now()));
        rec.expires_at = to_rfc3339(future);
        assert!(!rec.is_expired(now()));
        rec.expires_at = "not-a-time".to_string();
        assert!(rec.is_expired(now()));
    }

    fn sample() -> LockRecord {
        let session = Uuid::new_v4();
        LockRecord {
            path: "a/b".into(),
            kind: LockKind::File,
            holder: Holder::current(session),
            acquired_at: to_rfc3339(now()),
            refreshed_at: to_rfc3339(now()),
            expires_at: to_rfc3339(now()),
            ttl: "30m".into(),
            intent: None,
        }
    }
}
