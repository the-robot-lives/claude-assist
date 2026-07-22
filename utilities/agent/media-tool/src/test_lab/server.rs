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
use super::registry::{self, ProviderCatalog, ProviderEntry};
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

    let state = AppState {
        inner: Arc::new(AppInner {
            cfg: cfg.clone(),
            jobs: Mutex::new(HashMap::new()),
            providers,
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
        .route("/api/prompt/save", post(api_save_prompt))
        .layer(CorsLayer::permissive())
        .with_state(state);

    let addr = format!("127.0.0.1:{}", cfg.port);
    let listener = tokio::net::TcpListener::bind(&addr).await?;
    let url = format!("http://{addr}");
    ui::ok(&format!("Test lab listening on {url}"));
    eprintln!("  Graph lab: expand sections → pick a generator → scaffold / generate / view.");
    eprintln!("  Demos:     {}", cfg.demos_dir.display());
    eprintln!("  Workspace: {}", cfg.workspace_dir.display());
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
    Json(json!({
        "ok": true,
        "demos": st.inner.cfg.demos_dir.display().to_string(),
        "workspace": st.inner.cfg.workspace_dir.display().to_string(),
        "providers_total": st.inner.providers.total,
        "providers_implemented": st.inner.providers.implemented,
        "providers_stub": st.inner.providers.stub,
        "providers_fim_only": st.inner.providers.fim_only,
        "categories": st.inner.providers.categories.len(),
    }))
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

    Ok(Json(json!({
        "ok": true,
        "path": dest.display().to_string(),
        "provider_id": entry.id,
        "yaml": yaml,
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
    /// Asset type key: image, video, music, voice, diagram, html, svg, ...
    #[serde(rename = "type")]
    type_key: String,
    #[serde(default = "default_count")]
    count: usize,
    /// Optional creative brief / focus for the generated prompts
    brief: Option<String>,
}

fn default_count() -> usize {
    1
}

async fn api_generate_prompts(
    State(st): State<AppState>,
    Json(body): Json<GeneratePromptsBody>,
) -> Result<Json<Job>, ApiError> {
    let count = body.count.clamp(1, 5);
    let job = enqueue_job(
        &st,
        "generate_prompts",
        None,
        format!("Synthesize {count} {} test prompt(s)", body.type_key),
    )
    .await;
    let st2 = st.clone();
    let job_id = job.id.clone();
    tokio::spawn(async move {
        set_job_running(&st2, &job_id).await;
        let result = run_synthesize_prompts(&st2, &body.type_key, count, body.brief.as_deref()).await;
        finish_job(&st2, &job_id, result).await;
    });
    Ok(Json(job))
}

async fn run_synthesize_prompts(
    st: &AppState,
    type_key: &str,
    count: usize,
    brief: Option<&str>,
) -> Result<serde_json::Value, String> {
    let prepper = PromptPrepper::resolve(None, None, st.inner.cfg.verbose)
        .ok_or_else(|| {
            "No LLM for prompt synthesis (set GROQ_API_KEY or MEDIA_PREP_BASE_URL)".to_string()
        })?;

    // Reuse the prepper HTTP path with a custom instruction by calling the same
    // chat endpoint via a one-off request (PromptPrepper only exposes prepare/refine).
    // We'll use a lightweight internal call:
    let examples = load_type_examples(&st.inner.cfg.demos_dir, type_key, 2);
    let system = format!(
        "You write .media.prompt YAML test fixtures for the Noizu media-tool.\n\
         Schema version must be \"0.4\". Output ONLY a JSON array of objects:\n\
         [{{\"filename\": \"descriptive-slug.media.prompt\", \"yaml\": \"...full yaml...\"}}, ...]\n\
         Rules:\n\
         - type: {type_key} (use voice not audio; svg may use type image + text_format svg + format svg)\n\
         - Include quality: medium\n\
         - Include a realistic prompt.text and output.formats\n\
         - Include a simple eval block with pass_threshold 0.7 and 2-4 criteria\n\
         - Unique id fields\n\
         - No markdown fences in the JSON response"
    );
    let user = format!(
        "Generate {count} diverse test prompt file(s) for media type `{type_key}`.\n\
         Focus: {}\n\n\
         Example snippets from existing demos:\n{}\n",
        brief.unwrap_or("general coverage of common use cases"),
        examples
    );

    let url = if prepper.base_url.ends_with("/chat/completions") {
        prepper.base_url.clone()
    } else {
        format!("{}/chat/completions", prepper.base_url)
    };

    let body = json!({
        "model": prepper.model,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user}
        ],
        "temperature": 0.7,
        "max_tokens": 4096,
    });

    let client = reqwest::Client::new();
    let resp = client
        .post(&url)
        .header("Authorization", format!("Bearer {}", prepper.api_key))
        .header("Content-Type", "application/json")
        .json(&body)
        .timeout(Duration::from_secs(120))
        .send()
        .await
        .map_err(|e| e.to_string())?;

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

    let out_dir = st
        .inner
        .cfg
        .workspace_dir
        .join("prompts")
        .join(sanitize_type_dir(type_key));
    std::fs::create_dir_all(&out_dir).map_err(|e| e.to_string())?;

    let mut written = Vec::new();
    for item in items.into_iter().take(count) {
        let filename = item["filename"]
            .as_str()
            .unwrap_or("generated.media.prompt")
            .replace("..", "_");
        let yaml = item["yaml"].as_str().unwrap_or("").trim();
        if yaml.is_empty() {
            continue;
        }
        let dest = out_dir.join(&filename);
        std::fs::write(&dest, yaml).map_err(|e| e.to_string())?;
        written.push(dest.display().to_string());
    }

    if written.is_empty() {
        return Err("LLM returned no writable prompts".into());
    }

    Ok(json!({
        "type": type_key,
        "written": written,
        "label": type_label(type_key),
    }))
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
    if s.starts_with("```") {
        let after = s.find('\n').map(|i| &s[i + 1..]).unwrap_or(s);
        return after.trim_end_matches("```").trim().to_string();
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
    Ok(Json(json!({
        "ok": true,
        "path": dest.display().to_string(),
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
