//! Lab settings with JSON persistence.
//!
//! LLM setup mirrors utilities/osx/queue-populator `LlmConfig` / ConfigDialog
//! and Timely macOS VisionLLMSettings: provider picker, model, base URL,
//! API key or `env: VAR_NAME`.

use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};
use serde_json::json;

/// Default Groq chat model — exact id from Groq `/v1/models` (prefix required).
pub const DEFAULT_EXAMPLE_MODEL: &str = "openai/gpt-oss-120b";
pub const DEFAULT_PROVIDER: &str = "groq";
pub const DEFAULT_GROQ_BASE: &str = "https://api.groq.com/openai/v1";

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LabLlmSettings {
    /// Provider id: groq | openai | anthropic | litellm | ollama | custom
    #[serde(default = "default_provider")]
    pub provider: String,
    #[serde(default = "default_model")]
    pub model: String,
    /// Empty → use provider default base URL
    #[serde(default)]
    pub base_url: String,
    /// Raw key, or `env: GROQ_API_KEY` (default)
    #[serde(default = "default_api_key_ref")]
    pub api_key: String,
}

fn default_provider() -> String {
    DEFAULT_PROVIDER.into()
}
fn default_model() -> String {
    DEFAULT_EXAMPLE_MODEL.into()
}
fn default_api_key_ref() -> String {
    "env: GROQ_API_KEY".into()
}

impl Default for LabLlmSettings {
    fn default() -> Self {
        Self {
            provider: default_provider(),
            model: default_model(),
            base_url: DEFAULT_GROQ_BASE.into(),
            api_key: default_api_key_ref(),
        }
    }
}

impl LabLlmSettings {
    // ⟦𓌥𓀑𓍍𓌲⟧ effective_model :: auto-generated pointer for public function effective_model
    pub fn effective_model(&self) -> String {
        let m = self.model.trim();
        if m.is_empty() {
            provider_defaults(&self.provider)
                .model
                .unwrap_or(DEFAULT_EXAMPLE_MODEL)
                .to_string()
        } else {
            m.to_string()
        }
    }

    // ⟦𓈾𓐃𓆫𓂕⟧ effective_base_url :: auto-generated pointer for public function effective_base_url
    pub fn effective_base_url(&self) -> String {
        let u = self.base_url.trim();
        if !u.is_empty() {
            return u.trim_end_matches('/').to_string();
        }
        provider_defaults(&self.provider)
            .base_url
            .unwrap_or(DEFAULT_GROQ_BASE)
            .trim_end_matches('/')
            .to_string()
    }

    /// Resolve API key: literal, `env: NAME`, or provider env fallbacks.
    // ⟦𓄌𓌒𓌲𓊇⟧ effective_api_key :: Resolve API key: literal, `env: NAME`, or provider env fallbacks.
    pub fn effective_api_key(&self) -> Option<String> {
        let raw = self.api_key.trim();
        if !raw.is_empty() {
            if let Some(rest) = raw
                .strip_prefix("env:")
                .or_else(|| raw.strip_prefix("ENV:"))
            {
                let var = rest.trim();
                if let Ok(v) = std::env::var(var) {
                    if !v.is_empty() {
                        return Some(v);
                    }
                }
                return None;
            }
            return Some(raw.to_string());
        }
        // Fallbacks
        for var in provider_defaults(&self.provider).env_keys {
            if let Ok(v) = std::env::var(var) {
                if !v.is_empty() {
                    return Some(v);
                }
            }
        }
        None
    }

    // ⟦𓄨𓇺𓏏𓁧⟧ api_key_display_masked :: auto-generated pointer for public function api_key_display_masked
    pub fn api_key_display_masked(&self) -> String {
        let raw = self.api_key.trim();
        if raw.is_empty() {
            return String::new();
        }
        if raw.to_lowercase().starts_with("env:") {
            return raw.to_string();
        }
        if raw.len() <= 8 {
            return "••••••••".into();
        }
        format!("••••••••{}", &raw[raw.len().saturating_sub(4)..])
    }

