//! egui/eframe UI — replaces TranscriptWindow, MemoReviewWindow, ReviewWindow
//! and ConfigDialog. One main viewport hosting the transcript log plus
//! floating windows for memo review, entries review and configuration.
//! Overlay toasts become desktop notifications (no always-on-top windows on
//! GNOME Wayland).

use std::sync::{Arc, Mutex, MutexGuard};

use crossbeam_channel::{Receiver, Sender};
use eframe::egui;

use crate::config::llm as llm_config;
use crate::config::QueuePopulatorConfig;
use crate::coordinator::{BlockKind, CoordinatorMsg, UiUpdate};
use crate::llm::client::LlmClient;
use crate::llm::model_fetcher;
use crate::llm::response::ProposedEntry;
use crate::state_machine::{AppEvent, AppState};
use crate::ui::sounds;

const LOG_LIMIT: usize = 500;

fn lock_recover<T>(mutex: &Mutex<T>) -> MutexGuard<'_, T> {
    mutex.lock().unwrap_or_else(|poisoned| poisoned.into_inner())
}

struct LogLine {
    text: String,
    kind: BlockKind,
}

#[derive(Default)]
struct MemoReview {
    open: bool,
    text: String,
}

#[derive(Default)]
struct EntriesReview {
    open: bool,
    entries: Vec<ProposedEntry>,
}

struct ConfigDialog {
    open: bool,
    draft: QueuePopulatorConfig,
    api_key_input: String,
    models: Arc<Mutex<Option<Vec<String>>>>,
    test_result: Arc<Mutex<Option<String>>>,
}

pub struct QueuePopulatorApp {
    updates: Receiver<UiUpdate>,
    coordinator: Sender<CoordinatorMsg>,
    show_window: Receiver<()>,
    quit_window: Receiver<()>,

    config: QueuePopulatorConfig,
    state: AppState,
    paused: bool,
    live_transcript: String,
    log: Vec<LogLine>,

    memo: MemoReview,
    entries: EntriesReview,
    config_dialog: Option<ConfigDialog>,
}

impl QueuePopulatorApp {
    // ⟦𓍍𓃁𓃩𓎎⟧ new :: auto-generated pointer for public function new
    pub fn new(
        config: QueuePopulatorConfig,
        updates: Receiver<UiUpdate>,
        coordinator: Sender<CoordinatorMsg>,
        show_window: Receiver<()>,
        quit_window: Receiver<()>,
    ) -> Self {
        Self {
            updates,
            coordinator,
            show_window,
            quit_window,
            config,
            state: AppState::Idle,
            paused: false,
            live_transcript: String::new(),
            log: Vec::new(),
            memo: MemoReview::default(),
            entries: EntriesReview::default(),
            config_dialog: None,
        }
    }

    fn push_log(&mut self, text: String, kind: BlockKind) {
        self.log.push(LogLine { text, kind });
        if self.log.len() > LOG_LIMIT {
            self.log.drain(..self.log.len() - LOG_LIMIT);
        }
    }

    fn drain_updates(&mut self, ctx: &egui::Context) {
        while let Ok(()) = self.show_window.try_recv() {
            ctx.send_viewport_cmd(egui::ViewportCommand::Visible(true));
            ctx.send_viewport_cmd(egui::ViewportCommand::Focus);
        }

        while let Ok(update) = self.updates.try_recv() {
            match update {
                UiUpdate::State(state) => self.state = state,
                UiUpdate::Paused(paused) => self.paused = paused,
                UiUpdate::LiveTranscript { text, .. } => self.live_transcript = text,
                UiUpdate::Event(text) => self.push_log(text, BlockKind::Info),
                UiUpdate::Block { title, body, kind } => {
                    self.push_log(format!("── {title} ──\n{body}"), kind)
                }
                UiUpdate::Overlay { message, icon, seconds } => {
                    notify(&message, &icon, seconds);
                }
                UiUpdate::ShowMemoReview(text) => {
                    self.memo = MemoReview { open: true, text };
                    ctx.send_viewport_cmd(egui::ViewportCommand::Visible(true));
                    ctx.send_viewport_cmd(egui::ViewportCommand::Focus);
                }
                UiUpdate::HideMemoReview => self.memo.open = false,
                UiUpdate::ShowEntriesReview(entries) => {
                    self.entries = EntriesReview { open: true, entries };
                    ctx.send_viewport_cmd(egui::ViewportCommand::Visible(true));
                    ctx.send_viewport_cmd(egui::ViewportCommand::Focus);
                }
                UiUpdate::HideEntriesReview => self.entries.open = false,
                UiUpdate::PlayCommandSound => sounds::play_command(),
                UiUpdate::PlayMemoSound => sounds::play_memo(),
                UiUpdate::ConfigApplied(config) => self.config = config,
            }
        }
    }

