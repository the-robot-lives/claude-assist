//! Ratatui rendering: chat (left) + therobot state (right) + input, with an
//! optional hyperparameter menu overlay.

use crate::state::Snapshot;
use ratatui::{
    layout::{Alignment, Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Clear, Paragraph},
    Frame,
};

#[derive(PartialEq)]
pub enum Mode {
    Chat,
    Menu,
}

/// Editable runtime parameters (sampler + modulator priming).
#[derive(Clone, Copy)]
pub struct Params {
    pub temp: f32,
    pub top_k: i32,
    pub top_p: f32,
    pub min_p: f32,
    pub penalty_repeat: f32,
    pub penalty_last_n: i32,
    pub seed: u32,
    pub arousal: f32,
}

pub const MENU_LEN: usize = 8;

impl Params {
    pub fn label(i: usize) -> &'static str {
        match i {
            0 => "Temperature",
            1 => "Top-K",
            2 => "Top-P",
            3 => "Min-P",
            4 => "Repeat penalty",
            5 => "Repeat last-n",
            6 => "Seed",
            7 => "Arousal (m[0])",
            _ => "",
        }
    }
    pub fn value(&self, i: usize) -> String {
        match i {
            0 => format!("{:.2}", self.temp),
            1 => format!("{}", self.top_k),
            2 => format!("{:.2}", self.top_p),
            3 => format!("{:.2}", self.min_p),
            4 => format!("{:.2}", self.penalty_repeat),
            5 => format!("{}", self.penalty_last_n),
            6 => if self.seed == u32::MAX { "random".into() } else { format!("{}", self.seed) },
            7 => format!("{:+.1}", self.arousal),
            _ => String::new(),
        }
    }
    /// Adjust field `i` by one step in direction `dir` (+1/-1). Returns whether
    /// the change affects the sampler (vs. arousal-only).
    pub fn adjust(&mut self, i: usize, dir: f32) -> bool {
        match i {
            0 => { self.temp = (self.temp + 0.05 * dir).max(0.0); true }
            1 => { self.top_k = (self.top_k + dir as i32).max(0); true }
            2 => { self.top_p = (self.top_p + 0.01 * dir).clamp(0.0, 1.0); true }
            3 => { self.min_p = (self.min_p + 0.01 * dir).clamp(0.0, 1.0); true }
            4 => { self.penalty_repeat = (self.penalty_repeat + 0.02 * dir).max(0.0); true }
            5 => { self.penalty_last_n = (self.penalty_last_n + 8 * dir as i32).max(0); true }
            6 => {
                if self.seed == u32::MAX { self.seed = 0; }
                else { self.seed = (self.seed as i64 + dir as i64).max(0) as u32; }
                true
            }
            7 => { self.arousal += 0.5 * dir; false }
            _ => false,
        }
    }
}

pub struct App {
    pub transcript: String,
    pub input: String,
    pub snapshot: Snapshot,
    pub status: String,
    pub model_name: String,
    pub mode: Mode,
    pub params: Params,
    pub menu_idx: usize,
}

pub fn draw(f: &mut Frame, app: &App) {
    let root = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Length(1), Constraint::Min(3), Constraint::Length(3)])
        .split(f.area());

    draw_header(f, root[0], app);

    let cols = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(60), Constraint::Percentage(40)])
        .split(root[1]);

    draw_chat(f, cols[0], app);
    draw_state(f, cols[1], app);
    draw_input(f, root[2], app);

    if app.mode == Mode::Menu {
        draw_menu(f, f.area(), app);
    }
}

fn draw_header(f: &mut Frame, area: Rect, app: &App) {
    let p = &app.params;
    let hdr = format!(
        " robot-tui · {}   temp {:.2} · top-k {} · top-p {:.2} · rep {:.2} · arousal {:+.1} ",
        app.model_name, p.temp, p.top_k, p.top_p, p.penalty_repeat, p.arousal
    );
    let w = Paragraph::new(Line::from(Span::styled(
        hdr,
        Style::default().fg(Color::Black).bg(Color::Cyan).add_modifier(Modifier::BOLD),
    )));
    f.render_widget(w, area);
}

