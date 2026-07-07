//! Speech engine — replaces Sources/Audio/SpeechEngine.swift.
//!
//! Consumes 48 kHz mono f32 chunks from the audio capture channel, feeds a
//! sherpa-onnx streaming zipformer (which resamples internally to 16 kHz),
//! and emits partial/final transcript events mirroring the
//! SpeechEngineDelegate callbacks. Endpoint detection finalizes utterances;
//! unlike SFSpeechRecognizer there is no ~1-minute limit, so no restart timer.

use anyhow::{Context, Result};
use crossbeam_channel::{Receiver, Sender};
use sherpa_onnx::{OnlineRecognizer, OnlineRecognizerConfig};

use super::models::ModelPaths;
use crate::audio::SAMPLE_RATE;

#[derive(Debug, Clone, PartialEq)]
pub enum SpeechEvent {
    /// Live hypothesis for the current utterance.
    Partial(String),
    /// Utterance finalized by endpoint detection.
    Final(String),
    /// Recognition error (engine keeps running unless fatal).
    Error(String),
}

/// Audio chunks also flow to whoever needs raw samples (memo recorder) via
/// this tap, invoked on the engine thread before recognition.
pub type AudioTap = Box<dyn Fn(&[f32]) + Send>;

pub struct SpeechEngine {
    thread: Option<std::thread::JoinHandle<()>>,
    stop_tx: Sender<()>,
}

impl SpeechEngine {
    pub fn start(
        models: ModelPaths,
        audio_rx: Receiver<Vec<f32>>,
        events_tx: Sender<SpeechEvent>,
        audio_tap: Option<AudioTap>,
    ) -> Result<Self> {
        let recognizer = build_recognizer(&models)?;
        let (stop_tx, stop_rx) = crossbeam_channel::bounded::<()>(1);

        let thread = std::thread::Builder::new()
            .name("stt-engine".into())
            .spawn(move || run_loop(recognizer, audio_rx, events_tx, audio_tap, stop_rx))?;

        Ok(Self { thread: Some(thread), stop_tx })
    }

    pub fn stop(mut self) {
        let _ = self.stop_tx.send(());
        if let Some(thread) = self.thread.take() {
            let _ = thread.join();
        }
    }
}

fn build_recognizer(models: &ModelPaths) -> Result<OnlineRecognizer> {
    let mut config = OnlineRecognizerConfig::default();
    config.model_config.transducer.encoder = Some(models.encoder.to_string_lossy().into_owned());
    config.model_config.transducer.decoder = Some(models.decoder.to_string_lossy().into_owned());
    config.model_config.transducer.joiner = Some(models.joiner.to_string_lossy().into_owned());
    config.model_config.tokens = Some(models.tokens.to_string_lossy().into_owned());
    config.model_config.num_threads = 2;
    config.decoding_method = Some("greedy_search".into());
    // Endpointing tuned for command + dictation use:
    //  rule1: long trailing silence with no speech decoded yet
    //  rule2: shorter trailing silence after some speech
    //  rule3: hard cap on utterance length
    config.enable_endpoint = true;
    config.rule1_min_trailing_silence = 2.4;
    config.rule2_min_trailing_silence = 1.2;
    config.rule3_min_utterance_length = 30.0;

    OnlineRecognizer::create(&config).context("failed to create sherpa-onnx online recognizer")
}

fn run_loop(
    recognizer: OnlineRecognizer,
    audio_rx: Receiver<Vec<f32>>,
    events_tx: Sender<SpeechEvent>,
    audio_tap: Option<AudioTap>,
    stop_rx: Receiver<()>,
) {
    let stream = recognizer.create_stream();
    let mut last_partial = String::new();

    loop {
        crossbeam_channel::select! {
            recv(stop_rx) -> _ => return,
            recv(audio_rx) -> chunk => {
                let Ok(chunk) = chunk else { return }; // channel closed
                if let Some(tap) = &audio_tap {
                    tap(&chunk);
                }
                stream.accept_waveform(SAMPLE_RATE as i32, &chunk);
                while recognizer.is_ready(&stream) {
                    recognizer.decode(&stream);
                }

                let text = recognizer
                    .get_result(&stream)
                    .map(|r| r.text)
                    .unwrap_or_default();

                if recognizer.is_endpoint(&stream) {
                    let final_text = text.trim().to_string();
                    if !final_text.is_empty() {
                        let _ = events_tx.send(SpeechEvent::Final(final_text));
                    }
                    last_partial.clear();
                    recognizer.reset(&stream);
                } else if !text.is_empty() && text != last_partial {
                    last_partial = text.clone();
                    if events_tx.send(SpeechEvent::Partial(text)).is_err() {
                        return;
                    }
                }
            }
        }
    }
}
