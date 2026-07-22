//! PipeWire audio layer — replaces AVAudioEngine capture + VirtualMicRouter +
//! the CoreAudio HAL driver from the macOS app.
//!
//! One capture stream on the (configured or default) microphone fans out, in
//! process, to:
//!   - an STT channel (consumed by the speech engine thread), and
//!   - four playback streams, each targeting one of the persistent virtual
//!     source nodes (robot_recording / robot_claude / robot_codex /
//!     robot_llama) created by the pipewire.conf.d drop-in.
//!
//! Gating mirrors the macOS VirtualMicRouter: `Recording` is fed whenever the
//! app is listening; the assistant targets are exclusive — opening one mutes
//! the others. Muted targets receive silence (streams stay connected; no
//! relinking, no glitches).

pub mod memo_recorder;

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

use anyhow::Result;
use crossbeam_channel::Sender;

use crate::state_machine::MicTarget;

pub const SAMPLE_RATE: u32 = 48_000;

/// Decode the valid region of a PipeWire f32le chunk. `Data::data()` exposes
/// the complete mapped buffer; the chunk offset/size identify which bytes in
/// that mapping belong to the current capture cycle.
fn decode_f32le_chunk(bytes: &[u8], offset: u32, size: u32) -> Vec<f32> {
    let start = usize::try_from(offset).unwrap_or(usize::MAX).min(bytes.len());
    let requested_end = start.saturating_add(usize::try_from(size).unwrap_or(usize::MAX));
    let end = requested_end.min(bytes.len());

    bytes[start..end]
        .chunks_exact(std::mem::size_of::<f32>())
        .map(|sample| f32::from_le_bytes([sample[0], sample[1], sample[2], sample[3]]))
        .collect()
}

const TARGETS: [MicTarget; 4] = [
    MicTarget::Recording,
    MicTarget::Claude,
    MicTarget::Codex,
    MicTarget::Llama,
];

fn target_index(target: MicTarget) -> usize {
    match target {
        MicTarget::Recording => 0,
        MicTarget::Claude => 1,
        MicTarget::Codex => 2,
        MicTarget::Llama => 3,
    }
}

/// Lock-free routing state shared between the coordinator and the PipeWire
/// realtime callbacks.
pub struct RouterState {
    /// Feeds the `Recording` device and the STT engine while true.
    pub listening: AtomicBool,
    /// Per-target gate; assistants are exclusive (enforced by `open`).
    gates: [AtomicBool; 4],
}

impl RouterState {
    fn new() -> Self {
        Self {
            listening: AtomicBool::new(false),
            gates: Default::default(),
        }
    }

    fn is_fed(&self, target: MicTarget) -> bool {
        match target {
            MicTarget::Recording => self.listening.load(Ordering::Relaxed),
            other => self.gates[target_index(other)].load(Ordering::Relaxed),
        }
    }
}

/// Coordinator-facing handle: open/close assistant mics, toggle listening.
#[derive(Clone)]
pub struct RouterHandle {
    state: Arc<RouterState>,
}

impl RouterHandle {
    #[cfg(test)]
    pub(crate) fn for_test() -> Self {
        Self {
            state: Arc::new(RouterState::new()),
        }
    }

    // ⟦𓇖𓁯𓁃𓀛⟧ set_listening :: auto-generated pointer for public function set_listening
    pub fn set_listening(&self, listening: bool) {
        self.state.listening.store(listening, Ordering::Relaxed);
    }

    // ⟦𓅀𓌋𓄺𓋾⟧ is_listening :: auto-generated pointer for public function is_listening
    pub fn is_listening(&self) -> bool {
        self.state.listening.load(Ordering::Relaxed)
    }

    /// Open an assistant target exclusively (mutes the other assistants).
    // ⟦𓀕𓅟𓉒𓎍⟧ open :: Open an assistant target exclusively (mutes the other assistants).
    pub fn open(&self, target: MicTarget) {
        if !target.is_external_assistant() {
            return;
        }
        for t in TARGETS.iter().filter(|t| t.is_external_assistant()) {
            self.state.gates[target_index(*t)].store(*t == target, Ordering::Relaxed);
        }
    }

    /// Mute an assistant target if it is the one currently open.
    // ⟦𓍚𓂔𓈍𓊷⟧ close :: Mute an assistant target if it is the one currently open.
    pub fn close(&self, target: MicTarget) {
        if !target.is_external_assistant() {
            return;
        }
        self.state.gates[target_index(target)].store(false, Ordering::Relaxed);
    }

