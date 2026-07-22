//! Scan demos + workspace for .media.prompt files and group by asset type.

use std::collections::BTreeMap;
use std::path::{Path, PathBuf};

use serde::Serialize;

use crate::schema::parse_prompt_file;

#[derive(Debug, Clone, Serialize)]
pub struct TypeGroup {
    pub type_key: String,
    pub label: String,
    pub count: usize,
    pub prompts: Vec<PromptSummary>,
}

#[derive(Debug, Clone, Serialize)]
pub struct PromptSummary {
    pub id: String,
    pub type_key: String,
    pub schema: String,
    pub quality: String,
    pub service: Option<String>,
    pub model: Option<String>,
    pub path: String,
    pub rel_path: String,
    pub source: String, // "demos" | "workspace"
    pub prompt_preview: String,
    pub has_eval: bool,
    pub outputs: Vec<OutputFile>,
    pub tags: Vec<String>,
}

#[derive(Debug, Clone, Serialize)]
pub struct OutputFile {
    pub path: String,
    pub rel_path: String,
    pub format: String,
    pub exists: bool,
    pub size_bytes: Option<u64>,
    pub media_url: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct PromptDetail {
    pub summary: PromptSummary,
    pub yaml: String,
    pub prompt_text: String,
    pub system: Option<String>,
    pub negative: Option<String>,
    pub eval_yaml: Option<String>,
}

pub fn type_label(type_key: &str) -> &'static str {
    match type_key {
        "image" => "Image (raster)",
        "svg" => "SVG / vector",
        "video" => "Video",
        "music" => "Music",
        "voice" | "audio" => "Voice / TTS",
        "sfx" => "SFX",
        "diagram" => "Diagram",
        "html" => "HTML",
        "react-page" => "React page",
        "component" => "Component",
        "style-guide" => "Style guide",
        "document" => "Document",
        "game" => "Game (HTML)",
        _ => "Other",
    }
}

/// Special-case grouping: svg demos under demos/svg, games under demos/game.
fn display_type_key(yaml_type: &str, rel_path: &str, text_format: Option<&str>) -> String {
    let lower = rel_path.to_lowercase();
    if lower.contains("/game/") || lower.starts_with("game/") {
        return "game".into();
    }
    if lower.contains("/svg/")
        || lower.starts_with("svg/")
        || text_format.map(|t| t.eq_ignore_ascii_case("svg")).unwrap_or(false)
        || yaml_type == "image"
            && lower.ends_with(".media.prompt")
            && lower.contains("svg")
    {
        // Prefer svg bucket when under svg/ or text_format svg
        if text_format.map(|t| t.eq_ignore_ascii_case("svg")).unwrap_or(false)
            || lower.contains("/svg/")
            || lower.starts_with("svg/")
        {
            return "svg".into();
        }
    }
    if yaml_type.is_empty() {
        "unknown".into()
    } else {
        yaml_type.to_string()
    }
}

pub fn scan_catalog(demos_dir: &Path, workspace_dir: &Path) -> color_eyre::Result<Vec<TypeGroup>> {
    let mut by_type: BTreeMap<String, Vec<PromptSummary>> = BTreeMap::new();

    scan_root(demos_dir, demos_dir, "demos", &mut by_type)?;
    let ws_prompts = workspace_dir.join("prompts");
    if ws_prompts.is_dir() {
        scan_root(&ws_prompts, workspace_dir, "workspace", &mut by_type)?;
    }

    let mut groups = Vec::new();
    for (type_key, mut prompts) in by_type {
        prompts.sort_by(|a, b| a.id.cmp(&b.id));
        let label = type_label(&type_key).to_string();
        let count = prompts.len();
        groups.push(TypeGroup {
            type_key,
            label,
            count,
            prompts,
        });
    }
    Ok(groups)
}

