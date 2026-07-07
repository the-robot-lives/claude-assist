//! Port of Sources/Config/QueuePopulatorConfig.swift (+ AppConfig).
//! The JSON schema matches the macOS app so config files interchange.

pub mod debug_log;
pub mod env_resolver;
pub mod llm;
pub mod secret_store;
pub mod store;

use serde::{Deserialize, Serialize};

use llm::LlmConfig;

fn default_wake() -> String { "hey robot".into() }
fn default_end() -> String { "that is all".into() }
fn default_approve_memo() -> String { "approve memo".into() }
fn default_cancel() -> String { "cancel that".into() }
fn default_approve() -> String { "looks good".into() }
fn default_revise() -> String { "revise that".into() }
fn default_open_claude() -> String { "robot open claude".into() }
fn default_close_claude() -> String { "robot close claude".into() }
fn default_open_codex() -> String { "robot open codex".into() }
fn default_close_codex() -> String { "robot close codex".into() }
fn default_open_llama() -> String { "robot open llama".into() }
fn default_close_llama() -> String { "robot close llama".into() }

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(default)]
pub struct PhrasesConfig {
    pub wake: String,
    pub end: String,
    #[serde(rename = "approveMemo")]
    pub approve_memo: String,
    pub cancel: String,
    pub approve: String,
    pub revise: String,
    #[serde(rename = "openClaude")]
    pub open_claude: String,
    #[serde(rename = "closeClaude")]
    pub close_claude: String,
    #[serde(rename = "openCodex")]
    pub open_codex: String,
    #[serde(rename = "closeCodex")]
    pub close_codex: String,
    #[serde(rename = "openLlama")]
    pub open_llama: String,
    #[serde(rename = "closeLlama")]
    pub close_llama: String,
}

