use std::cell::RefCell;
use std::collections::BTreeMap;
use std::collections::BTreeSet;
use std::fs::File;
use std::io::BufRead;
use std::io::BufReader;
use std::io::Write;
use std::path::Path;
use std::path::PathBuf;

use chrono::SecondsFormat;
use chrono::Utc;
use codex_protocol::models::AgentMessageInputContent;
use codex_protocol::models::ContentItem;
use codex_protocol::models::ResponseItem;
use codex_protocol::protocol::CompactedItem;
use codex_protocol::protocol::RolloutItem;
use codex_protocol::protocol::RolloutLine;
use crossterm::event::KeyCode;
use crossterm::event::KeyEvent;
use crossterm::event::KeyModifiers;
use ratatui::buffer::Buffer;
use ratatui::layout::Rect;
use ratatui::style::Color;
use ratatui::style::Style;
use ratatui::style::Stylize;
use ratatui::text::Line;
use ratatui::widgets::Clear;
use ratatui::widgets::Paragraph;
use ratatui::widgets::StatefulWidgetRef;
use ratatui::widgets::Widget;
use ratatui::widgets::Wrap;

use crate::app_event::AppEvent;
use crate::app_event_sender::AppEventSender;
use crate::render::renderable::Renderable;

use super::CancellationEvent;
use super::bottom_pane_view::BottomPaneView;
use super::textarea::TextArea;
use super::textarea::TextAreaState;

const VIEW_TITLE: &str = "/edit-convo";
const MAX_VISIBLE_ENTRIES: usize = 9;

#[derive(Clone, Debug)]
struct EditableEntry {
    item_index: usize,
    label: String,
    text: String,
    kind: EntryKind,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum EntryKind {
    User,
    Assistant,
    System,
    Developer,
    Tool,
    Reasoning,
    Compaction,
    Other,
}

impl EntryKind {
    fn icon(self) -> &'static str {
        match self {
            EntryKind::User => "👤",
            EntryKind::Assistant => "🤖",
            EntryKind::System => "🛠",
            EntryKind::Developer => "🧭",
            EntryKind::Tool => "🔧",
            EntryKind::Reasoning => "💭",
            EntryKind::Compaction => "🧩",
            EntryKind::Other => "•",
        }
    }