fn scan_root(
    root: &Path,
    media_root: &Path,
    source: &str,
    by_type: &mut BTreeMap<String, Vec<PromptSummary>>,
) -> color_eyre::Result<()> {
    let mut files = Vec::new();
    collect_media_prompts(root, &mut files);
    files.sort();
    for path in files {
        match summarize_prompt(&path, media_root, source) {
            Ok(summary) => {
                by_type
                    .entry(summary.type_key.clone())
                    .or_default()
                    .push(summary);
            }
            Err(e) => {
                eprintln!("  lab: skip {}: {e}", path.display());
            }
        }
    }
    Ok(())
}

fn collect_media_prompts(dir: &Path, out: &mut Vec<PathBuf>) {
    let Ok(entries) = std::fs::read_dir(dir) else {
        return;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            // skip heavy/irrelevant
            let name = path.file_name().and_then(|n| n.to_str()).unwrap_or("");
            if name == "target" || name == ".git" || name == "node_modules" {
                continue;
            }
            collect_media_prompts(&path, out);
        } else if path
            .file_name()
            .and_then(|n| n.to_str())
            .map(|n| n.ends_with(".media.prompt"))
            .unwrap_or(false)
        {
            out.push(path);
        }
    }
}

fn summarize_prompt(
    path: &Path,
    media_root: &Path,
    source: &str,
) -> color_eyre::Result<PromptSummary> {
    let parsed = parse_prompt_file(path)?;
    let rel = pathdiff_rel(path, media_root);
    let type_key = display_type_key(
        &parsed.payload.r#type,
        &rel,
        parsed.payload.output.text_format.as_deref(),
    );

    let preview: String = parsed
        .payload
        .prompt
        .text
        .chars()
        .take(160)
        .collect::<String>()
        .replace('\n', " ");

    let outputs = resolve_outputs(&parsed, path, media_root);

    Ok(PromptSummary {
        id: parsed.meta.id.clone(),
        type_key,
        schema: parsed.payload.schema.clone(),
        quality: parsed.meta.quality.as_str().to_string(),
        service: parsed.meta.service.clone(),
        model: parsed.meta.model.clone(),
        path: path.display().to_string(),
        rel_path: rel,
        source: source.to_string(),
        prompt_preview: preview,
        has_eval: parsed.payload.eval.is_some(),
        outputs,
        tags: parsed.payload.tags.clone(),
    })
}

fn resolve_outputs(
    parsed: &crate::schema::ParsedPrompt,
    prompt_path: &Path,
    media_root: &Path,
) -> Vec<OutputFile> {
    let parent = prompt_path.parent().unwrap_or(Path::new("."));
    let stem = prompt_path
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("out")
        .strip_suffix(".media.prompt")
        .unwrap_or("out");

    let mut formats: Vec<String> = parsed
        .meta
        .output_formats
        .iter()
        .map(|f| f.format.clone())
        .collect();
    if formats.is_empty() {
        formats.push(parsed.meta.asset_type.default_extension().to_string());
    }

    // Also discover sibling files matching stem.*
    let mut found: Vec<OutputFile> = Vec::new();
    for fmt in &formats {
        if let Some(filename) = parsed
            .meta
            .output_formats
            .iter()
            .find(|f| &f.format == fmt)
            .and_then(|f| f.filename.clone())
        {
            let p = parent.join(&filename);
            found.push(output_entry(&p, media_root, fmt));
        } else {
            let p = parent.join(format!("{stem}.{fmt}"));
            found.push(output_entry(&p, media_root, fmt));
        }
    }

    // Discover any other sibling media next to the prompt
    if let Ok(rd) = std::fs::read_dir(parent) {
        for ent in rd.flatten() {
            let p = ent.path();
            if !p.is_file() {
                continue;
            }
            let name = p.file_name().and_then(|n| n.to_str()).unwrap_or("");
            if name.starts_with(stem)
                && !name.ends_with(".media.prompt")
                && !name.ends_with(".meta.yaml")
                && !name.ends_with(".meta.yml")
            {
                let ext = p
                    .extension()
                    .and_then(|e| e.to_str())
                    .unwrap_or("")
                    .to_string();
                if !found.iter().any(|o| o.path == p.display().to_string()) {
                    found.push(output_entry(&p, media_root, &ext));
                }
            }
        }
    }

    found
}

