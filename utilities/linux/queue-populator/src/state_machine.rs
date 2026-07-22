//! Port of Sources/StateMachine/{AppState,AppEvent,AppStateMachine}.swift.
//! Pure state transitions — no IO, no UI. The coordinator executes side effects.

use crate::llm::response::ProposedEntry;

/// Virtual microphone routing targets. `Recording` is always fed while
/// listening; the assistants are voice-command controlled and exclusive.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum MicTarget {
    Recording,
    Claude,
    Codex,
    Llama,
}

impl MicTarget {
    // ⟦𓀺𓊣𓀜𓎲⟧ label :: auto-generated pointer for public function label
    pub fn label(&self) -> &'static str {
        match self {
            MicTarget::Recording => "Recording",
            MicTarget::Claude => "Claude",
            MicTarget::Codex => "Codex",
            MicTarget::Llama => "Llama",
        }
    }

    /// PipeWire node.name of the virtual source this target feeds.
    // ⟦𓎐𓈕𓂑𓁫⟧ node_name :: PipeWire node.name of the virtual source this target feeds.
    pub fn node_name(&self) -> &'static str {
        match self {
            MicTarget::Recording => "robot_recording",
            MicTarget::Claude => "robot_claude",
            MicTarget::Codex => "robot_codex",
            MicTarget::Llama => "robot_llama",
        }
    }

    // ⟦𓇡𓐞𓊵𓎨⟧ is_external_assistant :: auto-generated pointer for public function is_external_assistant
    pub fn is_external_assistant(&self) -> bool {
        !matches!(self, MicTarget::Recording)
    }
}

#[derive(Debug, Clone, PartialEq, Default)]
pub enum AppState {
    #[default]
    Idle,
    Recording,
    MemoReview(String),
    Processing,
    Review(Vec<ProposedEntry>),
    Revising(Vec<ProposedEntry>),
}

