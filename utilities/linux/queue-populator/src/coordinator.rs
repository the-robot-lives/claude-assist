//! Port of Sources/Coordinator.swift.
//!
//! Owns the state machine, phrase detector, transcript buffer, LLM worker and
//! routing decisions. Runs on its own thread, consuming events from the
//! speech engine, the UI, and the LLM worker over a single channel; emits
//! UI updates over a UiSender so the UI layer stays swappable.

use std::sync::Arc;
use std::time::{Duration, Instant};

use crossbeam_channel::{Receiver, RecvTimeoutError, Sender};

use crate::audio::memo_recorder::MemoRecorder;
use crate::audio::RouterHandle;
use crate::config::debug_log;
use crate::config::store;
use crate::config::QueuePopulatorConfig;
use crate::config::MAX_RECORDING_SECONDS;
use crate::llm::client::LlmClient;
use crate::llm::prompt;
use crate::llm::response::ProposedEntry;
use crate::phrase_detector::PhraseDetector;
use crate::queue::writer;
use crate::state_machine::{AppEvent, AppState, AppStateMachine, SideEffect};
use crate::stt::engine::SpeechEvent;

/// Everything the coordinator reacts to, multiplexed onto one channel.
#[derive(Debug, Clone)]
pub enum CoordinatorMsg {
    Speech(SpeechEvent),
    /// UI button events, mapped to state machine events (memoApproved, cancel, ...).
    Ui(AppEvent),
    LlmCompleted(Vec<ProposedEntry>),
    LlmFailed(String),
    /// LLM request/response trace for the transcript window.
    ConfigUpdated(QueuePopulatorConfig),
    TogglePause,
    Quit,
}

/// Updates pushed to the UI layer (tray + windows). Fire-and-forget.
#[derive(Debug, Clone)]
pub enum UiUpdate {
    State(AppState),
    Paused(bool),
    LiveTranscript { text: String, state: AppState },
    Event(String),
    Block { title: String, body: String, kind: BlockKind },
    Overlay { message: String, icon: String, seconds: f64 },
    ShowMemoReview(String),
    HideMemoReview,
    ShowEntriesReview(Vec<ProposedEntry>),
    HideEntriesReview,
    PlayCommandSound,
    PlayMemoSound,
    ConfigApplied(QueuePopulatorConfig),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BlockKind {
    Info,
    Request,
    Response,
    Error,
}

pub struct Coordinator {
    config: QueuePopulatorConfig,
    state_machine: AppStateMachine,
    phrase_detector: PhraseDetector,
    router: RouterHandle,
    memo_recorder: Arc<MemoRecorder>,

    finalized_chunks: Vec<String>,
    current_partial: String,
    recording_started_at: Option<Instant>,
    paused: bool,

    rx: Receiver<CoordinatorMsg>,
    self_tx: Sender<CoordinatorMsg>,
    ui: Sender<UiUpdate>,
}

impl Coordinator {
    #[allow(clippy::too_many_arguments)]
    pub fn new(
        config: QueuePopulatorConfig,
        router: RouterHandle,
        memo_recorder: Arc<MemoRecorder>,
        rx: Receiver<CoordinatorMsg>,
        self_tx: Sender<CoordinatorMsg>,
        ui: Sender<UiUpdate>,
    ) -> Self {
        Self {
            phrase_detector: PhraseDetector::new(config.phrases.clone()),
            config,
            state_machine: AppStateMachine::new(),
            router,
            memo_recorder,
            finalized_chunks: Vec::new(),
            current_partial: String::new(),
            recording_started_at: None,
            paused: false,
            rx,
            self_tx,
            ui,
        }
    }