fn output_entry(path: &Path, media_root: &Path, format: &str) -> OutputFile {
    let exists = path.is_file();
    let size_bytes = if exists {
        std::fs::metadata(path).ok().map(|m| m.len())
    } else {
        None
    };
    let rel = pathdiff_rel(path, media_root);
    let media_url = format!("/api/media?path={}", urlencoding_path(&rel));
    OutputFile {
        path: path.display().to_string(),
        rel_path: rel,
        format: format.to_string(),
        exists,
        size_bytes,
        media_url,
    }
}

pub fn load_detail(path: &Path, media_root: &Path, source: &str) -> color_eyre::Result<PromptDetail> {
    let summary = summarize_prompt(path, media_root, source)?;
    let yaml = std::fs::read_to_string(path)?;
    let parsed = parse_prompt_file(path)?;
    let eval_yaml = parsed.payload.eval.as_ref().map(|_| {
        // re-extract eval block roughly from full yaml for display
        extract_eval_block(&yaml).unwrap_or_default()
    });
    Ok(PromptDetail {
        summary,
        yaml,
        prompt_text: parsed.payload.prompt.text.clone(),
        system: parsed.payload.prompt.system.clone(),
        negative: parsed.payload.prompt.negative.clone(),
        eval_yaml,
    })
}

fn extract_eval_block(yaml: &str) -> Option<String> {
    let mut lines = yaml.lines().peekable();
    let mut out = String::new();
    let mut in_eval = false;
    while let Some(line) = lines.next() {
        if !in_eval {
            if line.starts_with("eval:") {
                in_eval = true;
                out.push_str(line);
                out.push('\n');
            }
        } else {
            // stop at next top-level key (no indent)
            if !line.is_empty()
                && !line.starts_with(' ')
                && !line.starts_with('\t')
                && !line.starts_with('#')
            {
                break;
            }
            out.push_str(line);
            out.push('\n');
        }
    }
    if out.is_empty() {
        None
    } else {
        Some(out)
    }
}

fn pathdiff_rel(path: &Path, root: &Path) -> String {
    let path = path.canonicalize().unwrap_or_else(|_| path.to_path_buf());
    let root = root.canonicalize().unwrap_or_else(|_| root.to_path_buf());
    path.strip_prefix(&root)
        .map(|p| p.display().to_string())
        .unwrap_or_else(|_| path.display().to_string())
        .replace('\\', "/")
}

/// Minimal path query encoding (encode special chars).
pub fn urlencoding_path(s: &str) -> String {
    let mut out = String::with_capacity(s.len() * 2);
    for b in s.bytes() {
        match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'/' => {
                out.push(b as char);
            }
            _ => out.push_str(&format!("%{:02X}", b)),
        }
    }
    out
}

/// Resolve a media path query to an absolute file under allowed roots.
pub fn resolve_safe_media(
    rel: &str,
    demos_dir: &Path,
    workspace_dir: &Path,
) -> color_eyre::Result<PathBuf> {
    let rel = rel.trim_start_matches('/');
    if rel.contains("..") {
        color_eyre::eyre::bail!("path traversal rejected");
    }
    let candidates = [
        demos_dir.join(rel),
        workspace_dir.join(rel),
        // also allow absolute if under roots
        PathBuf::from(rel),
    ];
    for c in candidates {
        if c.is_file() {
            let canon = c.canonicalize()?;
            let demos = demos_dir.canonicalize().unwrap_or_else(|_| demos_dir.to_path_buf());
            let ws = workspace_dir
                .canonicalize()
                .unwrap_or_else(|_| workspace_dir.to_path_buf());
            if canon.starts_with(&demos) || canon.starts_with(&ws) {
                return Ok(canon);
            }
        }
    }
    color_eyre::eyre::bail!("media not found or outside allowed roots: {rel}")
}
