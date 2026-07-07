//! Port of Sources/Recognition/PhraseDetector.swift, plus light fuzzy matching
//! to absorb ASR wobble (e.g. "hey robots", "that is al").
//!
//! Matching is case-insensitive substring first (same as macOS), then a
//! token-window Levenshtein pass allowing 1 edit per word of the phrase.

use crate::config::PhrasesConfig;
use crate::state_machine::{AppEvent, AppState, MicTarget};

pub struct PhraseDetector {
    phrases: PhrasesConfig,
    fired_this_cycle: bool,
}

impl PhraseDetector {
    pub fn new(phrases: PhrasesConfig) -> Self {
        Self { phrases, fired_this_cycle: false }
    }

    pub fn reset(&mut self) {
        self.fired_this_cycle = false;
    }

    pub fn detect(&mut self, transcript: &str, state: &AppState) -> Option<AppEvent> {
        if self.fired_this_cycle {
            return None;
        }

        let lower = transcript.to_lowercase();

        // Virtual-mic commands are handled while idle (not mid-memo). Close is
        // checked before open so "robot close X" isn't shadowed by "robot open".
        if *state == AppState::Idle {
            if let Some(event) = self.detect_mic_command(&lower) {
                self.fired_this_cycle = true;
                return Some(event);
            }
        }

        let phrases = self.phrases.clone();
        match state {
            AppState::Idle => {
                if contains_phrase(&lower, &phrases.wake) {
                    self.fired_this_cycle = true;
                    return Some(AppEvent::WakeDetected);
                }
            }
            AppState::Recording => {
                if contains_phrase(&lower, &phrases.cancel) {
                    self.fired_this_cycle = true;
                    return Some(AppEvent::CancelDetected);
                }
                if contains_phrase(&lower, &phrases.end) {
                    self.fired_this_cycle = true;
                    let cleaned = strip_phrase(&phrases.end, transcript);
                    let without_wake = strip_phrase(&phrases.wake, &cleaned);
                    return Some(AppEvent::EndDetected { transcript: without_wake });
                }
            }
            AppState::MemoReview(_) => {
                if contains_phrase(&lower, &phrases.approve_memo) {
                    self.fired_this_cycle = true;
                    return Some(AppEvent::ApproveMemoDetected);
                }
                if contains_phrase(&lower, &phrases.cancel) {
                    self.fired_this_cycle = true;
                    return Some(AppEvent::CancelDetected);
                }
            }
            AppState::Review(_) => {
                if contains_phrase(&lower, &phrases.approve) {
                    self.fired_this_cycle = true;
                    return Some(AppEvent::ApproveDetected);
                }
                if contains_phrase(&lower, &phrases.revise) {
                    self.fired_this_cycle = true;
                    return Some(AppEvent::ReviseDetected);
                }
                if contains_phrase(&lower, &phrases.cancel) {
                    self.fired_this_cycle = true;
                    return Some(AppEvent::CancelDetected);
                }
            }
            AppState::Revising(_) => {
                if contains_phrase(&lower, &phrases.cancel) {
                    self.fired_this_cycle = true;
                    return Some(AppEvent::CancelDetected);
                }
                if contains_phrase(&lower, &phrases.end) {
                    self.fired_this_cycle = true;
                    let cleaned = strip_phrase(&phrases.end, transcript);
                    return Some(AppEvent::EndDetected { transcript: cleaned });
                }
            }
            AppState::Processing => {}
        }

        None
    }

    fn detect_mic_command(&self, lower: &str) -> Option<AppEvent> {
        let p = &self.phrases;
        if contains_phrase(lower, &p.close_claude) { return Some(AppEvent::MicClose(MicTarget::Claude)); }
        if contains_phrase(lower, &p.close_codex) { return Some(AppEvent::MicClose(MicTarget::Codex)); }
        if contains_phrase(lower, &p.close_llama) { return Some(AppEvent::MicClose(MicTarget::Llama)); }
        if contains_phrase(lower, &p.open_claude) { return Some(AppEvent::MicOpen(MicTarget::Claude)); }
        if contains_phrase(lower, &p.open_codex) { return Some(AppEvent::MicOpen(MicTarget::Codex)); }
        if contains_phrase(lower, &p.open_llama) { return Some(AppEvent::MicOpen(MicTarget::Llama)); }
        None
    }
}

