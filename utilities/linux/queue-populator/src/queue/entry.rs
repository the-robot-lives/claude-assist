//! Port of Sources/Queue/QueueEntry.swift.

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct QueueEntry {
    pub ts: String,
    #[serde(rename = "type")]
    pub entry_type: String,
    pub text: String,
    pub source: String,
    pub processed: bool,
}

impl QueueEntry {
    pub fn create(entry_type: &str, text: &str, source: &str) -> Self {
        Self {
            ts: chrono::Utc::now().format("%Y-%m-%dT%H:%M:%SZ").to_string(),
            entry_type: entry_type.to_string(),
            text: text.to_string(),
            source: source.to_string(),
            processed: false,
        }
    }
}
