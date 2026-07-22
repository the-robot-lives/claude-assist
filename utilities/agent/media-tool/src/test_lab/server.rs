//! Axum HTTP server + embedded SPA for the media-tool test lab.

use std::collections::{BTreeMap, HashMap};
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::time::Duration;

use axum::extract::{Query, State};
use axum::http::{header, StatusCode};
use axum::response::{Html, IntoResponse, Response};
use axum::routing::{get, post};
use axum::{Json, Router};
use serde::{Deserialize, Serialize};
use serde_json::json;
use tokio::sync::Mutex;
use tower_http::cors::CorsLayer;
use uuid::Uuid;

use crate::eval::Evaluator;
use crate::pipeline::{self, PipelineConfig};
use crate::prep::PromptPrepper;
use crate::schema::parse_prompt_file;
use crate::ui;

use super::catalog::{
    load_detail, resolve_safe_media, scan_catalog, type_label, PromptDetail, TypeGroup,
};
use super::persist::{self, ExamplesIndex};
use super::registry::{self, ProviderCatalog, ProviderEntry};
use super::settings::{self, LabSettings};
use super::LabConfig;

// ---------------------------------------------------------------------------
// Shared state
// ---------------------------------------------------------------------------

#[derive(Clone)]
struct AppState {
    inner: Arc<AppInner>,
}

struct AppInner {
    cfg: LabConfig,
    jobs: Mutex<HashMap<String, Job>>,
    /// Full provider/channel registry (≥100 entries), built at startup.
    providers: ProviderCatalog,
    /// Persisted lab settings (LLM for example-prompt generation, etc.)
    settings: Mutex<LabSettings>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "snake_case")]
enum JobStatus {
    Queued,
    Running,
    Succeeded,
    Failed,
}

#[derive(Debug, Clone, Serialize)]
struct Job {
    id: String,
    kind: String,
    status: JobStatus,
    prompt_path: Option<String>,
    message: String,
    started_at: String,
    finished_at: Option<String>,
    result: Option<serde_json::Value>,
}

// ---------------------------------------------------------------------------
// Public entry
// ---------------------------------------------------------------------------

pub async fn run_lab(cfg: LabConfig) -> color_eyre::Result<()> {
    ui::step(&format!(
        "Media-tool test lab — demos={} workspace={}",
        cfg.demos_dir.display(),
        cfg.workspace_dir.display()
    ));

    let providers =
        registry::build_catalog(&cfg.demos_dir, &cfg.package_root);
    ui::ok(&format!(
        "Provider registry: {} total ({} implemented, {} stub, {} FIM channels, {} local tools)",
        providers.total,
        providers.implemented,
        providers.stub,
        providers.fim_only,
        providers.local_tool
    ));

    let settings = LabSettings::load(&cfg.workspace_dir);
    ui::ok(&format!(
        "Example-prompt LLM: {} / {} ({})",
        settings.llm.provider,
        settings.llm.effective_model(),
        if settings.llm.effective_api_key().is_some() {
            "key ok"
        } else {
            "no key"
        }
    ));

    let state = AppState {
        inner: Arc::new(AppInner {
            cfg: cfg.clone(),
            jobs: Mutex::new(HashMap::new()),
            providers,
            settings: Mutex::new(settings),
        }),
    };

    let app = Router::new()
        .route("/", get(index_page))
        .route("/api/health", get(health))
        .route("/api/kinds", get(api_kinds))
        .route("/api/graph", get(api_graph))
        .route("/api/catalog", get(api_catalog))
        .route("/api/providers", get(api_providers))
        .route("/api/providers/{id}", get(api_provider_detail))
        .route("/api/providers/{id}/scaffold", post(api_provider_scaffold))
        .route("/api/prompt", get(api_prompt_detail))
        .route("/api/media", get(api_media))
        .route("/api/jobs", get(api_list_jobs))
        .route("/api/jobs/{id}", get(api_get_job))
        .route("/api/generate", post(api_generate))
        .route("/api/eval", post(api_eval))
        .route("/api/prompts/generate", post(api_generate_prompts))
        .route("/api/prompts/list", get(api_prompts_list))
        .route("/api/prompt/save", post(api_save_prompt))
        .route("/api/settings", get(api_settings_get).put(api_settings_put))
        .route("/api/settings/llm-meta", get(api_settings_llm_meta))
        .route("/api/settings/test-llm", post(api_settings_test_llm))
        .layer(CorsLayer::permissive())
        .with_state(state);

    let addr = format!("127.0.0.1:{}", cfg.port);
    let listener = tokio::net::TcpListener::bind(&addr).await?;
    let url = format!("http://{addr}");
    ui::ok(&format!("Test lab listening on {url}"));
    eprintln!("  Graph lab: expand sections → pick a generator → scaffold / generate / view.");
    eprintln!("  Demos:     {}", cfg.demos_dir.display());
    eprintln!("  Workspace: {}", cfg.workspace_dir.display());
    eprintln!(
        "  Index:     {}",
        ExamplesIndex::path(&cfg.workspace_dir).display()
    );
    eprintln!(
        "  Settings:  {}",
        LabSettings::settings_path(&cfg.workspace_dir).display()
    );
    eprintln!("  Ctrl+C to stop.\n");

    if cfg.open_browser {
        let _ = open_browser(&url);
    }

    axum::serve(listener, app).await?;
    Ok(())
}

fn open_browser(url: &str) -> std::io::Result<()> {
    #[cfg(target_os = "macos")]
    {
        std::process::Command::new("open").arg(url).spawn()?;
    }
    #[cfg(target_os = "linux")]
    {
        std::process::Command::new("xdg-open").arg(url).spawn()?;
    }
    #[cfg(target_os = "windows")]
    {
        std::process::Command::new("cmd")
            .args(["/C", "start", url])
            .spawn()?;
    }
    Ok(())
}

// ---------------------------------------------------------------------------
// Handlers
// ---------------------------------------------------------------------------

async fn index_page() -> Html<&'static str> {
    Html(include_str!("static/index.html"))
}

async fn health(State(st): State<AppState>) -> Json<serde_json::Value> {
    let settings = st.inner.settings.lock().await;
    let idx = ExamplesIndex::load(&st.inner.cfg.workspace_dir);
    let indexed_prompts: usize = idx.generators.values().map(|v| v.len()).sum();
    Json(json!({
        "ok": true,
        "demos": st.inner.cfg.demos_dir.display().to_string(),
        "workspace": st.inner.cfg.workspace_dir.display().to_string(),
        "examples_index": ExamplesIndex::path(&st.inner.cfg.workspace_dir).display().to_string(),
        "indexed_generators": idx.generators.len(),
        "indexed_prompts": indexed_prompts,
        "settings": LabSettings::settings_path(&st.inner.cfg.workspace_dir).display().to_string(),
        "providers_total": st.inner.providers.total,
        "providers_implemented": st.inner.providers.implemented,
        "providers_stub": st.inner.providers.stub,
        "providers_fim_only": st.inner.providers.fim_only,
        "categories": st.inner.providers.categories.len(),
        "llm": {
            "provider": settings.llm.provider,
            "model": settings.llm.effective_model(),
            "ready": settings.llm.effective_api_key().is_some()
                || !settings::provider_defaults(&settings.llm.provider).needs_api_key,
        },
    }))
}

async fn api_settings_get(State(st): State<AppState>) -> Json<serde_json::Value> {
    let settings = st.inner.settings.lock().await;
    let mut pubj = settings.public_json();
    pubj["path"] = json!(LabSettings::settings_path(&st.inner.cfg.workspace_dir).display().to_string());
    // Return editable api_key field: prefer env: refs as-is; for real keys send empty + has_key
    if !settings.llm.api_key.trim().to_lowercase().starts_with("env:")
        && !settings.llm.api_key.trim().is_empty()
    {
        pubj["llm"]["api_key_edit"] = json!("");
        pubj["llm"]["api_key_is_set"] = json!(true);
    } else {
        pubj["llm"]["api_key_edit"] = json!(settings.llm.api_key);
        pubj["llm"]["api_key_is_set"] = json!(settings.llm.effective_api_key().is_some());
    }
    Json(pubj)
}

async fn api_settings_llm_meta() -> Json<serde_json::Value> {
    Json(settings::llm_ui_meta())
}

#[derive(Deserialize)]
struct SettingsPutBody {
    llm: Option<LlmPutBody>,
}

#[derive(Deserialize)]
struct LlmPutBody {
    provider: Option<String>,
    model: Option<String>,
    base_url: Option<String>,
    /// If null/omitted and previous was a stored secret, keep previous.
    /// Empty string clears. `env: VAR` sets env ref.
    api_key: Option<String>,
}

