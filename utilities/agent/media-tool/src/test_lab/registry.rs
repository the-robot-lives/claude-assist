//! Complete provider / channel registry for the test lab.
//!
//! Merges:
//! 1. Binary media API services (implemented + planned stubs)
//! 2. Chat completion services
//! 3. Local renderers
//! 4. Every FIM solution under `references/fim/solution/` (~200 channels)
//! 5. Category membership from `assets/fim/categories/`

use std::collections::{BTreeMap, BTreeSet, HashMap};
use std::path::{Path, PathBuf};

use serde::Serialize;

use crate::fim;
use crate::providers::{self, api_key_env, default_model, is_stub_provider};
use crate::renderers;

// ---------------------------------------------------------------------------
// Public types
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize)]
#[allow(dead_code)]
pub struct ProviderEntry {
    /// Stable id: e.g. `media:gemini`, `chat:anthropic`, `render:mermaid`, `fim:d3_js`
    pub id: String,
    /// Human name / slug used in service: or text_format:
    pub slug: String,
    pub kind: ProviderKind,
    pub category: String,
    pub category_label: String,
    pub status: ProviderStatus,
    pub description: String,
    /// Asset type(s) this maps to when generating .media.prompt
    pub asset_types: Vec<String>,
    pub default_extension: Option<String>,
    pub api_key_env: Option<String>,
    pub default_model: Option<String>,
    /// FIM solution relative path if any
    pub fim_solution: Option<String>,
    /// Whether a demo .media.prompt currently exists
    pub demo_count: usize,
    pub demo_paths: Vec<String>,
}

#[derive(Debug, Clone, Copy, Serialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum ProviderKind {
    /// Binary media API (image/video/audio generation)
    MediaApi,
    /// Chat completion LLM
    ChatApi,
    /// Local markup→visual renderer
    Renderer,
    /// FIM text-format / library channel (chat + format guidance)
    FimChannel,
}

#[derive(Debug, Clone, Copy, Serialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum ProviderStatus {
    /// Wired in Rust and callable
    Implemented,
    /// Known in docs/candidates but not implemented (stub)
    Stub,
    /// Documented FIM channel only (use chat + text_format)
    FimOnly,
    /// Local tool may or may not be on PATH
    LocalTool,
}

#[derive(Debug, Clone, Serialize)]
pub struct ProviderCategory {
    pub key: String,
    pub label: String,
    pub kind_hint: String,
    pub count: usize,
    pub implemented: usize,
    pub stub: usize,
    pub fim_only: usize,
}

#[derive(Debug, Clone, Serialize)]
pub struct ProviderCatalog {
    pub total: usize,
    pub implemented: usize,
    pub stub: usize,
    pub fim_only: usize,
    pub local_tool: usize,
    pub categories: Vec<ProviderCategory>,
    pub providers: Vec<ProviderEntry>,
}

// ---------------------------------------------------------------------------
// Build
// ---------------------------------------------------------------------------