    fn send(&self, msg: CoordinatorMsg) {
        let _ = self.coordinator.send(msg);
    }

    // ---- panels ------------------------------------------------------------

    fn header(&mut self, ui: &mut egui::Ui) {
        ui.horizontal(|ui| {
            let state_label = if self.paused { "Paused" } else { self.state.label() };
            ui.heading(state_label);
            ui.separator();
            if ui.button(if self.paused { "▶ Resume" } else { "⏸ Pause" }).clicked() {
                self.send(CoordinatorMsg::TogglePause);
            }
            if ui.button("⚙ Configure").clicked() && self.config_dialog.is_none() {
                self.config_dialog = Some(ConfigDialog {
                    open: true,
                    draft: self.config.clone(),
                    api_key_input: String::new(),
                    models: Arc::new(Mutex::new(None)),
                    test_result: Arc::new(Mutex::new(None)),
                });
            }
            if ui.button("📁 Browse Queue").clicked() {
                let path = self.config.resolved_queue_base_path();
                let _ = std::fs::create_dir_all(&path);
                let _ = std::process::Command::new("xdg-open").arg(&path).spawn();
            }
        });
    }

    fn commands_help(&self, ui: &mut egui::Ui) {
        let p = &self.config.phrases;
        ui.collapsing("Voice commands", |ui| {
            egui::Grid::new("commands").num_columns(2).show(ui, |ui| {
                for (label, phrase) in [
                    ("Wake / start memo", &p.wake),
                    ("End memo", &p.end),
                    ("Approve memo", &p.approve_memo),
                    ("Approve entries", &p.approve),
                    ("Revise entries", &p.revise),
                    ("Cancel", &p.cancel),
                    ("Open Claude mic", &p.open_claude),
                    ("Close Claude mic", &p.close_claude),
                    ("Open Codex mic", &p.open_codex),
                    ("Close Codex mic", &p.close_codex),
                    ("Open Llama mic", &p.open_llama),
                    ("Close Llama mic", &p.close_llama),
                ] {
                    ui.label(label);
                    ui.monospace(format!("\"{phrase}\""));
                    ui.end_row();
                }
            });
        });
    }

    fn transcript_panel(&self, ui: &mut egui::Ui) {
        ui.group(|ui| {
            ui.label(egui::RichText::new("Live transcript").small().weak());
            let text = if self.live_transcript.is_empty() { "…" } else { &self.live_transcript };
            ui.label(egui::RichText::new(text).monospace());
        });
    }

    fn log_panel(&self, ui: &mut egui::Ui) {
        egui::ScrollArea::vertical()
            .stick_to_bottom(true)
            .auto_shrink([false, false])
            .show(ui, |ui| {
                for line in &self.log {
                    let color = match line.kind {
                        BlockKind::Info => ui.visuals().text_color(),
                        BlockKind::Request => egui::Color32::from_rgb(0xe8, 0xa8, 0x2e),
                        BlockKind::Response => egui::Color32::from_rgb(0x4c, 0xaf, 0x50),
                        BlockKind::Error => egui::Color32::from_rgb(0xe0, 0x4a, 0x3a),
                    };
                    ui.label(egui::RichText::new(&line.text).monospace().color(color));
                }
            });
    }

    fn memo_window(&mut self, ctx: &egui::Context) {
        if !self.memo.open {
            return;
        }
        let mut open = self.memo.open;
        let mut process_clicked = false;
        let mut cancel_clicked = false;
        egui::Window::new("Memo Review")
            .open(&mut open)
            .collapsible(false)
            .show(ctx, |ui| {
                ui.label(format!("Say \"{}\" or press Process.", self.config.phrases.approve_memo));
                ui.add(
                    egui::TextEdit::multiline(&mut self.memo.text)
                        .desired_rows(6)
                        .desired_width(f32::INFINITY),
                );
                ui.horizontal(|ui| {
                    process_clicked = ui.button("✔ Process").clicked();
                    cancel_clicked = ui.button("✖ Cancel").clicked();
                });
            });
        if process_clicked {
            self.send(CoordinatorMsg::Ui(AppEvent::MemoApproved { transcript: self.memo.text.clone() }));
            open = false;
        } else if cancel_clicked || !open {
            // Window closed via X counts as cancel.
            if !process_clicked {
                self.send(CoordinatorMsg::Ui(AppEvent::CancelDetected));
            }
            open = false;
        }
        self.memo.open = open;
    }