async fn api_settings_put(
    State(st): State<AppState>,
    Json(body): Json<SettingsPutBody>,
) -> Result<Json<serde_json::Value>, ApiError> {
    let mut settings = st.inner.settings.lock().await;
    if let Some(llm) = body.llm {
        if let Some(p) = llm.provider {
            let p = p.trim().to_lowercase();
            if !p.is_empty() {
                settings.llm.provider = p;
            }
        }
        if let Some(m) = llm.model {
            settings.llm.model = m.trim().to_string();
        }
        if let Some(u) = llm.base_url {
            settings.llm.base_url = u.trim().to_string();
        }
        if let Some(k) = llm.api_key {
            let k = k.trim().to_string();
            // Empty means "leave unchanged" when a non-env secret is already stored
            // and the client sent blank to avoid round-tripping secrets.
            if k.is_empty() {
                // keep existing unless it was empty
            } else if k == "—" || k.starts_with("••••") {
                // ignore masked placeholders
            } else {
                settings.llm.api_key = k;
            }
        }
        // If model empty after provider change, fill default
        if settings.llm.model.trim().is_empty() {
            settings.llm.model = settings::provider_defaults(&settings.llm.provider)
                .model
                .unwrap_or(settings::DEFAULT_EXAMPLE_MODEL)
                .to_string();
        }
        if settings.llm.base_url.trim().is_empty() {
            if let Some(u) = settings::provider_defaults(&settings.llm.provider).base_url {
                settings.llm.base_url = u.to_string();
            }
        }
    }
    settings
        .save(&st.inner.cfg.workspace_dir)
        .map_err(|e| ApiError::bad(format!("save settings: {e}")))?;

    let mut pubj = settings.public_json();
    pubj["path"] = json!(LabSettings::settings_path(&st.inner.cfg.workspace_dir).display().to_string());
    pubj["saved"] = json!(true);
    Ok(Json(pubj))
}

async fn api_settings_test_llm(State(st): State<AppState>) -> Result<Json<serde_json::Value>, ApiError> {
    let llm = st.inner.settings.lock().await.llm.clone();

    let key = llm.effective_api_key();
    if settings::provider_defaults(&llm.provider).needs_api_key && key.is_none() {
        return Err(ApiError::bad(
            "No API key resolved — set key or env: GROQ_API_KEY".into(),
        ));
    }
    let base = llm.effective_base_url();
    let model = llm.effective_model();
    let url = if base.ends_with("/chat/completions") {
        base.clone()
    } else {
        format!("{}/chat/completions", base)
    };

    let body = json!({
        "model": model,
        "messages": [
            {"role": "user", "content": "Reply with exactly: ok"}
        ],
        "max_tokens": 16,
        "temperature": 0,
    });

    let client = reqwest::Client::new();
    let mut req = client
        .post(&url)
        .header("Content-Type", "application/json")
        .json(&body)
        .timeout(Duration::from_secs(60));
    if let Some(k) = key {
        req = req.header("Authorization", format!("Bearer {k}"));
    }
    // Anthropic needs special headers — if provider is anthropic use messages API differently
    // For simplicity, only support OpenAI-compatible endpoints in test (groq, openai, litellm, ollama)
    if llm.provider == "anthropic" {
        return Ok(Json(json!({
            "ok": false,
            "message": "Anthropic test via OpenAI-compat not configured; save settings and use groq/openai for example prompts.",
        })));
    }

    let resp = req.send().await.map_err(|e| ApiError::bad(e.to_string()))?;
    let status = resp.status();
    let text = resp.text().await.unwrap_or_default();
    if !status.is_success() {
        return Ok(Json(json!({
            "ok": false,
            "message": format!("HTTP {status}: {}", text.chars().take(200).collect::<String>()),
            "model": model,
            "base_url": base,
        })));
    }
    Ok(Json(json!({
        "ok": true,
        "message": format!("Connected — model {model}"),
        "model": model,
        "base_url": base,
        "sample": text.chars().take(120).collect::<String>(),
    })))
}

async fn api_catalog(State(st): State<AppState>) -> Result<Json<Vec<TypeGroup>>, ApiError> {
    let groups = scan_catalog(&st.inner.cfg.demos_dir, &st.inner.cfg.workspace_dir)
        .map_err(|e| ApiError::bad(e.to_string()))?;
    Ok(Json(groups))
}

/// Hierarchical map for the landing page: sections → generators (media kinds + FIM).
/// Drill-down navigation; leaf nodes are generators you work with.
async fn api_graph(State(st): State<AppState>) -> Result<Json<serde_json::Value>, ApiError> {
    use crate::providers::{self, available, candidates_for};
    use crate::schema::{AssetType, AudioKind, Quality};
    use crate::test_lab::registry::ProviderKind;

    let groups = scan_catalog(&st.inner.cfg.demos_dir, &st.inner.cfg.workspace_dir)
        .map_err(|e| ApiError::bad(e.to_string()))?;

    // --- Media generation section (intent kinds; auto provider) ---
    let media_kinds: &[(&str, &str, &str, AssetType, AudioKind)] = &[
        (
            "image",
            "Image",
            "Still images & logos — quality selects Imagen path",
            AssetType::Image,
            AudioKind::Voice,
        ),
        (
            "video",
            "Video",
            "Short motion clips — quality selects Veo/Grok path",
            AssetType::Video,
            AudioKind::Voice,
        ),
        (
            "music",
            "Music",
            "Tracks & beds — auto Suno",
            AssetType::Audio,
            AudioKind::Music,
        ),
        (
            "voice",
            "Voice / TTS",
            "Spoken voiceovers — quality steps TTS engines",
            AssetType::Audio,
            AudioKind::Voice,
        ),
        (
            "sfx",
            "Sound effects",
            "Short SFX — Suno sound mode",
            AssetType::Audio,
            AudioKind::Sfx,
        ),
        (
            "diagram",
            "Diagram (generic)",
            "DSL diagrams via chat + render",
            AssetType::Diagram,
            AudioKind::Voice,
        ),
        (
            "html",
            "HTML page",
            "Self-contained pages",
            AssetType::Html,
            AudioKind::Voice,
        ),
        (
            "react-page",
            "React page",
            "TSX pages / landings",
            AssetType::ReactPage,
            AudioKind::Voice,
        ),
        (
            "component",
            "Component",
            "Reusable UI components",
            AssetType::Component,
            AudioKind::Voice,
        ),
        (
            "game",
            "Game",
            "Playable HTML canvas demos",
            AssetType::Html,
            AudioKind::Voice,
        ),
        (
            "document",
            "Document",
            "Markdown / text docs",
            AssetType::Document,
            AudioKind::Voice,
        ),
        (
            "svg",
            "SVG vector",
            "Vector graphics via chat",
            AssetType::Diagram,
            AudioKind::Voice,
        ),
    ];

    let mut media_children = Vec::new();
    for (key, label, blurb, asset, audio) in media_kinds {
        let mut examples = groups
            .iter()
            .find(|g| g.type_key == *key)
            .map(|g| g.prompts.clone())
            .unwrap_or_default();
        if *key == "voice" {
            if let Some(g) = groups.iter().find(|g| g.type_key == "audio") {
                for p in &g.prompts {
                    if !examples.iter().any(|e| e.path == p.path) {
                        examples.push(p.clone());
                    }
                }
            }
        }

        let mut by_q = serde_json::Map::new();
        for q in [Quality::Low, Quality::Medium, Quality::High] {
            let cands: Vec<_> = candidates_for(*asset, *audio, q)
                .into_iter()
                .map(|c| {
                    json!({
                        "service": c.service,
                        "model": c.model,
                        "ready": available(&c),
                        "api_key_env": providers::api_key_env(c.service),
                    })
                })
                .collect();
            let ready = cands.iter().any(|c| c["ready"].as_bool() == Some(true));
            by_q.insert(
                q.as_str().into(),
                json!({ "candidates": cands, "ready": ready }),
            );
        }

        media_children.push(json!({
            "id": format!("kind:{key}"),
            "slug": key,
            "label": label,
            "description": blurb,
            "node_type": "media_kind",
            "auto_selects": true,
            "example_count": examples.len(),
            "examples": examples,
            "quality": by_q,
            "children": [],
        }));
    }

    // --- FIM category sections (music notation, diagrams, etc.) ---
    let mut by_cat: BTreeMap<String, Vec<serde_json::Value>> = BTreeMap::new();
    let mut cat_labels: BTreeMap<String, String> = BTreeMap::new();

    for p in &st.inner.providers.providers {
        if p.kind != ProviderKind::FimChannel {
            continue;
        }
        // Skip pure media-api/chat/renderer categories
        if matches!(
            p.category.as_str(),
            "media-api" | "chat-api" | "renderer"
        ) {
            continue;
        }
        cat_labels
            .entry(p.category.clone())
            .or_insert_with(|| p.category_label.clone());

        by_cat.entry(p.category.clone()).or_default().push(json!({
            "id": p.id,
            "slug": p.slug,
            "label": p.slug.replace('_', " ").replace('-', " "),
            "description": p.description,
            "node_type": "generator",
            "status": p.status,
            "kind": p.kind,
            "asset_types": p.asset_types,
            "default_extension": p.default_extension,
            "fim_solution": p.fim_solution,
            "demo_count": p.demo_count,
            "demo_paths": p.demo_paths,
            "auto_selects": true,
            "auto_note": "Chat model auto-selected; this channel sets text_format / system guidance",
            "children": [],
        }));
    }

    // Sort generators within category by slug
    for list in by_cat.values_mut() {
        list.sort_by(|a, b| {
            a["slug"]
                .as_str()
                .unwrap_or("")
                .cmp(b["slug"].as_str().unwrap_or(""))
        });
    }

    let mut format_children = Vec::new();
    for (cat_key, gens) in &by_cat {
        let label = cat_labels
            .get(cat_key)
            .cloned()
            .unwrap_or_else(|| cat_key.replace('-', " "));
        format_children.push(json!({
            "id": format!("section:{cat_key}"),
            "slug": cat_key,
            "label": label,
            "description": format!("{} generators", gens.len()),
            "node_type": "section",
            "count": gens.len(),
            "children": gens,
        }));
    }
    format_children.sort_by(|a, b| {
        a["label"]
            .as_str()
            .unwrap_or("")
            .cmp(b["label"].as_str().unwrap_or(""))
    });

    // --- Renderers section ---
    let render_children: Vec<_> = st
        .inner
        .providers
        .providers
        .iter()
        .filter(|p| p.kind == ProviderKind::Renderer)
        .map(|p| {
            json!({
                "id": p.id,
                "slug": p.slug,
                "label": p.slug,
                "description": p.description,
                "node_type": "generator",
                "status": p.status,
                "kind": p.kind,
                "demo_count": p.demo_count,
                "demo_paths": p.demo_paths,
                "auto_selects": false,
                "children": [],
            })
        })
        .collect();

    let graph = json!({
        "roots": [
            {
                "id": "root:media",
                "label": "Media generation",
                "description": "Image, video, audio, pages — declare kind + quality; system picks providers",
                "node_type": "root_section",
                "count": media_children.len(),
                "children": media_children,
            },
            {
                "id": "root:formats",
                "label": "Formats & libraries",
                "description": "Full channel library: music notation, diagrams, charts, 3D, docs, …",
                "node_type": "root_section",
                "count": format_children.iter().map(|c| c["count"].as_u64().unwrap_or(0)).sum::<u64>(),
                "children": format_children,
            },
            {
                "id": "root:renderers",
                "label": "Local renderers",
                "description": "Markup → visual tools (mermaid, plantuml, …)",
                "node_type": "root_section",
                "count": render_children.len(),
                "children": render_children,
            },
        ],
        "totals": {
            "providers": st.inner.providers.total,
            "fim_channels": st.inner.providers.fim_only,
            "sections": format_children.len() + 2,
        }
    });

    Ok(Json(graph))
}

