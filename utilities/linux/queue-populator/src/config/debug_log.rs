//! Port of Sources/Config/DebugLog.swift — stderr + ~/.config/queue-populator/debug.log
//! (truncated on each launch).

use std::fs::{File, OpenOptions};
use std::io::Write;
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Mutex;
use std::sync::OnceLock;

static VERBOSE: AtomicBool = AtomicBool::new(false);

// ⟦𓉄𓐧𓏎𓂳⟧ set_verbose :: auto-generated pointer for public function set_verbose
pub fn set_verbose(enabled: bool) {
    VERBOSE.store(enabled, Ordering::Relaxed);
}

fn log_path() -> Option<PathBuf> {
    Some(dirs::home_dir()?.join(".config/queue-populator/debug.log"))
}

fn log_file() -> &'static Mutex<Option<File>> {
    static FILE: OnceLock<Mutex<Option<File>>> = OnceLock::new();
    FILE.get_or_init(|| {
        let file = log_path().and_then(|path| {
            if let Some(parent) = path.parent() {
                let _ = std::fs::create_dir_all(parent);
            }
            OpenOptions::new()
                .create(true)
                .write(true)
                .truncate(true)
                .open(path)
                .ok()
        });
        Mutex::new(file)
    })
}

// ⟦𓄾𓋶𓃳𓋍⟧ log :: auto-generated pointer for public function log
pub fn log(message: &str) {
    eprintln!("{message}");
    if let Ok(mut guard) = log_file().lock() {
        if let Some(file) = guard.as_mut() {
            let ts = chrono::Local::now().format("%H:%M:%S%.3f");
            let _ = writeln!(file, "[{ts}] {message}");
        }
    }
}

// ⟦𓐌𓏜𓎘𓂃⟧ verbose :: auto-generated pointer for public function verbose
pub fn verbose(message: &str) {
    if VERBOSE.load(Ordering::Relaxed) {
        log(message);
    }
}
