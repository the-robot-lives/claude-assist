//! Port of Sources/LLM/PromptBuilder.swift — prompt text copied verbatim.

use crate::llm::response::ProposedEntry;
use crate::queue::manifest;

pub fn classification_prompt(transcript: &str, system_override: Option<&str>) -> (String, String) {
    let system = system_override
        .map(String::from)
        .unwrap_or_else(default_system_prompt);
    let user = format!("USER MEMO TRANSCRIPT:\n{transcript}");
    (system, user)
}

pub fn revision_prompt(
    original: &[ProposedEntry],
    revision: &str,
    system_override: Option<&str>,
) -> (String, String) {
    let system = system_override
        .map(String::from)
        .unwrap_or_else(default_system_prompt);

    let entries_json = sorted_pretty_json(original).unwrap_or_else(|_| "[]".into());

    let user = format!(
        "You previously classified a voice memo into the following entries:\n\
         \n\
         PREVIOUS ENTRIES:\n\
         {entries_json}\n\
         \n\
         The user has provided revision instructions:\n\
         \n\
         REVISION INSTRUCTIONS:\n\
         {revision}\n\
         \n\
         Apply the user's revisions. You may add, remove, modify, or re-route entries.\n\
         Return the same JSON format as before with the corrected entries."
    );
    (system, user)
}

/// Pretty-print with sorted keys, mirroring the Swift JSONEncoder output.
pub fn sorted_pretty_json(entries: &[ProposedEntry]) -> serde_json::Result<String> {
    let value = serde_json::to_value(entries)?;
    let sorted = sort_value(value);
    serde_json::to_string_pretty(&sorted)
}

fn sort_value(value: serde_json::Value) -> serde_json::Value {
    match value {
        serde_json::Value::Object(map) => {
            let mut keys: Vec<String> = map.keys().cloned().collect();
            keys.sort();
            let mut sorted = serde_json::Map::new();
            for key in keys {
                sorted.insert(key.clone(), sort_value(map[&key].clone()));
            }
            serde_json::Value::Object(sorted)
        }
        serde_json::Value::Array(items) => {
            serde_json::Value::Array(items.into_iter().map(sort_value).collect())
        }
        other => other,
    }
}

fn default_system_prompt() -> String {
    format!(
        r#"You are a queue classifier. You receive voice-transcribed memos and classify them into structured queue entries.

RULES:
1. A single memo may produce multiple entries routed to different queues.
2. Each entry must include: "file" (relative path from the list below), "type" (short descriptor like "idea", "task", "reminder", "question", "study", "goal"), "text" (cleaned version of the relevant portion).
3. Preserve the user's intent. Clean up speech artifacts (um, uh, like, you know) but do not rephrase substantially.
4. If the memo is ambiguous about which queue to use, prefer the most specific queue. If truly ambiguous, use binlog.jsonl.
5. The "file" field MUST be one of the paths listed below. Do not invent new paths.
6. Return ONLY valid JSON — no markdown fences, no commentary outside the JSON object.

OUTPUT FORMAT:
{{"entries": [{{"file": "ideas/tools.jsonl", "type": "idea", "text": "Build a CLI that auto-generates changelogs from conventional commits"}}], "reasoning": "Brief explanation of classification choices"}}

AVAILABLE QUEUES:
{}"#,
        manifest::manifest_text()
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn classification_prompt_embeds_manifest() {
        let (system, user) = classification_prompt("buy milk", None);
        assert!(system.contains("AVAILABLE QUEUES:"));
        assert!(system.contains("- binlog.jsonl"));
        assert_eq!(user, "USER MEMO TRANSCRIPT:\nbuy milk");
    }

    #[test]
    fn system_override_respected() {
        let (system, _) = classification_prompt("x", Some("custom prompt"));
        assert_eq!(system, "custom prompt");
    }

    #[test]
    fn revision_prompt_includes_entries_and_instructions() {
        let original = vec![ProposedEntry {
            file: "todo.jsonl".into(),
            entry_type: "todo".into(),
            text: "buy milk".into(),
        }];
        let (_, user) = revision_prompt(&original, "make it oat milk", None);
        assert!(user.contains("PREVIOUS ENTRIES:"));
        assert!(user.contains("\"file\": \"todo.jsonl\""));
        assert!(user.contains("REVISION INSTRUCTIONS:\nmake it oat milk"));
    }
}
