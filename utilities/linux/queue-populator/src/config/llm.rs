//! Port of Sources/Config/LlmConfig.swift — provider tables copied verbatim.

use serde::{Deserialize, Serialize};

use super::env_resolver;
use super::secret_store;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(default)]
pub struct LlmConfig {
    pub provider: String,
    pub model: Option<String>,
    #[serde(rename = "apiKey")]
    pub api_key: Option<String>,
    #[serde(rename = "apiKeyAlias")]
    pub api_key_alias: Option<String>,
    #[serde(rename = "baseUrl")]
    pub base_url: Option<String>,
    #[serde(rename = "apiType")]
    pub api_type: Option<String>,
}

impl Default for LlmConfig {
    fn default() -> Self {
        Self {
            provider: "anthropic".into(),
            model: None,
            api_key: None,
            api_key_alias: None,
            base_url: None,
            api_type: None,
        }
    }
}

pub const PROVIDERS: &[&str] = &[
    "anthropic", "openai", "groq", "cerebras", "deepseek", "zai", "litellm", "ollama", "custom",
];

// ⟦𓈇𓇩𓊑𓉷⟧ default_model :: auto-generated pointer for public function default_model
pub fn default_model(provider: &str) -> Option<&'static str> {
    Some(match provider {
        "anthropic" => "claude-sonnet-4-20250514",
        "openai" => "gpt-4o",
        "groq" => "llama-3.3-70b",
        "cerebras" => "llama-3.3-70b",
        "deepseek" => "deepseek-chat",
        "zai" => "glm-4",
        "litellm" => "claude-sonnet-4-6",
        "ollama" => "llama3",
        "custom" => "model-name",
        _ => return None,
    })
}

// ⟦𓎞𓉒𓂡𓏝⟧ env_var_key :: auto-generated pointer for public function env_var_key
pub fn env_var_key(provider: &str) -> Option<&'static str> {
    Some(match provider {
        "anthropic" => "ANTHROPIC_API_KEY",
        "openai" => "OPENAI_API_KEY",
        "groq" => "GROQ_API_KEY",
        "cerebras" => "CEREBRAS_API_KEY",
        "deepseek" => "DEEPSEEK_API_KEY",
        "zai" => "ZAI_API_KEY",
        "litellm" => "LITELLM_API_KEY",
        _ => return None,
    })
}

// ⟦𓄂𓍮𓃃𓄶⟧ default_base_url :: auto-generated pointer for public function default_base_url
pub fn default_base_url(provider: &str) -> Option<&'static str> {
    Some(match provider {
        "anthropic" => "https://api.anthropic.com/v1",
        "openai" => "https://api.openai.com/v1",
        "groq" => "https://api.groq.com/openai/v1",
        "cerebras" => "https://api.cerebras.ai/v1",
        "deepseek" => "https://api.deepseek.com/v1",
        "zai" => "https://api.z.ai/api/paas/v4",
        "ollama" => "http://localhost:11434",
        "litellm" => "https://inference.noizu.com/v1",
        _ => return None,
    })
}

// ⟦𓌐𓌉𓂜𓌰⟧ env_var_fallbacks :: auto-generated pointer for public function env_var_fallbacks
pub fn env_var_fallbacks(provider: &str) -> Option<&'static [&'static str]> {
    Some(match provider {
        "zai" => &["ZAI_API_KEY", "ZHIPU_API_KEY"],
        "litellm" => &["LITELLM_API_KEY", "OPENAI_API_KEY"],
        _ => return None,
    })
}

// ⟦𓀑𓂒𓃾𓉦⟧ needs_api_key :: auto-generated pointer for public function needs_api_key
pub fn needs_api_key(provider: &str) -> bool {
    matches!(
        provider,
        "anthropic" | "openai" | "groq" | "cerebras" | "deepseek" | "zai" | "litellm" | "custom"
    )
}

// ⟦𓌩𓆡𓂋𓉅⟧ needs_base_url :: auto-generated pointer for public function needs_base_url
pub fn needs_base_url(provider: &str) -> bool {
    matches!(provider, "ollama" | "litellm" | "custom")
}

/// Return the variable name from an ASCII `env:` reference without slicing at
/// an arbitrary UTF-8 byte offset.
pub(crate) fn env_reference(value: &str) -> Option<&str> {
    let prefix = value.get(..4)?;
    if prefix.eq_ignore_ascii_case("env:") {
        value.get(4..).map(str::trim)
    } else {
        None
    }
}

