use std::sync::Arc;

use queue_populator::audio::memo_recorder::MemoRecorder;
use queue_populator::audio::AudioSystem;
use queue_populator::config::{self, store};
use queue_populator::coordinator::{Coordinator, CoordinatorMsg, UiUpdate};
use queue_populator::stt::engine::{SpeechEngine, SpeechEvent};
use queue_populator::stt::models;
use queue_populator::ui::app::QueuePopulatorApp;
use queue_populator::ui::tray::{QueuePopulatorTray, TrayState};

fn main() {
    let app_config = match config::AppConfig::parse(std::env::args().skip(1)) {
        Ok(cfg) => cfg,
        Err(msg) => {
            eprint!("{msg}");
            std::process::exit(2);
        }
    };

    if app_config.help {
        print!("{}", config::AppConfig::usage());
        return;
    }

    config::debug_log::set_verbose(app_config.verbose);

    let config = store::load_config();

    if app_config.check {
        std::process::exit(run_check());
    }

    // ---- channels -----------------------------------------------------------
    let (audio_tx, audio_rx) = crossbeam_channel::bounded::<Vec<f32>>(64);
    let (speech_tx, speech_rx) = crossbeam_channel::unbounded::<SpeechEvent>();
    let (coord_tx, coord_rx) = crossbeam_channel::unbounded::<CoordinatorMsg>();
    let (ui_tx, ui_rx) = crossbeam_channel::unbounded::<UiUpdate>();
    let (show_tx, show_rx) = crossbeam_channel::unbounded::<()>();
    let (quit_window_tx, quit_window_rx) = crossbeam_channel::bounded::<()>(1);

    // ---- audio ---------------------------------------------------------------
    let audio = match AudioSystem::start(config.recognition.input_device_id.clone(), audio_tx) {
        Ok(audio) => audio,
        Err(e) => {
            eprintln!("queue-populator: audio startup failed: {e}");
            std::process::exit(1);
        }
    };

    // ---- speech engine ---------------------------------------------------------
    let memo_recorder = Arc::new(MemoRecorder::with_max_recording_seconds(
        config.recognition.max_recording_seconds,
    ));
    let memo_tap = memo_recorder.clone();
    let stt_models = match models::locate() {
        Ok(models) => models,
        Err(e) => {
            eprintln!("queue-populator: {e}");
            audio.shutdown();
            std::process::exit(1);
        }
    };
    let speech_engine = match SpeechEngine::start(
        stt_models,
        audio_rx,
        speech_tx,
        Some(Box::new(move |samples| memo_tap.append(samples))),
    ) {
        Ok(engine) => engine,
        Err(e) => {
            eprintln!("queue-populator: speech engine failed: {e}");
            audio.shutdown();
            std::process::exit(1);
        }
    };

    // Forward speech events onto the coordinator channel.
    let speech_forward_thread = {
        let coord_tx = coord_tx.clone();
        match std::thread::Builder::new()
            .name("speech-forward".into())
            .spawn(move || {
                for event in speech_rx {
                    if coord_tx.send(CoordinatorMsg::Speech(event)).is_err() {
                        return;
                    }
                }
            })
        {
            Ok(thread) => thread,
            Err(e) => {
                eprintln!("queue-populator: cannot start speech-forward thread: {e}");
                speech_engine.stop();
                audio.shutdown();
                std::process::exit(1);
            }
        }
    };

    // ---- coordinator -------------------------------------------------------------
    let coordinator = Coordinator::new(
        config.clone(),
        audio.router.clone(),
        memo_recorder,
        coord_rx,
        coord_tx.clone(),
        ui_tx,
    );
    let coordinator_thread = match std::thread::Builder::new()
        .name("coordinator".into())
        .spawn(move || coordinator.run())
    {
        Ok(thread) => thread,
        Err(e) => {
            eprintln!("queue-populator: cannot start coordinator thread: {e}");
            speech_engine.stop();
            let _ = speech_forward_thread.join();
            audio.shutdown();
            std::process::exit(1);
        }
    };

    // ---- tray ------------------------------------------------------------------
    // ksni runs its own D-Bus service; the handle lets us push state updates.
    use ksni::blocking::TrayMethods as _;
    let tray_handle = QueuePopulatorTray {
        state: TrayState::Idle,
        paused: false,
        coordinator: coord_tx.clone(),
        show_window: show_tx,
        quit_window: quit_window_tx,
    }
    .spawn()
    .map_err(|e| eprintln!("queue-populator: tray unavailable: {e}"))
    .ok();

    // ---- UI updates fan-out: tray mirror + egui feed ------------------------------
    let (ui_app_tx, ui_app_rx) = crossbeam_channel::unbounded::<UiUpdate>();
    let ui_fanout_started = {
        let tray_handle = tray_handle.clone();
        std::thread::Builder::new()
            .name("ui-fanout".into())
            .spawn(move || {
                for update in ui_rx {
                    if let Some(handle) = &tray_handle {
                        match &update {
                            UiUpdate::State(state) => {
                                let tray_state = TrayState::from_app_state(state);
                                handle.update(move |tray| tray.state = tray_state);
                            }
                            UiUpdate::Paused(paused) => {
                                let paused = *paused;
                                handle.update(move |tray| tray.paused = paused);
                            }
                            _ => {}
                        }
                    }
                    if ui_app_tx.send(update).is_err() {
                        return;
                    }
                }
            })
    };
    if let Err(e) = ui_fanout_started {
        eprintln!("queue-populator: cannot start UI fan-out thread: {e}");
        let _ = coord_tx.send(CoordinatorMsg::Quit);
        let _ = coordinator_thread.join();
        speech_engine.stop();
        let _ = speech_forward_thread.join();
        audio.shutdown();
        std::process::exit(1);
    }

    // ---- eframe (main thread; blocks until quit) ------------------------------------
    let show_transcript = config.ui.show_transcript_window;
    let app = QueuePopulatorApp::new(
        config,
        ui_app_rx,
        coord_tx.clone(),
        show_rx,
        quit_window_rx,
    );
    let options = eframe::NativeOptions {
        viewport: eframe::egui::ViewportBuilder::default()
            .with_title("Queue Populator")
            .with_inner_size([720.0, 640.0])
            .with_visible(show_transcript),
        ..Default::default()
    };
    if let Err(e) = eframe::run_native(
        "queue-populator",
        options,
        Box::new(move |_| Ok(Box::new(app))),
    ) {
        eprintln!("queue-populator: UI failed: {e}");
    }

    // ---- shutdown -------------------------------------------------------------------
    let _ = coord_tx.send(CoordinatorMsg::Quit);
    let _ = coordinator_thread.join();
    speech_engine.stop();
    let _ = speech_forward_thread.join();
    audio.shutdown();
}