/// Intent-first media kinds: type + quality → auto provider candidates.
/// Kept for compatibility; primary nav is `/api/graph`.
async fn api_kinds(State(st): State<AppState>) -> Result<Json<serde_json::Value>, ApiError> {
    use crate::providers::{self, available, candidates_for};
    use crate::schema::{AssetType, AudioKind, Quality};

    let groups = scan_catalog(&st.inner.cfg.demos_dir, &st.inner.cfg.workspace_dir)
        .map_err(|e| ApiError::bad(e.to_string()))?;

    let kinds_meta: &[(&str, &str, &str, AssetType, AudioKind)] = &[
        (
            "image",
            "Image",
            "Still images and logos. Quality picks Imagen speed vs fidelity.",
            AssetType::Image,
            AudioKind::Voice,
        ),
        (
            "svg",
            "SVG / vector",
            "Vector graphics via chat generation (auto chat model).",
            AssetType::Image,
            AudioKind::Voice,
        ),
        (
            "video",
            "Video",
            "Short motion clips. Quality balances speed (Grok/Veo-fast) vs fidelity.",
            AssetType::Video,
            AudioKind::Voice,
        ),
        (
            "music",
            "Music",
            "Background tracks and songs (Suno).",
            AssetType::Audio,
            AudioKind::Music,
        ),
        (
            "voice",
            "Voice",
            "Spoken voiceovers. Quality steps through TTS engines.",
            AssetType::Audio,
            AudioKind::Voice,
        ),
        (
            "audio",
            "Voice (audio)",
            "Legacy type: audio treated as voice TTS.",
            AssetType::Audio,
            AudioKind::Voice,
        ),
        (
            "sfx",
            "Sound effects",
            "Short SFX clips (Suno sound mode).",
            AssetType::Audio,
            AudioKind::Sfx,
        ),
        (
            "diagram",
            "Diagram",
            "Architecture and flow diagrams (markup + local render).",
            AssetType::Diagram,
            AudioKind::Voice,
        ),
        (
            "html",
            "HTML page",
            "Self-contained pages and landing layouts.",
            AssetType::Html,
            AudioKind::Voice,
        ),
        (
            "react-page",
            "React page",
            "TSX page/component generation.",
            AssetType::ReactPage,
            AudioKind::Voice,
        ),
        (
            "component",
            "Component",
            "Reusable UI components.",
            AssetType::Component,
            AudioKind::Voice,
        ),
        (
            "game",
            "Game",
            "Playable HTML canvas / interactive demos.",
            AssetType::Html,
            AudioKind::Voice,
        ),
        (
            "document",
            "Document",
            "Markdown and text documents.",
            AssetType::Document,
            AudioKind::Voice,
        ),
        (
            "style-guide",
            "Style guide",
            "Design-system style guide pages.",
            AssetType::StyleGuide,
            AudioKind::Voice,
        ),
    ];

    let mut kinds = Vec::new();
    for (key, label, blurb, asset, audio) in kinds_meta {
        // Skip legacy "audio" as its own top-level card — demos fold into voice below.
        if *key == "audio" {
            continue;
        }

        let mut examples = groups
            .iter()
            .find(|g| g.type_key == *key)
            .map(|g| g.prompts.clone())
            .unwrap_or_default();

        // v0.3 demos often use type: audio for voice — surface them under Voice.
        if *key == "voice" {
            if let Some(g) = groups.iter().find(|g| g.type_key == "audio") {
                for p in &g.prompts {
                    if !examples.iter().any(|e| e.path == p.path) {
                        examples.push(p.clone());
                    }
                }
            }
        }

        // Chat-backed kinds: show chat auto-select path, not Imagen.
        let (cand_asset, cand_audio) = if matches!(
            *key,
            "svg" | "diagram" | "html" | "react-page" | "component" | "game" | "document"
                | "style-guide"
        ) {
            // Use Diagram as stand-in for is_chat_type candidate table (same chat list).
            (AssetType::Diagram, AudioKind::Voice)
        } else {
            (*asset, *audio)
        };

        let mut by_quality = serde_json::Map::new();
        for q in [Quality::Low, Quality::Medium, Quality::High] {
            let all = candidates_for(cand_asset, cand_audio, q);
            let cands: Vec<serde_json::Value> = all
                .iter()
                .map(|c| {
                    let ready = available(c);
                    json!({
                        "service": c.service,
                        "model": c.model,
                        "ready": ready,
                        "api_key_env": providers::api_key_env(c.service),
                    })
                })
                .collect();
            let any_ready = cands.iter().any(|c| c["ready"].as_bool() == Some(true));
            by_quality.insert(
                q.as_str().to_string(),
                json!({
                    "candidates": cands,
                    "ready": any_ready,
                }),
            );
        }

        kinds.push(json!({
            "key": key,
            "label": label,
            "description": blurb,
            "example_count": examples.len(),
            "examples": examples,
            "quality": by_quality,
            "auto_selects": true,
        }));
    }

    Ok(Json(json!({
        "kinds": kinds,
        "note": "Declare type + quality; the tool auto-selects providers. Pin service only when needed.",
    })))
}

#[derive(Deserialize)]
struct ProvidersQuery {
    /// Filter by category key
    category: Option<String>,
    /// Filter by kind: media_api | chat_api | renderer | fim_channel
    kind: Option<String>,
    /// Filter by status: implemented | stub | fim_only | local_tool
    status: Option<String>,
    /// Substring match on slug/description
    q: Option<String>,
}

