//! queue-populator core — Linux port of utilities/osx/queue-populator.
//! Platform-neutral logic lives here; audio/STT/UI layers are added on top.

pub mod audio;
pub mod config;
pub mod coordinator;
pub mod llm;
pub mod phrase_detector;
pub mod queue;
pub mod state_machine;
pub mod stt;
pub mod ui;
