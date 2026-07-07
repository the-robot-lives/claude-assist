//! Command/memo audio cues — replaces NSSound "Tink"/"Glass".
//! Tiny sine-blip WAVs are generated into the cache dir once, then played via
//! `pw-play` (ships with PipeWire) so we add no audio-output dependency.

use std::path::PathBuf;
use std::process::{Command, Stdio};

fn cache_dir() -> PathBuf {
    dirs::cache_dir()
        .unwrap_or_else(std::env::temp_dir)
        .join("queue-populator")
}

fn blip_path(name: &str, freq: f32, seconds: f32) -> Option<PathBuf> {
    let dir = cache_dir();
    let path = dir.join(format!("{name}.wav"));
    if path.is_file() {
        return Some(path);
    }
    std::fs::create_dir_all(&dir).ok()?;

    let sample_rate = 48_000u32;
    let frames = (seconds * sample_rate as f32) as usize;
    let spec = hound::WavSpec {
        channels: 1,
        sample_rate,
        bits_per_sample: 16,
        sample_format: hound::SampleFormat::Int,
    };
    let mut writer = hound::WavWriter::create(&path, spec).ok()?;
    for i in 0..frames {
        let t = i as f32 / sample_rate as f32;
        // Sine with a fast exponential decay — reads as a soft "tink".
        let envelope = (-t * 14.0).exp();
        let sample = (t * freq * std::f32::consts::TAU).sin() * envelope * 0.4;
        writer.write_sample((sample * i16::MAX as f32) as i16).ok()?;
    }
    writer.finalize().ok()?;
    Some(path)
}

fn play(path: PathBuf) {
    std::thread::spawn(move || {
        let _ = Command::new("pw-play")
            .arg(&path)
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();
    });
}

/// Short high blip on any recognized command ("Tink").
pub fn play_command() {
    if let Some(path) = blip_path("command", 1320.0, 0.25) {
        play(path);
    }
}

/// Two-tone lower chime when memo recording starts ("Glass").
pub fn play_memo() {
    if let Some(path) = blip_path("memo", 880.0, 0.4) {
        play(path);
    }
}
