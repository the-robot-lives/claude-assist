//! Port of Sources/LLM/LlmClient.swift — blocking HTTP via ureq (runs on the
//! coordinator's LLM worker thread).

use std::io::Read;
use std::time::Duration;

use rand::Rng;
use serde_json::json;

use crate::config::llm::{self, LlmConfig};
use crate::llm::response::{ClassificationResponse, ClassificationResult};
use crate::queue::manifest;

const MAX_RETRIES: u32 = 3;
const TIMEOUT: Duration = Duration::from_secs(30);
const MAX_RESPONSE_BYTES: usize = 2 * 1024 * 1024;
const MAX_ERROR_BODY_BYTES: usize = 64 * 1024;

#[derive(Debug)]
pub enum LlmError {
    NoApiKey,
    NoBaseUrl,
    RequestFailed(u16, String),
    Timeout,
    DecodingFailed(String),
    InvalidEntries(Vec<String>),
    EmptyResponse,
    ResponseTooLarge,
    Transport(String),
}

impl std::fmt::Display for LlmError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            LlmError::NoApiKey => write!(f, "No API key configured"),
            LlmError::NoBaseUrl => write!(f, "No base URL configured"),
            LlmError::RequestFailed(code, msg) => write!(f, "HTTP {code}: {msg}"),
            LlmError::Timeout => write!(f, "Request timed out (30s)"),
            LlmError::DecodingFailed(msg) => write!(f, "Failed to parse LLM response: {msg}"),
            LlmError::InvalidEntries(paths) => write!(f, "Invalid queue paths: {}", paths.join(", ")),
            LlmError::EmptyResponse => write!(f, "LLM returned empty response"),
            LlmError::ResponseTooLarge => {
                write!(f, "LLM response exceeded {MAX_RESPONSE_BYTES} bytes")
            }
            LlmError::Transport(msg) => write!(f, "Request failed: {msg}"),
        }
    }
}

impl std::error::Error for LlmError {}

pub struct LlmClient {
    config: LlmConfig,
    agent: ureq::Agent,
}

impl LlmClient {
    pub fn new(config: LlmConfig) -> Self {
        let agent = ureq::AgentBuilder::new()
            .timeout(TIMEOUT)
            .build();
        Self { config, agent }
    }

    pub fn classify_with_trace(&self, system: &str, user: &str) -> Result<ClassificationResult, LlmError> {
        let raw_text = self.send_with_retry(system, user)?;
        let response = parse_and_validate(&raw_text)?;
        Ok(ClassificationResult { response, raw_text })
    }

    fn send_with_retry(&self, system: &str, user: &str) -> Result<String, LlmError> {
        let mut last_error = LlmError::EmptyResponse;
        for attempt in 0..MAX_RETRIES {
            if attempt > 0 {
                let jitter: f64 = rand::thread_rng().gen_range(0.0..0.5);
                let delay = f64::from(1u32 << attempt) + jitter;
                std::thread::sleep(Duration::from_secs_f64(delay));
            }
            match self.send(system, user) {
                Ok(text) => return Ok(text),
                Err(e) => {
                    let retryable = matches!(
                        e,
                        LlmError::Timeout
                            | LlmError::RequestFailed(429, _)
                            | LlmError::RequestFailed(500..=599, _)
                    );
                    if retryable {
                        last_error = e;
                        continue;
                    }
                    return Err(e);
                }
            }
        }
        Err(last_error)
    }

    fn send(&self, system: &str, user: &str) -> Result<String, LlmError> {
        if llm::needs_base_url(&self.config.provider) && self.config.effective_base_url().is_none() {
            return Err(LlmError::NoBaseUrl);
        }
        let api_key = self.config.effective_api_key();
        if llm::needs_api_key(&self.config.provider) && api_key.is_none() {
            return Err(LlmError::NoApiKey);
        }

        if self.config.provider == "anthropic" {
            let api_key = api_key.ok_or(LlmError::NoApiKey)?;
            self.send_anthropic(system, user, &api_key)
        } else {
            self.send_openai_compatible(system, user, api_key.as_deref())
        }
    }

    fn post(&self, url: &str, headers: &[(&str, &str)], body: serde_json::Value) -> Result<serde_json::Value, LlmError> {
        let mut request = self.agent.post(url).set("content-type", "application/json");
        for (name, value) in headers {
            request = request.set(name, value);
        }
        match request.send_json(body) {
            Ok(response) => {
                let (body, truncated) = read_limited(response.into_reader(), MAX_RESPONSE_BYTES)?;
                if truncated {
                    return Err(LlmError::ResponseTooLarge);
                }
                serde_json::from_slice(&body).map_err(|e| LlmError::DecodingFailed(e.to_string()))
            }
            Err(ureq::Error::Status(code, response)) => {
                let (body, truncated) = read_limited(response.into_reader(), MAX_ERROR_BODY_BYTES)?;
                let mut body = String::from_utf8_lossy(&body).into_owned();
                if truncated {
                    body.push_str("… [truncated]");
                }
                Err(LlmError::RequestFailed(code, body))
            }
            Err(ureq::Error::Transport(t)) => {
                let msg = t.to_string();
                if msg.contains("timed out") || msg.contains("timeout") {
                    Err(LlmError::Timeout)
                } else {
                    Err(LlmError::Transport(msg))
                }
            }
        }
    }