    fn is_agent_like(self) -> bool {
        matches!(
            self,
            EntryKind::Assistant | EntryKind::Tool | EntryKind::Reasoning | EntryKind::Compaction
        )
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum ActionMode {
    Delete,
    Compact,
    Edit,
}

impl ActionMode {
    fn label(self) -> &'static str {
        match self {
            ActionMode::Delete => "delete",
            ActionMode::Compact => "compact",
            ActionMode::Edit => "edit",
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum EditPayloadMode {
    Text,
    Json,
}

impl EditPayloadMode {
    fn label(self) -> &'static str {
        match self {
            EditPayloadMode::Text => "text",
            EditPayloadMode::Json => "json",
        }
    }
}

#[derive(Clone, Debug)]
enum PendingOp {
    Delete {
        start: usize,
        end: usize,
    },
    Compact {
        start: usize,
        end: usize,
        summary: String,
    },
    EditText {
        index: usize,
        text: String,
    },
    EditJson {
        index: usize,
        item: RolloutItem,
    },
}

impl PendingOp {
    fn affected_entry_range(&self) -> (usize, usize) {
        match self {
            PendingOp::Delete { start, end } | PendingOp::Compact { start, end, .. } => {
                (*start, *end)
            }
            PendingOp::EditText { index, .. } | PendingOp::EditJson { index, .. } => {
                (*index, *index)
            }
        }
    }

    fn label(&self) -> &'static str {
        match self {
            PendingOp::Delete { .. } => "🗑 delete",
            PendingOp::Compact { .. } => "🧩 compact",
            PendingOp::EditText { .. } | PendingOp::EditJson { .. } => "✏ edit",
        }
    }
}

#[derive(Clone, Debug)]
struct EditConvoDocument {
    source_path: PathBuf,
    items: Vec<RolloutItem>,
    entries: Vec<EditableEntry>,
}

impl EditConvoDocument {
    fn load(path: PathBuf) -> Result<Self, String> {
        if !path.exists() {
            return Err("Rollout file has not been materialized yet.".to_string());
        }
        if path.extension().and_then(|ext| ext.to_str()) == Some("zst") {
            return Err("Compressed rollout files are not editable in the TUI yet.".to_string());
        }

        let file = File::open(&path)
            .map_err(|err| format!("Failed to open rollout {}: {err}", path.display()))?;
        let reader = BufReader::new(file);
        let mut items = Vec::new();
        let mut parse_errors = 0usize;

        for line in reader.lines() {
            let line = line.map_err(|err| format!("Failed to read rollout: {err}"))?;
            let trimmed = line.trim();
            if trimmed.is_empty() {
                continue;
            }
            match serde_json::from_str::<RolloutLine>(trimmed) {
                Ok(parsed) => items.push(parsed.item),
                Err(_) => parse_errors = parse_errors.saturating_add(1),
            }
        }

        if items.is_empty() {
            return Err("Rollout file did not contain editable entries.".to_string());
        }
        if parse_errors > 0 {
            return Err(format!(
                "Rollout contains {parse_errors} unparsable JSONL line(s); refusing to edit."
            ));
        }

        let entries = editable_entries(&items);
        if entries.is_empty() {
            return Err("No model-visible message items found in this rollout.".to_string());
        }

        Ok(Self {
            source_path: path,
            items,
            entries,
        })
    }
}

pub(crate) struct EditConvoView {
    app_event_tx: AppEventSender,
    document: Result<EditConvoDocument, String>,
    selected: usize,
    range_anchor: Option<usize>,
    action_mode: ActionMode,
    payload_mode: EditPayloadMode,
    staged_ops: Vec<PendingOp>,
    textarea: TextArea,
    textarea_state: RefCell<TextAreaState>,
    editing_payload: bool,
    complete: bool,
    status: Option<String>,
}

impl EditConvoView {
    pub(crate) fn new(rollout_path: Option<PathBuf>, app_event_tx: AppEventSender) -> Self {
        let document = rollout_path
            .ok_or_else(|| "Rollout path is not available for this session yet.".to_string())
            .and_then(EditConvoDocument::load);
        Self {
            app_event_tx,
            document,
            selected: 0,
            range_anchor: None,
            action_mode: ActionMode::Delete,
            payload_mode: EditPayloadMode::Text,
            staged_ops: Vec::new(),
            textarea: TextArea::new(),
            textarea_state: RefCell::new(TextAreaState::default()),
            editing_payload: false,
            complete: false,
            status: None,
        }
    }

    fn entries(&self) -> &[EditableEntry] {
        match &self.document {
            Ok(document) => &document.entries,
            Err(_) => &[],
        }
    }

    fn selected_range(&self) -> (usize, usize) {
        let start = self.range_anchor.unwrap_or(self.selected);
        (start.min(self.selected), start.max(self.selected))
    }

    fn move_selection(&mut self, delta: isize) {
        let len = self.entries().len();
        if len == 0 {
            return;
        }
        let selected = self.selected as isize + delta;
        self.selected = selected.clamp(0, len.saturating_sub(1) as isize) as usize;
    }

    fn cycle_action(&mut self, action_mode: ActionMode) {
        self.action_mode = action_mode;
        self.status = Some(format!("Action set to {}.", self.action_mode.label()));
    }

    fn begin_payload_edit(&mut self) {
        if self.entries().is_empty() {
            return;
        }
        let initial = match self.action_mode {
            ActionMode::Delete => {
                self.stage_delete();
                return;
            }
            ActionMode::Compact => "Summarize the selected messages here.".to_string(),
            ActionMode::Edit => match self.payload_mode {
                EditPayloadMode::Text => self.entries()[self.selected].text.clone(),
                EditPayloadMode::Json => match &self.document {
                    Ok(document) => serde_json::to_string_pretty(
                        &document.items[self.entries()[self.selected].item_index],
                    )
                    .unwrap_or_else(|_| "{}".to_string()),
                    Err(_) => "{}".to_string(),
                },
            },
        };
        self.textarea.set_text_clearing_elements(&initial);
        self.textarea_state.replace(TextAreaState::default());
        self.editing_payload = true;
        self.status = Some(format!(
            "Editing {} payload. Tab toggles text/json.",
            self.payload_mode.label()
        ));
    }

    fn stage_delete(&mut self) {
        let (start, end) = self.selected_range();
        self.staged_ops.push(PendingOp::Delete { start, end });
        self.status = Some(format!(
            "Staged delete for item range {}-{}.",
            start + 1,
            end + 1
        ));
    }

    fn stage_payload(&mut self) {
        let payload = self.textarea.text().trim().to_string();
        if payload.is_empty() {
            self.status = Some("Payload cannot be empty.".to_string());
            return;
        }

        match self.action_mode {
            ActionMode::Delete => self.stage_delete(),
            ActionMode::Compact => {
                let (start, end) = self.selected_range();
                self.staged_ops.push(PendingOp::Compact {
                    start,
                    end,
                    summary: payload,
                });
                self.status = Some(format!(
                    "Staged compaction for item range {}-{}.",
                    start + 1,
                    end + 1
                ));
            }
            ActionMode::Edit => match self.payload_mode {
                EditPayloadMode::Text => {
                    self.staged_ops.push(PendingOp::EditText {
                        index: self.selected,
                        text: payload,
                    });
                    self.status = Some(format!("Staged text edit for item {}.", self.selected + 1));
                }
                EditPayloadMode::Json => match serde_json::from_str::<RolloutItem>(&payload) {
                    Ok(item) => {
                        self.staged_ops.push(PendingOp::EditJson {
                            index: self.selected,
                            item,
                        });
                        self.status = Some(format!(
                            "Staged raw JSON edit for item {}.",
                            self.selected + 1
                        ));
                    }
                    Err(err) => {
                        self.status = Some(format!("Invalid rollout item JSON: {err}"));
                        return;
                    }
                },
            },
        }

        self.editing_payload = false;
    }

    fn toggle_payload_mode(&mut self) {
        self.payload_mode = match self.payload_mode {
            EditPayloadMode::Text => EditPayloadMode::Json,
            EditPayloadMode::Json => EditPayloadMode::Text,
        };
        if self.editing_payload && self.action_mode == ActionMode::Edit {
            self.begin_payload_edit();
        } else {
            self.status = Some(format!(
                "Payload mode set to {}.",
                self.payload_mode.label()
            ));
        }
    }

    fn apply(&mut self) {
        if self.staged_ops.is_empty() {
            self.status = Some("No edits staged. Press Enter to stage the current action.".into());
            return;
        }
        let Ok(document) = &self.document else {
            self.status = Some("Cannot apply because the rollout did not load.".to_string());
            return;
        };

        match apply_staged_ops(document, &self.staged_ops) {
            Ok(applied) => match write_rollout_copy(&document.source_path, &applied.items) {
                Ok(output_path) => {
                    let summary = applied.summary;
                    self.app_event_tx.send(AppEvent::EditConvoApplied {
                        output_path,
                        summary,
                    });
                    self.complete = true;
                }
                Err(err) => {
                    let message = format!("Failed to write edited rollout copy: {err}");
                    self.status = Some(message.clone());
                    self.app_event_tx
                        .send(AppEvent::EditConvoFailed { message });
                }
            },
            Err(message) => {
                self.status = Some(message.clone());
                self.app_event_tx
                    .send(AppEvent::EditConvoFailed { message });
            }
        }
    }

    fn current_impact_lines(&self) -> Vec<Line<'static>> {
        let entries = self.entries();
        if entries.is_empty() {
            return Vec::new();
        }
        let (start, end) = self.selected_range();
        let mut lines = vec![Line::from(vec![
            "⚠ ".red().bold(),
            format!(
                "{} would affect item range {}-{}",
                self.action_mode.label(),
                start + 1,
                end + 1
            )
            .into(),
        ])];
        for index in start..=end {
            if let Some(entry) = entries.get(index) {
                lines.push(Line::from(vec![
                    format!("  {} {:>2} ", entry.kind.icon(), index + 1).into(),
                    entry.label.clone().bold(),
                    " ".into(),
                    truncate(&entry.text, 80).dim(),
                ]));
            }
        }
        lines
    }
}

impl BottomPaneView for EditConvoView {
    fn handle_key_event(&mut self, key_event: KeyEvent) {
        if self.document.is_err() {
            if matches!(key_event.code, KeyCode::Esc | KeyCode::Enter) {
                self.complete = true;
            }
            return;
        }

        if self.editing_payload {
            match key_event {
                KeyEvent {
                    code: KeyCode::Esc, ..
                } => {
                    self.editing_payload = false;
                    self.status = Some("Edit cancelled.".to_string());
                }
                KeyEvent {
                    code: KeyCode::Tab, ..
                } => self.toggle_payload_mode(),
                KeyEvent {
                    code: KeyCode::Char('s'),
                    modifiers,
                    ..
                } if modifiers.contains(KeyModifiers::CONTROL) => self.stage_payload(),
                other => self.textarea.input(other),
            }
            return;
        }

        match key_event {
            KeyEvent {
                code: KeyCode::Esc, ..
            } => {
                self.complete = true;
            }
            KeyEvent {
                code: KeyCode::Up, ..
            } => self.move_selection(-1),
            KeyEvent {
                code: KeyCode::Down,
                ..
            } => self.move_selection(1),
            KeyEvent {
                code: KeyCode::Char('d'),
                ..
            } => self.cycle_action(ActionMode::Delete),
            KeyEvent {
                code: KeyCode::Char('c'),
                ..
            } => self.cycle_action(ActionMode::Compact),
            KeyEvent {
                code: KeyCode::Char('e'),
                ..
            } => self.cycle_action(ActionMode::Edit),
            KeyEvent {
                code: KeyCode::Char('u'),
                ..
            } => {
                if self.staged_ops.pop().is_some() {
                    self.status = Some("Removed the last staged edit.".to_string());
                }
            }
            KeyEvent {
                code: KeyCode::Char(' '),
                ..
            } => {
                self.range_anchor = match self.range_anchor {
                    Some(_) => None,
                    None => Some(self.selected),
                };
            }
            KeyEvent {
                code: KeyCode::Tab, ..
            } => self.toggle_payload_mode(),
            KeyEvent {
                code: KeyCode::Enter,
                ..
            } => self.begin_payload_edit(),
            KeyEvent {
                code: KeyCode::Char('s'),
                modifiers,
                ..
            } if modifiers.contains(KeyModifiers::CONTROL) => self.apply(),
            _ => {}
        }
    }