    pub fn run(mut self) {
        self.router.set_listening(true);
        self.send_ui(UiUpdate::State(self.state_machine.state().clone()));
        log(&format!(
            "queue-populator: listening for \"{}\"",
            self.config.phrases.wake
        ));
        log(&format!("  end: \"{}\"  cancel: \"{}\"", self.config.phrases.end, self.config.phrases.cancel));
        log(&format!("  queue: {}", self.config.resolved_queue_base_path()));
        log(&format!("  llm: {} / {}", self.config.llm.provider, self.config.llm.effective_model()));

        loop {
            let message = match self.rx.recv_timeout(Duration::from_millis(250)) {
                Ok(message) => Some(message),
                Err(RecvTimeoutError::Timeout) => None,
                Err(RecvTimeoutError::Disconnected) => break,
            };
            match message {
                None => {}
                Some(CoordinatorMsg::Speech(event)) => self.handle_speech(event),
                Some(CoordinatorMsg::Ui(event)) => self.handle_button(event),
                Some(CoordinatorMsg::LlmCompleted(entries)) => {
                    let effects = self.state_machine.handle(AppEvent::LlmCompleted(entries));
                    self.execute(effects);
                }
                Some(CoordinatorMsg::LlmFailed(error)) => {
                    let effects = self.state_machine.handle(AppEvent::LlmFailed(error));
                    self.execute(effects);
                }
                Some(CoordinatorMsg::ConfigUpdated(updated)) => self.apply_config(updated),
                Some(CoordinatorMsg::TogglePause) => self.toggle_pause(),
                Some(CoordinatorMsg::Quit) => break,
            }
            self.enforce_recording_timeout();
        }
        self.router.close_all();
        self.router.set_listening(false);
    }

    // ---- transcript buffer (port of buildFullTranscript & clipping) ------

    fn build_full_transcript(&self) -> String {
        let mut parts = self.finalized_chunks.clone();
        if !self.current_partial.is_empty() {
            parts.push(self.current_partial.clone());
        }
        parts.join(" ")
    }

    fn should_clip(&self, state: &AppState) -> bool {
        !matches!(state, AppState::Recording | AppState::Revising(_))
    }

    fn transcript_for_state(&self, state: &AppState) -> String {
        let text = self.build_full_transcript();
        if self.should_clip(state) {
            tail_chars(&text, 512)
        } else {
            text
        }
    }

    fn clip_buffer_if_needed(&mut self) {
        if !self.should_clip(self.state_machine.state()) {
            return;
        }
        let clipped = tail_chars(&self.build_full_transcript(), 512);
        self.finalized_chunks = if clipped.is_empty() { vec![] } else { vec![clipped] };
        self.current_partial.clear();
    }

    fn clear_buffer(&mut self) {
        self.finalized_chunks.clear();
        self.current_partial.clear();
    }

    fn enforce_recording_timeout(&mut self) {
        if !matches!(self.state_machine.state(), AppState::Recording | AppState::Revising(_)) {
            self.recording_started_at = None;
            return;
        }
        let Some(started_at) = self.recording_started_at else {
            return;
        };
        let limit = Duration::from_secs(u64::from(
            self.config
                .recognition
                .max_recording_seconds
                .clamp(1, MAX_RECORDING_SECONDS),
        ));
        if started_at.elapsed() < limit {
            return;
        }

        let transcript = match self.state_machine.state() {
            AppState::Recording => self.extract_memo(&self.build_full_transcript()),
            AppState::Revising(_) => self.build_full_transcript(),
            _ => return,
        };
        self.send_ui(UiUpdate::Event(format!(
            "Recording stopped after {} seconds",
            limit.as_secs()
        )));
        let effects = self
            .state_machine
            .handle(AppEvent::EndDetected { transcript });
        self.execute(effects);
    }

    // ---- speech events ---------------------------------------------------

    fn handle_speech(&mut self, event: SpeechEvent) {
        if self.paused {
            return;
        }
        match event {
            SpeechEvent::Partial(text) => {
                debug_log::verbose(&format!("  [partial] \"{text}\""));
                self.current_partial = text;
                self.process_transcript();
            }
            SpeechEvent::Final(text) => {
                log(&format!("  [finalized] \"{text}\""));
                self.finalized_chunks.push(text);
                self.current_partial.clear();
                // A final can complete a command phrase the partials missed.
                self.process_transcript();
                self.clip_buffer_if_needed();
                self.phrase_detector.reset();
            }
            SpeechEvent::Error(message) => {
                log(&format!("  [speech] {message}"));
                self.send_ui(UiUpdate::Event(format!("Speech: {message}")));
            }
        }
    }

