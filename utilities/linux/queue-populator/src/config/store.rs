//! Port of Sources/Config/ConfigStore.swift — load/save
//! ~/.config/queue-populator/config.json with atomic tmp+rename and
//! encrypt-plaintext-API-key-on-save.

use std::fs;
use std::io::Read;
use std::path::PathBuf;

use anyhow::{bail, Context, Result};

use super::debug_log;
use super::llm;
use super::secret_store;
use super::QueuePopulatorConfig;

const MAX_CONFIG_BYTES: usize = 4 * 1024 * 1024;

pub fn config_dir() -> PathBuf {
    dirs::home_dir()
        .unwrap_or_default()
        .join(".config/queue-populator")
}

pub fn config_file() -> PathBuf {
    config_dir().join("config.json")
}

pub fn load_config() -> QueuePopulatorConfig {
    load_config_from(&config_file())
}

pub fn load_config_from(path: &std::path::Path) -> QueuePopulatorConfig {
    debug_log::log(&format!("[LOAD] path: {}", path.display()));
    if !path.exists() {
        debug_log::log("[LOAD] no config file, using defaults");
        return defaults();
    }
    match read_config_bytes(path) {
        Ok(data) => match serde_json::from_slice::<QueuePopulatorConfig>(&data) {
            Ok(config) => {
                debug_log::log(&format!(
                    "[LOAD] decoded OK: provider={} model={}",
                    config.llm.provider,
                    config.llm.model.as_deref().unwrap_or("nil")
                ));
                let mut config = config.sanitized();
                if config.queue_base_path.trim().is_empty() {
                    config.queue_base_path = QueuePopulatorConfig::default_queue_base_path();
                }
                config
            }
            Err(e) => {
                debug_log::log(&format!("[LOAD] FAIL decode: {e}"));
                defaults()
            }
        },
        Err(e) => {
            debug_log::log(&format!("[LOAD] FAIL read: {e}"));
            defaults()
        }
    }
}

fn read_config_bytes(path: &std::path::Path) -> Result<Vec<u8>> {
    let file = fs::File::open(path).with_context(|| format!("cannot open {}", path.display()))?;
    let mut data = Vec::with_capacity(16 * 1024);
    file.take((MAX_CONFIG_BYTES as u64).saturating_add(1))
        .read_to_end(&mut data)
        .with_context(|| format!("cannot read {}", path.display()))?;
    if data.len() > MAX_CONFIG_BYTES {
        bail!("config exceeds {MAX_CONFIG_BYTES} bytes");
    }
    Ok(data)
}

fn defaults() -> QueuePopulatorConfig {
    QueuePopulatorConfig {
        queue_base_path: QueuePopulatorConfig::default_queue_base_path(),
        ..Default::default()
    }
}

pub fn save_config(config: &QueuePopulatorConfig) -> Result<()> {
    save_config_to(config, &config_file())
}

pub fn save_config_to(config: &QueuePopulatorConfig, path: &std::path::Path) -> Result<()> {
    let dir = path.parent().context("config path has no parent")?;
    fs::create_dir_all(dir)
        .with_context(|| format!("cannot create config directory {}", dir.display()))?;

    let mut to_save = config.sanitized();

    // Encrypt a plaintext API key before it hits disk (mirrors ConfigStore.swift).
    if let Some(key) = to_save.llm.api_key.clone().filter(|k| !k.is_empty()) {
        if should_encrypt_api_key(&key) {
            let Some(encrypted) = secret_store::encrypt(&key) else {
                bail!("failed to encrypt API key — is dc installed at ~/.local/bin/dc?");
            };
            to_save.llm.api_key = Some(encrypted);
            to_save.llm.api_key_alias = to_save
                .llm
                .api_key_alias
                .clone()
                .or_else(|| Some(secret_store::generate_alias()));
        }
    }

    let data = serde_json::to_string_pretty(&to_save).context("failed to encode config")?;
    if data.len() > MAX_CONFIG_BYTES {
        bail!("encoded config exceeds {MAX_CONFIG_BYTES} bytes");
    }

    let tmp = path.with_extension("json.tmp");
    fs::write(&tmp, &data).with_context(|| format!("cannot write {}", tmp.display()))?;
    fs::rename(&tmp, path).with_context(|| format!("cannot replace {}", path.display()))?;

    // Verify round-trip, warn-only like the Swift version.
    match fs::read(path).map_err(anyhow::Error::from).and_then(|d| {
        serde_json::from_slice::<QueuePopulatorConfig>(&d).map_err(anyhow::Error::from)
    }) {
        Ok(_) => debug_log::log(&format!("[SAVE] SUCCESS — saved and verified ({} bytes)", data.len())),
        Err(e) => debug_log::log(&format!("[SAVE] WARNING — written but re-read failed: {e}")),
    }
    Ok(())
}

fn should_encrypt_api_key(key: &str) -> bool {
    llm::env_reference(key).is_none() && !secret_store::is_encrypted(key)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trip_and_missing_file_defaults() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("config.json");

        let missing = load_config_from(&path);
        assert_eq!(missing.phrases.wake, "hey robot");

        let mut config = defaults();
        config.llm.provider = "litellm".into();
        config.phrases.wake = "yo robot".into();
        save_config_to(&config, &path).unwrap();

        let loaded = load_config_from(&path);
        assert_eq!(loaded.llm.provider, "litellm");
        assert_eq!(loaded.phrases.wake, "yo robot");
        assert!(!path.with_extension("json.tmp").exists());
    }

    #[test]
    fn corrupt_file_falls_back_to_defaults() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("config.json");
        std::fs::write(&path, "{not json").unwrap();
        let loaded = load_config_from(&path);
        assert_eq!(loaded.phrases.wake, "hey robot");
    }

    #[test]
    fn env_ref_key_not_encrypted_on_save() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("config.json");
        let mut config = defaults();
        config.llm.api_key = Some("env:MY_KEY".into());
        save_config_to(&config, &path).unwrap();
        let loaded = load_config_from(&path);
        assert_eq!(loaded.llm.api_key.as_deref(), Some("env:MY_KEY"));
    }

    #[test]
    fn unicode_keys_are_classified_without_utf8_slice_panics() {
        assert!(should_encrypt_api_key("a🔒"));
        assert!(should_encrypt_api_key("éaé"));
        assert!(!should_encrypt_api_key("ENV:SOME_KEY"));
        assert!(!should_encrypt_api_key("🔒:v1:ciphertext"));
    }

    #[test]
    fn oversized_config_falls_back_without_unbounded_read() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("config.json");
        std::fs::write(&path, vec![b' '; MAX_CONFIG_BYTES + 1]).unwrap();

        let loaded = load_config_from(&path);

        assert_eq!(loaded.phrases.wake, "hey robot");
        assert!(read_config_bytes(&path).is_err());
    }
}