    fn on_ctrl_c(&mut self) -> CancellationEvent {
        self.complete = true;
        CancellationEvent::Handled
    }

    fn prefer_esc_to_handle_key_event(&self) -> bool {
        true
    }

    fn is_complete(&self) -> bool {
        self.complete
    }

    fn handle_paste(&mut self, pasted: String) -> bool {
        if !self.editing_payload || pasted.is_empty() {
            return false;
        }
        self.textarea.insert_str(&pasted);
        true
    }
}

impl Renderable for EditConvoView {
    fn desired_height(&self, width: u16) -> u16 {
        if self.document.is_err() {
            return 5;
        }
        let base =
            6 + self.visible_entries().len() as u16 + self.current_impact_lines().len() as u16;
        if self.editing_payload {
            base.saturating_add(self.input_height(width))
                .saturating_add(1)
        } else {
            base.saturating_add(self.staged_ops.len().min(4) as u16)
                .min(24)
        }
    }

    fn cursor_pos(&self, area: Rect) -> Option<(u16, u16)> {
        if !self.editing_payload {
            return None;
        }
        let input = self.input_rect(area)?;
        let state = *self.textarea_state.borrow();
        self.textarea.cursor_pos_with_state(input, state)
    }

    fn render(&self, area: Rect, buf: &mut Buffer) {
        if area.width == 0 || area.height == 0 {
            return;
        }
        Clear.render(area, buf);

        let mut lines = Vec::new();
        lines.push(Line::from(vec![
            VIEW_TITLE.bold().cyan(),
            "  ".into(),
            format!(
                "action={} mode={}",
                self.action_mode.label(),
                self.payload_mode.label()
            )
            .dim(),
        ]));

        match &self.document {
            Err(message) => {
                lines.push(Line::from(message.clone().red()));
                lines.push(Line::from("Esc closes.".dim()));
                render_lines(&lines, area, buf);
                return;
            }
            Ok(document) => {
                lines.push(Line::from(vec![
                    "source ".dim(),
                    document.source_path.display().to_string().into(),
                ]));
            }
        }

        lines.push(Line::from(
            "↑/↓ select  Space range  d delete  c compact  e edit  Enter stage/edit  Tab json/text  u undo  Ctrl-S apply  Esc close"
                .dim(),
        ));

        for (index, entry) in self.visible_entries() {
            let selected = index == self.selected;
            let in_range = self.index_in_range(index);
            let marker = if selected {
                "▶"
            } else if in_range {
                "▌"
            } else {
                " "
            };
            let mut spans = vec![
                marker.into(),
                " ".into(),
                format!("{} {:>2} ", entry.kind.icon(), index + 1).into(),
                entry.label.clone().bold(),
                " ".into(),
                truncate(&entry.text, area.width.saturating_sub(18) as usize).into(),
            ];
            if in_range {
                spans.insert(0, "⚠ ".red().bold());
            }
            lines.push(Line::from(spans));
        }

        if !self.staged_ops.is_empty() {
            lines.push(Line::from("staged".yellow().bold()));
            for (index, op) in self.staged_ops.iter().rev().take(4).enumerate() {
                let (start, end) = op.affected_entry_range();
                lines.push(Line::from(vec![
                    format!("  {}. ", index + 1).dim(),
                    op.label().into(),
                    format!(" {}-{}", start + 1, end + 1).into(),
                ]));
            }
        }

        if let Some(status) = &self.status {
            lines.push(Line::from(status.clone().yellow()));
        }

        lines.extend(self.current_impact_lines());
        render_lines(&lines, area, buf);

        if self.editing_payload
            && let Some(input_area) = self.input_rect(area)
        {
            let title = match self.action_mode {
                ActionMode::Compact => "compaction summary",
                ActionMode::Edit => "message edit",
                ActionMode::Delete => "delete",
            };
            Paragraph::new(Line::from(vec![
                title.bold(),
                " ".into(),
                format!("({})", self.payload_mode.label()).dim(),
            ]))
            .render(
                Rect {
                    x: input_area.x,
                    y: input_area.y.saturating_sub(1),
                    width: input_area.width,
                    height: 1,
                },
                buf,
            );
            let mut state = self.textarea_state.borrow_mut();
            StatefulWidgetRef::render_ref(&(&self.textarea), input_area, buf, &mut state);
        }
    }
}

impl EditConvoView {
    fn visible_entries(&self) -> Vec<(usize, &EditableEntry)> {
        let entries = self.entries();
        if entries.is_empty() {
            return Vec::new();
        }
        let half = MAX_VISIBLE_ENTRIES / 2;
        let start = self.selected.saturating_sub(half);
        let end = (start + MAX_VISIBLE_ENTRIES).min(entries.len());
        let start = end.saturating_sub(MAX_VISIBLE_ENTRIES);
        (start..end).map(|index| (index, &entries[index])).collect()
    }