impl Default for PhrasesConfig {
    fn default() -> Self {
        Self {
            wake: default_wake(),
            end: default_end(),
            approve_memo: default_approve_memo(),
            cancel: default_cancel(),
            approve: default_approve(),
            revise: default_revise(),
            open_claude: default_open_claude(),
            close_claude: default_close_claude(),
            open_codex: default_open_codex(),
            close_codex: default_close_codex(),
            open_llama: default_open_llama(),
            close_llama: default_close_llama(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(default)]
pub struct RecognitionConfig {
    pub locale: String,
    #[serde(rename = "onDevice")]
    pub on_device: bool,
    #[serde(rename = "maxRecordingSeconds")]
    pub max_recording_seconds: u32,
    #[serde(rename = "inputDeviceId")]
    pub input_device_id: Option<String>,
}

impl Default for RecognitionConfig {
    fn default() -> Self {
        Self {
            locale: "en-US".into(),
            on_device: true,
            max_recording_seconds: 300,
            input_device_id: None,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(default)]
pub struct UiConfig {
    #[serde(rename = "overlayDismissSeconds")]
    pub overlay_dismiss_seconds: f64,
    #[serde(rename = "showTranscriptWindow")]
    pub show_transcript_window: bool,
}

impl Default for UiConfig {
    fn default() -> Self {
        Self {
            overlay_dismiss_seconds: 3.0,
            show_transcript_window: true,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Default)]
#[serde(default)]
pub struct QueuePopulatorConfig {
    pub llm: LlmConfig,
    pub phrases: PhrasesConfig,
    #[serde(rename = "queueBasePath")]
    pub queue_base_path: String,
    #[serde(rename = "systemPromptOverride")]
    pub system_prompt_override: Option<String>,
    pub recognition: RecognitionConfig,
    pub ui: UiConfig,
}

pub fn expand_tilde(path: &str) -> String {
    if let Some(rest) = path.strip_prefix("~/") {
        if let Some(home) = dirs::home_dir() {
            return home.join(rest).to_string_lossy().into_owned();
        }
    } else if path == "~" {
        if let Some(home) = dirs::home_dir() {
            return home.to_string_lossy().into_owned();
        }
    }
    path.to_string()
}

impl QueuePopulatorConfig {
    pub fn default_queue_base_path() -> String {
        "~/personal-development/queue".into()
    }

    pub fn resolved_queue_base_path(&self) -> String {
        expand_tilde(&self.queue_base_path)
    }

    pub fn sanitized(&self) -> Self {
        let mut copy = self.clone();
        let defaults = PhrasesConfig::default();

        fn phrase(value: &str, fallback: &str) -> String {
            let trimmed = value.to_lowercase().trim().to_string();
            if trimmed.is_empty() { fallback.to_string() } else { trimmed }
        }

        copy.phrases.wake = phrase(&copy.phrases.wake, &defaults.wake);
        copy.phrases.end = phrase(&copy.phrases.end, &defaults.end);
        copy.phrases.approve_memo = phrase(&copy.phrases.approve_memo, &defaults.approve_memo);
        copy.phrases.cancel = phrase(&copy.phrases.cancel, &defaults.cancel);
        copy.phrases.approve = phrase(&copy.phrases.approve, &defaults.approve);
        copy.phrases.revise = phrase(&copy.phrases.revise, &defaults.revise);
        copy.phrases.open_claude = phrase(&copy.phrases.open_claude, &defaults.open_claude);
        copy.phrases.close_claude = phrase(&copy.phrases.close_claude, &defaults.close_claude);
        copy.phrases.open_codex = phrase(&copy.phrases.open_codex, &defaults.open_codex);
        copy.phrases.close_codex = phrase(&copy.phrases.close_codex, &defaults.close_codex);
        copy.phrases.open_llama = phrase(&copy.phrases.open_llama, &defaults.open_llama);
        copy.phrases.close_llama = phrase(&copy.phrases.close_llama, &defaults.close_llama);
        if copy.queue_base_path.trim().is_empty() {
            copy.queue_base_path = Self::default_queue_base_path();
        }
        copy
    }
}

/// Command-line options (port of Sources/Config/AppConfig.swift; --authorize → --check).
#[derive(Debug, Clone, Default)]
pub struct AppConfig {
    pub check: bool,
    pub verbose: bool,
}

impl AppConfig {
    pub fn parse(args: impl Iterator<Item = String>) -> Result<Self, String> {
        let mut cfg = AppConfig::default();
        for arg in args {
            match arg.as_str() {
                "--check" => cfg.check = true,
                "--verbose" | "-v" => cfg.verbose = true,
                "--help" | "-h" => {
                    return Err(concat!(
                        "usage: queue-populator [--check] [--verbose]\n",
                        "  --check    verify audio devices and STT models are available, then exit\n",
                        "  --verbose  extra stderr logging\n",
                    )
                    .to_string())
                }
                other => return Err(format!("unknown argument: {other}")),
            }
        }
        Ok(cfg)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn defaults_match_macos() {
        let c = QueuePopulatorConfig { queue_base_path: QueuePopulatorConfig::default_queue_base_path(), ..Default::default() };
        assert_eq!(c.phrases.wake, "hey robot");
        assert_eq!(c.phrases.end, "that is all");
        assert_eq!(c.phrases.open_claude, "robot open claude");
        assert_eq!(c.queue_base_path, "~/personal-development/queue");
        assert_eq!(c.recognition.locale, "en-US");
        assert_eq!(c.ui.overlay_dismiss_seconds, 3.0);
    }

    #[test]
    fn sanitize_lowercases_and_falls_back() {
        let mut c = QueuePopulatorConfig::default();
        c.phrases.wake = "  HEY Robot  ".into();
        c.phrases.end = "   ".into();
        c.queue_base_path = " ".into();
        let s = c.sanitized();
        assert_eq!(s.phrases.wake, "hey robot");
        assert_eq!(s.phrases.end, "that is all");
        assert_eq!(s.queue_base_path, "~/personal-development/queue");
    }

    #[test]
    fn tolerant_decode_fills_defaults() {
        let json = r#"{"phrases": {"wake": "yo computer"}, "llm": {"provider": "ollama"}}"#;
        let c: QueuePopulatorConfig = serde_json::from_str(json).unwrap();
        assert_eq!(c.phrases.wake, "yo computer");
        assert_eq!(c.phrases.end, "that is all");
        assert_eq!(c.llm.provider, "ollama");
    }

    #[test]
    fn camel_case_round_trip() {
        let c = QueuePopulatorConfig::default();
        let json = serde_json::to_string(&c).unwrap();
        assert!(json.contains("approveMemo"));
        assert!(json.contains("queueBasePath"));
        assert!(json.contains("openClaude"));
        let back: QueuePopulatorConfig = serde_json::from_str(&json).unwrap();
        assert_eq!(back, c);
    }
}
