//! Port of Sources/Config/EnvResolver.swift.
//! Resolves an env var from the process environment, falling back to an
//! interactive login shell (`$SHELL -lic`) so direnv/exported secrets that only
//! exist in the user's shell profile are visible. Results are cached.

use std::collections::HashMap;
use std::process::Command;
use std::sync::Mutex;
use std::sync::OnceLock;

fn cache() -> &'static Mutex<HashMap<String, Option<String>>> {
    static CACHE: OnceLock<Mutex<HashMap<String, Option<String>>>> = OnceLock::new();
    CACHE.get_or_init(|| Mutex::new(HashMap::new()))
}

/// Strip ANSI CSI/OSC escape sequences that interactive shells may emit.
fn strip_ansi(input: &str) -> String {
    let mut out = String::with_capacity(input.len());
    let mut chars = input.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '\u{1b}' {
            match chars.peek() {
                Some('[') => {
                    chars.next();
                    // CSI: consume until a byte in 0x40..=0x7e
                    for c2 in chars.by_ref() {
                        if ('\u{40}'..='\u{7e}').contains(&c2) {
                            break;
                        }
                    }
                }
                Some(']') => {
                    chars.next();
                    // OSC: consume until BEL or ST (ESC \)
                    let mut prev_esc = false;
                    for c2 in chars.by_ref() {
                        if c2 == '\u{7}' || (prev_esc && c2 == '\\') {
                            break;
                        }
                        prev_esc = c2 == '\u{1b}';
                    }
                }
                _ => {}
            }
        } else {
            out.push(c);
        }
    }
    out
}

fn resolve_via_login_shell(name: &str) -> Option<String> {
    // Guard against injection through the variable name.
    if !name.chars().all(|c| c.is_ascii_alphanumeric() || c == '_') || name.is_empty() {
        return None;
    }
    let shell = std::env::var("SHELL").unwrap_or_else(|_| "/bin/sh".into());
    let output = Command::new(&shell)
        .args(["-lic", &format!("printf '%s' \"${name}\"")])
        .output()
        .ok()?;
    if !output.status.success() {
        return None;
    }
    let raw = String::from_utf8_lossy(&output.stdout);
    let cleaned = strip_ansi(&raw).trim().to_string();
    if cleaned.is_empty() { None } else { Some(cleaned) }
}

// ⟦𓋱𓇍𓋅𓅱⟧ resolve :: auto-generated pointer for public function resolve
pub fn resolve(name: &str) -> Option<String> {
    if let Ok(val) = std::env::var(name) {
        if !val.is_empty() {
            return Some(val);
        }
    }
    let mut cache = cache().lock().unwrap_or_else(|poisoned| poisoned.into_inner());
    if let Some(cached) = cache.get(name) {
        return cached.clone();
    }
    let resolved = resolve_via_login_shell(name);
    cache.insert(name.to_string(), resolved.clone());
    resolved
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn process_env_wins() {
        std::env::set_var("QP_ENV_RESOLVER_TEST", "direct");
        assert_eq!(resolve("QP_ENV_RESOLVER_TEST").as_deref(), Some("direct"));
    }

    #[test]
    fn strip_ansi_removes_csi_and_osc() {
        assert_eq!(strip_ansi("\u{1b}[31mred\u{1b}[0m"), "red");
        assert_eq!(strip_ansi("\u{1b}]0;title\u{7}value"), "value");
        assert_eq!(strip_ansi("plain"), "plain");
    }

    #[test]
    fn rejects_bad_names() {
        assert_eq!(resolve_via_login_shell("FOO; rm -rf /"), None);
        assert_eq!(resolve_via_login_shell(""), None);
    }
}