impl AppState {
    // ⟦𓎆𓍼𓇅𓎷⟧ label :: auto-generated pointer for public function label
    pub fn label(&self) -> &'static str {
        match self {
            AppState::Idle => "Idle",
            AppState::Recording => "Recording",
            AppState::MemoReview(_) => "Memo Review",
            AppState::Processing => "Processing",
            AppState::Review(_) => "Review",
            AppState::Revising(_) => "Revising",
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub enum AppEvent {
    WakeDetected,
    EndDetected { transcript: String },
    ApproveMemoDetected,
    MemoApproved { transcript: String },
    CancelDetected,
    ApproveDetected,
    ReviseDetected,
    LlmCompleted(Vec<ProposedEntry>),
    LlmFailed(String),
    WriteCompleted(usize),
    WriteFailed(String),
    // Handled by the coordinator directly (never reach the state machine):
    MicOpen(MicTarget),
    MicClose(MicTarget),
}

#[derive(Debug, Clone, PartialEq)]
pub enum SideEffect {
    StartRecording,
    StopRecording,
    ShowMemoReview(String),
    HideMemoReview,
    SendToLlm { transcript: String },
    SendRevisionToLlm { original: Vec<ProposedEntry>, revision: String },
    ShowReview(Vec<ProposedEntry>),
    WriteEntries(Vec<ProposedEntry>),
    ShowOverlay(String),
    ShowError(String),
    ReturnToIdle,
}

#[derive(Default)]
pub struct AppStateMachine {
    state: AppState,
}

impl AppStateMachine {
    // ⟦𓌕𓆆𓅩𓅣⟧ new :: auto-generated pointer for public function new
    pub fn new() -> Self {
        Self { state: AppState::Idle }
    }

    // ⟦𓄠𓂼𓎨𓏦⟧ state :: auto-generated pointer for public function state
    pub fn state(&self) -> &AppState {
        &self.state
    }

    // ⟦𓊡𓄊𓎍𓁑⟧ handle :: auto-generated pointer for public function handle
    pub fn handle(&mut self, event: AppEvent) -> Vec<SideEffect> {
        use AppEvent as E;
        use AppState as S;
        use SideEffect as F;

        // Queue writes finish outside the state machine. Always reconcile the
        // internal state as well as the UI when their result comes back.
        match &event {
            E::WriteCompleted(count) => {
                self.state = S::Idle;
                return vec![F::ShowOverlay(format!("Wrote {count} entries")), F::ReturnToIdle];
            }
            E::WriteFailed(error) => {
                self.state = S::Idle;
                return vec![F::ShowError(format!("Write error: {error}")), F::ReturnToIdle];
            }
            _ => {}
        }

        match (self.state.clone(), event) {
            (S::Idle, E::WakeDetected) => {
                self.state = S::Recording;
                vec![F::StartRecording, F::ShowOverlay("Recording...".into())]
            }

            (S::Recording, E::EndDetected { transcript }) => {
                let trimmed = transcript.trim().to_string();
                if trimmed.is_empty() {
                    self.state = S::Idle;
                    vec![F::StopRecording, F::ShowOverlay("Nothing heard".into()), F::ReturnToIdle]
                } else {
                    self.state = S::MemoReview(trimmed.clone());
                    vec![F::StopRecording, F::ShowOverlay("Review memo".into()), F::ShowMemoReview(trimmed)]
                }
            }

            (S::Recording, E::CancelDetected) => {
                self.state = S::Idle;
                vec![F::StopRecording, F::ShowOverlay("Cancelled".into()), F::ReturnToIdle]
            }

            (S::MemoReview(_), E::MemoApproved { transcript }) => {
                let trimmed = transcript.trim().to_string();
                if trimmed.is_empty() {
                    self.state = S::Idle;
                    vec![F::HideMemoReview, F::ShowOverlay("Nothing heard".into()), F::ReturnToIdle]
                } else {
                    self.state = S::Processing;
                    vec![F::HideMemoReview, F::ShowOverlay("Processing...".into()), F::SendToLlm { transcript: trimmed }]
                }
            }

            (S::MemoReview(transcript), E::ApproveMemoDetected) => {
                self.state = S::Processing;
                vec![F::HideMemoReview, F::ShowOverlay("Processing...".into()), F::SendToLlm { transcript }]
            }

            (S::MemoReview(_), E::CancelDetected) => {
                self.state = S::Idle;
                vec![F::HideMemoReview, F::ShowOverlay("Memo discarded".into()), F::ReturnToIdle]
            }

            (S::Processing, E::LlmCompleted(entries)) => {
                if entries.is_empty() {
                    self.state = S::Idle;
                    vec![F::ShowOverlay("No entries classified".into()), F::ReturnToIdle]
                } else {
                    self.state = S::Review(entries.clone());
                    vec![F::ShowReview(entries)]
                }
            }

            (S::Processing, E::LlmFailed(error)) => {
                self.state = S::Idle;
                vec![F::ShowError(error), F::ReturnToIdle]
            }

            (S::Review(entries), E::ApproveDetected) => {
                self.state = S::Idle;
                let count = entries.len();
                // Announce before the synchronous write so its completion or
                // error remains the final status shown to the user.
                vec![F::ShowOverlay(format!("Writing {count} entries...")), F::WriteEntries(entries)]
            }

            (S::Review(entries), E::ReviseDetected) => {
                self.state = S::Revising(entries);
                vec![F::StartRecording, F::ShowOverlay("Recording revision...".into())]
            }

            (S::Review(_), E::CancelDetected) => {
                self.state = S::Idle;
                vec![F::ShowOverlay("Discarded".into()), F::ReturnToIdle]
            }

            (S::Revising(entries), E::EndDetected { transcript }) => {
                let trimmed = transcript.trim().to_string();
                if trimmed.is_empty() {
                    self.state = S::Review(entries.clone());
                    vec![F::StopRecording, F::ShowOverlay("No revision heard".into()), F::ShowReview(entries)]
                } else {
                    self.state = S::Processing;
                    vec![
                        F::StopRecording,
                        F::ShowOverlay("Revising...".into()),
                        F::SendRevisionToLlm { original: entries, revision: trimmed },
                    ]
                }
            }

            (S::Revising(entries), E::CancelDetected) => {
                self.state = S::Review(entries.clone());
                vec![F::StopRecording, F::ShowOverlay("Revision cancelled".into()), F::ShowReview(entries)]
            }

            _ => vec![],
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn entry(file: &str, text: &str) -> ProposedEntry {
        ProposedEntry {
            file: file.into(),
            entry_type: "idea".into(),
            text: text.into(),
        }
    }

    #[test]
    fn wake_starts_recording() {
        let mut sm = AppStateMachine::new();
        let fx = sm.handle(AppEvent::WakeDetected);
        assert_eq!(*sm.state(), AppState::Recording);
        assert_eq!(fx[0], SideEffect::StartRecording);
    }

    #[test]
    fn wake_ignored_outside_idle() {
        let mut sm = AppStateMachine::new();
        sm.handle(AppEvent::WakeDetected);
        let fx = sm.handle(AppEvent::WakeDetected);
        assert!(fx.is_empty());
        assert_eq!(*sm.state(), AppState::Recording);
    }

    #[test]
    fn end_with_empty_transcript_returns_to_idle() {
        let mut sm = AppStateMachine::new();
        sm.handle(AppEvent::WakeDetected);
        let fx = sm.handle(AppEvent::EndDetected { transcript: "   ".into() });
        assert_eq!(*sm.state(), AppState::Idle);
        assert!(fx.contains(&SideEffect::ShowOverlay("Nothing heard".into())));
    }

    #[test]
    fn end_with_memo_enters_memo_review() {
        let mut sm = AppStateMachine::new();
        sm.handle(AppEvent::WakeDetected);
        let fx = sm.handle(AppEvent::EndDetected { transcript: " buy milk ".into() });
        assert_eq!(*sm.state(), AppState::MemoReview("buy milk".into()));
        assert!(fx.contains(&SideEffect::ShowMemoReview("buy milk".into())));
    }

    #[test]
    fn memo_approved_voice_sends_state_transcript() {
        let mut sm = AppStateMachine::new();
        sm.handle(AppEvent::WakeDetected);
        sm.handle(AppEvent::EndDetected { transcript: "buy milk".into() });
        let fx = sm.handle(AppEvent::ApproveMemoDetected);
        assert_eq!(*sm.state(), AppState::Processing);
        assert!(fx.contains(&SideEffect::SendToLlm { transcript: "buy milk".into() }));
    }

    #[test]
    fn memo_approved_button_sends_edited_transcript() {
        let mut sm = AppStateMachine::new();
        sm.handle(AppEvent::WakeDetected);
        sm.handle(AppEvent::EndDetected { transcript: "buy milk".into() });
        let fx = sm.handle(AppEvent::MemoApproved { transcript: "buy oat milk".into() });
        assert!(fx.contains(&SideEffect::SendToLlm { transcript: "buy oat milk".into() }));
    }

    #[test]
    fn memo_cancel_discards() {
        let mut sm = AppStateMachine::new();
        sm.handle(AppEvent::WakeDetected);
        sm.handle(AppEvent::EndDetected { transcript: "x".into() });
        let fx = sm.handle(AppEvent::CancelDetected);
        assert_eq!(*sm.state(), AppState::Idle);
        assert!(fx.contains(&SideEffect::ShowOverlay("Memo discarded".into())));
    }

    #[test]
    fn llm_empty_entries_returns_idle() {
        let mut sm = AppStateMachine::new();
        sm.handle(AppEvent::WakeDetected);
        sm.handle(AppEvent::EndDetected { transcript: "x".into() });
        sm.handle(AppEvent::ApproveMemoDetected);
        let fx = sm.handle(AppEvent::LlmCompleted(vec![]));
        assert_eq!(*sm.state(), AppState::Idle);
        assert!(fx.contains(&SideEffect::ShowOverlay("No entries classified".into())));
    }

    #[test]
    fn llm_failure_shows_error() {
        let mut sm = AppStateMachine::new();
        sm.handle(AppEvent::WakeDetected);
        sm.handle(AppEvent::EndDetected { transcript: "x".into() });
        sm.handle(AppEvent::ApproveMemoDetected);
        let fx = sm.handle(AppEvent::LlmFailed("boom".into()));
        assert_eq!(*sm.state(), AppState::Idle);
        assert!(fx.contains(&SideEffect::ShowError("boom".into())));
    }

    fn drive_to_review(sm: &mut AppStateMachine) -> Vec<ProposedEntry> {
        sm.handle(AppEvent::WakeDetected);
        sm.handle(AppEvent::EndDetected { transcript: "x".into() });
        sm.handle(AppEvent::ApproveMemoDetected);
        let entries = vec![entry("todo.jsonl", "buy milk")];
        sm.handle(AppEvent::LlmCompleted(entries.clone()));
        entries
    }

    #[test]
    fn review_approve_writes() {
        let mut sm = AppStateMachine::new();
        let entries = drive_to_review(&mut sm);
        let fx = sm.handle(AppEvent::ApproveDetected);
        assert_eq!(*sm.state(), AppState::Idle);
        assert_eq!(
            fx,
            vec![
                SideEffect::ShowOverlay("Writing 1 entries...".into()),
                SideEffect::WriteEntries(entries),
            ]
        );
    }

    #[test]
    fn review_revise_records_revision() {
        let mut sm = AppStateMachine::new();
        let entries = drive_to_review(&mut sm);
        let fx = sm.handle(AppEvent::ReviseDetected);
        assert_eq!(*sm.state(), AppState::Revising(entries));
        assert!(fx.contains(&SideEffect::StartRecording));
    }

    #[test]
    fn revising_end_sends_revision() {
        let mut sm = AppStateMachine::new();
        let entries = drive_to_review(&mut sm);
        sm.handle(AppEvent::ReviseDetected);
        let fx = sm.handle(AppEvent::EndDetected { transcript: "route to ideas".into() });
        assert_eq!(*sm.state(), AppState::Processing);
        assert!(fx.contains(&SideEffect::SendRevisionToLlm {
            original: entries,
            revision: "route to ideas".into()
        }));
    }

    #[test]
    fn revising_empty_end_returns_to_review() {
        let mut sm = AppStateMachine::new();
        let entries = drive_to_review(&mut sm);
        sm.handle(AppEvent::ReviseDetected);
        let fx = sm.handle(AppEvent::EndDetected { transcript: "".into() });
        assert_eq!(*sm.state(), AppState::Review(entries.clone()));
        assert!(fx.contains(&SideEffect::ShowReview(entries)));
    }

    #[test]
    fn revising_cancel_returns_to_review() {
        let mut sm = AppStateMachine::new();
        let entries = drive_to_review(&mut sm);
        sm.handle(AppEvent::ReviseDetected);
        let fx = sm.handle(AppEvent::CancelDetected);
        assert_eq!(*sm.state(), AppState::Review(entries.clone()));
        assert!(fx.contains(&SideEffect::ShowReview(entries)));
    }

    #[test]
    fn write_completed_from_any_state() {
        let mut sm = AppStateMachine::new();
        sm.handle(AppEvent::WakeDetected);
        let fx = sm.handle(AppEvent::WriteCompleted(3));
        assert_eq!(*sm.state(), AppState::Idle);
        assert!(fx.contains(&SideEffect::ShowOverlay("Wrote 3 entries".into())));
        assert!(fx.contains(&SideEffect::ReturnToIdle));
    }

    #[test]
    fn write_failure_returns_to_idle_with_error() {
        let mut sm = AppStateMachine::new();
        sm.handle(AppEvent::WakeDetected);
        let fx = sm.handle(AppEvent::WriteFailed("disk full".into()));
        assert_eq!(*sm.state(), AppState::Idle);
        assert_eq!(
            fx,
            vec![
                SideEffect::ShowError("Write error: disk full".into()),
                SideEffect::ReturnToIdle,
            ]
        );
    }
}