async fn api_providers(
    State(st): State<AppState>,
    Query(q): Query<ProvidersQuery>,
) -> Json<serde_json::Value> {
    let mut list: Vec<&ProviderEntry> = st.inner.providers.providers.iter().collect();
    if let Some(ref cat) = q.category {
        list.retain(|p| &p.category == cat);
    }
    if let Some(ref kind) = q.kind {
        list.retain(|p| format!("{:?}", p.kind).to_lowercase().contains(&kind.to_lowercase().replace('-', "_")));
    }
    if let Some(ref status) = q.status {
        list.retain(|p| {
            format!("{:?}", p.status)
                .to_lowercase()
                .contains(&status.to_lowercase().replace('-', "_"))
        });
    }
    if let Some(ref query) = q.q {
        let ql = query.to_lowercase();
        list.retain(|p| {
            p.slug.to_lowercase().contains(&ql)
                || p.description.to_lowercase().contains(&ql)
                || p.id.to_lowercase().contains(&ql)
        });
    }
    Json(json!({
        "total": st.inner.providers.total,
        "implemented": st.inner.providers.implemented,
        "stub": st.inner.providers.stub,
        "fim_only": st.inner.providers.fim_only,
        "local_tool": st.inner.providers.local_tool,
        "categories": st.inner.providers.categories,
        "filtered": list.len(),
        "providers": list,
    }))
}

async fn api_provider_detail(
    State(st): State<AppState>,
    axum::extract::Path(id): axum::extract::Path<String>,
) -> Result<Json<serde_json::Value>, ApiError> {
    // Accept id with or without URL-encoded colon (media:gemini or media%3Agemini)
    let id = id.replace("%3A", ":").replace("%3a", ":");
    let entry = st
        .inner
        .providers
        .providers
        .iter()
        .find(|p| p.id == id || p.slug == id)
        .ok_or_else(|| ApiError::not_found(format!("provider {id}")))?;

    let scaffold = registry::suggest_prompt_yaml(entry);
    // FIM body preview if available
    let fim_preview = entry.fim_solution.as_ref().and_then(|rel| {
        let dir = crate::fim::resolve_solution_dir()?;
        let path = dir.join(rel);
        let text = std::fs::read_to_string(path).ok()?;
        Some(text.chars().take(4000).collect::<String>())
    });

    Ok(Json(json!({
        "provider": entry,
        "scaffold_yaml": scaffold,
        "fim_preview": fim_preview,
    })))
}

/// Write a scaffolded test prompt for this provider into the workspace.
async fn api_provider_scaffold(
    State(st): State<AppState>,
    axum::extract::Path(id): axum::extract::Path<String>,
) -> Result<Json<serde_json::Value>, ApiError> {
    let id = id.replace("%3A", ":").replace("%3a", ":");
    let entry = st
        .inner
        .providers
        .providers
        .iter()
        .find(|p| p.id == id || p.slug == id)
        .ok_or_else(|| ApiError::not_found(format!("provider {id}")))?
        .clone();

    let yaml = registry::suggest_prompt_yaml(&entry);
    let folder = match entry.kind {
        registry::ProviderKind::MediaApi => format!("media/{}", entry.slug),
        registry::ProviderKind::ChatApi => format!("chat/{}", entry.slug.replace('.', "-")),
        registry::ProviderKind::Renderer => format!("render/{}", entry.slug),
        registry::ProviderKind::FimChannel => format!("fim/{}", entry.slug),
    };
    let dest_dir = st
        .inner
        .cfg
        .workspace_dir
        .join("prompts")
        .join(&folder);
    std::fs::create_dir_all(&dest_dir).map_err(|e| ApiError::bad(e.to_string()))?;
    let dest = dest_dir.join(format!("{}.media.prompt", entry.slug.replace('.', "-")));
    std::fs::write(&dest, &yaml).map_err(|e| ApiError::bad(e.to_string()))?;
    // Validate
    parse_prompt_file(&dest).map_err(|e| ApiError::bad(format!("invalid scaffold: {e}")))?;

    let path_str = dest.display().to_string();
    register_written_prompt(
        &st.inner.cfg.workspace_dir,
        &entry.slug,
        &path_str,
        Some(&entry.id),
    );

    Ok(Json(json!({
        "ok": true,
        "path": path_str,
        "provider_id": entry.id,
        "yaml": yaml,
        "index": ExamplesIndex::path(&st.inner.cfg.workspace_dir).display().to_string(),
    })))
}

#[derive(Deserialize)]
struct PromptQuery {
    path: String,
    source: Option<String>,
}

async fn api_prompt_detail(
    State(st): State<AppState>,
    Query(q): Query<PromptQuery>,
) -> Result<Json<PromptDetail>, ApiError> {
    let path = PathBuf::from(&q.path);
    if !path.is_file() {
        return Err(ApiError::not_found(format!("prompt not found: {}", q.path)));
    }
    let media_root = media_root_for(&path, &st.inner.cfg);
    let source = q.source.as_deref().unwrap_or_else(|| {
        if path.starts_with(&st.inner.cfg.workspace_dir) {
            "workspace"
        } else {
            "demos"
        }
    });
    let detail = load_detail(&path, &media_root, source).map_err(|e| ApiError::bad(e.to_string()))?;
    Ok(Json(detail))
}

#[derive(Deserialize)]
struct MediaQuery {
    path: String,
}

async fn api_media(
    State(st): State<AppState>,
    Query(q): Query<MediaQuery>,
) -> Result<Response, ApiError> {
    let file = resolve_safe_media(
        &q.path,
        &st.inner.cfg.demos_dir,
        &st.inner.cfg.workspace_dir,
    )
    .map_err(|e| ApiError::not_found(e.to_string()))?;

    let data = tokio::fs::read(&file)
        .await
        .map_err(|e| ApiError::bad(e.to_string()))?;
    let mime = mime_guess::from_path(&file)
        .first_or_octet_stream()
        .to_string();
    Ok((
        StatusCode::OK,
        [(header::CONTENT_TYPE, mime)],
        data,
    )
        .into_response())
}

#[derive(Deserialize)]
struct GenerateBody {
    path: String,
    #[serde(default)]
    force: bool,
    #[serde(default)]
    no_eval: bool,
    #[serde(default)]
    dry_run: bool,
    #[serde(default = "default_variants")]
    variants: usize,
    /// Optional quality override: low | medium | high (drives auto provider selection)
    quality: Option<String>,
}

fn default_variants() -> usize {
    1
}

async fn api_generate(
    State(st): State<AppState>,
    Json(body): Json<GenerateBody>,
) -> Result<Json<Job>, ApiError> {
    let path = PathBuf::from(&body.path);
    if !path.is_file() {
        return Err(ApiError::not_found(format!("prompt not found: {}", body.path)));
    }

    let job = enqueue_job(
        &st,
        "generate",
        Some(body.path.clone()),
        format!("Generate {}", path.display()),
    )
    .await;

    let st2 = st.clone();
    let job_id = job.id.clone();
    let path2 = path.clone();
    tokio::spawn(async move {
        set_job_running(&st2, &job_id).await;
        let result = run_generate_job(&st2, &path2, &body).await;
        finish_job(&st2, &job_id, result).await;
    });

    Ok(Json(job))
}

async fn run_generate_job(
    st: &AppState,
    path: &Path,
    body: &GenerateBody,
) -> Result<serde_json::Value, String> {
    let prompt = parse_prompt_file(path).map_err(|e| e.to_string())?;
    let quality_override = body
        .quality
        .as_deref()
        .and_then(|q| q.parse::<crate::schema::Quality>().ok());

    let config = PipelineConfig {
        variant_count: body.variants.max(1),
        dry_run: body.dry_run,
        force: body.force,
        model_override: None,
        verbose: st.inner.cfg.verbose,
        refine: false,
        quality_override,
        service_override: None, // intent-first: never pin from lab UI
        no_eval: body.no_eval,
        no_prep: false,
        fim_enabled: std::env::var("MEDIA_FIM_INJECT").ok().as_deref() != Some("0"),
        eval_url: None,
        eval_model: None,
    };
    pipeline::run_generation(vec![prompt], &config)
        .await
        .map_err(|e| e.to_string())?;

    // Rescan outputs for this prompt
    let media_root = media_root_for(path, &st.inner.cfg);
    let source = if path.starts_with(&st.inner.cfg.workspace_dir) {
        "workspace"
    } else {
        "demos"
    };
    let detail = load_detail(path, &media_root, source).map_err(|e| e.to_string())?;
    Ok(json!({
        "prompt_id": detail.summary.id,
        "outputs": detail.summary.outputs,
    }))
}

#[derive(Deserialize)]
struct EvalBody {
    /// Path to an output media file (or prompt path — then eval first existing output)
    path: String,
    /// Optional prompt path for criteria + prompt text
    prompt_path: Option<String>,
}

async fn api_eval(
    State(st): State<AppState>,
    Json(body): Json<EvalBody>,
) -> Result<Json<Job>, ApiError> {
    let job = enqueue_job(
        &st,
        "eval",
        Some(body.path.clone()),
        format!("Eval {}", body.path),
    )
    .await;
    let st2 = st.clone();
    let job_id = job.id.clone();
    tokio::spawn(async move {
        set_job_running(&st2, &job_id).await;
        let result = run_eval_job(&st2, &body).await;
        finish_job(&st2, &job_id, result).await;
    });
    Ok(Json(job))
}