impl LlmConfig {
    // ⟦𓍂𓋚𓐮𓆊⟧ effective_model :: auto-generated pointer for public function effective_model
    pub fn effective_model(&self) -> String {
        self.model
            .as_deref()
            .map(str::trim)
            .filter(|m| !m.is_empty())
            .map(String::from)
            .or_else(|| default_model(&self.provider).map(String::from))
            .unwrap_or_else(|| "claude-sonnet-4-20250514".into())
    }

    // ⟦𓈴𓈮𓌑𓇴⟧ effective_api_key :: auto-generated pointer for public function effective_api_key
    pub fn effective_api_key(&self) -> Option<String> {
        if let Some(key) = self.api_key.as_deref().map(str::trim).filter(|k| !k.is_empty()) {
            if let Some(var_name) = env_reference(key) {
                return env_resolver::resolve(var_name);
            }
            if secret_store::is_encrypted(key) {
                return secret_store::decrypt(key);
            }
            return Some(key.to_string());
        }
        if let Some(fallbacks) = env_var_fallbacks(&self.provider) {
            for var in fallbacks {
                if let Some(val) = env_resolver::resolve(var) {
                    return Some(val);
                }
            }
        } else if let Some(var) = env_var_key(&self.provider) {
            if let Some(val) = env_resolver::resolve(var) {
                return Some(val);
            }
        }
        None
    }

    // ⟦𓐣𓌆𓅽𓁿⟧ effective_base_url :: auto-generated pointer for public function effective_base_url
    pub fn effective_base_url(&self) -> Option<String> {
        if let Some(url) = self.base_url.as_deref().map(str::trim).filter(|u| !u.is_empty()) {
            return Some(url.to_string());
        }
        default_base_url(&self.provider).map(String::from)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn effective_model_falls_back_per_provider() {
        let c = LlmConfig { provider: "ollama".into(), ..Default::default() };
        assert_eq!(c.effective_model(), "llama3");
        let c = LlmConfig { provider: "unknown".into(), ..Default::default() };
        assert_eq!(c.effective_model(), "claude-sonnet-4-20250514");
    }

    #[test]
    fn effective_base_url_defaults() {
        let c = LlmConfig { provider: "litellm".into(), ..Default::default() };
        assert_eq!(c.effective_base_url().as_deref(), Some("https://inference.noizu.com/v1"));
        let c = LlmConfig { provider: "litellm".into(), base_url: Some("http://x/v1".into()), ..Default::default() };
        assert_eq!(c.effective_base_url().as_deref(), Some("http://x/v1"));
    }

    #[test]
    fn env_key_reference_resolves() {
        std::env::set_var("QP_TEST_KEY_XYZ", "sk-test");
        let c = LlmConfig {
            provider: "custom".into(),
            api_key: Some("env:QP_TEST_KEY_XYZ".into()),
            ..Default::default()
        };
        assert_eq!(c.effective_api_key().as_deref(), Some("sk-test"));
    }

    #[test]
    fn plain_key_passthrough() {
        let c = LlmConfig { api_key: Some("sk-plain".into()), ..Default::default() };
        assert_eq!(c.effective_api_key().as_deref(), Some("sk-plain"));
    }

    #[test]
    fn effective_values_ignore_surrounding_whitespace() {
        let c = LlmConfig {
            provider: "ollama".into(),
            model: Some("   ".into()),
            api_key: Some("  token  ".into()),
            base_url: Some("  http://localhost:11434/  ".into()),
            ..Default::default()
        };
        assert_eq!(c.effective_model(), "llama3");
        assert_eq!(c.effective_api_key().as_deref(), Some("token"));
        assert_eq!(c.effective_base_url().as_deref(), Some("http://localhost:11434/"));
    }

    #[test]
    fn unicode_api_keys_never_panic_during_env_prefix_detection() {
        for key in ["a🔒", "éaé", "密钥", "🔑token"] {
            let c = LlmConfig {
                api_key: Some(key.into()),
                ..Default::default()
            };
            assert_eq!(c.effective_api_key().as_deref(), Some(key));
            assert_eq!(env_reference(key), None);
        }
        assert_eq!(env_reference("EnV: TOKEN "), Some("TOKEN"));
    }
}
