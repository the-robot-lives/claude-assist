//! Port of Sources/Config/SecretStore.swift — shells out to the repo `dc` tool.

use std::process::Command;

use rand::seq::SliceRandom;

const ENCRYPTED_PREFIX: &str = "\u{1F512}:v1:"; // 🔒:v1:

fn dc_bin() -> std::path::PathBuf {
    dirs::home_dir()
        .unwrap_or_default()
        .join(".local/bin/dc")
}

pub fn is_encrypted(value: &str) -> bool {
    value.starts_with(ENCRYPTED_PREFIX)
}

fn run_dc(args: &[&str]) -> Option<String> {
    let bin = dc_bin();
    if !bin.is_file() {
        eprintln!("queue-populator: dc not found at {}", bin.display());
        return None;
    }
    let output = Command::new(&bin)
        .args(args)
        .output()
        .map_err(|e| eprintln!("queue-populator: dc failed: {e}"))
        .ok()?;
    if !output.status.success() {
        return None;
    }
    let text = String::from_utf8_lossy(&output.stdout).trim().to_string();
    if text.is_empty() { None } else { Some(text) }
}

pub fn encrypt(plaintext: &str) -> Option<String> {
    run_dc(&["encrypt", "--value", plaintext])
}

pub fn decrypt(token: &str) -> Option<String> {
    run_dc(&["decrypt", token])
}

pub fn generate_alias() -> String {
    const ADJECTIVES: &[&str] = &[
        "amber", "azure", "bold", "calm", "coral", "dark", "deep", "fair", "fell", "gold",
        "gray", "hale", "high", "iron", "jade", "keen", "last", "lone", "mild", "moss",
        "nova", "opal", "pale", "pine", "pure", "rare", "rose", "ruby", "sage", "silk",
        "soft", "star", "teal", "true", "vast", "warm", "wild", "wise", "wren", "zinc",
    ];
    const NOUNS: &[&str] = &[
        "arch", "bark", "bell", "bird", "bone", "cape", "cask", "claw", "dawn", "dell",
        "dove", "dusk", "edge", "fawn", "fern", "fish", "ford", "gate", "glen", "gull",
        "hawk", "haze", "hill", "isle", "jade", "keel", "knot", "lake", "leaf", "lynx",
        "mist", "moon", "moth", "moss", "nest", "owl", "palm", "peak", "pine", "pool",
        "rain", "reef", "sage", "seal", "snow", "star", "tide", "vale", "vine", "wren",
    ];
    let mut rng = rand::thread_rng();
    format!(
        "{}-{}-{}",
        ADJECTIVES.choose(&mut rng).unwrap(),
        NOUNS.choose(&mut rng).unwrap(),
        NOUNS.choose(&mut rng).unwrap()
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn encrypted_prefix_detection() {
        assert!(is_encrypted("\u{1F512}:v1:abcdef"));
        assert!(!is_encrypted("sk-plain"));
        assert!(!is_encrypted("env:FOO"));
    }

    #[test]
    fn alias_shape() {
        let alias = generate_alias();
        assert_eq!(alias.split('-').count(), 3);
    }
}