fn draw_chat(f: &mut Frame, area: Rect, app: &App) {
    let inner_w = area.width.saturating_sub(2).max(1) as usize;
    let inner_h = area.height.saturating_sub(2).max(1) as usize;

    // wrap + style, tracking <think> regions to dim them
    let mut styled: Vec<Line> = Vec::new();
    let mut in_think = false;
    for raw in app.transcript.split('\n') {
        if raw.contains("<think>") { in_think = true; }
        for chunk in wrap_one(raw, inner_w) {
            let line = if chunk.starts_with("You:") {
                Line::from(Span::styled(chunk, Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)))
            } else if chunk.starts_with("Bot:") {
                Line::from(Span::styled(chunk, Style::default().fg(Color::Green).add_modifier(Modifier::BOLD)))
            } else if in_think {
                Line::from(Span::styled(chunk, Style::default().fg(Color::DarkGray).add_modifier(Modifier::ITALIC)))
            } else {
                Line::from(chunk)
            };
            styled.push(line);
        }
        if raw.contains("</think>") { in_think = false; }
    }
    let start = styled.len().saturating_sub(inner_h);
    let view: Vec<Line> = styled[start..].to_vec();

    let p = Paragraph::new(view)
        .block(Block::default().borders(Borders::ALL).title(" conversation "));
    f.render_widget(p, area);
}

fn draw_state(f: &mut Frame, area: Rect, app: &App) {
    let s = &app.snapshot;

    let outer = Block::default().borders(Borders::ALL).title(" therobot live state ");
    let inner = outer.inner(area);
    f.render_widget(outer, area);

    if !s.enabled {
        f.render_widget(
            Paragraph::new("stock model — no therobot state")
                .style(Style::default().fg(Color::DarkGray)),
            inner,
        );
        return;
    }

    // Fixed-height sections for modulator, probes, and the recall/delta footer;
    // the episodic-memory list fills whatever vertical space is left, so it is
    // never clipped away by the sections above it.
    let mod_h = (1 + s.modulator.len() + s.mod_latent.map_or(0, |_| 1)) as u16;
    let prb_h = (1 + s.probes.len().max(1)) as u16;
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(mod_h + 1),
            Constraint::Length(prb_h + 1),
            Constraint::Min(3),          // memory — takes the rest
            Constraint::Length(2),       // recall + delta footer
        ])
        .split(inner);

    // modulator
    let mut ml: Vec<Line> = vec![section("modulator")];
    for (name, v) in &s.modulator {
        ml.push(Line::from(vec![
            Span::styled(format!("  {name:<9} "), Style::default().fg(Color::Gray)),
            Span::raw(format!("{v:+.2} ")),
            Span::styled(bar(*v, -4.0, 4.0, 12), Style::default().fg(Color::Cyan)),
        ]));
    }
    if let Some((n, norm)) = s.mod_latent {
        ml.push(Line::from(Span::styled(
            format!("  latent×{n:<3} ‖·‖={norm:.2}  (memory content space)"),
            Style::default().fg(Color::DarkGray),
        )));
    }
    f.render_widget(Paragraph::new(ml), chunks[0]);

    // probes
    let mut pl: Vec<Line> = vec![section("probes (attr=class@conf)")];
    for tap in &s.probes {
        let mut spans = vec![Span::styled(
            format!("  {:<8} ", tap.name),
            Style::default().fg(Color::Yellow),
        )];
        for (attr, cls, conf) in &tap.attrs {
            spans.push(Span::raw(format!("{attr}={cls}@{conf:.2} ")));
        }
        pl.push(Line::from(spans));
    }
    f.render_widget(Paragraph::new(pl), chunks[1]);

    // episodic memory — fills the middle region, newest first, as many as fit
    let mem_area = chunks[2];
    let capacity = mem_area.height.saturating_sub(2).max(1) as usize; // minus 2 header rows
    let mut eml: Vec<Line> = vec![
        section(&format!("episodic memory · {} stored", s.mem_count)),
        Line::from(Span::styled(
            "  idx  salience  age  match  → re-instates",
            Style::default().fg(Color::DarkGray),
        )),
    ];
    if s.memory.is_empty() {
        eml.push(Line::from(Span::styled("  (none yet)", Style::default().fg(Color::DarkGray))));
    }
    for e in s.memory.iter().take(capacity) {
        let sc = salience_color(e.salience);
        let firing = e.match_cos > 0.3;
        // firing rows get a marker + a warmer match color
        let marker = if firing { "●" } else { " " };
        let mcolor = if e.match_cos > 0.6 {
            Color::Red
        } else if e.match_cos > 0.3 {
            Color::Yellow
        } else if e.match_cos > 0.0 {
            Color::Gray
        } else {
            Color::DarkGray
        };
        let mut spans = vec![
            Span::styled(marker.to_string(), Style::default().fg(Color::Green)),
            Span::styled(format!(" #{:<4}", e.idx), Style::default().fg(Color::DarkGray)),
            Span::styled(
                format!(" {:>6.2}", e.salience),
                Style::default().fg(sc).add_modifier(Modifier::BOLD),
            ),
            Span::styled(format!("  {:>4}t", e.age_tokens), Style::default().fg(Color::DarkGray)),
            Span::styled(format!("  {:>+.2}", e.match_cos), Style::default().fg(mcolor)),
        ];
        if let Some((ch, v)) = &e.inject {
            spans.push(Span::styled(
                format!("  →{ch}{v:+.1}"),
                Style::default().fg(Color::Green),
            ));
        }
        eml.push(Line::from(spans));
    }
    let shown = s.memory.len().min(capacity);
    if s.mem_count as usize > shown && shown > 0 {
        eml.push(Line::from(Span::styled(
            format!("  … +{} older", s.mem_count as usize - shown),
            Style::default().fg(Color::DarkGray),
        )));
    }
    f.render_widget(Paragraph::new(eml), mem_area);

    // footer: recall + delta
    let mut fl: Vec<Line> = Vec::new();
    if let Some(nr) = s.recall_norm {
        fl.push(Line::from(format!("‖recall‖ = {nr:.3}")));
    }
    if let Some((keep, toks)) = s.delta {
        fl.push(Line::from(format!("delta keep = {keep:.2} ({toks}t)")));
    }
    f.render_widget(Paragraph::new(fl), chunks[3]);
}

