//! robot-tui — a ratatui front-end for therobot models.
//!
//!   robot-tui -m <model.gguf> [-c n_ctx]
//!
//! Left pane: the chat. Right pane: live modulator / probes / episodic memory /
//! recall / delta. One token is generated per frame so the state animates as the
//! model decodes. Probes (which run a backend compute graph) are refreshed only
//! at turn boundaries, when no decode is in flight — safe for the Metal backend.

mod engine;
mod ffi;
mod state;
mod ui;

use anyhow::{anyhow, Result};
use crossterm::{
    event::{self, Event, KeyCode, KeyEvent, KeyModifiers},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{backend::CrosstermBackend, Terminal};
use std::io::stdout;
use std::time::Duration;

use engine::Engine;
use state::Snapshot;
use ui::{App, Mode, Params};

fn params_from_engine(eng: &Engine) -> Params {
    let sp = eng.sampler_params();
    Params {
        temp: sp.temp,
        top_k: sp.top_k,
        top_p: sp.top_p,
        min_p: sp.min_p,
        penalty_repeat: sp.penalty_repeat,
        penalty_last_n: sp.penalty_last_n,
        seed: sp.seed,
        arousal: 0.0,
    }
}

fn apply_params(eng: &mut Engine, p: &Params, sampler_changed: bool) {
    if sampler_changed {
        let mut sp = eng.sampler_params();
        sp.temp = p.temp;
        sp.top_k = p.top_k;
        sp.top_p = p.top_p;
        sp.min_p = p.min_p;
        sp.penalty_repeat = p.penalty_repeat;
        sp.penalty_last_n = p.penalty_last_n;
        sp.seed = p.seed;
        eng.set_sampler_params(sp);
    } else {
        eng.set_arousal(p.arousal);
    }
}

fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    let mut model_path = String::new();
    let mut n_ctx: u32 = 4096;
    let mut i = 1;
    while i < args.len() {
        match args[i].as_str() {
            "-m" | "--model" => { i += 1; model_path = args.get(i).cloned().unwrap_or_default(); }
            "-c" | "--ctx" => { i += 1; n_ctx = args.get(i).and_then(|s| s.parse().ok()).unwrap_or(4096); }
            "-h" | "--help" => { eprintln!("usage: robot-tui -m <model.gguf> [-c n_ctx]"); return Ok(()); }
            other => return Err(anyhow!("unknown arg: {other}")),
        }
        i += 1;
    }
    if model_path.is_empty() {
        return Err(anyhow!("need -m <model.gguf>"));
    }

    // send any llama/ggml stderr chatter to a log file so it can never land on
    // the TUI (belt-and-suspenders with the callback mute in Engine::load).
    unsafe {
        let logf = std::ffi::CString::new("robot-tui.log").unwrap();
        ffi::robot_log_to_file(logf.as_ptr());
    }

    let mut eng = Engine::load(&model_path, n_ctx)?;
    let snapshot = Snapshot::sample(&eng, true, &Snapshot::default());
    let params = params_from_engine(&eng);
    let model_name = model_path
        .rsplit('/')
        .next()
        .unwrap_or(&model_path)
        .trim_end_matches(".gguf")
        .to_string();
    let mut app = App {
        transcript: String::new(),
        input: String::new(),
        snapshot,
        status: String::new(),
        model_name,
        mode: Mode::Chat,
        params,
        menu_idx: 0,
    };
    if !app.snapshot.enabled {
        app.status = "stock model (no therobot extensions)".into();
    }

    // terminal setup
    enable_raw_mode()?;
    let mut out = stdout();
    execute!(out, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(out);
    let mut term = Terminal::new(backend)?;

    let res = run(&mut term, &mut eng, &mut app);

    // teardown (always, even on error)
    disable_raw_mode()?;
    execute!(term.backend_mut(), LeaveAlternateScreen)?;
    term.show_cursor()?;
    res
}

fn run<B: ratatui::backend::Backend>(
    term: &mut Terminal<B>,
    eng: &mut Engine,
    app: &mut App,
) -> Result<()> {
    term.clear()?; // start from a clean buffer
    loop {
        term.draw(|f| ui::draw(f, app))?;

        // stream a token per frame while generating
        if eng.generating {
            match eng.step() {
                Some(piece) => {
                    app.transcript.push_str(&piece);
                    app.snapshot = Snapshot::sample(eng, false, &app.snapshot); // host-only
                }
                None => {
                    // turn finished, backend idle → safe to evaluate probes
                    app.transcript.push('\n');
                    app.snapshot = Snapshot::sample(eng, true, &app.snapshot);
                    app.status.clear();
                }
            }
        }

        // input handling — short poll so generation keeps ticking
        let timeout = if eng.generating { Duration::from_millis(1) } else { Duration::from_millis(80) };
        if event::poll(timeout)? {
            if let Event::Key(key) = event::read()? {
                if handle_key(key, eng, app)? {
                    return Ok(());
                }
            }
        }
    }
}

/// returns true to quit
fn handle_key(key: KeyEvent, eng: &mut Engine, app: &mut App) -> Result<bool> {
    // Ctrl-C always exits
    if key.code == KeyCode::Char('c') && key.modifiers.contains(KeyModifiers::CONTROL) {
        return Ok(true);
    }
    // Ctrl-E toggles the hyperparameter menu (live, even mid-generation)
    if key.code == KeyCode::Char('e') && key.modifiers.contains(KeyModifiers::CONTROL) {
        app.mode = if app.mode == Mode::Menu { Mode::Chat } else { Mode::Menu };
        return Ok(false);
    }

    // ---- menu mode: edit hyperparameters ----
    if app.mode == Mode::Menu {
        match key.code {
            KeyCode::Esc | KeyCode::Enter => app.mode = Mode::Chat,
            KeyCode::Up => { if app.menu_idx > 0 { app.menu_idx -= 1; } }
            KeyCode::Down => { if app.menu_idx + 1 < ui::MENU_LEN { app.menu_idx += 1; } }
            KeyCode::Left | KeyCode::Right => {
                let dir = if key.code == KeyCode::Right { 1.0 } else { -1.0 };
                let sampler_changed = app.params.adjust(app.menu_idx, dir);
                apply_params(eng, &app.params, sampler_changed);
            }
            _ => {}
        }
        return Ok(false);
    }

    // Esc exits from chat mode
    if key.code == KeyCode::Esc {
        return Ok(true);
    }
    // ignore typing while the model is generating (except exits above)
    if eng.generating {
        return Ok(false);
    }
    match key.code {
        KeyCode::Char(c) => app.input.push(c),
        KeyCode::Backspace => { app.input.pop(); }
        KeyCode::Enter => {
            let line = std::mem::take(&mut app.input);
            let line = line.trim().to_string();
            if line.is_empty() {
                return Ok(false);
            }
            if line == "/quit" || line == "/exit" {
                return Ok(true);
            }
            if line == "/config" || line == "/params" {
                app.mode = Mode::Menu;
                return Ok(false);
            }
            if line == "/reset" {
                eng.reset_session(true);
                app.transcript.push_str("\n[session reset]\n");
                app.snapshot = Snapshot::sample(eng, true, &app.snapshot);
                return Ok(false);
            }
            app.transcript.push_str(&format!("\nYou: {line}\nBot: "));
            app.status = "generating…".into();
            eng.begin_turn(&line)?;
        }
        _ => {}
    }
    Ok(false)
}