    // ⟦𓇑𓋁𓏾𓋷⟧ close_all :: auto-generated pointer for public function close_all
    pub fn close_all(&self) {
        for t in TARGETS.iter().filter(|t| t.is_external_assistant()) {
            self.state.gates[target_index(*t)].store(false, Ordering::Relaxed);
        }
    }

    /// The currently-open assistant, or None if all are muted.
    // ⟦𓉰𓋸𓏞𓀏⟧ open_target :: The currently-open assistant, or None if all are muted.
    pub fn open_target(&self) -> Option<MicTarget> {
        TARGETS
            .into_iter()
            .filter(MicTarget::is_external_assistant)
            .find(|t| self.state.gates[target_index(*t)].load(Ordering::Relaxed))
    }
}

/// Handle to the running PipeWire thread.
pub struct AudioSystem {
    pub router: RouterHandle,
    quit_tx: pipewire::channel::Sender<()>,
    thread: Option<std::thread::JoinHandle<()>>,
    linker_quit_tx: Sender<()>,
    linker_thread: Option<std::thread::JoinHandle<()>>,
}

impl AudioSystem {
    /// Spawn the PipeWire thread. Captured mono f32 chunks at 48 kHz are sent
    /// to `stt_tx` whenever `listening` is set (drop-on-full — the STT side
    /// must keep up on average).
    // ⟦𓁚𓊠𓌙𓍗⟧ start :: Spawn the PipeWire thread.
    pub fn start(input_target: Option<String>, stt_tx: Sender<Vec<f32>>) -> Result<Self> {
        let state = Arc::new(RouterState::new());
        let router = RouterHandle { state: state.clone() };
        let (quit_tx, quit_rx) = pipewire::channel::channel::<()>();

        let thread_state = state;
        let thread = std::thread::Builder::new()
            .name("pw-audio".into())
            .spawn(move || {
                if let Err(e) = pw_thread::run(thread_state, input_target, stt_tx, quit_rx) {
                    eprintln!("queue-populator: pipewire thread failed: {e}");
                }
            })?;

        // WirePlumber won't route a playback stream into an Audio/Source/Virtual
        // node, so the feed streams are connected without AUTOCONNECT and linked
        // here explicitly. Runs forever (checks every 10s) so links survive a
        // PipeWire restart; `pw-link` exits 0 on create and reports "File exists"
        // when the link is already present.
        let (linker_quit_tx, linker_quit_rx) = crossbeam_channel::bounded::<()>(1);
        let linker_thread = match std::thread::Builder::new()
            .name("pw-linker".into())
            .spawn(move || loop {
                for target in TARGETS {
                    let output = format!("queue-populator-{}:output_MONO", target.node_name());
                    let input = format!("{}:input_MONO", target.node_name());
                    let _ = std::process::Command::new("pw-link")
                        .args([&output, &input])
                        .stdout(std::process::Stdio::null())
                        .stderr(std::process::Stdio::null())
                        .status();
                }
                match linker_quit_rx.recv_timeout(std::time::Duration::from_secs(10)) {
                    Ok(()) | Err(crossbeam_channel::RecvTimeoutError::Disconnected) => return,
                    Err(crossbeam_channel::RecvTimeoutError::Timeout) => {}
                }
            })
        {
            Ok(thread) => thread,
            Err(e) => {
                let _ = quit_tx.send(());
                let _ = thread.join();
                return Err(e.into());
            }
        };

        Ok(Self {
            router,
            quit_tx,
            thread: Some(thread),
            linker_quit_tx,
            linker_thread: Some(linker_thread),
        })
    }

    // ⟦𓂑𓃐𓍻𓋎⟧ shutdown :: auto-generated pointer for public function shutdown
    pub fn shutdown(mut self) {
        let _ = self.quit_tx.send(());
        let _ = self.linker_quit_tx.send(());
        if let Some(thread) = self.thread.take() {
            let _ = thread.join();
        }
        if let Some(thread) = self.linker_thread.take() {
            let _ = thread.join();
        }
    }
}

mod pw_thread {
    use super::*;

    use pipewire as pw;
    use pw::{properties::properties, spa};
    use ringbuf::traits::{Consumer, Producer, Split};
    use ringbuf::HeapRb;
    use spa::pod::Pod;

    /// ~1s of headroom per target at 48kHz mono.
    const RING_CAPACITY: usize = 48_000;