    fn entries_window(&mut self, ctx: &egui::Context) {
        if !self.entries.open {
            return;
        }
        let mut open = self.entries.open;
        let mut action: Option<AppEvent> = None;
        egui::Window::new("Review Entries")
            .open(&mut open)
            .collapsible(false)
            .show(ctx, |ui| {
                let p = &self.config.phrases;
                ui.label(format!(
                    "Say \"{}\", \"{}\" or \"{}\" — or use the buttons.",
                    p.approve, p.revise, p.cancel
                ));
                ui.separator();
                for entry in &self.entries.entries {
                    ui.horizontal(|ui| {
                        ui.label(
                            egui::RichText::new(format!(" {} ", entry.entry_type))
                                .background_color(egui::Color32::from_rgb(0x3a, 0x86, 0xe0))
                                .color(egui::Color32::WHITE)
                                .small(),
                        );
                        ui.monospace(&entry.file);
                    });
                    ui.label(&entry.text);
                    ui.separator();
                }
                ui.horizontal(|ui| {
                    if ui.button("✔ Approve").clicked() {
                        action = Some(AppEvent::ApproveDetected);
                    }
                    if ui.button("✎ Revise").clicked() {
                        action = Some(AppEvent::ReviseDetected);
                    }
                    if ui.button("✖ Cancel").clicked() {
                        action = Some(AppEvent::CancelDetected);
                    }
                });
            });
        if let Some(event) = action {
            self.send(CoordinatorMsg::Ui(event));
            open = false;
        } else if !open {
            self.send(CoordinatorMsg::Ui(AppEvent::CancelDetected));
        }
        self.entries.open = open;
    }