async fn run_eval_job(st: &AppState, body: &EvalBody) -> Result<serde_json::Value, String> {
    let media_path = PathBuf::from(&body.path);
    if !media_path.is_file() {
        return Err(format!("file not found: {}", body.path));
    }

    // Resolve prompt: explicit or sibling .media.prompt
    let prompt_path = if let Some(ref p) = body.prompt_path {
        PathBuf::from(p)
    } else {
        find_sibling_prompt(&media_path).ok_or_else(|| {
            "could not find sibling .media.prompt — pass prompt_path".to_string()
        })?
    };
    let parsed = parse_prompt_file(&prompt_path).map_err(|e| e.to_string())?;
    let eval = parsed
        .payload
        .eval
        .clone()
        .unwrap_or_else(default_eval_for_type);

    let evaluator = Evaluator::resolve(None, None, st.inner.cfg.verbose)
        .await
        .ok_or_else(|| {
            "No eval endpoint reachable (set MEDIA_EVAL_BASE_URL / GROQ_API_KEY / port-forward)"
                .to_string()
        })?;

    let score = evaluator
        .score_output(
            &media_path,
            &parsed.payload.prompt.text,
            &eval,
            st.inner.cfg.verbose,
        )
        .await;

    match score {
        Some(s) => {
            let passes = s.passes(&eval);
            Ok(json!({
                "scorable": true,
                "passes": passes,
                "weighted": s.weighted,
                "per_criterion": s.per_criterion,
                "reject_hits": s.reject_hits,
                "notes": s.notes,
                "threshold": eval.effective_pass_threshold(),
                "prompt_path": prompt_path.display().to_string(),
                "media_path": media_path.display().to_string(),
            }))
        }
        None => Ok(json!({
            "scorable": false,
            "passes": null,
            "notes": "Artifact un-scorable (audio, missing ffmpeg for video, or eval parse failure)",
            "prompt_path": prompt_path.display().to_string(),
            "media_path": media_path.display().to_string(),
        })),
    }
}

fn default_eval_for_type() -> crate::schema::EvalSection {
    use crate::schema::{EvalCriterion, EvalSection};
    let mut criteria = HashMap::new();
    criteria.insert(
        "relevance".into(),
        EvalCriterion {
            weight: Some(3.0),
            scale: None,
            description: Some("Matches the generation brief".into()),
            fail_signals: vec![],
        },
    );
    criteria.insert(
        "quality".into(),
        EvalCriterion {
            weight: Some(2.0),
            scale: None,
            description: Some("Overall technical and aesthetic quality".into()),
            fail_signals: vec![],
        },
    );
    EvalSection {
        pass_threshold: Some(0.7),
        max_attempts: None,
        required_pass: vec!["relevance".into()],
        criteria,
        reject_if: vec![],
        mode: None,
        visual: None,
    }
}

fn find_sibling_prompt(media: &Path) -> Option<PathBuf> {
    let parent = media.parent()?;
    let stem = media.file_stem()?.to_str()?;
    // sample-hero.png → sample-hero.media.prompt
    let candidate = parent.join(format!("{stem}.media.prompt"));
    if candidate.is_file() {
        return Some(candidate);
    }
    // stem may include .genai etc — strip known suffixes
    if let Some(base) = stem.split('.').next() {
        let c2 = parent.join(format!("{base}.media.prompt"));
        if c2.is_file() {
            return Some(c2);
        }
    }
    // any .media.prompt in dir with matching stem prefix
    let rd = std::fs::read_dir(parent).ok()?;
    for ent in rd.flatten() {
        let p = ent.path();
        let name = p.file_name()?.to_str()?;
        if name.ends_with(".media.prompt") && name.starts_with(stem) {
            return Some(p);
        }
    }
    None
}

#[derive(Deserialize)]
struct GeneratePromptsBody {
    /// Asset type key: image, video, music, voice, diagram, html, svg, component, ...
    #[serde(rename = "type")]
    type_key: String,
    #[serde(default = "default_count")]
    count: usize,
    /// Optional creative brief / focus for the generated prompts
    brief: Option<String>,
    /// FIM / format channel slug (e.g. paper_js, lilypond) → sets text_format
    text_format: Option<String>,
    /// Optional folder under workspace/prompts (e.g. fim/paper_js)
    out_subdir: Option<String>,
}

fn default_count() -> usize {
    1
}

#[derive(Deserialize)]
struct PromptsListQuery {
    /// Generator slug (paper_js, lilypond, image, …)
    slug: String,
    /// Optional node id (fim:paper_js, kind:image)
    id: Option<String>,
}

/// List demo + workspace prompts for a generator so the UI can refresh after scaffold.
async fn api_prompts_list(
    State(st): State<AppState>,
    Query(q): Query<PromptsListQuery>,
) -> Result<Json<serde_json::Value>, ApiError> {
    let slug = q.slug.trim();
    if slug.is_empty() {
        return Err(ApiError::bad("slug required".into()));
    }

    let mut paths: Vec<PathBuf> = Vec::new();

    // Persistent index first (survives restarts)
    let idx = ExamplesIndex::load(&st.inner.cfg.workspace_dir);
    for p in idx.paths_for_slug(&st.inner.cfg.workspace_dir, slug) {
        paths.push(p);
    }
    if let Some(ref id) = q.id {
        for p in idx.paths_for_slug(&st.inner.cfg.workspace_dir, id) {
            paths.push(p);
        }
    }

    // Workspace: prompts/**/slug* and prompts/fim/slug/
    let ws_prompts = st.inner.cfg.workspace_dir.join("prompts");
    collect_prompts_matching(&ws_prompts, slug, &mut paths);

    // Demos linked via registry
    if let Some(entry) = st.inner.providers.providers.iter().find(|p| {
        p.slug == slug || q.id.as_deref() == Some(p.id.as_str())
    }) {
        for p in &entry.demo_paths {
            paths.push(PathBuf::from(p));
        }
    }

    // Demos by type folder name
    let demo_type_dir = st.inner.cfg.demos_dir.join(slug);
    if demo_type_dir.is_dir() {
        collect_prompts_matching(&demo_type_dir, slug, &mut paths);
    }
    // Also scan demos for matching stem
    collect_prompts_matching(&st.inner.cfg.demos_dir, slug, &mut paths);

    // Dedup
    paths.sort();
    paths.dedup();

    let mut items = Vec::new();
    for path in paths {
        if !path.is_file() {
            continue;
        }
        let media_root = media_root_for(&path, &st.inner.cfg);
        let source = if path.starts_with(&st.inner.cfg.workspace_dir) {
            "workspace"
        } else {
            "demos"
        };
        match load_detail(&path, &media_root, source) {
            Ok(d) => {
                items.push(json!({
                    "id": d.summary.id,
                    "path": d.summary.path,
                    "rel_path": d.summary.rel_path,
                    "source": source,
                    "prompt_preview": d.summary.prompt_preview,
                    "has_eval": d.summary.has_eval,
                    "outputs": d.summary.outputs,
                    "type_key": d.summary.type_key,
                }));
            }
            Err(_) => {
                items.push(json!({
                    "id": path.file_stem().and_then(|s| s.to_str()).unwrap_or("prompt"),
                    "path": path.display().to_string(),
                    "source": source,
                    "prompt_preview": "",
                    "has_eval": false,
                    "outputs": [],
                }));
            }
        }
    }

    Ok(Json(json!({ "slug": slug, "prompts": items })))
}

fn collect_prompts_matching(dir: &Path, slug: &str, out: &mut Vec<PathBuf>) {
    if !dir.is_dir() {
        return;
    }
    let slug_l = slug.to_lowercase();
    let Ok(rd) = std::fs::read_dir(dir) else {
        return;
    };
    for ent in rd.flatten() {
        let p = ent.path();
        if p.is_dir() {
            let name = p
                .file_name()
                .and_then(|n| n.to_str())
                .unwrap_or("")
                .to_lowercase();
            // Recurse into matching or generic folders
            if name == slug_l
                || name.contains(&slug_l)
                || name == "fim"
                || name == "workspace"
                || dir.ends_with("prompts")
                || dir.ends_with("demos")
            {
                collect_prompts_matching(&p, slug, out);
            }
        } else if p
            .file_name()
            .and_then(|n| n.to_str())
            .map(|n| n.ends_with(".media.prompt"))
            .unwrap_or(false)
        {
            let name = p
                .file_name()
                .and_then(|n| n.to_str())
                .unwrap_or("")
                .to_lowercase();
            let parent = p
                .parent()
                .and_then(|x| x.file_name())
                .and_then(|n| n.to_str())
                .unwrap_or("")
                .to_lowercase();
            if name.contains(&slug_l) || parent == slug_l || parent.contains(&slug_l) {
                out.push(p);
            }
        }
    }
}