pub fn build_catalog(demos_dir: &Path, package_root: &Path) -> ProviderCatalog {
    let mut by_id: BTreeMap<String, ProviderEntry> = BTreeMap::new();
    let demo_index = index_demos_by_provider(demos_dir);

    // 1) Media APIs (implemented + planned)
    for row in MEDIA_API_TABLE {
        let id = format!("media:{}", row.slug);
        let implemented = !is_stub_provider(row.slug) && providers::get_provider(row.slug).is_some();
        // Some chat-only slugs aren't media — check carefully
        let implemented = implemented
            || matches!(
                row.slug,
                "gemini"
                    | "suno"
                    | "openai-tts"
                    | "elevenlabs"
                    | "qwen-tts"
                    | "veo"
                    | "grok-video"
            );
        let (demo_count, demo_paths) = demos_for(&demo_index, row.slug, None);
        by_id.insert(
            id.clone(),
            ProviderEntry {
                id,
                slug: row.slug.into(),
                kind: ProviderKind::MediaApi,
                category: "media-api".into(),
                category_label: "Media APIs (image / video / audio)".into(),
                status: if implemented {
                    ProviderStatus::Implemented
                } else {
                    ProviderStatus::Stub
                },
                description: row.description.into(),
                asset_types: row.asset_types.iter().map(|s| (*s).to_string()).collect(),
                default_extension: Some(row.default_ext.into()),
                api_key_env: {
                    let e = api_key_env(row.slug);
                    if e.is_empty() || row.slug == "local" {
                        None
                    } else {
                        Some(e.into())
                    }
                },
                default_model: Some(default_model(row.slug).into()),
                fim_solution: row.fim.map(|s| s.to_string()),
                demo_count,
                demo_paths,
            },
        );
    }

    // 2) Chat APIs
    for row in CHAT_API_TABLE {
        let id = format!("chat:{}", row.slug);
        let implemented = providers::get_chat_provider(row.slug).is_some();
        let (demo_count, demo_paths) = demos_for(&demo_index, row.slug, None);
        by_id.insert(
            id.clone(),
            ProviderEntry {
                id,
                slug: row.slug.into(),
                kind: ProviderKind::ChatApi,
                category: "chat-api".into(),
                category_label: "Chat APIs (LLM text / code / markup)".into(),
                status: if implemented {
                    ProviderStatus::Implemented
                } else {
                    ProviderStatus::Stub
                },
                description: row.description.into(),
                asset_types: vec![
                    "diagram".into(),
                    "html".into(),
                    "react-page".into(),
                    "component".into(),
                    "document".into(),
                ],
                default_extension: None,
                api_key_env: Some(api_key_env(row.slug).into()),
                default_model: Some(default_model(row.slug).into()),
                fim_solution: None,
                demo_count,
                demo_paths,
            },
        );
    }

    // 3) Renderers
    for row in RENDERER_TABLE {
        let id = format!("render:{}", row.slug);
        let available = renderers::get_renderer(row.slug)
            .map(|r| r.is_available())
            .unwrap_or(false);
        let implemented = renderers::get_renderer(row.slug).is_some();
        let (demo_count, demo_paths) = demos_for(&demo_index, row.slug, Some(row.slug));
        by_id.insert(
            id.clone(),
            ProviderEntry {
                id,
                slug: row.slug.into(),
                kind: ProviderKind::Renderer,
                category: "renderer".into(),
                category_label: "Renderers (markup → visual)".into(),
                status: if implemented {
                    if available {
                        ProviderStatus::Implemented
                    } else {
                        ProviderStatus::LocalTool
                    }
                } else {
                    ProviderStatus::Stub
                },
                description: format!(
                    "{}{}",
                    row.description,
                    if implemented && !available {
                        " — CLI not detected on PATH"
                    } else {
                        ""
                    }
                ),
                asset_types: vec!["diagram".into(), "html".into()],
                default_extension: Some(row.default_ext.into()),
                api_key_env: None,
                default_model: None,
                fim_solution: row.fim.map(|s| s.to_string()),
                demo_count,
                demo_paths,
            },
        );
    }

    // 4) Category map from assets/fim/categories
    let category_map = load_category_map(package_root);

    // 5) Every FIM solution file
    if let Some(sol_dir) = fim::resolve_solution_dir() {
        // providers/*.md already partially covered — still list as FIM enrichment
        let provider_dir = sol_dir.join("providers");
        if provider_dir.is_dir() {
            if let Ok(rd) = std::fs::read_dir(&provider_dir) {
                for ent in rd.flatten() {
                    let path = ent.path();
                    if path.extension().and_then(|e| e.to_str()) != Some("md") {
                        continue;
                    }
                    let stem = path.file_stem().unwrap().to_string_lossy().to_string();
                    // Map to media API slug if known
                    let media_slug = match stem.as_str() {
                        "imagen" => Some("gemini"),
                        "stable-diffusion" => Some("stability"),
                        "runway-gen3" => Some("runway"),
                        other => Some(other),
                    };
                    if let Some(ms) = media_slug {
                        let id = format!("media:{ms}");
                        if let Some(entry) = by_id.get_mut(&id) {
                            entry.fim_solution =
                                Some(format!("providers/{stem}.md"));
                        } else {
                            // orphan FIM provider doc
                            let (demo_count, demo_paths) = demos_for(&demo_index, ms, None);
                            by_id.insert(
                                id.clone(),
                                ProviderEntry {
                                    id,
                                    slug: ms.into(),
                                    kind: ProviderKind::MediaApi,
                                    category: "media-api".into(),
                                    category_label: "Media APIs (image / video / audio)".into(),
                                    status: if is_stub_provider(ms) {
                                        ProviderStatus::Stub
                                    } else {
                                        ProviderStatus::Stub
                                    },
                                    description: format!("FIM provider guidance: {stem}"),
                                    asset_types: vec!["image".into()],
                                    default_extension: Some("png".into()),
                                    api_key_env: Some(api_key_env(ms).into()),
                                    default_model: Some(default_model(ms).into()),
                                    fim_solution: Some(format!("providers/{stem}.md")),
                                    demo_count,
                                    demo_paths,
                                },
                            );
                        }
                    }
                }
            }
        }

        // top-level solution/*.md → FIM channels
        if let Ok(rd) = std::fs::read_dir(&sol_dir) {
            for ent in rd.flatten() {
                let path = ent.path();
                if path.is_dir() {
                    continue;
                }
                if path.extension().and_then(|e| e.to_str()) != Some("md") {
                    continue;
                }
                let stem = path.file_stem().unwrap().to_string_lossy().to_string();
                if stem.eq_ignore_ascii_case("readme") || stem.starts_with("PROVIDER") {
                    continue;
                }
                let id = format!("fim:{stem}");
                if by_id.contains_key(&id) {
                    continue;
                }
                let (cat_key, cat_label) = category_map
                    .get(&stem)
                    .cloned()
                    .unwrap_or_else(|| infer_category(&stem));
                let (asset_types, default_ext) = infer_asset_for_fim(&stem, &cat_key);
                let (demo_count, demo_paths) = demos_for(&demo_index, &stem, Some(&stem));
                let desc = first_heading_or(&path, &format!("FIM channel: {stem}"));
                by_id.insert(
                    id.clone(),
                    ProviderEntry {
                        id,
                        slug: stem.clone(),
                        kind: ProviderKind::FimChannel,
                        category: cat_key,
                        category_label: cat_label,
                        status: ProviderStatus::FimOnly,
                        description: desc,
                        asset_types,
                        default_extension: default_ext,
                        api_key_env: None,
                        default_model: None,
                        fim_solution: Some(format!("{stem}.md")),
                        demo_count,
                        demo_paths,
                    },
                );
            }
        }
    }

    // Also ensure every category member exists even if solution file missing
    for (slug, (cat_key, cat_label)) in &category_map {
        let id = format!("fim:{slug}");
        if by_id.contains_key(&id) {
            continue;
        }
        let (asset_types, default_ext) = infer_asset_for_fim(slug, cat_key);
        let (demo_count, demo_paths) = demos_for(&demo_index, slug, Some(slug));
        by_id.insert(
            id.clone(),
            ProviderEntry {
                id,
                slug: slug.clone(),
                kind: ProviderKind::FimChannel,
                category: cat_key.clone(),
                category_label: cat_label.clone(),
                status: ProviderStatus::FimOnly,
                description: format!("Category channel: {slug} (no solution .md yet)"),
                asset_types,
                default_extension: default_ext,
                api_key_env: None,
                default_model: None,
                fim_solution: None,
                demo_count,
                demo_paths,
            },
        );
    }

    let providers: Vec<ProviderEntry> = by_id.into_values().collect();
    let mut implemented = 0;
    let mut stub = 0;
    let mut fim_only = 0;
    let mut local_tool = 0;
    for p in &providers {
        match p.status {
            ProviderStatus::Implemented => implemented += 1,
            ProviderStatus::Stub => stub += 1,
            ProviderStatus::FimOnly => fim_only += 1,
            ProviderStatus::LocalTool => local_tool += 1,
        }
    }

    // Build category summary
    let mut cat_acc: BTreeMap<String, ProviderCategory> = BTreeMap::new();
    for p in &providers {
        let e = cat_acc.entry(p.category.clone()).or_insert(ProviderCategory {
            key: p.category.clone(),
            label: p.category_label.clone(),
            kind_hint: match p.kind {
                ProviderKind::MediaApi => "media".into(),
                ProviderKind::ChatApi => "chat".into(),
                ProviderKind::Renderer => "renderer".into(),
                ProviderKind::FimChannel => "fim".into(),
            },
            count: 0,
            implemented: 0,
            stub: 0,
            fim_only: 0,
        });
        e.count += 1;
        match p.status {
            ProviderStatus::Implemented | ProviderStatus::LocalTool => e.implemented += 1,
            ProviderStatus::Stub => e.stub += 1,
            ProviderStatus::FimOnly => e.fim_only += 1,
        }
    }
    let mut categories: Vec<ProviderCategory> = cat_acc.into_values().collect();
    // Stable order: media-api, chat-api, renderer, then alpha FIM cats
    categories.sort_by(|a, b| {
        let rank = |k: &str| match k {
            "media-api" => 0,
            "chat-api" => 1,
            "renderer" => 2,
            _ => 10,
        };
        rank(&a.key).cmp(&rank(&b.key)).then(a.label.cmp(&b.label))
    });

    ProviderCatalog {
        total: providers.len(),
        implemented,
        stub,
        fim_only,
        local_tool,
        categories,
        providers,
    }
}