    fn config_window(&mut self, ctx: &egui::Context) {
        let Some(dialog) = &mut self.config_dialog else { return };
        let mut open = dialog.open;
        let mut save_clicked = false;
        egui::Window::new("Configuration")
            .open(&mut open)
            .default_width(480.0)
            .show(ctx, |ui| {
                egui::ScrollArea::vertical().max_height(500.0).show(ui, |ui| {
                    ui.heading("LLM");
                    egui::ComboBox::from_label("Provider")
                        .selected_text(&dialog.draft.llm.provider)
                        .show_ui(ui, |ui| {
                            for provider in llm_config::PROVIDERS {
                                ui.selectable_value(
                                    &mut dialog.draft.llm.provider,
                                    provider.to_string(),
                                    *provider,
                                );
                            }
                        });

                    let mut model = dialog.draft.llm.model.clone().unwrap_or_default();
                    ui.horizontal(|ui| {
                        ui.label("Model");
                        ui.text_edit_singleline(&mut model);
                        if ui.button("Fetch Models").clicked() {
                            let provider = dialog.draft.llm.provider.clone();
                            let key = dialog.draft.llm.effective_api_key();
                            let base = dialog.draft.llm.effective_base_url();
                            let slot = dialog.models.clone();
                            let _ = std::thread::Builder::new()
                                .name("model-fetch".into())
                                .spawn(move || {
                                    let models = model_fetcher::fetch_models(
                                        &provider,
                                        key.as_deref(),
                                        base.as_deref(),
                                    );
                                    *lock_recover(&slot) = Some(models);
                                });
                        }
                    });
                    dialog.draft.llm.model = if model.trim().is_empty() { None } else { Some(model) };

                    if let Some(models) = lock_recover(&dialog.models).clone() {
                        egui::ComboBox::from_label(format!("{} models", models.len()))
                            .selected_text(dialog.draft.llm.model.clone().unwrap_or_default())
                            .show_ui(ui, |ui| {
                                for m in &models {
                                    ui.selectable_value(&mut dialog.draft.llm.model, Some(m.clone()), m);
                                }
                            });
                    }

                    ui.horizontal(|ui| {
                        ui.label("API key");
                        ui.add(
                            egui::TextEdit::singleline(&mut dialog.api_key_input)
                                .password(true)
                                .hint_text(match &dialog.draft.llm.api_key_alias {
                                    Some(alias) => format!("saved: {alias} (blank keeps current)"),
                                    None => "plain key, or env:VAR_NAME".to_string(),
                                }),
                        );
                    });
                    if let Some(env_key) = llm_config::env_var_key(&dialog.draft.llm.provider) {
                        ui.label(
                            egui::RichText::new(format!("env fallback: ${env_key}")).small().weak(),
                        );
                    }

                    let mut base_url = dialog.draft.llm.base_url.clone().unwrap_or_default();
                    ui.horizontal(|ui| {
                        ui.label("Base URL");
                        ui.add(
                            egui::TextEdit::singleline(&mut base_url).hint_text(
                                llm_config::default_base_url(&dialog.draft.llm.provider).unwrap_or(""),
                            ),
                        );
                    });
                    dialog.draft.llm.base_url =
                        if base_url.trim().is_empty() { None } else { Some(base_url) };

                    if ui.button("Test Inference").clicked() {
                        let mut llm = dialog.draft.llm.clone();
                        if !dialog.api_key_input.trim().is_empty() {
                            llm.api_key = Some(dialog.api_key_input.trim().to_string());
                        }
                        let slot = dialog.test_result.clone();
                        *lock_recover(&slot) = Some("testing…".into());
                        let _ = std::thread::Builder::new()
                            .name("inference-test".into())
                            .spawn(move || {
                                let client = LlmClient::new(llm);
                                let result = client.classify_with_trace(
                                    "Reply with exactly this JSON: {\"entries\": [], \"reasoning\": \"ok\"}",
                                    "ping",
                                );
                                *lock_recover(&slot) = Some(match result {
                                    Ok(_) => "✓ inference OK".into(),
                                    Err(e) => format!("✗ {e}"),
                                });
                            });
                    }
                    if let Some(result) = lock_recover(&dialog.test_result).clone() {
                        ui.label(result);
                    }

                    ui.separator();
                    ui.heading("Queue");
                    ui.horizontal(|ui| {
                        ui.label("Base path");
                        ui.text_edit_singleline(&mut dialog.draft.queue_base_path);
                    });

                    ui.separator();
                    ui.heading("Input device");
                    let mut device = dialog.draft.recognition.input_device_id.clone().unwrap_or_default();
                    ui.horizontal(|ui| {
                        ui.label("PipeWire node");
                        ui.add(
                            egui::TextEdit::singleline(&mut device)
                                .hint_text("blank = default source"),
                        );
                    });
                    dialog.draft.recognition.input_device_id =
                        if device.trim().is_empty() { None } else { Some(device) };

                    ui.separator();
                    ui.heading("Phrases");
                    egui::Grid::new("phrases").num_columns(2).show(ui, |ui| {
                        for (label, value) in [
                            ("Wake", &mut dialog.draft.phrases.wake),
                            ("End", &mut dialog.draft.phrases.end),
                            ("Approve memo", &mut dialog.draft.phrases.approve_memo),
                            ("Cancel", &mut dialog.draft.phrases.cancel),
                            ("Approve", &mut dialog.draft.phrases.approve),
                            ("Revise", &mut dialog.draft.phrases.revise),
                            ("Open Claude", &mut dialog.draft.phrases.open_claude),
                            ("Close Claude", &mut dialog.draft.phrases.close_claude),
                            ("Open Codex", &mut dialog.draft.phrases.open_codex),
                            ("Close Codex", &mut dialog.draft.phrases.close_codex),
                            ("Open Llama", &mut dialog.draft.phrases.open_llama),
                            ("Close Llama", &mut dialog.draft.phrases.close_llama),
                        ] {
                            ui.label(label);
                            ui.text_edit_singleline(value);
                            ui.end_row();
                        }
                    });

                    ui.separator();
                    save_clicked = ui.button("💾 Save").clicked();
                });
            });

        if save_clicked {
            let mut updated = dialog.draft.clone();
            if !dialog.api_key_input.trim().is_empty() {
                updated.llm.api_key = Some(dialog.api_key_input.trim().to_string());
                updated.llm.api_key_alias = None;
            }
            self.send(CoordinatorMsg::ConfigUpdated(updated));
            self.config_dialog = None;
        } else if !open {
            self.config_dialog = None;
        } else if let Some(dialog) = &mut self.config_dialog {
            dialog.open = open;
        }
    }
}

impl eframe::App for QueuePopulatorApp {
    fn logic(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        if self.quit_window.try_recv().is_ok() {
            ctx.send_viewport_cmd(egui::ViewportCommand::Close);
            return;
        }
        self.drain_updates(ctx);
        // Poll channels even when idle.
        ctx.request_repaint_after(std::time::Duration::from_millis(150));
    }

    fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        let ctx = ui.ctx().clone();

        egui::CentralPanel::default().show(ui, |ui| {
            self.header(ui);
            ui.separator();
            self.transcript_panel(ui);
            self.commands_help(ui);
            ui.separator();
            self.log_panel(ui);
        });

        self.memo_window(&ctx);
        self.entries_window(&ctx);
        self.config_window(&ctx);
    }
}

fn notify(message: &str, icon: &str, seconds: f64) {
    let summary = if icon.is_empty() {
        "Queue Populator".to_string()
    } else {
        format!("{icon} Queue Populator")
    };
    let body = message.to_string();
    let timeout_ms = (seconds * 1000.0) as i32;
    let _ = std::thread::Builder::new()
        .name("desktop-notification".into())
        .spawn(move || {
            let _ = notify_rust::Notification::new()
                .summary(&summary)
                .body(&body)
                .timeout(notify_rust::Timeout::Milliseconds(timeout_ms as u32))
                .show();
        });
}
