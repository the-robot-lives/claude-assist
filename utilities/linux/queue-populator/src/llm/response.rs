//! Port of Sources/LLM/LlmResponse.swift.

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct ProposedEntry {
    pub file: String,
    #[serde(rename = "type")]
    pub entry_type: String,
    pub text: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ClassificationResponse {
    pub entries: Vec<ProposedEntry>,
    #[serde(default)]
    pub reasoning: Option<String>,
}

#[derive(Debug, Clone)]
pub struct ClassificationResult {
    pub response: ClassificationResponse,
    pub raw_text: String,
}