    fn process_transcript(&mut self) {
        let current_state = self.state_machine.state().clone();
        let text = self.transcript_for_state(&current_state);
        self.send_ui(UiUpdate::LiveTranscript { text: text.clone(), state: current_state.clone() });

        let Some(event) = self.phrase_detector.detect(&text, &current_state) else {
            return;
        };
        self.send_ui(UiUpdate::PlayCommandSound);

        match event {
            AppEvent::WakeDetected => {
                log("━━━ WAKE PHRASE DETECTED ━━━");
                log(&format!("  state: {} → Recording", current_state.label()));
                self.clear_buffer();
                self.phrase_detector.reset();
                let effects = self.state_machine.handle(AppEvent::WakeDetected);
                self.execute(effects);
            }

            AppEvent::EndDetected { transcript } => {
                let detected = transcript.trim().to_string();
                let memo = if detected.is_empty() {
                    self.extract_memo(&self.build_full_transcript())
                } else {
                    detected
                };
                log("━━━ END PHRASE DETECTED ━━━");
                log(&format!("  state: {} → Processing", current_state.label()));
                log(&format!("  extracted memo: \"{memo}\""));
                let effects = self.state_machine.handle(AppEvent::EndDetected { transcript: memo });
                self.execute(effects);
            }

            AppEvent::ApproveMemoDetected => {
                log("━━━ APPROVE MEMO PHRASE DETECTED ━━━");
                let effects = self.state_machine.handle(AppEvent::ApproveMemoDetected);
                self.execute(effects);
            }

            AppEvent::MicOpen(target) => {
                log(&format!("━━━ MIC OPEN: {} ━━━", target.label()));
                self.clear_buffer();
                self.router.open(target);
                self.send_ui(UiUpdate::Overlay {
                    message: format!("{} mic open", target.label()),
                    icon: "🎙".into(),
                    seconds: self.config.ui.overlay_dismiss_seconds,
                });
                self.send_ui(UiUpdate::Event(format!("Virtual mic open: {}", target.label())));
            }

            AppEvent::MicClose(target) => {
                log(&format!("━━━ MIC CLOSE: {} ━━━", target.label()));
                self.clear_buffer();
                self.router.close(target);
                self.send_ui(UiUpdate::Overlay {
                    message: format!("{} mic muted", target.label()),
                    icon: "🔇".into(),
                    seconds: self.config.ui.overlay_dismiss_seconds,
                });
                self.send_ui(UiUpdate::Event(format!("Virtual mic muted: {}", target.label())));
            }

            AppEvent::ReviseDetected => {
                log("━━━ REVISE PHRASE DETECTED ━━━");
                self.clear_buffer();
                self.phrase_detector.reset();
                let effects = self.state_machine.handle(AppEvent::ReviseDetected);
                self.execute(effects);
            }

            other => {
                log(&format!("━━━ PHRASE: {other:?} ━━━"));
                let effects = self.state_machine.handle(other);
                self.execute(effects);
            }
        }
    }

    fn extract_memo(&self, text: &str) -> String {
        let mut memo = text.to_string();
        for phrase in [&self.config.phrases.wake, &self.config.phrases.end] {
            memo = crate::phrase_detector::strip_phrase(phrase, &memo);
        }
        memo.trim().to_string()
    }

    // ---- buttons / effects -----------------------------------------------

    fn handle_button(&mut self, event: AppEvent) {
        log(&format!("━━━ BUTTON: {event:?} ━━━"));
        let effects = self.state_machine.handle(event);
        self.execute(effects);
    }