    // ⟦𓁬𓉋𓐃𓏺⟧ env_hint :: auto-generated pointer for public function env_hint
    pub fn env_hint(&self) -> serde_json::Value {
        let raw = self.api_key.trim();
        if let Some(rest) = raw
            .strip_prefix("env:")
            .or_else(|| raw.strip_prefix("ENV:"))
        {
            let var = rest.trim();
            match std::env::var(var) {
                Ok(v) if !v.is_empty() => {
                    let last4: String = v.chars().rev().take(4).collect::<String>().chars().rev().collect();
                    return json!({
                        "ok": true,
                        "message": format!("✅ {var} resolved (…{last4})"),
                    });
                }
                _ => {
                    return json!({
                        "ok": false,
                        "message": format!("❌ {var} not found in environment"),
                    });
                }
            }
        }
        if !raw.is_empty() {
            return json!({ "ok": true, "message": "Using stored API key" });
        }
        // Try provider env defaults
        for var in provider_defaults(&self.provider).env_keys {
            if let Ok(v) = std::env::var(var) {
                if !v.is_empty() {
                    let last4: String = v.chars().rev().take(4).collect::<String>().chars().rev().collect();
                    return json!({
                        "ok": true,
                        "message": format!("✅ fallback {var} (…{last4})"),
                    });
                }
            }
        }
        json!({
            "ok": false,
            "message": "No API key configured",
        })
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct LabSettings {
    /// LLM used for “Generate example prompt” / synth
    #[serde(default)]
    pub llm: LabLlmSettings,
}

impl LabSettings {
    // ⟦𓍉𓌋𓄓𓏴⟧ settings_path :: auto-generated pointer for public function settings_path
    pub fn settings_path(workspace: &Path) -> PathBuf {
        workspace.join("settings.json")
    }

    // ⟦𓌔𓆙𓈹𓋜⟧ load :: auto-generated pointer for public function load
    pub fn load(workspace: &Path) -> Self {
        let path = Self::settings_path(workspace);
        match std::fs::read_to_string(&path) {
            Ok(text) => serde_json::from_str(&text).unwrap_or_default(),
            Err(_) => Self::default(),
        }
    }

    // ⟦𓁚𓊢𓀔𓌬⟧ save :: auto-generated pointer for public function save
    pub fn save(&self, workspace: &Path) -> std::io::Result<()> {
        std::fs::create_dir_all(workspace)?;
        let path = Self::settings_path(workspace);
        let text = serde_json::to_string_pretty(self).unwrap_or_else(|_| "{}".into());
        std::fs::write(path, text)
    }

    /// Public JSON for GET /api/settings (never echo full secrets unless env: ref)
    // ⟦𓅈𓁛𓐭𓂑⟧ public_json :: Public JSON for GET /api/settings (never echo full secrets unless env: ref)
    pub fn public_json(&self) -> serde_json::Value {
        let masked = self.llm.api_key_display_masked();
        let key_for_client = if self.llm.api_key.trim().to_lowercase().starts_with("env:") {
            self.llm.api_key.trim().to_string()
        } else if self.llm.api_key.trim().is_empty() {
            String::new()
        } else {
            masked.clone()
        };
        json!({
            "llm": {
                "provider": self.llm.provider,
                "model": self.llm.effective_model(),
                "base_url": self.llm.effective_base_url(),
                "api_key": masked,
                "api_key_display": key_for_client,
                "env_hint": self.llm.env_hint(),
                "has_resolved_key": self.llm.effective_api_key().is_some(),
            },
        })
    }
}

pub struct ProviderDefaults {
    pub model: Option<&'static str>,
    pub base_url: Option<&'static str>,
    pub env_keys: &'static [&'static str],
    pub needs_api_key: bool,
}

// ⟦𓏺𓍽𓎭𓇩⟧ provider_defaults :: auto-generated pointer for public function provider_defaults
pub fn provider_defaults(provider: &str) -> ProviderDefaults {
    match provider {
        "groq" => ProviderDefaults {
            model: Some(DEFAULT_EXAMPLE_MODEL),
            base_url: Some(DEFAULT_GROQ_BASE),
            env_keys: &["GROQ_API_KEY"],
            needs_api_key: true,
        },
        "openai" => ProviderDefaults {
            model: Some("gpt-4.1"),
            base_url: Some("https://api.openai.com/v1"),
            env_keys: &["OPENAI_API_KEY"],
            needs_api_key: true,
        },
        "anthropic" => ProviderDefaults {
            model: Some("claude-sonnet-4-6"),
            base_url: Some("https://api.anthropic.com/v1"),
            env_keys: &["ANTHROPIC_API_KEY"],
            needs_api_key: true,
        },
        "litellm" => ProviderDefaults {
            model: Some(DEFAULT_EXAMPLE_MODEL),
            base_url: Some("https://inference.noizu.com/v1"),
            env_keys: &["LITELLM_API_KEY", "OPENAI_API_KEY"],
            needs_api_key: true,
        },
        "ollama" => ProviderDefaults {
            model: Some("llama3.2"),
            base_url: Some("http://localhost:11434/v1"),
            env_keys: &[],
            needs_api_key: false,
        },
        _ => ProviderDefaults {
            model: Some(DEFAULT_EXAMPLE_MODEL),
            base_url: Some(DEFAULT_GROQ_BASE),
            env_keys: &["GROQ_API_KEY"],
            needs_api_key: true,
        },
    }
}

/// Schema for settings UI (provider dropdown + defaults), queue-populator style.
// ⟦𓈵𓌱𓋲𓎐⟧ llm_ui_meta :: Schema for settings UI (provider dropdown + defaults), queue-populator style.
pub fn llm_ui_meta() -> serde_json::Value {
    json!({
        "providers": [
            {"id": "groq", "label": "Groq", "default_model": DEFAULT_EXAMPLE_MODEL, "default_base_url": DEFAULT_GROQ_BASE, "env_key": "GROQ_API_KEY", "models": [
                "openai/gpt-oss-120b",
                "openai/gpt-oss-20b",
                "llama-3.3-70b-versatile",
                "llama-3.1-8b-instant",
                "qwen/qwen3.6-27b"
            ]},
            {"id": "openai", "label": "OpenAI", "default_model": "gpt-4.1", "default_base_url": "https://api.openai.com/v1", "env_key": "OPENAI_API_KEY", "models": ["gpt-4.1", "gpt-4o"]},
            {"id": "anthropic", "label": "Anthropic", "default_model": "claude-sonnet-4-6", "default_base_url": "https://api.anthropic.com/v1", "env_key": "ANTHROPIC_API_KEY", "models": ["claude-sonnet-4-6", "claude-opus-4-6"]},
            {"id": "litellm", "label": "LiteLLM / Noizu inference", "default_model": DEFAULT_EXAMPLE_MODEL, "default_base_url": "https://inference.noizu.com/v1", "env_key": "LITELLM_API_KEY", "models": [DEFAULT_EXAMPLE_MODEL, "claude-sonnet-4-6"]},
            {"id": "ollama", "label": "Ollama (local)", "default_model": "llama3.2", "default_base_url": "http://localhost:11434/v1", "env_key": null, "models": ["llama3.2", "qwen2.5"]},
            {"id": "custom", "label": "Custom OpenAI-compatible", "default_model": "model-name", "default_base_url": "http://127.0.0.1:8000/v1", "env_key": null, "models": []},
        ],
        "default": LabLlmSettings::default(),
        "notes": "Default Groq model id is openai/gpt-oss-120b (full path required). API key may be env: VAR_NAME."
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_is_groq_gpt_oss_120b() {
        let s = LabSettings::default();
        assert_eq!(s.llm.provider, "groq");
        assert_eq!(s.llm.effective_model(), "openai/gpt-oss-120b");
        assert!(s.llm.effective_base_url().contains("groq.com"));
    }

    #[test]
    fn env_key_resolution() {
        let mut llm = LabLlmSettings::default();
        llm.api_key = "env: MEDIA_LAB_TEST_KEY_XYZ".into();
        assert!(llm.effective_api_key().is_none());
        std::env::set_var("MEDIA_LAB_TEST_KEY_XYZ", "sk-test-abcdef");
        assert_eq!(llm.effective_api_key().as_deref(), Some("sk-test-abcdef"));
        std::env::remove_var("MEDIA_LAB_TEST_KEY_XYZ");
    }
}