/// `--check`: verify models and PipeWire are usable, then exit.
fn run_check() -> i32 {
    let mut failures = 0;

    match models::locate() {
        Ok(_) => println!("✓ STT models present ({})", models::model_root().display()),
        Err(e) => {
            println!("✗ {e}");
            failures += 1;
        }
    }

    let virtual_nodes = ["robot_recording", "robot_claude", "robot_codex", "robot_llama"];
    match std::process::Command::new("pw-cli").args(["ls", "Node"]).output() {
        Ok(output) => {
            let listing = String::from_utf8_lossy(&output.stdout);
            for node in virtual_nodes {
                if listing.contains(node) {
                    println!("✓ virtual source {node}");
                } else {
                    println!("✗ virtual source {node} missing — install config/10-robot-virtual-mics.conf and restart pipewire");
                    failures += 1;
                }
            }
        }
        Err(e) => {
            println!("✗ pw-cli unavailable: {e}");
            failures += 1;
        }
    }

    for tool in ["ffmpeg", "pw-play"] {
        let found = std::process::Command::new(tool)
            .arg("--version")
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .status()
            .is_ok();
        if found {
            println!("✓ {tool}");
        } else {
            println!("△ {tool} not found ({})", if tool == "ffmpeg" { "memo MP3 export disabled" } else { "sound cues disabled" });
        }
    }

    if failures == 0 {
        println!("all checks passed");
        0
    } else {
        1
    }
}