    fn execute(&mut self, effects: Vec<SideEffect>) {
        for effect in effects {
            match effect {
                SideEffect::StartRecording => {
                    self.recording_started_at = Some(Instant::now());
                    self.phrase_detector.reset();
                    self.send_ui(UiUpdate::State(self.state_machine.state().clone()));
                    self.start_memo_recording_if_needed();
                    self.send_ui(UiUpdate::PlayMemoSound);
                    self.overlay_state();
                    self.send_ui(UiUpdate::Event("Recording started".into()));
                }

                SideEffect::StopRecording => {
                    self.recording_started_at = None;
                    self.finish_memo_recording_if_needed();
                    self.send_ui(UiUpdate::State(self.state_machine.state().clone()));
                }

                SideEffect::ShowMemoReview(memo) => {
                    self.send_ui(UiUpdate::State(self.state_machine.state().clone()));
                    self.phrase_detector.reset();
                    self.clear_buffer();
                    self.send_ui(UiUpdate::Block {
                        title: "MEMO REVIEW".into(),
                        body: memo.clone(),
                        kind: BlockKind::Info,
                    });
                    self.send_ui(UiUpdate::ShowMemoReview(memo));
                }

                SideEffect::HideMemoReview => self.send_ui(UiUpdate::HideMemoReview),

                SideEffect::SendToLlm { transcript } => {
                    self.send_ui(UiUpdate::State(AppState::Processing));
                    self.overlay_processing();
                    self.send_ui(UiUpdate::Event(format!("Sending to LLM: {transcript}")));
                    log("━━━ SENDING TO LLM ━━━");
                    log(&format!("  provider: {}", self.config.llm.provider));
                    log(&format!("  transcript: \"{transcript}\""));
                    self.spawn_llm_classify(transcript);
                }

                SideEffect::SendRevisionToLlm { original, revision } => {
                    self.send_ui(UiUpdate::State(AppState::Processing));
                    self.overlay_processing();
                    self.send_ui(UiUpdate::Event(format!("Sending revision: {revision}")));
                    log("━━━ SENDING REVISION TO LLM ━━━");
                    self.spawn_llm_revise(original, revision);
                }

                SideEffect::ShowReview(entries) => {
                    self.send_ui(UiUpdate::State(self.state_machine.state().clone()));
                    self.overlay_state();
                    self.phrase_detector.reset();
                    self.clear_buffer();
                    log("━━━ REVIEW ━━━");
                    for (i, entry) in entries.iter().enumerate() {
                        log(&format!(
                            "  [{}] → {}  type={}  text=\"{}\"",
                            i + 1,
                            entry.file,
                            entry.entry_type,
                            entry.text
                        ));
                    }
                    self.send_ui(UiUpdate::ShowEntriesReview(entries));
                }

                SideEffect::WriteEntries(entries) => {
                    self.send_ui(UiUpdate::HideEntriesReview);
                    log("━━━ WRITING ENTRIES ━━━");
                    self.write_entries(&entries);
                }

                SideEffect::ShowOverlay(message) => {
                    self.send_ui(UiUpdate::Overlay {
                        message: message.clone(),
                        icon: String::new(),
                        seconds: self.config.ui.overlay_dismiss_seconds,
                    });
                    log(&format!("  [overlay] {message}"));
                }

                SideEffect::ShowError(error) => {
                    self.send_ui(UiUpdate::Overlay {
                        message: format!("Error: {error}"),
                        icon: "⚠️".into(),
                        seconds: 5.0,
                    });
                    self.send_ui(UiUpdate::Event(format!("Error: {error}")));
                    log(&format!("  [ERROR] {error}"));
                }

                SideEffect::ReturnToIdle => {
                    self.send_ui(UiUpdate::State(AppState::Idle));
                    self.phrase_detector.reset();
                    self.clear_buffer();
                    log("  [state] → Idle");
                }
            }
        }
    }

    fn overlay_state(&self) {
        let state = self.state_machine.state();
        self.send_ui(UiUpdate::Overlay {
            message: state.label().to_string(),
            icon: String::new(),
            seconds: self.config.ui.overlay_dismiss_seconds,
        });
    }

    fn overlay_processing(&self) {
        self.send_ui(UiUpdate::Overlay {
            message: "Processing...".into(),
            icon: String::new(),
            seconds: 30.0,
        });
    }

    // ---- memo audio -------------------------------------------------------

    fn memo_output_dir(&self) -> std::path::PathBuf {
        let queue = std::path::PathBuf::from(self.config.resolved_queue_base_path());
        if queue.file_name().map(|n| n == "queue").unwrap_or(false) {
            queue.parent().map(|p| p.to_path_buf()).unwrap_or(queue)
        } else {
            queue
        }
    }

    fn start_memo_recording_if_needed(&self) {
        if *self.state_machine.state() != AppState::Recording || self.memo_recorder.is_recording() {
            return;
        }
        match self.memo_recorder.start(&self.memo_output_dir()) {
            Ok(()) => log("  [memo-audio] recording started"),
            Err(e) => {
                self.send_ui(UiUpdate::Event(format!("Memo audio disabled: {e}")));
                log(&format!("  [memo-audio] disabled: {e}"));
            }
        }
    }

    fn finish_memo_recording_if_needed(&self) {
        if !self.memo_recorder.is_recording() {
            return;
        }
        if !matches!(self.state_machine.state(), AppState::MemoReview(_)) {
            self.memo_recorder.cancel();
            log("  [memo-audio] cancelled");
            return;
        }
        match self.memo_recorder.stop_and_export_mp3() {
            Ok(Some(path)) => {
                self.send_ui(UiUpdate::Event(format!("Memo audio exported: {}", path.display())));
                log(&format!("  [memo-audio] exported {}", path.display()));
            }
            Ok(None) => {
                self.send_ui(UiUpdate::Event("Memo audio skipped: no audio frames captured".into()));
                log("  [memo-audio] skipped: no audio frames captured");
            }
            Err(e) => {
                self.send_ui(UiUpdate::Event(format!("Memo audio export failed: {e}")));
                log(&format!("  [memo-audio] export failed: {e}"));
            }
        }
    }