// ---------------------------------------------------------------------------
// Static tables
// ---------------------------------------------------------------------------

struct MediaRow {
    slug: &'static str,
    description: &'static str,
    asset_types: &'static [&'static str],
    default_ext: &'static str,
    fim: Option<&'static str>,
}

const MEDIA_API_TABLE: &[MediaRow] = &[
    MediaRow {
        slug: "gemini",
        description: "Google Imagen (via Gemini API)",
        asset_types: &["image"],
        default_ext: "png",
        fim: Some("providers/imagen.md"),
    },
    MediaRow {
        slug: "openai",
        description: "OpenAI image generation (DALL·E / gpt-image)",
        asset_types: &["image"],
        default_ext: "png",
        fim: None,
    },
    MediaRow {
        slug: "stability",
        description: "Stability AI image generation",
        asset_types: &["image"],
        default_ext: "png",
        fim: Some("providers/stable-diffusion.md"),
    },
    MediaRow {
        slug: "replicate",
        description: "Replicate hosted image models",
        asset_types: &["image"],
        default_ext: "png",
        fim: None,
    },
    MediaRow {
        slug: "ideogram",
        description: "Ideogram image generation",
        asset_types: &["image"],
        default_ext: "png",
        fim: None,
    },
    MediaRow {
        slug: "recraft",
        description: "Recraft image generation",
        asset_types: &["image"],
        default_ext: "png",
        fim: None,
    },
    MediaRow {
        slug: "fal",
        description: "fal.ai image generation",
        asset_types: &["image"],
        default_ext: "png",
        fim: None,
    },
    MediaRow {
        slug: "together",
        description: "Together AI image generation",
        asset_types: &["image"],
        default_ext: "png",
        fim: None,
    },
    MediaRow {
        slug: "fireworks",
        description: "Fireworks image generation",
        asset_types: &["image"],
        default_ext: "png",
        fim: None,
    },
    MediaRow {
        slug: "local",
        description: "Local image generator (A1111 / ComfyUI style)",
        asset_types: &["image"],
        default_ext: "png",
        fim: Some("providers/stable-diffusion.md"),
    },
    MediaRow {
        slug: "midjourney",
        description: "Midjourney (planned)",
        asset_types: &["image"],
        default_ext: "png",
        fim: Some("providers/midjourney.md"),
    },
    MediaRow {
        slug: "flux",
        description: "Flux image models (planned)",
        asset_types: &["image"],
        default_ext: "png",
        fim: Some("providers/flux.md"),
    },
    MediaRow {
        slug: "suno",
        description: "Suno music / SFX generation",
        asset_types: &["music", "sfx", "audio"],
        default_ext: "mp3",
        fim: Some("providers/suno.md"),
    },
    MediaRow {
        slug: "udio",
        description: "Udio music generation (planned)",
        asset_types: &["music"],
        default_ext: "mp3",
        fim: Some("providers/udio.md"),
    },
    MediaRow {
        slug: "bark",
        description: "Bark TTS / audio (planned)",
        asset_types: &["voice", "audio"],
        default_ext: "wav",
        fim: None,
    },
    MediaRow {
        slug: "musicgen",
        description: "MusicGen (planned)",
        asset_types: &["music"],
        default_ext: "wav",
        fim: None,
    },
    MediaRow {
        slug: "openai-tts",
        description: "OpenAI TTS",
        asset_types: &["voice", "audio"],
        default_ext: "mp3",
        fim: Some("providers/openai-tts.md"),
    },
    MediaRow {
        slug: "elevenlabs",
        description: "ElevenLabs TTS",
        asset_types: &["voice", "audio"],
        default_ext: "mp3",
        fim: Some("providers/elevenlabs.md"),
    },
    MediaRow {
        slug: "qwen-tts",
        description: "Qwen / DashScope TTS",
        asset_types: &["voice", "audio"],
        default_ext: "mp3",
        fim: Some("providers/qwen-tts.md"),
    },
    MediaRow {
        slug: "veo",
        description: "Google Veo video",
        asset_types: &["video"],
        default_ext: "mp4",
        fim: Some("providers/veo.md"),
    },
    MediaRow {
        slug: "grok-video",
        description: "xAI Grok Imagine video",
        asset_types: &["video"],
        default_ext: "mp4",
        fim: Some("providers/grok-video.md"),
    },
    MediaRow {
        slug: "runway",
        description: "Runway Gen video (planned)",
        asset_types: &["video"],
        default_ext: "mp4",
        fim: Some("providers/runway-gen3.md"),
    },
    MediaRow {
        slug: "sora",
        description: "OpenAI Sora (planned)",
        asset_types: &["video"],
        default_ext: "mp4",
        fim: Some("providers/sora.md"),
    },
    MediaRow {
        slug: "pika",
        description: "Pika video (planned)",
        asset_types: &["video"],
        default_ext: "mp4",
        fim: None,
    },
    MediaRow {
        slug: "kling",
        description: "Kling video (planned)",
        asset_types: &["video"],
        default_ext: "mp4",
        fim: None,
    },
    MediaRow {
        slug: "minimax",
        description: "MiniMax video (planned)",
        asset_types: &["video"],
        default_ext: "mp4",
        fim: None,
    },
];