async fn api_generate_prompts(
    State(st): State<AppState>,
    Json(body): Json<GeneratePromptsBody>,
) -> Result<Json<Job>, ApiError> {
    let count = body.count.clamp(1, 5);
    let label = body
        .text_format
        .clone()
        .unwrap_or_else(|| body.type_key.clone());
    let job = enqueue_job(
        &st,
        "generate_prompts",
        None,
        format!("Synthesize {count} {label} test prompt(s)"),
    )
    .await;
    let st2 = st.clone();
    let job_id = job.id.clone();
    tokio::spawn(async move {
        set_job_running(&st2, &job_id).await;
        let result = run_synthesize_prompts(
            &st2,
            &body.type_key,
            count,
            body.brief.as_deref(),
            body.text_format.as_deref(),
            body.out_subdir.as_deref(),
        )
        .await;
        finish_job(&st2, &job_id, result).await;
    });
    Ok(Json(job))
}

async fn run_synthesize_prompts(
    st: &AppState,
    type_key: &str,
    count: usize,
    brief: Option<&str>,
    text_format: Option<&str>,
    out_subdir: Option<&str>,
) -> Result<serde_json::Value, String> {
    // Prefer lab settings (default: Groq openai/gpt-oss-120b); fall back to prepper env.
    let (base_url, model, api_key) = {
        let settings = st.inner.settings.lock().await;
        let llm = &settings.llm;
        let key = llm.effective_api_key();
        if key.is_some() || !settings::provider_defaults(&llm.provider).needs_api_key {
            (
                llm.effective_base_url(),
                llm.effective_model(),
                key.unwrap_or_else(|| "none".into()),
            )
        } else if let Some(prepper) = PromptPrepper::resolve(None, None, st.inner.cfg.verbose) {
            (prepper.base_url, prepper.model, prepper.api_key)
        } else {
            return Err(
                "No LLM for prompt synthesis — open Settings and configure Groq (openai/gpt-oss-120b) or set GROQ_API_KEY"
                    .into(),
            );
        }
    };

    let format_hint = text_format.unwrap_or("");
    let examples = load_type_examples(
        &st.inner.cfg.demos_dir,
        if format_hint.is_empty() {
            type_key
        } else {
            format_hint
        },
        2,
    );
    let text_format_rule = if format_hint.is_empty() {
        String::new()
    } else {
        format!(
            "- MUST set output.text_format: \"{format_hint}\" and use a suitable output format extension\n\
             - prompt.system should instruct: output ONLY valid {format_hint} (no markdown fences)\n\
             - type should be one of: component, html, diagram, document (pick best for {format_hint})\n"
        )
    };
    let system = format!(
        "You write .media.prompt YAML test fixtures for the Noizu media-tool.\n\
         Schema version must be \"0.4\". Output ONLY a JSON array of objects:\n\
         [{{\"filename\": \"descriptive-slug.media.prompt\", \"yaml\": \"...full yaml string...\"}}, ...]\n\
         CRITICAL YAML shape for output.formats (every entry MUST be a map with key format):\n\
         output:\n\
           formats:\n\
             - format: js\n\
         NEVER write bare strings like `- js` or `formats: [js]`.\n\
         Rules:\n\
         - Base type key context: {type_key}\n\
         {text_format_rule}\
         - Include quality: medium\n\
         - Do NOT pin service: — prefer quality so the tool auto-selects providers\n\
         - prompt.text must be a concrete creative brief (not a meta placeholder)\n\
         - Include eval with pass_threshold: 0.7 and 2-4 criteria maps with weight + description\n\
         - Unique id fields (kebab-case)\n\
         - No markdown fences in the JSON response"
    );
    let user = format!(
        "Generate {count} diverse test prompt file(s) for `{}`.\n\
         Focus: {}\n\n\
         Example snippets from existing demos:\n{}\n",
        if format_hint.is_empty() {
            type_key
        } else {
            format_hint
        },
        brief.unwrap_or("general coverage of common use cases"),
        examples
    );

    let url = if base_url.ends_with("/chat/completions") {
        base_url.clone()
    } else {
        format!("{}/chat/completions", base_url.trim_end_matches('/'))
    };

    let body = json!({
        "model": model,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user}
        ],
        "temperature": 0.7,
        "max_tokens": 8192,
    });

    if st.inner.cfg.verbose {
        ui::verbose(&format!("Example-prompt LLM POST {url} model={model}"));
    }

    let client = reqwest::Client::new();
    let mut req = client
        .post(&url)
        .header("Content-Type", "application/json")
        .json(&body)
        .timeout(Duration::from_secs(180));
    if api_key != "none" && !api_key.is_empty() {
        req = req.header("Authorization", format!("Bearer {api_key}"));
    }
    let resp = req.send().await.map_err(|e| e.to_string())?;

    if !resp.status().is_success() {
        return Err(format!("LLM HTTP {}", resp.status()));
    }
    let val: serde_json::Value = resp.json().await.map_err(|e| e.to_string())?;
    let raw = val["choices"][0]["message"]["content"]
        .as_str()
        .unwrap_or("")
        .trim()
        .to_string();
    let cleaned = strip_json_fences(&raw);
    let items: Vec<serde_json::Value> =
        serde_json::from_str(&cleaned).map_err(|e| format!("JSON parse: {e}; raw={}", &cleaned[..cleaned.len().min(200)]))?;

    let sub = out_subdir
        .map(|s| s.trim().trim_start_matches('/').to_string())
        .filter(|s| !s.is_empty() && !s.contains(".."))
        .unwrap_or_else(|| {
            if let Some(tf) = text_format.filter(|s| !s.is_empty()) {
                format!("fim/{}", sanitize_type_dir(tf))
            } else {
                sanitize_type_dir(type_key)
            }
        });
    let out_dir = st.inner.cfg.workspace_dir.join("prompts").join(&sub);
    std::fs::create_dir_all(&out_dir).map_err(|e| e.to_string())?;

    let mut written = Vec::new();
    let mut last_err = String::new();
    for item in items.into_iter().take(count.max(1) + 2) {
        if written.len() >= count {
            break;
        }
        let mut filename = item["filename"]
            .as_str()
            .unwrap_or("generated.media.prompt")
            .replace("..", "_");
        if !filename.ends_with(".media.prompt") {
            filename = format!(
                "{}.media.prompt",
                filename.trim_end_matches(".yaml").trim_end_matches(".yml")
            );
        }
        let raw_yaml = item["yaml"].as_str().unwrap_or("").trim().to_string();
        if raw_yaml.is_empty() {
            // Sometimes models put the whole prompt at the top level
            if let Some(y) = item.as_str() {
                if y.contains("prompt:") {
                    let repaired = repair_media_prompt_yaml(y, type_key, text_format);
                    if let Ok(path) = write_validated_prompt(&out_dir, &filename, &repaired) {
                        written.push(path);
                    }
                }
            }
            continue;
        }
        let repaired = repair_media_prompt_yaml(&raw_yaml, type_key, text_format);
        match write_validated_prompt(&out_dir, &filename, &repaired) {
            Ok(path) => written.push(path),
            Err(e) => {
                last_err = format!("{filename}: {e}");
                // try once more with a known-good skeleton merge
                let fallback = merge_with_skeleton(&repaired, type_key, text_format);
                if let Ok(path) = write_validated_prompt(
                    &out_dir,
                    &filename.replace(".media.prompt", "-fixed.media.prompt"),
                    &fallback,
                ) {
                    written.push(path);
                }
            }
        }
    }

    if written.is_empty() {
        return Err(if last_err.is_empty() {
            "LLM returned no writable prompts".into()
        } else {
            format!("LLM YAML invalid — {last_err}")
        });
    }

    let index_slug = text_format
        .filter(|s| !s.is_empty())
        .unwrap_or(type_key);
    for path in &written {
        register_written_prompt(
            &st.inner.cfg.workspace_dir,
            index_slug,
            path,
            None,
        );
    }

    Ok(json!({
        "type": type_key,
        "text_format": text_format,
        "written": written,
        "path": written.first(),
        "label": type_label(type_key),
        "workspace": st.inner.cfg.workspace_dir.display().to_string(),
        "index": ExamplesIndex::path(&st.inner.cfg.workspace_dir).display().to_string(),
    }))
}

fn write_validated_prompt(out_dir: &Path, filename: &str, yaml: &str) -> Result<String, String> {
    let dest = out_dir.join(filename);
    std::fs::write(&dest, yaml).map_err(|e| e.to_string())?;
    parse_prompt_file(&dest).map_err(|e| {
        let _ = std::fs::remove_file(&dest);
        e.to_string()
    })?;
    Ok(dest.display().to_string())
}