/// Exact (substring) match first, then fuzzy token-window match.
pub fn contains_phrase(lower_text: &str, lower_phrase: &str) -> bool {
    if lower_phrase.is_empty() {
        return false;
    }
    if lower_text.contains(lower_phrase) {
        return true;
    }
    fuzzy_window_match(lower_text, lower_phrase).is_some()
}

/// Slide a window of `phrase` word-count over the text tokens; match when each
/// aligned word is within an edit distance budget (1 edit per word of length
/// >= 4, exact match required for shorter words).
fn fuzzy_window_match(lower_text: &str, lower_phrase: &str) -> Option<(usize, usize)> {
    let phrase_words: Vec<&str> = lower_phrase.split_whitespace().collect();
    if phrase_words.is_empty() {
        return None;
    }
    let text_words: Vec<&str> = lower_text.split_whitespace().collect();
    if text_words.len() < phrase_words.len() {
        return None;
    }

    // Phrase-level budget for 3+-word phrases: tolerate a small number of
    // edits across the joined window (catches truncated finals like
    // "that is al"). Two-word commands stay strict per-word so short words
    // ("hey", "robot") can't drift.
    let phrase_budget = if phrase_words.len() >= 3 {
        (lower_phrase.chars().count() / 8).max(1)
    } else {
        0
    };

    for start in 0..=(text_words.len() - phrase_words.len()) {
        let window: Vec<String> = (0..phrase_words.len())
            .map(|i| strip_punctuation(text_words[start + i]))
            .collect();

        let per_word_ok = phrase_words.iter().zip(&window).all(|(phrase_word, text_word)| {
            let budget = if phrase_word.chars().count() >= 4 { 1 } else { 0 };
            levenshtein(text_word, phrase_word) <= budget
        });

        let phrase_ok = phrase_budget > 0
            && levenshtein(&window.join(" "), lower_phrase) <= phrase_budget;

        if per_word_ok || phrase_ok {
            return Some((start, start + phrase_words.len()));
        }
    }
    None
}

fn strip_punctuation(word: &str) -> String {
    word.trim_matches(|c: char| !c.is_alphanumeric()).to_string()
}

fn levenshtein(a: &str, b: &str) -> usize {
    let a: Vec<char> = a.chars().collect();
    let b: Vec<char> = b.chars().collect();
    if a.is_empty() { return b.len(); }
    if b.is_empty() { return a.len(); }

    let mut prev: Vec<usize> = (0..=b.len()).collect();
    let mut curr = vec![0usize; b.len() + 1];
    for (i, ca) in a.iter().enumerate() {
        curr[0] = i + 1;
        for (j, cb) in b.iter().enumerate() {
            let cost = usize::from(ca != cb);
            curr[j + 1] = (prev[j + 1] + 1).min(curr[j] + 1).min(prev[j] + cost);
        }
        std::mem::swap(&mut prev, &mut curr);
    }
    prev[b.len()]
}