    // ---- LLM ---------------------------------------------------------------

    fn spawn_llm_classify(&self, transcript: String) {
        let (system, user) = prompt::classification_prompt(
            &transcript,
            self.config.system_prompt_override.as_deref(),
        );
        self.trace_llm_request(&system, &user, "LLM REQUEST");
        let client = LlmClient::new(self.config.llm.clone());
        let tx = self.self_tx.clone();
        let failure_tx = self.self_tx.clone();
        let ui = self.ui.clone();
        if let Err(e) = std::thread::Builder::new()
            .name("llm".into())
            .spawn(move || {
                dispatch_llm_result(client.classify_with_trace(&system, &user), tx, ui, "LLM RESPONSE");
            })
        {
            let _ = failure_tx.send(CoordinatorMsg::LlmFailed(format!(
                "cannot start LLM worker: {e}"
            )));
        }
    }

    fn spawn_llm_revise(&self, original: Vec<ProposedEntry>, revision: String) {
        let (system, user) = prompt::revision_prompt(
            &original,
            &revision,
            self.config.system_prompt_override.as_deref(),
        );
        self.trace_llm_request(&system, &user, "LLM REVISION REQUEST");
        let client = LlmClient::new(self.config.llm.clone());
        let tx = self.self_tx.clone();
        let failure_tx = self.self_tx.clone();
        let ui = self.ui.clone();
        if let Err(e) = std::thread::Builder::new()
            .name("llm".into())
            .spawn(move || {
                dispatch_llm_result(
                    client.classify_with_trace(&system, &user),
                    tx,
                    ui,
                    "LLM REVISION RESPONSE",
                );
            })
        {
            let _ = failure_tx.send(CoordinatorMsg::LlmFailed(format!(
                "cannot start LLM worker: {e}"
            )));
        }
    }

    fn trace_llm_request(&self, system: &str, user: &str, title: &str) {
        self.send_ui(UiUpdate::Block {
            title: format!(
                "{title}  {} / {}",
                self.config.llm.provider,
                self.config.llm.effective_model()
            ),
            body: format!("SYSTEM:\n{system}\n\nUSER:\n{user}"),
            kind: BlockKind::Request,
        });
    }

    fn write_entries(&mut self, entries: &[ProposedEntry]) {
        match writer::append_all(entries, &self.config.resolved_queue_base_path()) {
            Ok(count) => {
                log(&format!("━━━ WROTE {count} ENTRIES ━━━"));
                self.send_ui(UiUpdate::Event(format!("Wrote {count} entries")));
                let effects = self.state_machine.handle(AppEvent::WriteCompleted(count));
                self.execute(effects);
            }
            Err(e) => {
                log(&format!("━━━ WRITE ERROR: {e} ━━━"));
                self.send_ui(UiUpdate::Event(format!("Write error: {e}")));
                let effects = self.state_machine.handle(AppEvent::WriteFailed(e.to_string()));
                self.execute(effects);
            }
        }
    }

    // ---- pause / config -----------------------------------------------------

    fn toggle_pause(&mut self) {
        self.paused = !self.paused;
        self.router.set_listening(!self.paused);
        self.send_ui(UiUpdate::Paused(self.paused));
        if self.paused {
            log("━━━ PAUSED ━━━");
            self.send_ui(UiUpdate::Event("Listening paused".into()));
            self.send_ui(UiUpdate::Overlay { message: "Paused".into(), icon: "⏸".into(), seconds: self.config.ui.overlay_dismiss_seconds });
        } else {
            self.clear_buffer();
            self.phrase_detector.reset();
            log("━━━ RESUMED ━━━");
            self.send_ui(UiUpdate::Event("Listening resumed".into()));
            self.send_ui(UiUpdate::Overlay { message: "Resumed".into(), icon: "▶️".into(), seconds: self.config.ui.overlay_dismiss_seconds });
        }
    }

    fn apply_config(&mut self, updated: QueuePopulatorConfig) {
        match store::save_config(&updated) {
            Ok(()) => {
                self.config = store::load_config();
                self.memo_recorder.set_max_recording_seconds(
                    self.config.recognition.max_recording_seconds,
                );
                self.phrase_detector = PhraseDetector::new(self.config.phrases.clone());
                self.send_ui(UiUpdate::ConfigApplied(self.config.clone()));
                self.send_ui(UiUpdate::Overlay {
                    message: "Configuration saved".into(),
                    icon: "✓".into(),
                    seconds: self.config.ui.overlay_dismiss_seconds,
                });
                self.send_ui(UiUpdate::Event("Configuration saved".into()));
            }
            Err(e) => {
                self.send_ui(UiUpdate::Overlay {
                    message: "Save failed — check permissions".into(),
                    icon: "✗".into(),
                    seconds: 5.0,
                });
                self.send_ui(UiUpdate::Event(format!("Config save failed: {e}")));
            }
        }
    }

