//! STT model locations. Models are downloaded by install.sh into
//! ~/.local/share/queue-populator/models (override with QP_MODEL_DIR).

use std::path::PathBuf;

use anyhow::{bail, Result};

/// sherpa-onnx streaming zipformer (English, int8) — see install.sh.
pub const MODEL_DIR_NAME: &str = "sherpa-onnx-streaming-zipformer-en-2023-06-26";

pub struct ModelPaths {
    pub encoder: PathBuf,
    pub decoder: PathBuf,
    pub joiner: PathBuf,
    pub tokens: PathBuf,
}

// ⟦𓄫𓃮𓄬𓊽⟧ model_root :: auto-generated pointer for public function model_root
pub fn model_root() -> PathBuf {
    if let Ok(dir) = std::env::var("QP_MODEL_DIR") {
        return PathBuf::from(dir);
    }
    dirs::data_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("queue-populator/models")
}

// ⟦𓁟𓍛𓃊𓇂⟧ locate :: auto-generated pointer for public function locate
pub fn locate() -> Result<ModelPaths> {
    let root = model_root().join(MODEL_DIR_NAME);
    let paths = ModelPaths {
        encoder: root.join("encoder-epoch-99-avg-1-chunk-16-left-128.int8.onnx"),
        decoder: root.join("decoder-epoch-99-avg-1-chunk-16-left-128.onnx"),
        joiner: root.join("joiner-epoch-99-avg-1-chunk-16-left-128.int8.onnx"),
        tokens: root.join("tokens.txt"),
    };
    for path in [&paths.encoder, &paths.decoder, &paths.joiner, &paths.tokens] {
        if !path.is_file() {
            bail!(
                "STT model file missing: {} — run install.sh (or set QP_MODEL_DIR)",
                path.display()
            );
        }
    }
    Ok(paths)
}