fn draw_input(f: &mut Frame, area: Rect, app: &App) {
    let title = if app.status.is_empty() {
        " message · Enter=send · /config (or ^E) · /reset · /quit · Esc=exit ".to_string()
    } else {
        format!(" {} ", app.status)
    };
    let p = Paragraph::new(Line::from(vec![
        Span::styled("> ", Style::default().add_modifier(Modifier::BOLD)),
        Span::raw(app.input.clone()),
    ]))
    .block(Block::default().borders(Borders::ALL).title(title));
    f.render_widget(p, area);
}

fn draw_menu(f: &mut Frame, area: Rect, app: &App) {
    let r = centered_rect(46, 60, area);
    f.render_widget(Clear, r);

    let mut lines: Vec<Line> = Vec::new();
    lines.push(Line::from(Span::styled(
        "adjust with ← →   move with ↑ ↓   Esc/Enter to close",
        Style::default().fg(Color::DarkGray),
    )));
    lines.push(Line::from(""));
    for i in 0..MENU_LEN {
        let selected = i == app.menu_idx;
        let marker = if selected { "▸ " } else { "  " };
        let style = if selected {
            Style::default().fg(Color::Black).bg(Color::Cyan).add_modifier(Modifier::BOLD)
        } else {
            Style::default()
        };
        lines.push(Line::from(Span::styled(
            format!("{marker}{:<16} {}", Params::label(i), app.params.value(i)),
            style,
        )));
    }

    let p = Paragraph::new(lines)
        .block(Block::default().borders(Borders::ALL).title(" hyperparameters ").title_alignment(Alignment::Center));
    f.render_widget(p, r);
}

fn section(title: &str) -> Line<'static> {
    Line::from(Span::styled(
        title.to_string(),
        Style::default().add_modifier(Modifier::BOLD).fg(Color::White),
    ))
}

// warmer/brighter = more salient (more "important" a write the gate judged it)
fn salience_color(s: f32) -> Color {
    if s < 3.0 {
        Color::DarkGray
    } else if s < 4.0 {
        Color::Gray
    } else if s < 5.0 {
        Color::Cyan
    } else if s < 6.0 {
        Color::Yellow
    } else {
        Color::Red
    }
}

fn bar(v: f32, lo: f32, hi: f32, w: usize) -> String {
    let f = ((v - lo) / (hi - lo)).clamp(0.0, 1.0);
    let n = (f * w as f32) as usize;
    let mut s = String::new();
    for i in 0..w {
        s.push(if i < n { '#' } else { '.' });
    }
    s
}

fn wrap_one(raw: &str, width: usize) -> Vec<String> {
    if raw.is_empty() {
        return vec![String::new()];
    }
    let mut out = Vec::new();
    let mut cur = String::new();
    for ch in raw.chars() {
        cur.push(ch);
        if cur.chars().count() >= width {
            out.push(std::mem::take(&mut cur));
        }
    }
    if !cur.is_empty() {
        out.push(cur);
    }
    out
}

fn centered_rect(pct_x: u16, pct_y: u16, area: Rect) -> Rect {
    let v = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage((100 - pct_y) / 2),
            Constraint::Percentage(pct_y),
            Constraint::Percentage((100 - pct_y) / 2),
        ])
        .split(area);
    Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage((100 - pct_x) / 2),
            Constraint::Percentage(pct_x),
            Constraint::Percentage((100 - pct_x) / 2),
        ])
        .split(v[1])[1]
}