    fn send_anthropic(&self, system: &str, user: &str, api_key: &str) -> Result<String, LlmError> {
        let base = self
            .config
            .effective_base_url()
            .unwrap_or_else(|| "https://api.anthropic.com/v1".into());
        let endpoint = join_url(&base, "messages");

        let body = json!({
            "model": self.config.effective_model(),
            "max_tokens": 4096,
            "system": system,
            "messages": [{"role": "user", "content": user}],
        });
        let json = self.post(
            &endpoint,
            &[("x-api-key", api_key), ("anthropic-version", "2023-06-01")],
            body,
        )?;
        json["content"][0]["text"]
            .as_str()
            .map(String::from)
            .ok_or(LlmError::EmptyResponse)
    }

    fn send_openai_compatible(&self, system: &str, user: &str, api_key: Option<&str>) -> Result<String, LlmError> {
        let base = self
            .config
            .effective_base_url()
            .unwrap_or_else(|| "https://api.openai.com/v1".into());
        let endpoint = join_url(&base, "chat/completions");

        let mut body = json!({
            "model": self.config.effective_model(),
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
        });
        if !matches!(self.config.provider.as_str(), "ollama" | "custom") {
            body["response_format"] = json!({"type": "json_object"});
        }

        let auth = api_key.map(|k| format!("Bearer {k}"));
        let mut headers: Vec<(&str, &str)> = Vec::new();
        if let Some(auth) = auth.as_deref() {
            headers.push(("Authorization", auth));
        }
        let json = self.post(&endpoint, &headers, body)?;
        json["choices"][0]["message"]["content"]
            .as_str()
            .map(String::from)
            .ok_or(LlmError::EmptyResponse)
    }
}

fn read_limited(reader: impl Read, limit: usize) -> Result<(Vec<u8>, bool), LlmError> {
    let mut body = Vec::with_capacity(limit.min(16 * 1024));
    reader
        .take((limit as u64).saturating_add(1))
        .read_to_end(&mut body)
        .map_err(|e| LlmError::Transport(e.to_string()))?;
    let truncated = body.len() > limit;
    if truncated {
        body.truncate(limit);
    }
    Ok((body, truncated))
}

fn join_url(base: &str, path: &str) -> String {
    if base.ends_with('/') {
        format!("{base}{path}")
    } else {
        format!("{base}/{path}")
    }
}

pub fn parse_and_validate(text: &str) -> Result<ClassificationResponse, LlmError> {
    let mut cleaned = text.trim();
    if let Some(rest) = cleaned.strip_prefix("```json") {
        cleaned = rest;
    }
    if let Some(rest) = cleaned.strip_prefix("```") {
        cleaned = rest;
    }
    if let Some(rest) = cleaned.strip_suffix("```") {
        cleaned = rest;
    }
    let cleaned = cleaned.trim();

    let response: ClassificationResponse = serde_json::from_str(cleaned).map_err(|e| {
        let preview: String = cleaned.chars().take(200).collect();
        LlmError::DecodingFailed(format!("{e} — response: {preview}"))
    })?;

    let mut invalid: Vec<String> = response
        .entries
        .iter()
        .map(|entry| entry.file.clone())
        .filter(|file| !manifest::is_valid_path(file))
        .collect();
    invalid.sort();
    invalid.dedup();
    if !invalid.is_empty() {
        return Err(LlmError::InvalidEntries(invalid));
    }
    Ok(response)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_plain_json() {
        let text = r#"{"entries": [{"file": "todo.jsonl", "type": "todo", "text": "buy milk"}], "reasoning": "simple"}"#;
        let response = parse_and_validate(text).unwrap();
        assert_eq!(response.entries.len(), 1);
        assert_eq!(response.entries[0].file, "todo.jsonl");
        assert_eq!(response.reasoning.as_deref(), Some("simple"));
    }

    #[test]
    fn parse_strips_code_fences() {
        let text = "```json\n{\"entries\": []}\n```";
        let response = parse_and_validate(text).unwrap();
        assert!(response.entries.is_empty());

        let text = "```\n{\"entries\": []}\n```";
        assert!(parse_and_validate(text).is_ok());
    }

    #[test]
    fn parse_missing_reasoning_ok() {
        let text = r#"{"entries": []}"#;
        assert!(parse_and_validate(text).unwrap().reasoning.is_none());
    }

    #[test]
    fn invalid_paths_rejected() {
        let text = r#"{"entries": [{"file": "made-up.jsonl", "type": "x", "text": "y"}]}"#;
        match parse_and_validate(text) {
            Err(LlmError::InvalidEntries(paths)) => assert_eq!(paths, vec!["made-up.jsonl"]),
            other => panic!("expected InvalidEntries, got {other:?}"),
        }
    }

    #[test]
    fn garbage_reports_preview() {
        match parse_and_validate("not json at all") {
            Err(LlmError::DecodingFailed(msg)) => assert!(msg.contains("not json at all")),
            other => panic!("expected DecodingFailed, got {other:?}"),
        }
    }

    #[test]
    fn cloud_provider_without_key_fails_before_network_request() {
        let client = LlmClient::new(LlmConfig {
            provider: "openai".into(),
            api_key: Some("env:".into()),
            ..Default::default()
        });
        assert!(matches!(client.send("system", "user"), Err(LlmError::NoApiKey)));
    }

    #[test]
    fn custom_provider_requires_base_url() {
        let client = LlmClient::new(LlmConfig {
            provider: "custom".into(),
            api_key: Some("token".into()),
            ..Default::default()
        });
        assert!(matches!(client.send("system", "user"), Err(LlmError::NoBaseUrl)));
    }

    #[test]
    fn response_reader_is_bounded() {
        let (body, truncated) = read_limited(std::io::Cursor::new(b"123456789"), 8).unwrap();
        assert_eq!(body, b"12345678");
        assert!(truncated);

        let (body, truncated) = read_limited(std::io::Cursor::new(b"short"), 8).unwrap();
        assert_eq!(body, b"short");
        assert!(!truncated);
    }
}