/// Case-insensitive removal of every occurrence of `phrase` (exact substring),
/// then trim — mirrors the Swift stripPhrase. Fuzzy variants of the phrase are
/// also removed when found via the token-window match.
pub fn strip_phrase(phrase: &str, text: &str) -> String {
    let lower_phrase = phrase.to_lowercase();
    if lower_phrase.is_empty() {
        return text.trim().to_string();
    }

    // Exact case-insensitive removal.
    let mut result = String::with_capacity(text.len());
    let lower_text = text.to_lowercase();
    let mut cursor = 0;
    while let Some(pos) = lower_text[cursor..].find(&lower_phrase) {
        let abs = cursor + pos;
        result.push_str(&text[cursor..abs]);
        cursor = abs + lower_phrase.len();
    }
    result.push_str(&text[cursor..]);

    // Fuzzy removal of a remaining near-match window (one pass is enough for
    // command phrases at the edges of a memo).
    let lower_result = result.to_lowercase();
    if let Some((start, end)) = fuzzy_window_match(&lower_result, &lower_phrase) {
        let words: Vec<&str> = result.split_whitespace().collect();
        let kept: Vec<&str> = words
            .iter()
            .enumerate()
            .filter(|(i, _)| *i < start || *i >= end)
            .map(|(_, w)| *w)
            .collect();
        result = kept.join(" ");
    }

    result.trim().to_string()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::llm::response::ProposedEntry;

    fn detector() -> PhraseDetector {
        PhraseDetector::new(PhrasesConfig::default())
    }

    #[test]
    fn wake_detected_in_idle() {
        let mut d = detector();
        let ev = d.detect("okay hey robot let's go", &AppState::Idle);
        assert_eq!(ev, Some(AppEvent::WakeDetected));
    }

    #[test]
    fn fired_latch_blocks_until_reset() {
        let mut d = detector();
        assert!(d.detect("hey robot", &AppState::Idle).is_some());
        assert!(d.detect("hey robot", &AppState::Idle).is_none());
        d.reset();
        assert!(d.detect("hey robot", &AppState::Idle).is_some());
    }

    #[test]
    fn fuzzy_wake_variants() {
        let mut d = detector();
        assert_eq!(d.detect("hey robots", &AppState::Idle), Some(AppEvent::WakeDetected));
        d.reset();
        assert_eq!(d.detect("hey robut please", &AppState::Idle), Some(AppEvent::WakeDetected));
        d.reset();
        // "hey" is short → exact required
        assert_eq!(d.detect("hay robot", &AppState::Idle), None);
    }

    #[test]
    fn close_checked_before_open() {
        let mut d = detector();
        let ev = d.detect("robot close claude", &AppState::Idle);
        assert_eq!(ev, Some(AppEvent::MicClose(MicTarget::Claude)));
    }

    #[test]
    fn mic_commands_only_in_idle() {
        let mut d = detector();
        let ev = d.detect("robot open claude", &AppState::Recording);
        assert_eq!(ev, None);
    }

    #[test]
    fn mic_open_targets() {
        for (text, target) in [
            ("robot open claude", MicTarget::Claude),
            ("robot open codex", MicTarget::Codex),
            ("robot open llama", MicTarget::Llama),
        ] {
            let mut d = detector();
            assert_eq!(d.detect(text, &AppState::Idle), Some(AppEvent::MicOpen(target)), "{text}");
        }
    }

    #[test]
    fn cancel_beats_end_in_recording() {
        let mut d = detector();
        let ev = d.detect("cancel that is all", &AppState::Recording);
        assert_eq!(ev, Some(AppEvent::CancelDetected));
    }

    #[test]
    fn end_strips_wake_and_end() {
        let mut d = detector();
        let ev = d.detect("hey robot buy milk that is all", &AppState::Recording);
        assert_eq!(ev, Some(AppEvent::EndDetected { transcript: "buy milk".into() }));
    }

    #[test]
    fn review_phrases() {
        let entries = vec![ProposedEntry { file: "todo.jsonl".into(), entry_type: "t".into(), text: "x".into() }];
        let state = AppState::Review(entries);
        let mut d = detector();
        assert_eq!(d.detect("looks good", &state), Some(AppEvent::ApproveDetected));
        let mut d = detector();
        assert_eq!(d.detect("revise that", &state), Some(AppEvent::ReviseDetected));
        let mut d = detector();
        assert_eq!(d.detect("cancel that", &state), Some(AppEvent::CancelDetected));
    }

    #[test]
    fn memo_review_phrases() {
        let state = AppState::MemoReview("x".into());
        let mut d = detector();
        assert_eq!(d.detect("approve memo", &state), Some(AppEvent::ApproveMemoDetected));
        let mut d = detector();
        assert_eq!(d.detect("cancel that", &state), Some(AppEvent::CancelDetected));
    }

    #[test]
    fn nothing_in_processing() {
        let mut d = detector();
        assert_eq!(d.detect("hey robot cancel that looks good", &AppState::Processing), None);
    }

    #[test]
    fn strip_phrase_exact_and_fuzzy() {
        assert_eq!(strip_phrase("that is all", "buy milk that is all"), "buy milk");
        assert_eq!(strip_phrase("that is all", "buy milk that is al"), "buy milk");
        assert_eq!(strip_phrase("hey robot", "Hey Robot buy milk"), "buy milk");
    }

    #[test]
    fn levenshtein_sanity() {
        assert_eq!(levenshtein("robot", "robot"), 0);
        assert_eq!(levenshtein("robot", "robut"), 1);
        assert_eq!(levenshtein("robot", "rowboat"), 2);
        assert_eq!(levenshtein("", "abc"), 3);
    }
}