struct ChatRow {
    slug: &'static str,
    description: &'static str,
}

const CHAT_API_TABLE: &[ChatRow] = &[
    ChatRow {
        slug: "groq-chat",
        description: "Groq OpenAI-compatible chat (default auto-select)",
    },
    ChatRow {
        slug: "anthropic",
        description: "Anthropic Claude chat",
    },
    ChatRow {
        slug: "gemini-chat",
        description: "Google Gemini chat",
    },
    ChatRow {
        slug: "openai-chat",
        description: "OpenAI chat completions",
    },
    ChatRow {
        slug: "z.ai",
        description: "xAI Grok chat (z.ai alias)",
    },
];

struct RenderRow {
    slug: &'static str,
    description: &'static str,
    default_ext: &'static str,
    fim: Option<&'static str>,
}

const RENDERER_TABLE: &[RenderRow] = &[
    RenderRow {
        slug: "mermaid",
        description: "Mermaid CLI (mmdc)",
        default_ext: "svg",
        fim: Some("mermaid.md"),
    },
    RenderRow {
        slug: "plantuml",
        description: "PlantUML",
        default_ext: "svg",
        fim: Some("plantuml.md"),
    },
    RenderRow {
        slug: "graphviz",
        description: "Graphviz dot",
        default_ext: "svg",
        fim: Some("graphviz.md"),
    },
    RenderRow {
        slug: "puppeteer",
        description: "Puppeteer / Chromium screenshots",
        default_ext: "png",
        fim: Some("html.md"),
    },
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fn load_category_map(package_root: &Path) -> HashMap<String, (String, String)> {
    let mut map = HashMap::new();
    let cat_root = package_root
        .join("skill/content-media-engine/assets/fim/categories");
    if !cat_root.is_dir() {
        return map;
    }
    if let Ok(cats) = std::fs::read_dir(&cat_root) {
        for cat in cats.flatten() {
            let cat_path = cat.path();
            if !cat_path.is_dir() {
                continue;
            }
            let cat_key = cat.file_name().to_string_lossy().to_string();
            let cat_label = humanize(&cat_key);
            if let Ok(members) = std::fs::read_dir(&cat_path) {
                for m in members.flatten() {
                    let name = m.file_name().to_string_lossy().to_string();
                    // category members are files without extension or dirs
                    let slug = name;
                    map.insert(slug, (cat_key.clone(), cat_label.clone()));
                }
            }
        }
    }
    map
}

fn humanize(s: &str) -> String {
    s.replace('-', " ")
        .split_whitespace()
        .map(|w| {
            let mut c = w.chars();
            match c.next() {
                None => String::new(),
                Some(f) => f.to_uppercase().collect::<String>() + c.as_str(),
            }
        })
        .collect::<Vec<_>>()
        .join(" ")
}

fn infer_category(stem: &str) -> (String, String) {
    let s = stem.to_lowercase();
    let (k, l) = if matches!(
        s.as_str(),
        "haiku" | "sonnet" | "limerick" | "epic-poem" | "short-story" | "novel-chapter"
    ) {
        ("literature", "Literature & Poetry")
    } else if matches!(
        s.as_str(),
        "ad-copy"
            | "marketing-copy"
            | "press-release"
            | "seo-article"
            | "email-copy"
            | "ux-microcopy"
    ) {
        ("marketing", "Marketing & Copy")
    } else if matches!(
        s.as_str(),
        "user-manual"
            | "getting-started"
            | "api-reference"
            | "technical-blog"
            | "readme"
    ) {
        ("instructional", "Instructional Docs")
    } else if s.contains("mermaid")
        || s.contains("plantuml")
        || s.contains("graphviz")
        || s.contains("diag")
    {
        ("diagrams-dsl-xml", "Diagrams DSL / XML")
    } else {
        ("uncategorized", "Uncategorized FIM Channels")
    };
    (k.into(), l.into())
}

fn infer_asset_for_fim(stem: &str, cat: &str) -> (Vec<String>, Option<String>) {
    let s = stem.to_lowercase();
    if cat.contains("diagram") || s.contains("mermaid") || s.contains("plantuml") || s.contains("graphviz") || s.contains("wavedrom") {
        return (vec!["diagram".into()], Some(ext_for_diagram(&s)));
    }
    if cat.contains("music") || matches!(s.as_str(), "abcjs" | "lilypond" | "vexflow" | "musicxml" | "osmd") {
        return (vec!["document".into()], Some("txt".into()));
    }
    if cat.contains("document") || matches!(s.as_str(), "html" | "markdown" | "latex" | "typst" | "asciidoc") {
        if s == "html" {
            return (vec!["html".into()], Some("html".into()));
        }
        return (vec!["document".into()], Some("md".into()));
    }
    if s == "svg" || s == "svg_js" {
        return (vec!["image".into()], Some("svg".into()));
    }
    if s.contains("react") || s.ends_with("_js") || s.contains("tsx") {
        return (vec!["component".into(), "html".into()], Some("tsx".into()));
    }
    if matches!(
        s.as_str(),
        "haiku" | "sonnet" | "limerick" | "epic-poem" | "ad-copy" | "ux-microcopy"
    ) {
        return (vec!["document".into()], Some("txt".into()));
    }
    (vec!["document".into(), "component".into()], Some("md".into()))
}

fn ext_for_diagram(s: &str) -> String {
    if s.contains("plantuml") || s.contains("puml") {
        "puml".into()
    } else if s.contains("graphviz") || s == "dot" {
        "dot".into()
    } else if s.contains("wavedrom") {
        "json".into()
    } else {
        "mmd".into()
    }
}

fn first_heading_or(path: &Path, fallback: &str) -> String {
    let Ok(text) = std::fs::read_to_string(path) else {
        return fallback.into();
    };
    for line in text.lines().take(30) {
        let t = line.trim();
        if let Some(rest) = t.strip_prefix("# ") {
            return rest.trim().to_string();
        }
    }
    // second paragraph as description
    let mut paras = text.split("\n\n");
    let _ = paras.next();
    if let Some(p) = paras.next() {
        let one: String = p.chars().take(160).collect();
        if !one.trim().is_empty() {
            return one.replace('\n', " ");
        }
    }
    fallback.into()
}

/// demo_index: service/format slug → paths
fn index_demos_by_provider(demos_dir: &Path) -> HashMap<String, Vec<String>> {
    let mut map: HashMap<String, Vec<String>> = HashMap::new();
    let mut files = Vec::new();
    collect_prompts(demos_dir, &mut files);
    for path in files {
        let Ok(text) = std::fs::read_to_string(&path) else {
            continue;
        };
        let path_s = path.display().to_string();
        // crude yaml key scrape
        for key in ["service:", "diagram_type:", "text_format:"] {
            for line in text.lines() {
                let line = line.trim();
                if let Some(rest) = line.strip_prefix(key) {
                    let val = rest.trim().trim_matches('"').trim_matches('\'');
                    if !val.is_empty() {
                        map.entry(val.to_string()).or_default().push(path_s.clone());
                    }
                }
            }
        }
        // folder name as type
        if let Some(parent) = path.parent().and_then(|p| p.file_name()) {
            let folder = parent.to_string_lossy().to_string();
            map.entry(folder).or_default().push(path_s.clone());
        }
    }
    // dedupe paths
    for v in map.values_mut() {
        let set: BTreeSet<_> = v.iter().cloned().collect();
        *v = set.into_iter().collect();
    }
    map
}

fn demos_for(
    index: &HashMap<String, Vec<String>>,
    slug: &str,
    alt: Option<&str>,
) -> (usize, Vec<String>) {
    let mut paths = Vec::new();
    if let Some(p) = index.get(slug) {
        paths.extend(p.iter().cloned());
    }
    if let Some(a) = alt {
        if a != slug {
            if let Some(p) = index.get(a) {
                paths.extend(p.iter().cloned());
            }
        }
    }
    // aliases
    let aliases: &[&str] = match slug {
        "groq-chat" => &["groq"],
        "z.ai" => &["zai", "z.ai"],
        "gemini" => &["imagen"],
        "graphviz" => &["dot", "graphviz-dot"],
        "plantuml" => &["puml"],
        "mermaid" => &["mmd"],
        _ => &[],
    };
    for a in aliases {
        if let Some(p) = index.get(*a) {
            paths.extend(p.iter().cloned());
        }
    }
    let set: BTreeSet<_> = paths.into_iter().collect();
    let paths: Vec<_> = set.into_iter().collect();
    (paths.len(), paths)
}

fn collect_prompts(dir: &Path, out: &mut Vec<PathBuf>) {
    let Ok(rd) = std::fs::read_dir(dir) else {
        return;
    };
    for ent in rd.flatten() {
        let p = ent.path();
        if p.is_dir() {
            let name = p.file_name().and_then(|n| n.to_str()).unwrap_or("");
            if name == "target" || name == ".git" {
                continue;
            }
            collect_prompts(&p, out);
        } else if p
            .file_name()
            .and_then(|n| n.to_str())
            .map(|n| n.ends_with(".media.prompt"))
            .unwrap_or(false)
        {
            out.push(p);
        }
    }
}

/// Suggest a minimal .media.prompt YAML for a provider entry.
pub fn suggest_prompt_yaml(entry: &ProviderEntry) -> String {
    let asset = entry
        .asset_types
        .first()
        .map(|s| s.as_str())
        .unwrap_or("document");
    let ext = entry
        .default_extension
        .as_deref()
        .unwrap_or("md");
    let id = format!("lab-{}-001", entry.slug.replace('.', "-"));

    match entry.kind {
        ProviderKind::MediaApi => {
            let svc = &entry.slug;
            format!(
                r#"schema: "0.4"
id: {id}
type: {asset}
quality: medium
service: {svc}

prompt:
  text: "Test generation for provider {svc}: a clear, simple subject suitable for automated eval."

output:
  formats:
    - format: {ext}

eval:
  pass_threshold: 0.65
  criteria:
    relevance:
      weight: 3
      description: "Matches the test brief"
    technical:
      weight: 2
      description: "Valid non-empty output"
tags: [lab, provider-fixture, {svc}]
"#
            )
        }
        ProviderKind::ChatApi => format!(
            r#"schema: "0.4"
id: {id}
type: html
quality: medium
service: {svc}

prompt:
  system: "Output ONLY a complete self-contained HTML page with inline CSS. No markdown fences."
  text: "Create a minimal one-section landing page titled Provider Lab Test for {svc}."
  provider_options:
    max_tokens: 4096
    temperature: 0.3

output:
  formats:
    - format: html
  text_format: html

eval:
  pass_threshold: 0.7
  criteria:
    completeness:
      weight: 3
      description: "Has title and body content"
tags: [lab, chat-fixture, {svc}]
"#,
            svc = entry.slug
        ),
        ProviderKind::Renderer => format!(
            r#"schema: "0.4"
id: {id}
type: diagram
quality: medium
service: groq-chat

prompt:
  system: "Output ONLY valid markup for {tool}. No fences, no explanation."
  text: "Simple flowchart: Start → Process → End"

output:
  formats:
    - format: {fmt}
    - format: svg
  diagram_type: {tool}
  text_format: {tool}

post_processing:
  - action: render
    params:
      tool: {tool}
      output_format: svg

eval:
  pass_threshold: 0.7
  criteria:
    syntax_quality:
      weight: 3
      description: "Valid {tool} markup"
tags: [lab, renderer-fixture, {tool}]
"#,
            tool = entry.slug,
            fmt = if entry.slug == "plantuml" {
                "puml"
            } else if entry.slug == "graphviz" {
                "dot"
            } else {
                "mmd"
            }
        ),
        ProviderKind::FimChannel => {
            let text_format = &entry.slug;
            format!(
                r#"schema: "0.4"
id: {id}
type: {asset}
quality: medium
service: groq-chat

prompt:
  system: "You generate {text_format} artifacts. Output ONLY the raw artifact — no markdown fences, no commentary."
  text: "Create a small, self-contained {text_format} example suitable for a test fixture. Keep it short and valid."
  provider_options:
    max_tokens: 4096
    temperature: 0.2

output:
  formats:
    - format: {ext}
  text_format: {text_format}

eval:
  pass_threshold: 0.65
  criteria:
    relevance:
      weight: 3
      description: "Valid {text_format} content matching the brief"
    completeness:
      weight: 2
      description: "Self-contained artifact"
tags: [lab, fim-fixture, {text_format}]
"#
            )
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn catalog_has_over_100_providers() {
        let root = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        let demos = root.join("demos");
        let cat = build_catalog(&demos, &root);
        assert!(
            cat.total >= 100,
            "expected ≥100 providers, got {} (impl={} stub={} fim={})",
            cat.total,
            cat.implemented,
            cat.stub,
            cat.fim_only
        );
        assert!(
            cat.categories.len() >= 5,
            "expected multiple categories, got {}",
            cat.categories.len()
        );
        // core media APIs present
        assert!(cat.providers.iter().any(|p| p.slug == "gemini"));
        assert!(cat.providers.iter().any(|p| p.slug == "mermaid"));
        assert!(cat.providers.iter().any(|p| p.slug == "d3_js" || p.id == "fim:d3_js"));
    }
}