    fn index_in_range(&self, index: usize) -> bool {
        let (start, end) = self.selected_range();
        (start..=end).contains(&index)
    }

    fn input_height(&self, width: u16) -> u16 {
        self.textarea
            .desired_height(width.saturating_sub(2))
            .clamp(3, 8)
    }

    fn input_rect(&self, area: Rect) -> Option<Rect> {
        let height = self.input_height(area.width);
        if area.height <= height.saturating_add(1) || area.width <= 2 {
            return None;
        }
        Some(Rect {
            x: area.x.saturating_add(1),
            y: area.y + area.height - height,
            width: area.width.saturating_sub(2),
            height,
        })
    }
}

#[derive(Debug)]
struct AppliedEdits {
    items: Vec<RolloutItem>,
    summary: String,
}

fn apply_staged_ops(
    document: &EditConvoDocument,
    ops: &[PendingOp],
) -> Result<AppliedEdits, String> {
    let mut dropped_item_indices = BTreeSet::new();
    let mut replacements: BTreeMap<usize, Vec<RolloutItem>> = BTreeMap::new();
    let mut affected_entries = BTreeSet::new();
    let mut audit_parts = Vec::new();

    for op in ops {
        let entry_indices = expanded_entry_indices(&document.entries, op);
        for entry_index in &entry_indices {
            if !affected_entries.insert(*entry_index) {
                return Err(format!(
                    "Staged edits overlap at item {}; undo one edit and try again.",
                    entry_index + 1
                ));
            }
        }

        let item_indices: Vec<usize> = entry_indices
            .iter()
            .map(|entry_index| document.entries[*entry_index].item_index)
            .collect();
        let Some(first_item_index) = item_indices.iter().min().copied() else {
            continue;
        };
        for item_index in &item_indices {
            dropped_item_indices.insert(*item_index);
        }

        match op {
            PendingOp::Delete { start, end } => {
                audit_parts.push(format!("deleted {}-{}", start + 1, end + 1));
            }
            PendingOp::Compact {
                start,
                end,
                summary,
            } => {
                replacements.insert(
                    first_item_index,
                    vec![RolloutItem::Compacted(CompactedItem {
                        message: summary.clone(),
                        replacement_history: None,
                        window_number: None,
                        first_window_id: None,
                        previous_window_id: None,
                        window_id: None,
                    })],
                );
                audit_parts.push(format!("compacted {}-{}", start + 1, end + 1));
            }
            PendingOp::EditText { index, text } => {
                let entry = &document.entries[*index];
                let mut item = document.items[entry.item_index].clone();
                replace_item_text(&mut item, text)?;
                replacements.insert(first_item_index, vec![item]);
                audit_parts.push(format!("edited {}", index + 1));
            }
            PendingOp::EditJson { index, item } => {
                replacements.insert(first_item_index, vec![item.clone()]);
                audit_parts.push(format!("edited {} as raw JSON", index + 1));
            }
        }
    }

    let mut result = Vec::new();
    for (item_index, item) in document.items.iter().enumerate() {
        if let Some(replacement) = replacements.get(&item_index) {
            result.extend(replacement.clone());
        }
        if !dropped_item_indices.contains(&item_index) {
            result.push(item.clone());
        }
    }

    let summary = audit_parts.join("; ");
    result.push(audit_item(&summary));
    validate_sequence(&result)?;

    Ok(AppliedEdits {
        items: result,
        summary,
    })
}

fn expanded_entry_indices(entries: &[EditableEntry], op: &PendingOp) -> BTreeSet<usize> {
    let (start, end) = op.affected_entry_range();
    let mut result: BTreeSet<usize> = (start..=end).collect();
    if matches!(op, PendingOp::Delete { .. })
        && (start..=end).any(|index| entries[index].kind.is_agent_like())
    {
        if let Some(previous) = (0..start)
            .rev()
            .find(|index| matches!(entries[*index].kind, EntryKind::User | EntryKind::System))
        {
            result.insert(previous);
        }
        let mut next = end.saturating_add(1);
        while next < entries.len() && entries[next].kind == EntryKind::Tool {
            result.insert(next);
            next = next.saturating_add(1);
        }
    }
    result
}

fn validate_sequence(items: &[RolloutItem]) -> Result<(), String> {
    let entries = editable_entries(items);
    let mut previous_primary: Option<(usize, EntryKind)> = None;
    for (index, entry) in entries.iter().enumerate() {
        let primary = match entry.kind {
            EntryKind::User | EntryKind::Assistant | EntryKind::Compaction => Some(entry.kind),
            _ => None,
        };
        let Some(kind) = primary else {
            continue;
        };
        if let Some((previous_index, previous_kind)) = previous_primary {
            if previous_kind == EntryKind::User && kind == EntryKind::User {
                return Err(format!(
                    "Invalid sequence after edits: user item {} is followed by user item {}.",
                    previous_index + 1,
                    index + 1
                ));
            }
            if previous_kind != EntryKind::User && kind != EntryKind::User {
                return Err(format!(
                    "Invalid sequence after edits: agent item {} is followed by agent item {}.",
                    previous_index + 1,
                    index + 1
                ));
            }
        }
        previous_primary = Some((index, kind));
    }
    Ok(())
}

fn editable_entries(items: &[RolloutItem]) -> Vec<EditableEntry> {
    items
        .iter()
        .enumerate()
        .filter_map(|(item_index, item)| entry_for_item(item_index, item))
        .collect()
}

fn entry_for_item(item_index: usize, item: &RolloutItem) -> Option<EditableEntry> {
    match item {
        RolloutItem::ResponseItem(response_item) => {
            let (kind, label, text) = response_item_summary(response_item);
            Some(EditableEntry {
                item_index,
                label,
                text,
                kind,
            })
        }
        RolloutItem::Compacted(compacted) => Some(EditableEntry {
            item_index,
            label: "compacted summary".to_string(),
            text: compacted.message.clone(),
            kind: EntryKind::Compaction,
        }),
        _ => None,
    }
}

fn response_item_summary(item: &ResponseItem) -> (EntryKind, String, String) {
    match item {
        ResponseItem::Message { role, content, .. } => {
            let kind = match role.as_str() {
                "user" => EntryKind::User,
                "assistant" => EntryKind::Assistant,
                "system" => EntryKind::System,
                "developer" => EntryKind::Developer,
                _ => EntryKind::Other,
            };
            (kind, format!("{role} message"), content_text(content))
        }
        ResponseItem::AgentMessage {
            author,
            recipient,
            content,
            ..
        } => (
            EntryKind::Assistant,
            format!("agent {author}->{recipient}"),
            agent_content_text(content),
        ),
        ResponseItem::Reasoning { summary, .. } => (
            EntryKind::Reasoning,
            "reasoning".to_string(),
            format!("{summary:?}"),
        ),
        ResponseItem::FunctionCall {
            name, arguments, ..
        } => (
            EntryKind::Tool,
            format!("tool call {name}"),
            arguments.clone(),
        ),
        ResponseItem::FunctionCallOutput { .. }
        | ResponseItem::CustomToolCall { .. }
        | ResponseItem::CustomToolCallOutput { .. }
        | ResponseItem::ToolSearchCall { .. }
        | ResponseItem::ToolSearchOutput { .. }
        | ResponseItem::LocalShellCall { .. }
        | ResponseItem::WebSearchCall { .. } => (
            EntryKind::Tool,
            "tool item".to_string(),
            serde_json::to_string(item).unwrap_or_default(),
        ),
        ResponseItem::Compaction { .. } | ResponseItem::ContextCompaction { .. } => (
            EntryKind::Compaction,
            "context compaction".to_string(),
            serde_json::to_string(item).unwrap_or_default(),
        ),
        _ => (
            EntryKind::Other,
            "response item".to_string(),
            serde_json::to_string(item).unwrap_or_default(),
        ),
    }
}

fn replace_item_text(item: &mut RolloutItem, text: &str) -> Result<(), String> {
    match item {
        RolloutItem::ResponseItem(ResponseItem::Message { content, .. }) => {
            replace_content_text(content, text);
            Ok(())
        }
        RolloutItem::ResponseItem(ResponseItem::AgentMessage { content, .. }) => {
            *content = vec![AgentMessageInputContent::InputText {
                text: text.to_string(),
            }];
            Ok(())
        }
        RolloutItem::Compacted(compacted) => {
            compacted.message = text.to_string();
            Ok(())
        }
        _ => Err("Text editing is only supported for messages and compaction summaries.".into()),
    }
}

fn replace_content_text(content: &mut Vec<ContentItem>, text: &str) {
    let output = content
        .iter()
        .any(|item| matches!(item, ContentItem::OutputText { .. }));
    *content = if output {
        vec![ContentItem::OutputText {
            text: text.to_string(),
        }]
    } else {
        vec![ContentItem::InputText {
            text: text.to_string(),
        }]
    };
}

fn content_text(content: &[ContentItem]) -> String {
    content
        .iter()
        .filter_map(|item| match item {
            ContentItem::InputText { text } | ContentItem::OutputText { text } => {
                Some(text.as_str())
            }
            ContentItem::InputImage { image_url, .. } => Some(image_url.as_str()),
        })
        .collect::<Vec<_>>()
        .join("\n")
}

fn agent_content_text(content: &[AgentMessageInputContent]) -> String {
    content
        .iter()
        .map(|item| match item {
            AgentMessageInputContent::InputText { text } => text.as_str(),
            AgentMessageInputContent::EncryptedContent { .. } => "[encrypted]",
        })
        .collect::<Vec<_>>()
        .join("\n")
}

fn audit_item(summary: &str) -> RolloutItem {
    RolloutItem::ResponseItem(ResponseItem::Message {
        id: None,
        role: "system".to_string(),
        content: vec![ContentItem::InputText {
            text: format!("Conversation history edited by user through /edit-convo: {summary}."),
        }],
        phase: None,
        internal_chat_message_metadata_passthrough: None,
    })
}

fn write_rollout_copy(source_path: &Path, items: &[RolloutItem]) -> std::io::Result<PathBuf> {
    let output_path = edited_rollout_path(source_path);
    let mut file = File::create(&output_path)?;
    for item in items {
        let line = RolloutLine {
            timestamp: Utc::now().to_rfc3339_opts(SecondsFormat::Millis, true),
            item: item.clone(),
        };
        writeln!(file, "{}", serde_json::to_string(&line)?)?;
    }
    file.flush()?;
    Ok(output_path)
}

fn edited_rollout_path(source_path: &Path) -> PathBuf {
    let parent = source_path.parent().unwrap_or_else(|| Path::new("."));
    let stem = source_path
        .file_stem()
        .and_then(|stem| stem.to_str())
        .unwrap_or("rollout");
    let stamp = Utc::now().format("%Y%m%dT%H%M%SZ");
    let mut candidate = parent.join(format!("{stem}-edit-convo-{stamp}.jsonl"));
    let mut suffix = 2usize;
    while candidate.exists() {
        candidate = parent.join(format!("{stem}-edit-convo-{stamp}-{suffix}.jsonl"));
        suffix = suffix.saturating_add(1);
    }
    candidate
}

fn render_lines(lines: &[Line<'static>], area: Rect, buf: &mut Buffer) {
    let paragraph = Paragraph::new(lines.to_vec())
        .wrap(Wrap { trim: false })
        .style(Style::default().fg(Color::Reset));
    paragraph.render(area, buf);
}

fn truncate(text: &str, max: usize) -> String {
    let trimmed = text.replace('\n', " ");
    if trimmed.chars().count() <= max {
        return trimmed;
    }
    let mut output: String = trimmed.chars().take(max.saturating_sub(1)).collect();
    output.push('…');
    output
}

#[cfg(test)]
mod tests {
    use super::*;

    fn message(role: &str, text: &str) -> RolloutItem {
        RolloutItem::ResponseItem(ResponseItem::Message {
            id: None,
            role: role.to_string(),
            content: vec![ContentItem::InputText {
                text: text.to_string(),
            }],
            phase: None,
            internal_chat_message_metadata_passthrough: None,
        })
    }

    fn document(items: Vec<RolloutItem>) -> EditConvoDocument {
        EditConvoDocument {
            source_path: PathBuf::from("/tmp/rollout.jsonl"),
            entries: editable_entries(&items),
            items,
        }
    }

    #[test]
    fn delete_agent_expands_to_previous_user() {
        let doc = document(vec![
            message("user", "hello"),
            message("assistant", "answer"),
            message("user", "next"),
            message("assistant", "answer 2"),
        ]);
        let applied = apply_staged_ops(&doc, &[PendingOp::Delete { start: 1, end: 1 }]).unwrap();
        let entries = editable_entries(&applied.items);
        assert_eq!(entries[0].text, "next");
        assert_eq!(entries[1].text, "answer 2");
    }

    #[test]
    fn compact_replaces_range_with_summary_and_audit() {
        let doc = document(vec![
            message("user", "hello"),
            message("assistant", "answer"),
            message("user", "next"),
            message("assistant", "answer 2"),
        ]);
        let applied = apply_staged_ops(
            &doc,
            &[PendingOp::Compact {
                start: 0,
                end: 1,
                summary: "summary".to_string(),
            }],
        )
        .unwrap();
        assert!(matches!(applied.items[0], RolloutItem::Compacted(_)));
        assert!(matches!(
            applied.items.last(),
            Some(RolloutItem::ResponseItem(_))
        ));
    }

    #[test]
    fn validation_rejects_user_user_sequence() {
        let doc = document(vec![
            message("user", "a"),
            message("assistant", "b"),
            message("user", "c"),
        ]);
        let err = apply_staged_ops(&doc, &[PendingOp::Delete { start: 1, end: 1 }])
            .expect_err("delete should fail");
        assert!(err.contains("user item"));
    }
}
