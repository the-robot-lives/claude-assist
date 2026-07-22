//! Interactive web lab for browsing media types, example prompts, generation,
//! preview, and eval — aimed at QA and expanding the test corpus.
//!
//! Also exposes the full provider/channel registry (media APIs, chat, renderers,
//! and every FIM solution — 100+ entries).

mod catalog;
mod persist;
mod registry;
mod server;
mod settings;

use std::path::PathBuf;

pub use server::run_lab;

/// Resolved paths for the lab server.
#[derive(Debug, Clone)]
pub struct LabConfig {
    pub port: u16,
    /// Curated demos (read-mostly).
    pub demos_dir: PathBuf,
    /// Workspace for generated test prompts + live outputs (writable).
    pub workspace_dir: PathBuf,
    /// Package root (demos/workspace + FIM categories resolved relative to this).
    pub package_root: PathBuf,
    pub verbose: bool,
    pub open_browser: bool,
}

impl LabConfig {
    pub fn resolve(
        port: u16,
        demos: Option<PathBuf>,
        workspace: Option<PathBuf>,
        verbose: bool,
        open_browser: bool,
    ) -> color_eyre::Result<Self> {
        let package_root = find_package_root()?;
        let demos_dir = demos.unwrap_or_else(|| package_root.join("demos"));
        // Stable workspace (not under tmp/) so examples + YAML persist across runs.
        let workspace_dir =
            workspace.unwrap_or_else(|| package_root.join("lab-workspace"));

        if !demos_dir.is_dir() {
            color_eyre::eyre::bail!(
                "Demos directory not found: {} (pass --demos)",
                demos_dir.display()
            );
        }
        persist::ensure_workspace(&package_root, &workspace_dir)?;

        Ok(Self {
            port,
            demos_dir,
            workspace_dir,
            package_root,
            verbose,
            open_browser,
        })
    }
}

fn find_package_root() -> color_eyre::Result<PathBuf> {
    // 1. CWD if it looks like media-tool
    if let Ok(cwd) = std::env::current_dir() {
        if cwd.join("demos").is_dir() && cwd.join("Cargo.toml").is_file() {
            return Ok(cwd);
        }
        // Walk up
        let mut cursor = cwd.as_path();
        while let Some(parent) = cursor.parent() {
            let candidate = parent.join("utilities/agent/media-tool");
            if candidate.join("demos").is_dir() {
                return Ok(candidate);
            }
            if parent.join("demos").is_dir() && parent.join("Cargo.toml").is_file() {
                // maybe already in media-tool parent chain
                if parent
                    .file_name()
                    .and_then(|n| n.to_str())
                    .map(|n| n == "media-tool")
                    .unwrap_or(false)
                {
                    return Ok(parent.to_path_buf());
                }
            }
            cursor = parent;
        }
    }

    // 2. INFRA_ROOT
    if let Ok(root) = std::env::var("INFRA_ROOT") {
        let p = PathBuf::from(root).join("utilities/agent/media-tool");
        if p.join("demos").is_dir() {
            return Ok(p);
        }
    }

    color_eyre::eyre::bail!(
        "Could not locate media-tool package root (need demos/). Run from utilities/agent/media-tool or set INFRA_ROOT."
    )
}