    fn audio_format_params(buffer: &mut Vec<u8>) -> Result<()> {
        let mut audio_info = spa::param::audio::AudioInfoRaw::new();
        audio_info.set_format(spa::param::audio::AudioFormat::F32LE);
        audio_info.set_rate(SAMPLE_RATE);
        audio_info.set_channels(1);
        let object = spa::pod::Object {
            type_: spa::utils::SpaTypes::ObjectParamFormat.as_raw(),
            id: spa::param::ParamType::EnumFormat.as_raw(),
            properties: audio_info.into(),
        };
        *buffer = spa::pod::serialize::PodSerializer::serialize(
            std::io::Cursor::new(Vec::new()),
            &spa::pod::Value::Object(object),
        )
        .map_err(|e| anyhow::anyhow!("pod serialize failed: {e:?}"))?
        .0
        .into_inner();
        Ok(())
    }

    // ⟦𓇪𓌾𓊏𓈴⟧ run :: auto-generated pointer for public function run
    pub fn run(
        state: Arc<RouterState>,
        input_target: Option<String>,
        stt_tx: Sender<Vec<f32>>,
        quit_rx: pipewire::channel::Receiver<()>,
    ) -> Result<()> {
        pw::init();
        let mainloop = pw::main_loop::MainLoopRc::new(None)?;
        let context = pw::context::ContextRc::new(&mainloop, None)?;
        let core = context.connect_rc(None)?;

        let loop_clone = mainloop.clone();
        let _quit_attach = quit_rx.attach(mainloop.loop_(), move |_| {
            loop_clone.quit();
        });

        // Per-target rings: capture side pushes, playback side pops.
        let mut producers = Vec::new();
        let mut consumers = Vec::new();
        for _ in TARGETS {
            let (producer, consumer) = HeapRb::<f32>::new(RING_CAPACITY).split();
            producers.push(producer);
            consumers.push(consumer);
        }

        // ---- capture stream --------------------------------------------
        let mut capture_props = properties! {
            *pw::keys::MEDIA_TYPE => "Audio",
            *pw::keys::MEDIA_CATEGORY => "Capture",
            *pw::keys::MEDIA_ROLE => "Communication",
            *pw::keys::NODE_NAME => "queue-populator-capture",
        };
        if let Some(target) = input_target.filter(|t| !t.is_empty()) {
            capture_props.insert(*pw::keys::TARGET_OBJECT, target);
        }

        let capture = pw::stream::StreamBox::new(&core, "queue-populator-capture", capture_props)?;

        struct CaptureData {
            state: Arc<RouterState>,
            producers: Vec<ringbuf::HeapProd<f32>>,
            stt_tx: Sender<Vec<f32>>,
        }

        let capture_data = CaptureData {
            state: state.clone(),
            producers,
            stt_tx,
        };

        let _capture_listener = capture
            .add_local_listener_with_user_data(capture_data)
            .process(|stream, data| {
                let Some(mut buffer) = stream.dequeue_buffer() else {
                    return;
                };
                let datas = buffer.datas_mut();
                if datas.is_empty() {
                    return;
                }
                if datas[0].as_raw().chunk.is_null() {
                    return;
                }
                let (chunk_offset, chunk_size) = {
                    let chunk = datas[0].chunk();
                    (chunk.offset(), chunk.size())
                };
                let Some(bytes) = datas[0].data() else { return };
                let samples = decode_f32le_chunk(bytes, chunk_offset, chunk_size);
                if samples.is_empty() {
                    return;
                }

                for (idx, target) in TARGETS.iter().enumerate() {
                    if data.state.is_fed(*target) {
                        let _ = data.producers[idx].push_slice(&samples);
                    }
                }

                if data.state.listening.load(Ordering::Relaxed) {
                    let _ = data.stt_tx.try_send(samples);
                }
            })
            .register()?;

        let mut capture_format = Vec::new();
        audio_format_params(&mut capture_format)?;
        let capture_param = Pod::from_bytes(&capture_format)
            .ok_or_else(|| anyhow::anyhow!("serialized capture format is not a valid SPA POD"))?;
        let mut capture_params = [capture_param];
        capture.connect(
            spa::utils::Direction::Input,
            None,
            pw::stream::StreamFlags::AUTOCONNECT
                | pw::stream::StreamFlags::MAP_BUFFERS
                | pw::stream::StreamFlags::RT_PROCESS,
            &mut capture_params,
        )?;

        // ---- playback streams into the virtual sources ------------------
        struct PlaybackData {
            state: Arc<RouterState>,
            consumer: ringbuf::HeapCons<f32>,
            target: MicTarget,
        }

        // Keep the stream boxes + listeners alive for the loop's lifetime.
        let mut playback_streams = Vec::new();

        for (_idx, target) in TARGETS.iter().enumerate() {
            let props = properties! {
                *pw::keys::MEDIA_TYPE => "Audio",
                *pw::keys::MEDIA_CATEGORY => "Playback",
                *pw::keys::MEDIA_ROLE => "Communication",
                *pw::keys::NODE_NAME => format!("queue-populator-{}", target.node_name()),
                // Linked manually by the pw-linker thread (see AudioSystem::start);
                // autoconnect would fall back to the default sink.
                "node.dont-fallback" => "true",
            };
            let stream =
                pw::stream::StreamBox::new(&core, &format!("feed-{}", target.node_name()), props)?;

            let playback_data = PlaybackData {
                state: state.clone(),
                consumer: consumers.remove(0),
                target: *target,
            };

            let listener = stream
                .add_local_listener_with_user_data(playback_data)
                .process(|stream, data| {
                    let Some(mut buffer) = stream.dequeue_buffer() else {
                        return;
                    };
                    let datas = buffer.datas_mut();
                    if datas.is_empty() {
                        return;
                    }
                    let slot = &mut datas[0];
                    if slot.as_raw().chunk.is_null() {
                        return;
                    }
                    let Some(bytes) = slot.data() else { return };
                    let capacity_samples = (bytes.len() / 4).min(u32::MAX as usize / 4);
                    let fed = data.state.is_fed(data.target);

                    let mut written = 0usize;
                    if fed {
                        while written < capacity_samples {
                            let Some(sample) = data.consumer.try_pop() else { break };
                            let dst = written * 4;
                            bytes[dst..dst + 4].copy_from_slice(&sample.to_le_bytes());
                            written += 1;
                        }
                    } else {
                        // Muted: drop backlog so re-opening starts live.
                        while data.consumer.try_pop().is_some() {}
                    }
                    // Pad the rest of the cycle with silence.
                    for i in written..capacity_samples {
                        let dst = i * 4;
                        bytes[dst..dst + 4].copy_from_slice(&0.0f32.to_le_bytes());
                    }

                    let chunk = slot.chunk_mut();
                    *chunk.offset_mut() = 0;
                    *chunk.stride_mut() = 4;
                    *chunk.size_mut() = (capacity_samples * 4) as u32;
                })
                .register()?;

            let mut format = Vec::new();
            audio_format_params(&mut format)?;
            let playback_param = Pod::from_bytes(&format)
                .ok_or_else(|| anyhow::anyhow!("serialized playback format is not a valid SPA POD"))?;
            let mut params = [playback_param];
            stream.connect(
                spa::utils::Direction::Output,
                None,
                pw::stream::StreamFlags::MAP_BUFFERS | pw::stream::StreamFlags::RT_PROCESS,
                &mut params,
            )?;

            playback_streams.push((stream, listener));
        }

        mainloop.run();
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn assistants_are_exclusive() {
        let state = Arc::new(RouterState::new());
        let router = RouterHandle { state };

        router.open(MicTarget::Claude);
        assert_eq!(router.open_target(), Some(MicTarget::Claude));

        router.open(MicTarget::Codex);
        assert_eq!(router.open_target(), Some(MicTarget::Codex));
        assert!(!router.state.is_fed(MicTarget::Claude));

        router.close(MicTarget::Claude); // not open — no effect
        assert_eq!(router.open_target(), Some(MicTarget::Codex));

        router.close(MicTarget::Codex);
        assert_eq!(router.open_target(), None);
    }

    #[test]
    fn recording_follows_listening() {
        let state = Arc::new(RouterState::new());
        let router = RouterHandle { state: state.clone() };
        assert!(!state.is_fed(MicTarget::Recording));
        router.set_listening(true);
        assert!(state.is_fed(MicTarget::Recording));
        // Recording is not command-controllable.
        router.open(MicTarget::Recording);
        router.close(MicTarget::Recording);
        assert!(state.is_fed(MicTarget::Recording));
    }

    #[test]
    fn capture_decode_respects_chunk_offset_and_size() {
        let mut bytes = Vec::new();
        for sample in [99.0f32, 1.25, -2.5, 77.0] {
            bytes.extend_from_slice(&sample.to_le_bytes());
        }

        assert_eq!(decode_f32le_chunk(&bytes, 4, 8), vec![1.25, -2.5]);
    }

    #[test]
    fn capture_decode_clamps_invalid_chunk_bounds() {
        let mut bytes = Vec::new();
        bytes.extend_from_slice(&1.0f32.to_le_bytes());
        bytes.extend_from_slice(&2.0f32.to_le_bytes());
        bytes.push(0xff); // an incomplete trailing sample must be ignored

        assert_eq!(decode_f32le_chunk(&bytes, 4, u32::MAX), vec![2.0]);
        assert!(decode_f32le_chunk(&bytes, u32::MAX, 4).is_empty());
    }
}