fn register_written_prompt(workspace: &Path, slug: &str, path_str: &str, generator_id: Option<&str>) {
    let path = PathBuf::from(path_str);
    let id = path
        .file_name()
        .and_then(|n| n.to_str())
        .map(|n| n.trim_end_matches(".media.prompt").to_string());
    persist::register_prompt(
        workspace,
        slug,
        &path,
        id,
        generator_id.map(|s| s.to_string()),
    );
}

/// Normalize common LLM YAML mistakes so fixtures parse with schema.rs.
fn repair_media_prompt_yaml(yaml: &str, type_key: &str, text_format: Option<&str>) -> String {
    let mut doc: serde_yaml::Value = match serde_yaml::from_str(yaml) {
        Ok(v) => v,
        Err(_) => {
            return merge_with_skeleton(yaml, type_key, text_format);
        }
    };

    let map = match doc.as_mapping_mut() {
        Some(m) => m,
        None => return merge_with_skeleton(yaml, type_key, text_format),
    };

    // schema / type / quality defaults
    ensure_str_key(map, "schema", "0.4");
    if !map.contains_key(serde_yaml::Value::String("type".into())) {
        let t = if text_format.is_some() {
            // channel generators → chat asset type
            match type_key {
                "html" | "game" => "html",
                "diagram" => "diagram",
                "document" => "document",
                "image" | "svg" => "image",
                _ => "component",
            }
        } else {
            type_key
        };
        map.insert(
            serde_yaml::Value::String("type".into()),
            serde_yaml::Value::String(t.into()),
        );
    }
    ensure_str_key(map, "quality", "medium");

    // Fix output.formats
    let default_ext = text_format
        .map(|tf| default_ext_for_channel(tf))
        .unwrap_or_else(|| default_ext_for_type(type_key));

    let output_key = serde_yaml::Value::String("output".into());
    if !map.contains_key(&output_key) {
        map.insert(output_key.clone(), serde_yaml::Value::Mapping(Default::default()));
    }
    if let Some(serde_yaml::Value::Mapping(out)) = map.get_mut(&output_key) {
        if let Some(tf) = text_format.filter(|s| !s.is_empty()) {
            out.insert(
                serde_yaml::Value::String("text_format".into()),
                serde_yaml::Value::String(tf.into()),
            );
        }
        let formats_key = serde_yaml::Value::String("formats".into());
        let fixed = normalize_formats(out.get(&formats_key), default_ext);
        out.insert(formats_key, fixed);
    }

    // Ensure prompt.text exists
    let prompt_key = serde_yaml::Value::String("prompt".into());
    if let Some(serde_yaml::Value::Mapping(p)) = map.get_mut(&prompt_key) {
        let text_key = serde_yaml::Value::String("text".into());
        let empty = p
            .get(&text_key)
            .and_then(|v| v.as_str())
            .map(|s| s.trim().is_empty())
            .unwrap_or(true);
        if empty {
            p.insert(
                text_key,
                serde_yaml::Value::String(format!(
                    "Create a polished, self-contained {} example that demonstrates core features.",
                    text_format.unwrap_or(type_key)
                )),
            );
        }
        // system for channels
        if let Some(tf) = text_format.filter(|s| !s.is_empty()) {
            let sys_key = serde_yaml::Value::String("system".into());
            if !p.contains_key(&sys_key) {
                p.insert(
                    sys_key,
                    serde_yaml::Value::String(format!(
                        "You generate {tf} artifacts. Output ONLY the raw artifact — no markdown fences, no commentary."
                    )),
                );
            }
        }
    } else {
        let mut p = serde_yaml::Mapping::new();
        p.insert(
            serde_yaml::Value::String("text".into()),
            serde_yaml::Value::String(format!(
                "Create a polished, self-contained {} example.",
                text_format.unwrap_or(type_key)
            )),
        );
        if let Some(tf) = text_format {
            p.insert(
                serde_yaml::Value::String("system".into()),
                serde_yaml::Value::String(format!(
                    "You generate {tf} artifacts. Output ONLY the raw artifact — no markdown fences."
                )),
            );
        }
        map.insert(prompt_key, serde_yaml::Value::Mapping(p));
    }

    // Strip accidental service pin from lab fixtures (auto-select)
    map.remove(serde_yaml::Value::String("service".into()));

    serde_yaml::to_string(&doc).unwrap_or_else(|_| merge_with_skeleton(yaml, type_key, text_format))
}

fn ensure_str_key(map: &mut serde_yaml::Mapping, key: &str, default: &str) {
    let k = serde_yaml::Value::String(key.into());
    if !map.contains_key(&k) {
        map.insert(k, serde_yaml::Value::String(default.into()));
    }
}

fn normalize_formats(existing: Option<&serde_yaml::Value>, default_ext: &str) -> serde_yaml::Value {
    let mut entries: Vec<serde_yaml::Value> = Vec::new();
    match existing {
        Some(serde_yaml::Value::Sequence(seq)) => {
            for item in seq {
                match item {
                    serde_yaml::Value::String(s) => {
                        let mut m = serde_yaml::Mapping::new();
                        m.insert(
                            serde_yaml::Value::String("format".into()),
                            serde_yaml::Value::String(s.clone()),
                        );
                        entries.push(serde_yaml::Value::Mapping(m));
                    }
                    serde_yaml::Value::Mapping(m) => {
                        let mut m = m.clone();
                        let fk = serde_yaml::Value::String("format".into());
                        if !m.contains_key(&fk) {
                            // common mistake: { js: true } or { ext: "js" }
                            let guess = m
                                .get(serde_yaml::Value::String("ext".into()))
                                .or_else(|| m.get(serde_yaml::Value::String("type".into())))
                                .and_then(|v| v.as_str())
                                .unwrap_or(default_ext);
                            m.insert(fk, serde_yaml::Value::String(guess.into()));
                        }
                        entries.push(serde_yaml::Value::Mapping(m));
                    }
                    _ => {}
                }
            }
        }
        Some(serde_yaml::Value::String(s)) => {
            let mut m = serde_yaml::Mapping::new();
            m.insert(
                serde_yaml::Value::String("format".into()),
                serde_yaml::Value::String(s.clone()),
            );
            entries.push(serde_yaml::Value::Mapping(m));
        }
        _ => {}
    }
    if entries.is_empty() {
        let mut m = serde_yaml::Mapping::new();
        m.insert(
            serde_yaml::Value::String("format".into()),
            serde_yaml::Value::String(default_ext.into()),
        );
        entries.push(serde_yaml::Value::Mapping(m));
    }
    serde_yaml::Value::Sequence(entries)
}

fn default_ext_for_channel(tf: &str) -> &'static str {
    let t = tf.to_lowercase();
    if t.contains("mermaid") {
        "mmd"
    } else if t.contains("plantuml") || t == "puml" {
        "puml"
    } else if t.contains("graphviz") || t == "dot" {
        "dot"
    } else if t == "html" || t.contains("html") {
        "html"
    } else if t.contains("svg") {
        "svg"
    } else if t.contains("react") || t == "tsx" {
        "tsx"
    } else if t.contains("paper") || t.ends_with("_js") || t.contains("js") {
        "js"
    } else if t.contains("lily") || t == "ly" {
        "ly"
    } else if t == "abc" || t.contains("abc") {
        "abc"
    } else {
        "md"
    }
}

fn default_ext_for_type(type_key: &str) -> &'static str {
    match type_key {
        "image" | "svg" => "png",
        "video" => "mp4",
        "music" | "voice" | "audio" | "sfx" => "mp3",
        "html" | "game" | "style-guide" => "html",
        "react-page" | "component" => "tsx",
        "diagram" => "mmd",
        _ => "md",
    }
}

fn merge_with_skeleton(yaml: &str, type_key: &str, text_format: Option<&str>) -> String {
    let ext = text_format
        .map(default_ext_for_channel)
        .unwrap_or_else(|| default_ext_for_type(type_key));
    let t = if text_format.is_some() {
        match type_key {
            "html" | "game" => "html",
            "diagram" => "diagram",
            "document" => "document",
            "image" | "svg" => "image",
            _ => "component",
        }
    } else {
        type_key
    };
    let tf_line = text_format
        .map(|tf| format!("  text_format: {tf}\n"))
        .unwrap_or_default();
    let sys = text_format
        .map(|tf| {
            format!(
                "  system: |\n    You generate {tf} artifacts. Output ONLY the raw artifact. No markdown fences.\n"
            )
        })
        .unwrap_or_default();
    // Prefer LLM text if we can snatch it
    let text = yaml
        .lines()
        .find(|l| l.trim_start().starts_with("text:"))
        .map(|l| l.trim().trim_start_matches("text:").trim().trim_matches('"'))
        .filter(|s| !s.is_empty() && !s.contains("test fixture"))
        .unwrap_or("Create a polished, self-contained demonstration of the core features.");

    format!(
        r#"schema: "0.4"
id: lab-{slug}-001
type: {t}
quality: medium

prompt:
{sys}  text: "{text}"

output:
{tf_line}  formats:
    - format: {ext}

eval:
  pass_threshold: 0.7
  criteria:
    relevance:
      weight: 3
      description: "Matches the brief for {slug}"
    completeness:
      weight: 2
      description: "Self-contained valid output"

tags: [lab, generated, {slug}]
"#,
        slug = text_format.unwrap_or(type_key).replace('_', "-"),
        t = t,
        sys = sys,
        text = text.replace('"', "'"),
        tf_line = tf_line,
        ext = ext,
    )
}

