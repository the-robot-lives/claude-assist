//! Port of Sources/Queue/QueueWriter.swift — validate against the manifest,
//! create directories, append one sorted-key JSON line per entry.

use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::Path;

use anyhow::{bail, Context, Result};

use super::entry::QueueEntry;
use super::manifest;
use crate::llm::response::ProposedEntry;

/// Serialize with alphabetically sorted keys to match the macOS JSONEncoder
/// `.sortedKeys` output (processed, source, text, ts, type).
fn sorted_json_line(entry: &QueueEntry) -> Result<String> {
    let value = serde_json::to_value(entry)?;
    let obj = value.as_object().context("entry did not serialize to an object")?;
    let mut keys: Vec<&String> = obj.keys().collect();
    keys.sort();
    let mut sorted = serde_json::Map::new();
    for key in keys {
        sorted.insert(key.clone(), obj[key].clone());
    }
    Ok(serde_json::to_string(&serde_json::Value::Object(sorted))?)
}

pub fn append(entry: &QueueEntry, relative_path: &str, base_path: &str) -> Result<()> {
    if !manifest::is_valid_path(relative_path) {
        bail!("invalid queue path: {relative_path}");
    }

    let full_path = Path::new(base_path).join(relative_path);
    if let Some(dir) = full_path.parent() {
        fs::create_dir_all(dir).with_context(|| format!("cannot create {}", dir.display()))?;
    }

    let line = sorted_json_line(entry)? + "\n";
    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(&full_path)
        .with_context(|| format!("cannot open {}", full_path.display()))?;
    file.write_all(line.as_bytes())
        .with_context(|| format!("cannot append to {}", full_path.display()))?;
    Ok(())
}

pub fn append_all(entries: &[ProposedEntry], base_path: &str) -> Result<usize> {
    // Validate the complete batch before touching the filesystem. The LLM
    // path normally validates these too, but this public writer must not leave
    // a partial batch behind when called from another source.
    if let Some(invalid) = entries
        .iter()
        .map(|entry| entry.file.as_str())
        .find(|path| !manifest::is_valid_path(path))
    {
        bail!("invalid queue path: {invalid}");
    }

    let mut written = 0;
    for proposed in entries {
        let entry = QueueEntry::create(&proposed.entry_type, &proposed.text, "voice");
        append(&entry, &proposed.file, base_path)?;
        written += 1;
    }
    Ok(written)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn append_creates_dirs_and_sorted_line() {
        let dir = tempfile::tempdir().unwrap();
        let base = dir.path().to_str().unwrap();
        let entry = QueueEntry {
            ts: "2026-07-05T00:00:00Z".into(),
            entry_type: "idea".into(),
            text: "build a thing".into(),
            source: "voice".into(),
            processed: false,
        };
        append(&entry, "ideas/tools.jsonl", base).unwrap();
        let content = std::fs::read_to_string(dir.path().join("ideas/tools.jsonl")).unwrap();
        assert_eq!(
            content,
            "{\"processed\":false,\"source\":\"voice\",\"text\":\"build a thing\",\"ts\":\"2026-07-05T00:00:00Z\",\"type\":\"idea\"}\n"
        );
    }

    #[test]
    fn append_is_additive() {
        let dir = tempfile::tempdir().unwrap();
        let base = dir.path().to_str().unwrap();
        let entry = QueueEntry::create("task", "one", "voice");
        append(&entry, "tasks.jsonl", base).unwrap();
        append(&entry, "tasks.jsonl", base).unwrap();
        let content = std::fs::read_to_string(dir.path().join("tasks.jsonl")).unwrap();
        assert_eq!(content.lines().count(), 2);
    }

    #[test]
    fn invalid_path_rejected() {
        let dir = tempfile::tempdir().unwrap();
        let base = dir.path().to_str().unwrap();
        let entry = QueueEntry::create("task", "x", "voice");
        assert!(append(&entry, "evil.jsonl", base).is_err());
        assert!(append(&entry, "../escape.jsonl", base).is_err());
    }

    #[test]
    fn append_all_counts() {
        let dir = tempfile::tempdir().unwrap();
        let base = dir.path().to_str().unwrap();
        let entries = vec![
            ProposedEntry { file: "todo.jsonl".into(), entry_type: "todo".into(), text: "a".into() },
            ProposedEntry { file: "reminders.jsonl".into(), entry_type: "reminder".into(), text: "b".into() },
        ];
        assert_eq!(append_all(&entries, base).unwrap(), 2);
    }

    #[test]
    fn append_all_rejects_batch_before_any_write() {
        let dir = tempfile::tempdir().unwrap();
        let base = dir.path().to_str().unwrap();
        let entries = vec![
            ProposedEntry { file: "todo.jsonl".into(), entry_type: "todo".into(), text: "valid first".into() },
            ProposedEntry { file: "../escape.jsonl".into(), entry_type: "todo".into(), text: "invalid second".into() },
        ];

        assert!(append_all(&entries, base).is_err());
        assert!(!dir.path().join("todo.jsonl").exists());
    }
}
