//! Port of Sources/Audio/MemoAudioRecorder.swift.
//! Accumulates mono f32 samples while recording (appended from the speech
//! engine thread — not the realtime callback), then exports
//! `<output-dir>/memo-<yyyyMMdd-HHmmss>.mp3` via ffmpeg on approval.

use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{Mutex, MutexGuard};

use anyhow::{bail, Context, Result};

use super::SAMPLE_RATE;
use crate::config::MAX_RECORDING_SECONDS;

struct Active {
    samples: Vec<f32>,
    output_dir: PathBuf,
    stamp: String,
}

pub struct MemoRecorder {
    active: Mutex<Option<Active>>,
    max_samples: AtomicUsize,
}

impl MemoRecorder {
    pub fn new() -> Self {
        Self::with_max_recording_seconds(300)
    }

    pub fn with_max_recording_seconds(seconds: u32) -> Self {
        let recorder = Self {
            active: Mutex::new(None),
            max_samples: AtomicUsize::new(0),
        };
        recorder.set_max_recording_seconds(seconds);
        recorder
    }

    pub fn set_max_recording_seconds(&self, seconds: u32) {
        let seconds = usize::try_from(seconds.clamp(1, MAX_RECORDING_SECONDS))
            .unwrap_or(MAX_RECORDING_SECONDS as usize);
        self.max_samples
            .store(seconds.saturating_mul(SAMPLE_RATE as usize), Ordering::Relaxed);
    }

    pub fn is_recording(&self) -> bool {
        self.lock_active().is_some()
    }

    /// Begin buffering. `output_dir` is where the MP3 lands on export.
    pub fn start(&self, output_dir: &Path) -> Result<()> {
        std::fs::create_dir_all(output_dir)
            .with_context(|| format!("cannot create {}", output_dir.display()))?;
        let stamp = chrono::Local::now().format("%Y%m%d-%H%M%S").to_string();
        *self.lock_active() = Some(Active {
            samples: Vec::new(),
            output_dir: output_dir.to_path_buf(),
            stamp,
        });
        Ok(())
    }

    /// Append captured samples (48 kHz mono f32). No-op when not recording.
    pub fn append(&self, samples: &[f32]) {
        if let Some(active) = self.lock_active().as_mut() {
            let remaining = self
                .max_samples
                .load(Ordering::Relaxed)
                .saturating_sub(active.samples.len());
            active.samples.extend_from_slice(&samples[..samples.len().min(remaining)]);
        }
    }

    pub fn cancel(&self) {
        *self.lock_active() = None;
    }

    /// Stop and export as MP3. Returns None when no audio frames were captured.
    pub fn stop_and_export_mp3(&self) -> Result<Option<PathBuf>> {
        let Some(active) = self.lock_active().take() else {
            return Ok(None);
        };
        if active.samples.is_empty() {
            return Ok(None);
        }

        let (wav_path, mp3_path, fallback_wav_path) =
            unique_output_paths(&active.output_dir, &active.stamp)?;

        write_wav(&wav_path, &active.samples)?;
        finish_mp3_export(&wav_path, &mp3_path, &fallback_wav_path, || {
            convert_to_mp3(&wav_path, &mp3_path)
        })
        .map(Some)
    }

    fn lock_active(&self) -> MutexGuard<'_, Option<Active>> {
        self.active.lock().unwrap_or_else(|poisoned| poisoned.into_inner())
    }
}

fn unique_output_paths(output_dir: &Path, stamp: &str) -> Result<(PathBuf, PathBuf, PathBuf)> {
    for sequence in 0..=u32::MAX {
        let suffix = if sequence == 0 {
            String::new()
        } else {
            format!("-{sequence}")
        };
        let stem = format!("memo-{stamp}{suffix}");
        let temporary_wav = output_dir.join(format!(".{stem}.wav"));
        let mp3 = output_dir.join(format!("{stem}.mp3"));
        let fallback_wav = output_dir.join(format!("{stem}.wav"));
        if !temporary_wav.exists() && !mp3.exists() && !fallback_wav.exists() {
            return Ok((temporary_wav, mp3, fallback_wav));
        }
    }
    bail!("no unused memo filename remains for timestamp {stamp}")
}

fn finish_mp3_export(
    temporary_wav: &Path,
    mp3: &Path,
    fallback_wav: &Path,
    convert: impl FnOnce() -> Result<()>,
) -> Result<PathBuf> {
    match convert() {
        Ok(()) => {
            let _ = std::fs::remove_file(temporary_wav);
            Ok(mp3.to_path_buf())
        }
        Err(conversion_error) => match std::fs::rename(temporary_wav, fallback_wav) {
            Ok(()) => bail!(
                "MP3 conversion failed: {conversion_error}; WAV preserved at {}",
                fallback_wav.display()
            ),
            Err(rename_error) => bail!(
                "MP3 conversion failed: {conversion_error}; could not expose temporary WAV {} as {}: {rename_error}",
                temporary_wav.display(),
                fallback_wav.display()
            ),
        },
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

    #[test]
    fn failed_mp3_conversion_preserves_visible_wav() {
        let dir = tempfile::tempdir().unwrap();
        let temporary = dir.path().join(".memo-test.wav");
        let mp3 = dir.path().join("memo-test.mp3");
        let fallback = dir.path().join("memo-test.wav");
        std::fs::write(&temporary, b"wav data").unwrap();

        let error = finish_mp3_export(&temporary, &mp3, &fallback, || {
            bail!("encoder unavailable")
        })
        .unwrap_err();

        assert!(error.to_string().contains("encoder unavailable"));
        assert!(error.to_string().contains("WAV preserved"));
        assert_eq!(std::fs::read(&fallback).unwrap(), b"wav data");
        assert!(!temporary.exists());
    }

    #[test]
    fn memo_paths_do_not_overwrite_existing_recording() {
        let dir = tempfile::tempdir().unwrap();
        std::fs::write(dir.path().join("memo-stamp.mp3"), b"existing").unwrap();

        let (temporary, mp3, fallback) = unique_output_paths(dir.path(), "stamp").unwrap();

        assert_eq!(temporary.file_name().unwrap(), ".memo-stamp-1.wav");
        assert_eq!(mp3.file_name().unwrap(), "memo-stamp-1.mp3");
        assert_eq!(fallback.file_name().unwrap(), "memo-stamp-1.wav");
    }

    #[test]
    fn poisoned_recorder_lock_is_recovered() {
        let recorder = MemoRecorder::new();
        let _ = std::panic::catch_unwind(|| {
            let _guard = recorder.active.lock().unwrap();
            panic!("seed lock poison");
        });

        assert!(!recorder.is_recording());
        recorder.cancel();
    }

    #[test]
    fn recording_buffer_is_hard_capped() {
        let dir = tempfile::tempdir().unwrap();
        let recorder = MemoRecorder::with_max_recording_seconds(1);
        recorder.start(dir.path()).unwrap();
        recorder.append(&vec![0.25; SAMPLE_RATE as usize + 1024]);

        let samples = recorder.lock_active();
        assert_eq!(samples.as_ref().unwrap().samples.len(), SAMPLE_RATE as usize);

        let bounded = MemoRecorder::with_max_recording_seconds(u32::MAX);
        assert_eq!(
            bounded.max_samples.load(Ordering::Relaxed),
            MAX_RECORDING_SECONDS as usize * SAMPLE_RATE as usize
        );
    }
}

impl Default for MemoRecorder {
    fn default() -> Self {
        Self::new()
    }
}