    fn send_ui(&self, update: UiUpdate) {
        let _ = self.ui.send(update);
    }
}

fn dispatch_llm_result(
    result: Result<crate::llm::response::ClassificationResult, crate::llm::client::LlmError>,
    tx: Sender<CoordinatorMsg>,
    ui: Sender<UiUpdate>,
    title: &str,
) {
    match result {
        Ok(result) => {
            let parsed = serde_json::to_string_pretty(&result.response.entries)
                .unwrap_or_else(|_| format!("{:?}", result.response.entries));
            let reasoning = result
                .response
                .reasoning
                .clone()
                .map(|r| format!("\n\nreasoning:\n{r}"))
                .unwrap_or_default();
            let _ = ui.send(UiUpdate::Block {
                title: title.to_string(),
                body: format!("RAW:\n{}\n\nPARSED:\n{parsed}{reasoning}", result.raw_text),
                kind: BlockKind::Response,
            });
            log(&format!("━━━ {title} ━━━"));
            log(&format!("  entries: {}", result.response.entries.len()));
            let _ = tx.send(CoordinatorMsg::LlmCompleted(result.response.entries));
        }
        Err(e) => {
            let _ = ui.send(UiUpdate::Block {
                title: "LLM ERROR".into(),
                body: e.to_string(),
                kind: BlockKind::Error,
            });
            log("━━━ LLM ERROR ━━━");
            log(&format!("  {e}"));
            let _ = tx.send(CoordinatorMsg::LlmFailed(e.to_string()));
        }
    }
}

fn tail_chars(text: &str, max: usize) -> String {
    let count = text.chars().count();
    if count <= max {
        text.to_string()
    } else {
        text.chars().skip(count - max).collect()
    }
}

fn log(message: &str) {
    debug_log::log(message);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tail_chars_clips_from_front() {
        assert_eq!(tail_chars("hello", 10), "hello");
        assert_eq!(tail_chars("hello", 3), "llo");
        assert_eq!(tail_chars("", 3), "");
    }

    #[test]
    fn growing_partial_fires_mic_command_only_once() {
        let config = QueuePopulatorConfig::default();
        let router = RouterHandle::for_test();
        let router_assert = router.clone();
        let (coord_tx, coord_rx) = crossbeam_channel::unbounded();
        let (ui_tx, ui_rx) = crossbeam_channel::unbounded();
        let mut coordinator = Coordinator::new(
            config,
            router,
            Arc::new(MemoRecorder::new()),
            coord_rx,
            coord_tx,
            ui_tx,
        );

        coordinator.current_partial = "robot open claude".into();
        coordinator.process_transcript();
        coordinator.current_partial = "robot open claude can you hear me".into();
        coordinator.process_transcript();

        assert_eq!(router_assert.open_target(), Some(crate::state_machine::MicTarget::Claude));
        let command_sounds = ui_rx
            .try_iter()
            .filter(|update| matches!(update, UiUpdate::PlayCommandSound))
            .count();
        assert_eq!(command_sounds, 1);
    }

    #[test]
    fn recording_deadline_forces_review_without_waiting_for_end_phrase() {
        let mut config = QueuePopulatorConfig::default();
        config.recognition.max_recording_seconds = 1;
        let router = RouterHandle::for_test();
        let (coord_tx, coord_rx) = crossbeam_channel::unbounded();
        let (ui_tx, _ui_rx) = crossbeam_channel::unbounded();
        let mut coordinator = Coordinator::new(
            config,
            router,
            Arc::new(MemoRecorder::with_max_recording_seconds(1)),
            coord_rx,
            coord_tx,
            ui_tx,
        );
        coordinator.state_machine.handle(AppEvent::WakeDetected);
        coordinator.current_partial = "hey robot bounded memo".into();
        coordinator.recording_started_at = Some(Instant::now() - Duration::from_secs(2));

        coordinator.enforce_recording_timeout();

        assert_eq!(
            coordinator.state_machine.state(),
            &AppState::MemoReview("bounded memo".into())
        );
        assert_eq!(coordinator.recording_started_at, None);
    }
}
