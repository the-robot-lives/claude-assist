//! Port of Sources/Audio/MemoAudioRecorder.swift.
//! Accumulates mono f32 samples while recording (appended from the speech
//! engine thread — not the realtime callback), then exports
//! `<output-dir>/memo-<yyyyMMdd-HHmmss>.mp3` via ffmpeg on approval.

use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::Mutex;

use anyhow::{bail, Context, Result};

use super::SAMPLE_RATE;

struct Active {
    samples: Vec<f32>,
    output_dir: PathBuf,
    stamp: String,
}

#[derive(Default)]
pub struct MemoRecorder {
    active: Mutex<Option<Active>>,
}

impl MemoRecorder {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn is_recording(&self) -> bool {
        self.active.lock().unwrap().is_some()
    }

    /// Begin buffering. `output_dir` is where the MP3 lands on export.
    pub fn start(&self, output_dir: &Path) -> Result<()> {
        std::fs::create_dir_all(output_dir)
            .with_context(|| format!("cannot create {}", output_dir.display()))?;
        let stamp = chrono::Local::now().format("%Y%m%d-%H%M%S").to_string();
        *self.active.lock().unwrap() = Some(Active {
            samples: Vec::new(),
            output_dir: output_dir.to_path_buf(),
            stamp,
        });
        Ok(())
    }

    /// Append captured samples (48 kHz mono f32). No-op when not recording.
    pub fn append(&self, samples: &[f32]) {
        if let Some(active) = self.active.lock().unwrap().as_mut() {
            active.samples.extend_from_slice(samples);
        }
    }

    pub fn cancel(&self) {
        *self.active.lock().unwrap() = None;
    }

    /// Stop and export as MP3. Returns None when no audio frames were captured.
    pub fn stop_and_export_mp3(&self) -> Result<Option<PathBuf>> {
        let Some(active) = self.active.lock().unwrap().take() else {
            return Ok(None);
        };
        if active.samples.is_empty() {
            return Ok(None);
        }

        let wav_path = active.output_dir.join(format!(".memo-{}.wav", active.stamp));
        let mp3_path = active.output_dir.join(format!("memo-{}.mp3", active.stamp));

        write_wav(&wav_path, &active.samples)?;
        let result = convert_to_mp3(&wav_path, &mp3_path);
        let _ = std::fs::remove_file(&wav_path);
        result?;
        Ok(Some(mp3_path))
    }
}

fn write_wav(path: &Path, samples: &[f32]) -> Result<()> {
    let spec = hound::WavSpec {
        channels: 1,
        sample_rate: SAMPLE_RATE,
        bits_per_sample: 16,
        sample_format: hound::SampleFormat::Int,
    };
    let mut writer = hound::WavWriter::create(path, spec)
        .with_context(|| format!("cannot create {}", path.display()))?;
    for &sample in samples {
        let clamped = (sample.clamp(-1.0, 1.0) * i16::MAX as f32) as i16;
        writer.write_sample(clamped)?;
    }
    writer.finalize()?;
    Ok(())
}

fn convert_to_mp3(wav: &Path, mp3: &Path) -> Result<()> {
    // Prefer ffmpeg; fall back to lame.
    let ffmpeg = Command::new("ffmpeg")
        .args(["-y", "-loglevel", "error", "-i"])
        .arg(wav)
        .args(["-codec:a", "libmp3lame", "-qscale:a", "4"])
        .arg(mp3)
        .status();
    match ffmpeg {
        Ok(status) if status.success() => return Ok(()),
        Ok(status) => eprintln!("queue-populator: ffmpeg exited with {status}"),
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => {}
        Err(e) => eprintln!("queue-populator: ffmpeg failed: {e}"),
    }

    let lame = Command::new("lame")
        .args(["--quiet", "-V4"])
        .arg(wav)
        .arg(mp3)
        .status();
    match lame {
        Ok(status) if status.success() => Ok(()),
        Ok(status) => bail!("lame exited with {status}"),
        Err(e) => bail!("mp3 conversion needs ffmpeg or lame installed: {e}"),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn lifecycle_without_export() {
        let dir = tempfile::tempdir().unwrap();
        let recorder = MemoRecorder::new();
        assert!(!recorder.is_recording());
        recorder.append(&[0.5; 100]); // ignored — not recording

        recorder.start(dir.path()).unwrap();
        assert!(recorder.is_recording());
        recorder.append(&[0.5; 100]);
        recorder.cancel();
        assert!(!recorder.is_recording());
        assert_eq!(recorder.stop_and_export_mp3().unwrap(), None);
    }

    #[test]
    fn empty_export_is_none() {
        let dir = tempfile::tempdir().unwrap();
        let recorder = MemoRecorder::new();
        recorder.start(dir.path()).unwrap();
        assert_eq!(recorder.stop_and_export_mp3().unwrap(), None);
    }

    #[test]
    fn wav_write_shape() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("test.wav");
        write_wav(&path, &[0.0, 0.5, -0.5, 1.0, -1.0]).unwrap();
        let reader = hound::WavReader::open(&path).unwrap();
        assert_eq!(reader.spec().channels, 1);
        assert_eq!(reader.spec().sample_rate, SAMPLE_RATE);
        assert_eq!(reader.len(), 5);
    }
}