fn load_type_examples(demos: &Path, type_key: &str, limit: usize) -> String {
    let mut out = String::new();
    let mut n = 0usize;
    let _ = visit_prompts(demos, &mut |path| {
        if n >= limit {
            return;
        }
        let rel = path.display().to_string().to_lowercase();
        let match_type = rel.contains(&format!("/{type_key}/"))
            || rel.contains(&format!("\\{type_key}\\"))
            || (type_key == "svg" && rel.contains("/svg/"))
            || (type_key == "game" && rel.contains("/game/"));
        if !match_type {
            return;
        }
        if let Ok(text) = std::fs::read_to_string(path) {
            let snippet: String = text.chars().take(800).collect();
            out.push_str(&format!("--- {} ---\n{}\n\n", path.display(), snippet));
            n += 1;
        }
    });
    if out.is_empty() {
        out.push_str("(no local demos for this type — invent reasonable fixtures)\n");
    }
    out
}

fn visit_prompts(dir: &Path, f: &mut dyn FnMut(&Path)) {
    let Ok(rd) = std::fs::read_dir(dir) else {
        return;
    };
    for ent in rd.flatten() {
        let p = ent.path();
        if p.is_dir() {
            visit_prompts(&p, f);
        } else if p
            .file_name()
            .and_then(|n| n.to_str())
            .map(|n| n.ends_with(".media.prompt"))
            .unwrap_or(false)
        {
            f(&p);
        }
    }
}

fn sanitize_type_dir(type_key: &str) -> String {
    type_key
        .chars()
        .map(|c| {
            if c.is_ascii_alphanumeric() || c == '-' || c == '_' {
                c
            } else {
                '_'
            }
        })
        .collect()
}

fn strip_json_fences(s: &str) -> String {
    let s = s.trim();
    // Drop reasoning blocks if present
    let s = if let Some(i) = s.rfind("</think>") {
        s[i + "</think>".len()..].trim()
    } else {
        s
    };
    let s = if s.starts_with("```") {
        let after = s.find('\n').map(|i| &s[i + 1..]).unwrap_or(s);
        after.trim_end_matches("```").trim()
    } else {
        s
    };
    // Extract first JSON array if model added prose
    if !s.starts_with('[') {
        if let Some(start) = s.find('[') {
            if let Some(end) = s.rfind(']') {
                if end > start {
                    return s[start..=end].to_string();
                }
            }
        }
    }
    s.to_string()
}

#[derive(Deserialize)]
struct SavePromptBody {
    /// Relative path under workspace/prompts/ or absolute under workspace
    path: Option<String>,
    /// Type folder when creating new
    #[serde(rename = "type")]
    type_key: Option<String>,
    filename: Option<String>,
    yaml: String,
}

async fn api_save_prompt(
    State(st): State<AppState>,
    Json(body): Json<SavePromptBody>,
) -> Result<Json<serde_json::Value>, ApiError> {
    let dest = if let Some(ref p) = body.path {
        let pb = PathBuf::from(p);
        if pb.is_absolute() {
            pb
        } else {
            st.inner.cfg.workspace_dir.join("prompts").join(p)
        }
    } else {
        let tk = body.type_key.as_deref().unwrap_or("misc");
        let name = body
            .filename
            .as_deref()
            .unwrap_or("untitled.media.prompt");
        st.inner
            .cfg
            .workspace_dir
            .join("prompts")
            .join(sanitize_type_dir(tk))
            .join(name)
    };

    // Safety: only write under workspace
    let ws = st
        .inner
        .cfg
        .workspace_dir
        .canonicalize()
        .unwrap_or_else(|_| st.inner.cfg.workspace_dir.clone());
    if let Some(parent) = dest.parent() {
        std::fs::create_dir_all(parent).map_err(|e| ApiError::bad(e.to_string()))?;
    }
    let canon_parent = dest
        .parent()
        .and_then(|p| p.canonicalize().ok())
        .unwrap_or_else(|| dest.clone());
    if !canon_parent.starts_with(&ws) && !dest.starts_with(&st.inner.cfg.workspace_dir) {
        return Err(ApiError::bad(
            "refusing to write outside workspace".into(),
        ));
    }

    // Validate YAML parses
    let tmp = st.inner.cfg.workspace_dir.join(".validate-tmp.media.prompt");
    std::fs::write(&tmp, &body.yaml).map_err(|e| ApiError::bad(e.to_string()))?;
    if let Err(e) = parse_prompt_file(&tmp) {
        let _ = std::fs::remove_file(&tmp);
        return Err(ApiError::bad(format!("invalid .media.prompt: {e}")));
    }
    let _ = std::fs::remove_file(&tmp);

    std::fs::write(&dest, &body.yaml).map_err(|e| ApiError::bad(e.to_string()))?;

    let path_str = dest.display().to_string();
    let slug = body
        .type_key
        .as_deref()
        .filter(|s| !s.is_empty())
        .map(|s| sanitize_type_dir(s))
        .unwrap_or_else(|| persist::infer_slug_from_path(&st.inner.cfg.workspace_dir, &dest));
    register_written_prompt(&st.inner.cfg.workspace_dir, &slug, &path_str, None);

    Ok(Json(json!({
        "ok": true,
        "path": path_str,
        "slug": slug,
        "index": ExamplesIndex::path(&st.inner.cfg.workspace_dir).display().to_string(),
    })))
}

async fn api_list_jobs(State(st): State<AppState>) -> Json<Vec<Job>> {
    let jobs = st.inner.jobs.lock().await;
    let mut list: Vec<Job> = jobs.values().cloned().collect();
    list.sort_by(|a, b| b.started_at.cmp(&a.started_at));
    Json(list)
}

async fn api_get_job(
    State(st): State<AppState>,
    axum::extract::Path(id): axum::extract::Path<String>,
) -> Result<Json<Job>, ApiError> {
    let jobs = st.inner.jobs.lock().await;
    jobs.get(&id)
        .cloned()
        .map(Json)
        .ok_or_else(|| ApiError::not_found(format!("job {id}")))
}

// ---------------------------------------------------------------------------
// Job helpers
// ---------------------------------------------------------------------------

async fn enqueue_job(
    st: &AppState,
    kind: &str,
    prompt_path: Option<String>,
    message: String,
) -> Job {
    let id = Uuid::new_v4().to_string();
    let job = Job {
        id: id.clone(),
        kind: kind.to_string(),
        status: JobStatus::Queued,
        prompt_path,
        message,
        started_at: chrono::Utc::now().to_rfc3339(),
        finished_at: None,
        result: None,
    };
    st.inner.jobs.lock().await.insert(id, job.clone());
    job
}

async fn set_job_running(st: &AppState, id: &str) {
    let mut jobs = st.inner.jobs.lock().await;
    if let Some(j) = jobs.get_mut(id) {
        j.status = JobStatus::Running;
        j.message = format!("Running {}…", j.kind);
    }
}

async fn finish_job(st: &AppState, id: &str, result: Result<serde_json::Value, String>) {
    let mut jobs = st.inner.jobs.lock().await;
    if let Some(j) = jobs.get_mut(id) {
        j.finished_at = Some(chrono::Utc::now().to_rfc3339());
        match result {
            Ok(v) => {
                j.status = JobStatus::Succeeded;
                j.message = "Done".into();
                j.result = Some(v);
            }
            Err(e) => {
                j.status = JobStatus::Failed;
                j.message = e;
                j.result = None;
            }
        }
    }
}

fn media_root_for(path: &Path, cfg: &LabConfig) -> PathBuf {
    if path.starts_with(&cfg.workspace_dir) {
        cfg.workspace_dir.clone()
    } else {
        cfg.demos_dir.clone()
    }
}

// ---------------------------------------------------------------------------
// Errors
// ---------------------------------------------------------------------------

struct ApiError {
    status: StatusCode,
    message: String,
}

impl ApiError {
    fn bad(msg: String) -> Self {
        Self {
            status: StatusCode::BAD_REQUEST,
            message: msg,
        }
    }
    fn not_found(msg: String) -> Self {
        Self {
            status: StatusCode::NOT_FOUND,
            message: msg,
        }
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let body = json!({ "error": self.message });
        (self.status, Json(body)).into_response()
    }
}
