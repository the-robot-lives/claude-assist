use std::time::Duration;

use serde_json::json;

use crate::schema::{AssetType, AudioKind, PromptSection};
use crate::ui;

const GROQ_API_URL: &str = "https://api.groq.com/openai/v1/chat/completions";
const DEFAULT_PREP_MODEL: &str = "meta-llama/llama-4-scout-17b-16e-instruct";

// ---------------------------------------------------------------------------
// Prep channel — branches instruction rules by media kind / text format
// ---------------------------------------------------------------------------

/// Which prep/refine rule set to apply. Derived from asset type + text_format
/// (+ service for TTS detection on generic Audio).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PrepChannel {
    /// Raster image models (Imagen, etc.)
    RasterImage,
    /// SVG / vector via chat (type image + text_format svg, or format svg)
    Svg,
    /// Video generation models
    Video,
    /// Music generation (Suno)
    Music,
    /// TTS — speaking text must stay verbatim; prefer no LLM rewrite
    Voice,
    /// Chat: diagrams (mermaid/plantuml/graphviz/…)
    Diagram,
    /// Chat: HTML pages / style guides
    Html,
    /// Chat: React / TS / components
    Code,
    /// Chat: markdown / documents
    Document,
    /// Fallback when nothing more specific matches
    Generic,
}

/// Map asset type + audio kind + optional text_format (+ service) to a prep channel.
pub fn prep_channel(
    asset_type: AssetType,
    audio_kind: AudioKind,
    text_format: Option<&str>,
    service: &str,
) -> PrepChannel {
    let tf = text_format
        .map(|s| s.trim().to_lowercase())
        .unwrap_or_default();
    let svc = service.trim().to_lowercase();

    // Text-format overrides (including image+svg chat path)
    if matches!(tf.as_str(), "svg") {
        return PrepChannel::Svg;
    }
    if matches!(
        tf.as_str(),
        "mermaid" | "mmd" | "plantuml" | "puml" | "graphviz" | "dot" | "drawio" | "wavedrom"
    ) {
        return PrepChannel::Diagram;
    }
    if matches!(tf.as_str(), "html" | "htm") {
        return PrepChannel::Html;
    }
    if matches!(
        tf.as_str(),
        "tsx" | "jsx" | "ts" | "js" | "react" | "react-page" | "component"
    ) {
        return PrepChannel::Code;
    }
    if matches!(tf.as_str(), "md" | "markdown" | "document") {
        return PrepChannel::Document;
    }

    // TTS services always voice channel
    if matches!(svc.as_str(), "openai-tts" | "elevenlabs" | "qwen-tts") {
        return PrepChannel::Voice;
    }
    if matches!(svc.as_str(), "suno") {
        return PrepChannel::Music;
    }

    match asset_type {
        AssetType::Image => PrepChannel::RasterImage,
        AssetType::Video => PrepChannel::Video,
        AssetType::Audio => match audio_kind {
            AudioKind::Music | AudioKind::Sfx => PrepChannel::Music,
            AudioKind::Voice => PrepChannel::Voice,
        },
        AssetType::Diagram => PrepChannel::Diagram,
        AssetType::Html | AssetType::StyleGuide => PrepChannel::Html,
        AssetType::Component | AssetType::ReactPage => PrepChannel::Code,
        AssetType::Document => PrepChannel::Document,
        AssetType::Unknown => PrepChannel::Generic,
    }
}

/// When false, callers should not send text through the prep LLM (verbatim path).
/// Voice/TTS must not be rewritten; only hard-truncate if a provider limit forces it.
pub fn allows_llm_prep(channel: PrepChannel) -> bool {
    !matches!(channel, PrepChannel::Voice)
}

/// Role preamble for the prep LLM (first sentence of the instruction).
pub fn prep_role_preamble(channel: PrepChannel) -> &'static str {
    match channel {
        PrepChannel::RasterImage => {
            "You are preparing a prompt for an AI image generator. The source is a detailed creative specification. Your job is to CLEAN it for the target provider — NOT to summarize or shorten it unless a length constraint requires it. The detailed descriptions, mood language, and specific visual directions are what make the prompt effective. Preserve them."
        }
        PrepChannel::Svg => {
            "You are preparing a brief for an SVG/vector graphic generator (chat model). Preserve exact colors (including hex codes), viewBox sizes, stroke widths, and geometric constraints. Do NOT convert the brief into a photographic image prompt."
        }
        PrepChannel::Video => {
            "You are preparing a prompt for an AI video generator. Lead with scene, action, and camera motion. Keep the prompt tight (typically 60–120 words) unless a longer limit is allowed."
        }
        PrepChannel::Music => {
            "You are preparing a prompt for an AI music generator. Lead with genre and mood, list instruments, and describe structure as emotional phases (not bar-by-bar timestamps)."
        }
        PrepChannel::Voice => {
            "You are preparing spoken text for a TTS engine. Return the speaking text VERBATIM — do not paraphrase, dramatize, or restructure. Only strip non-speech markup (bullets, markdown headers)."
        }
        PrepChannel::Diagram => {
            "You are preparing a brief for a diagram DSL generator (Mermaid/PlantUML/Graphviz/etc.). Preserve entity names, relationships, and ordered structure. Do NOT flatten lists into free prose that loses graph topology."
        }
        PrepChannel::Html => {
            "You are preparing a brief for an HTML/CSS/JS page generator. Preserve layout requirements, dimensions, fonts, interaction behavior, and feature checklists. Do NOT strip implementation details or convert everything to a visual-only prose description."
        }
        PrepChannel::Code => {
            "You are preparing a brief for a code/component generator (React/TS/JS). Preserve exports, props, framework constraints, and structural requirements. Keep bullet lists and API contracts intact."
        }
        PrepChannel::Document => {
            "You are preparing a brief for a document/markdown generator. Preserve section structure, headings, and factual requirements. Keep lists and tables when present."
        }
        PrepChannel::Generic => {
            "You are preparing a prompt for a media/code generator. Clean formatting artifacts but preserve descriptive and structural content needed for the target."
        }
    }
}

/// "WHAT TO CHANGE" / cleanup rules for the prep LLM.
pub fn prep_change_rules(channel: PrepChannel) -> &'static str {
    match channel {
        PrepChannel::RasterImage => {
            "WHAT TO CHANGE:\n\
- Merge any \"Art Direction\" / system context into the main prompt as a style preamble\n\
- Replace hex color codes with descriptive color names (e.g. #C0503A → warm muted red)\n\
- Remove pixel dimensions, percentage values, and CSS-like specs — describe relative sizes instead\n\
- Remove section headers, bullet formatting, and numbered lists — flow into natural prose paragraphs\n\
- Remove implementation/interaction instructions — describe the static visual appearance only\n\
- Remove font specifications — describe the feel instead\n\
- Keep ALL descriptive content: colors, materials, textures, spatial arrangement, mood, style references, named elements, quantities\n\
- Keep overall length similar unless a length constraint requires condensation\n\
- Negative prompt: minimal formatting cleanup only"
        }
        PrepChannel::Svg => {
            "WHAT TO CHANGE:\n\
- KEEP hex color codes (#00D4FF etc.) — SVG generators need exact brand colors\n\
- KEEP numeric viewBox / size constraints when specified (e.g. 0 0 200 200, stroke-width 2)\n\
- Preserve geometric and composition requirements as structured bullets if present\n\
- Remove markdown code fences and meta-instructions about how to call APIs\n\
- Do NOT rewrite into a photographic or raster-image style prompt\n\
- Do NOT invent new decorative elements beyond the brief\n\
- Negative prompt: keep exclusions that forbid text/photos/3D when present"
        }
        PrepChannel::Video => {
            "WHAT TO CHANGE:\n\
- Lead with scene + action + camera movement; put art style early\n\
- Prefer motion and temporal flow over static layout details\n\
- Replace hex codes with color names\n\
- Remove pixel dimensions and UI implementation details\n\
- Aim for concise cinematic language (≈60–120 words) unless length limit differs\n\
- Negative prompt: minimal cleanup only"
        }
        PrepChannel::Music => {
            "WHAT TO CHANGE:\n\
- Lead with genre and mood; list instruments and overall sound\n\
- Describe structure as phases (intro/build/climax/outro), not exact timestamps or bar numbers\n\
- Keep under ~200 words unless a limit says otherwise\n\
- Preserve negative/excluded styles\n\
- Do not invent lyrics unless the brief requests vocals"
        }
        PrepChannel::Voice => {
            "WHAT TO CHANGE:\n\
- Return speaking text VERBATIM\n\
- Only remove bullets, markdown headers, or stage directions that are not spoken\n\
- Do not rewrite tone into the text if style belongs in provider_options\n\
- Negative is usually empty for TTS"
        }
        PrepChannel::Diagram => {
            "WHAT TO CHANGE:\n\
- Preserve node/entity names and relationships exactly\n\
- Keep ordered lists of components and connections — do NOT collapse into unstructured prose\n\
- Remove requests for markdown fences or explanatory essays around the diagram\n\
- Do not invent extra subsystems not in the brief\n\
- Hex colors may be kept if the DSL supports them; otherwise descriptive colors are fine"
        }
        PrepChannel::Html => {
            "WHAT TO CHANGE:\n\
- KEEP layout dimensions, spacing, fonts, color values (including hex), and interaction behavior\n\
- KEEP feature checklists (tiers, FAQ, CTAs) as structure the generator must implement\n\
- Do NOT strip JavaScript/CSS requirements or convert the page brief into a static screenshot description\n\
- Remove only meta-instructions about tooling (\"use Claude\", \"don't explain\") if redundant with system\n\
- Negative: rare; pass through if present"
        }
        PrepChannel::Code => {
            "WHAT TO CHANGE:\n\
- KEEP exports, props, types, framework constraints, and file-structure requirements\n\
- Preserve bullet lists of behaviors and edge cases\n\
- Do not convert the brief into natural-language-only prose that loses API contracts\n\
- Remove only redundant meta-commentary\n\
- Negative: rare; pass through if present"
        }
        PrepChannel::Document => {
            "WHAT TO CHANGE:\n\
- Preserve section outline, headings, and required topics\n\
- Keep lists and tables of facts\n\
- Light cleanup of meta-instructions only\n\
- Do not invent claims not in the brief"
        }
        PrepChannel::Generic => {
            "WHAT TO CHANGE:\n\
- Clean technical tokens and formatting artifacts\n\
- Preserve descriptive and structural content\n\
- Do not over-summarize"
        }
    }
}

/// Refine-specific extra rules (appended after channel change rules).
fn prep_refine_extra(channel: PrepChannel) -> &'static str {
    match channel {
        PrepChannel::RasterImage | PrepChannel::Video => {
            "REFINEMENT FOCUS:\n\
- Start from the full original description — do NOT summarize or shorten\n\
- Make targeted adjustments for the eval feedback (anatomy, style, composition, missing elements, reject hits)\n\
- Reinforce weak criteria more prominently; move critical subject terms earlier"
        }
        PrepChannel::Svg | PrepChannel::Diagram | PrepChannel::Html | PrepChannel::Code | PrepChannel::Document => {
            "REFINEMENT FOCUS:\n\
- Start from the full original brief — do NOT rewrite from scratch\n\
- Address eval failures with concrete constraints (missing nodes, invalid markup, missing CTA, etc.)\n\
- Prefer adding explicit requirements over vague style adjectives"
        }
        PrepChannel::Music => {
            "REFINEMENT FOCUS:\n\
- Adjust genre/mood/instrument language to address eval feedback\n\
- Strengthen exclusions in the negative when reject-style issues appear"
        }
        PrepChannel::Voice | PrepChannel::Generic => {
            "REFINEMENT FOCUS:\n\
- Minimal edits only; address eval notes without inventing new content"
        }
    }
}

pub struct PreparedPrompt {
    pub text: String,
    pub negative: Option<String>,
}

pub struct PromptPrepper {
    pub base_url: String,
    pub model: String,
    pub api_key: String,
}

impl PromptPrepper {
    /// Resolve the prompt preparation LLM endpoint.
    ///
    /// Priority:
    ///   1. MEDIA_PREP_BASE_URL env / --prep-url   (OpenAI-compatible endpoint)
    ///   2. Groq cloud API (GROQ_API_KEY must be set)
    ///
    /// Model: MEDIA_PREP_MODEL env / --prep-model, else default.
    pub fn resolve(
        cli_url: Option<&str>,
        cli_model: Option<&str>,
        verbose: bool,
    ) -> Option<PromptPrepper> {
        let model = cli_model
            .map(|s| s.to_string())
            .or_else(|| std::env::var("MEDIA_PREP_MODEL").ok())
            .unwrap_or_else(|| DEFAULT_PREP_MODEL.to_string());

        // Priority 1: explicit override
        if let Some(url) = cli_url
            .map(|s| s.to_string())
            .or_else(|| std::env::var("MEDIA_PREP_BASE_URL").ok())
        {
            let api_key = std::env::var("MEDIA_PREP_API_KEY").unwrap_or_else(|_| "none".into());
            if verbose {
                ui::verbose(&format!(
                    "Prompt prep via custom endpoint: {} (model: {})",
                    url, model
                ));
            }
            return Some(PromptPrepper {
                base_url: url,
                model,
                api_key,
            });
        }

        // Priority 2: Groq cloud
        if let Ok(key) = std::env::var("GROQ_API_KEY") {
            if !key.is_empty() {
                if verbose {
                    ui::verbose(&format!("Prompt prep via Groq (model: {})", model));
                }
                return Some(PromptPrepper {
                    base_url: GROQ_API_URL
                        .trim_end_matches("/chat/completions")
                        .to_string(),
                    model,
                    api_key: key,
                });
            }
        }

        if verbose {
            ui::verbose(
                "No prompt prep endpoint available (set GROQ_API_KEY or MEDIA_PREP_BASE_URL)",
            );
        }
        None
    }

    pub async fn prepare_prompt(
        &self,
        prompt_section: &PromptSection,
        service: &str,
        asset_type: AssetType,
        audio_kind: AudioKind,
        text_format: Option<&str>,
        fim_enabled: bool,
        verbose: bool,
    ) -> Option<PreparedPrompt> {
        let channel = prep_channel(asset_type, audio_kind, text_format, service);
        if !allows_llm_prep(channel) {
            if verbose {
                ui::verbose(&format!(
                    "Prep skipped for {:?} channel — using verbatim text",
                    channel
                ));
            }
            return None;
        }

        let system_context = prompt_section.system.as_deref().unwrap_or("");
        let raw_text = &prompt_section.text;
        let raw_negative = prompt_section.negative.as_deref().unwrap_or("");

        let provider_guidance =
            resolve_guidance(service, asset_type, text_format, fim_enabled, verbose);
        let limit = crate::providers::constraints(service).max_prompt_chars;
        let length_instruction = if let Some(max) = limit {
            format!(
                "\nCRITICAL LENGTH CONSTRAINT: The target provider has a {} character prompt limit. \
                 The source is {} chars. You MUST condense the output to fit within {} characters \
                 while preserving the most important creative details for this asset type.\n",
                max,
                prompt_section.text.len(),
                max
            )
        } else {
            String::new()
        };

        let instruction = build_prep_instruction(
            channel,
            service,
            asset_type,
            system_context,
            raw_text,
            raw_negative,
            &provider_guidance,
            &length_instruction,
            false,
            "",
            "",
        );

        let url = if self.base_url.ends_with("/chat/completions") {
            self.base_url.clone()
        } else {
            format!("{}/chat/completions", self.base_url)
        };

        let body = json!({
            "model": self.model,
            "messages": [{"role": "user", "content": instruction}],
            "temperature": 0.3,
            "max_tokens": 2048,
        });

        let client = reqwest::Client::new();

        if verbose {
            ui::verbose(&format!(
                "Prompt prep POST {} (service={}, model={})",
                url, service, self.model
            ));
        }

        let resp = match client
            .post(&url)
            .header("Authorization", format!("Bearer {}", self.api_key))
            .header("Content-Type", "application/json")
            .json(&body)
            .timeout(Duration::from_secs(60))
            .send()
            .await
        {
            Ok(r) => r,
            Err(e) => {
                if verbose {
                    ui::verbose(&format!("Prompt prep request failed: {}", e));
                }
                return None;
            }
        };

        if !resp.status().is_success() {
            let status = resp.status();
            let body_text = resp.text().await.unwrap_or_default();
            if verbose {
                ui::verbose(&format!(
                    "Prompt prep HTTP {}: {}",
                    status,
                    &body_text[..body_text.len().min(200)]
                ));
            }
            return None;
        }

        let val: serde_json::Value = match resp.json().await {
            Ok(v) => v,
            Err(e) => {
                if verbose {
                    ui::verbose(&format!("Prompt prep response parse error: {}", e));
                }
                return None;
            }
        };

        let raw = val["choices"][0]["message"]["content"]
            .as_str()
            .unwrap_or("")
            .trim()
            .to_string();

        if verbose {
            ui::verbose(&format!("Prompt prep raw: {}", &raw[..raw.len().min(300)]));
        }

        let cleaned = strip_reasoning_and_fences(&raw);

        match serde_json::from_str::<serde_json::Value>(&cleaned) {
            Ok(parsed) => {
                let text = parsed["prompt"].as_str().unwrap_or("").trim().to_string();
                if text.is_empty() {
                    if verbose {
                        ui::verbose("Prompt prep returned empty prompt — falling back to raw");
                    }
                    return None;
                }
                let negative = parsed["negative"]
                    .as_str()
                    .map(|s| s.trim().to_string())
                    .filter(|s| !s.is_empty());

                // Enforce hard limit if the LLM still exceeded it
                let text = if let Some(max) = limit {
                    if text.len() > max {
                        if verbose {
                            ui::verbose(&format!(
                                "LLM output ({} chars) still exceeds limit ({}) — trimming at sentence boundary",
                                text.len(), max
                            ));
                        }
                        truncate_at_sentence(&text, max)
                    } else {
                        text
                    }
                } else {
                    text
                };

                Some(PreparedPrompt { text, negative })
            }
            Err(e) => {
                if verbose {
                    ui::verbose(&format!(
                        "Prompt prep JSON parse failed: {} — cleaned text: {}",
                        e,
                        &cleaned[..cleaned.len().min(200)]
                    ));
                }
                None
            }
        }
    }

    /// Refine a prompt based on eval feedback and the actual failed output.
    /// The LLM sees the generated image alongside the eval scores/notes so it
    /// can make targeted corrections based on what the model actually produced.
    pub async fn refine_prompt(
        &self,
        prompt_section: &PromptSection,
        service: &str,
        asset_type: AssetType,
        audio_kind: AudioKind,
        text_format: Option<&str>,
        fim_enabled: bool,
        eval_notes: &str,
        scores_summary: &str,
        failed_output: Option<&std::path::Path>,
        verbose: bool,
    ) -> Option<PreparedPrompt> {
        let channel = prep_channel(asset_type, audio_kind, text_format, service);
        if !allows_llm_prep(channel) {
            if verbose {
                ui::verbose(&format!(
                    "Refine skipped for {:?} channel — voice text stays verbatim",
                    channel
                ));
            }
            return None;
        }

        let system_context = prompt_section.system.as_deref().unwrap_or("");
        let raw_text = &prompt_section.text;
        let raw_negative = prompt_section.negative.as_deref().unwrap_or("");

        let provider_guidance =
            resolve_guidance(service, asset_type, text_format, fim_enabled, verbose);

        let instruction = build_prep_instruction(
            channel,
            service,
            asset_type,
            system_context,
            raw_text,
            raw_negative,
            &provider_guidance,
            "",
            true,
            scores_summary,
            eval_notes,
        );

        let url = if self.base_url.ends_with("/chat/completions") {
            self.base_url.clone()
        } else {
            format!("{}/chat/completions", self.base_url)
        };

        // Build message content — text instruction + optional failed output image
        let content = if let Some(output_path) = failed_output {
            let ext = output_path
                .extension()
                .and_then(|e| e.to_str())
                .unwrap_or("");
            match ext {
                "png" | "jpg" | "jpeg" | "webp" => {
                    if let Ok(data) = std::fs::read(output_path) {
                        use base64::Engine;
                        let b64 = base64::engine::general_purpose::STANDARD.encode(&data);
                        let mime = match ext {
                            "png" => "image/png",
                            "jpg" | "jpeg" => "image/jpeg",
                            "webp" => "image/webp",
                            _ => "image/png",
                        };
                        if verbose {
                            ui::verbose("Including failed output image in refinement request");
                        }
                        json!([
                            {"type": "text", "text": instruction},
                            {"type": "text", "text": "\n\n[The image below is what the previous generation produced — use it to understand what went wrong and what to fix in the prompt]"},
                            {"type": "image_url", "image_url": {"url": format!("data:{};base64,{}", mime, b64)}}
                        ])
                    } else {
                        json!(instruction)
                    }
                }
                // Text-based outputs (SVG, HTML, etc.) — include inline
                "svg" | "html" | "mmd" | "tsx" | "md" => {
                    if let Ok(text_content) = std::fs::read_to_string(output_path) {
                        let truncated = if text_content.len() > 8192 {
                            &text_content[..8192]
                        } else {
                            &text_content
                        };
                        json!(format!(
                            "{}\n\n[Previous output content]\n{}",
                            instruction, truncated
                        ))
                    } else {
                        json!(instruction)
                    }
                }
                _ => json!(instruction),
            }
        } else {
            json!(instruction)
        };

        let body = json!({
            "model": self.model,
            "messages": [{"role": "user", "content": content}],
            "temperature": 0.4,
            "max_tokens": 2048,
        });

        let client = reqwest::Client::new();

        if verbose {
            ui::verbose(&format!(
                "Prompt refine POST {} (vision-informed refinement)",
                url
            ));
        }

        let resp = match client
            .post(&url)
            .header("Authorization", format!("Bearer {}", self.api_key))
            .header("Content-Type", "application/json")
            .json(&body)
            .timeout(Duration::from_secs(60))
            .send()
            .await
        {
            Ok(r) => r,
            Err(e) => {
                if verbose {
                    ui::verbose(&format!("Prompt refine request failed: {}", e));
                }
                return None;
            }
        };

        if !resp.status().is_success() {
            if verbose {
                ui::verbose(&format!("Prompt refine HTTP {}", resp.status()));
            }
            return None;
        }

        let val: serde_json::Value = match resp.json().await {
            Ok(v) => v,
            Err(e) => {
                if verbose {
                    ui::verbose(&format!("Prompt refine response error: {}", e));
                }
                return None;
            }
        };

        let raw = val["choices"][0]["message"]["content"]
            .as_str()
            .unwrap_or("")
            .trim()
            .to_string();

        if verbose {
            ui::verbose(&format!(
                "Prompt refine raw: {}",
                &raw[..raw.len().min(300)]
            ));
        }

        let cleaned = strip_reasoning_and_fences(&raw);

        match serde_json::from_str::<serde_json::Value>(&cleaned) {
            Ok(parsed) => {
                let text = parsed["prompt"].as_str().unwrap_or("").trim().to_string();
                if text.is_empty() {
                    return None;
                }
                let negative = parsed["negative"]
                    .as_str()
                    .map(|s| s.trim().to_string())
                    .filter(|s| !s.is_empty());
                Some(PreparedPrompt { text, negative })
            }
            Err(_) => None,
        }
    }
}

/// Build the full prep or refine user instruction (pure; unit-tested).
pub fn build_prep_instruction(
    channel: PrepChannel,
    service: &str,
    asset_type: AssetType,
    system_context: &str,
    raw_text: &str,
    raw_negative: &str,
    provider_guidance: &str,
    length_instruction: &str,
    is_refine: bool,
    scores_summary: &str,
    eval_notes: &str,
) -> String {
    let system_section = if system_context.is_empty() {
        String::new()
    } else {
        format!("--- Art Direction / System ---\n{}\n", system_context)
    };

    let role = if is_refine {
        "You are refining a generation prompt that failed quality evaluation. Adjust the prompt to fix the evaluator issues — do NOT rewrite from scratch."
    } else {
        prep_role_preamble(channel)
    };

    let eval_block = if is_refine {
        format!(
            "\nEVALUATION FEEDBACK (why the previous generation failed):\nScores: {scores_summary}\nNotes: {eval_notes}\n"
        )
    } else {
        String::new()
    };

    let refine_extra = if is_refine {
        format!("\n{}\n", prep_refine_extra(channel))
    } else {
        String::new()
    };

    format!(
        "{role}{length_instruction}\n\n\
SOURCE SPECIFICATION:\n\
{system_section}\
--- Creative Brief ---\n\
{raw_text}\n\n\
--- Negative/Exclusions ---\n\
{raw_negative}\n\n\
TARGET PROVIDER: {service}\n\
ASSET TYPE: {asset_type:?}\n\
PREP CHANNEL: {channel:?}\n\
{eval_block}\n\
{provider_guidance}\n\n\
{change_rules}\n\
{refine_extra}\n\
Reply with ONLY valid JSON (no markdown fences, no commentary):\n\
{{\"prompt\": \"the cleaned prompt text\", \"negative\": \"cleaned negative prompt or empty string\"}}",
        change_rules = prep_change_rules(channel),
    )
}

/// Resolve the channel guidance for the prep/refine instruction.
///
/// When FIM injection is enabled and a solution file resolves for this target, the
/// loaded solution **replaces** the static guidance (it is more specific and current).
/// Otherwise we fall back to the compiled-in static `provider_prompt_guidance` so
/// behavior never regresses when the FIM dir/file is absent.
fn resolve_guidance(
    service: &str,
    asset_type: AssetType,
    text_format: Option<&str>,
    fim_enabled: bool,
    verbose: bool,
) -> String {
    if let Some(content) = crate::fim::guidance_for(service, asset_type, text_format, fim_enabled) {
        if verbose {
            let label = text_format.unwrap_or(service);
            ui::verbose(&format!(
                "FIM solution loaded for {service}/{label} ({} chars; replaces static guidance)",
                content.len()
            ));
        }
        content
    } else {
        if verbose && fim_enabled {
            let label = text_format.unwrap_or("");
            ui::verbose(&format!(
                "No FIM solution for {service}/{asset_type:?}/{label} — using static guidance"
            ));
        }
        provider_prompt_guidance(service, asset_type, text_format).to_string()
    }
}

/// Static provider/format notes when FIM is unavailable.
pub fn provider_prompt_guidance(
    service: &str,
    asset_type: AssetType,
    text_format: Option<&str>,
) -> &'static str {
    let channel = prep_channel(asset_type, AudioKind::Voice, text_format, service);
    match (service, asset_type) {
        ("gemini", AssetType::Image) if !matches!(channel, PrepChannel::Svg) => {
            "PROVIDER NOTES (Gemini Imagen):\n\
             - Imagen handles rich, detailed prompts well — do NOT shorten or summarize\n\
             - Front-load the subject and art style in the first sentence\n\
             - Art style terms are powerful: \"concept art\", \"painterly\", \"chiaroscuro\", \"oil painting\"\n\
             - Describe colors by name, never hex codes — the model renders codes as literal text\n\
             - Spatial descriptions (\"upper left\", \"in the background\") work well — keep them\n\
             - Mood and atmosphere language is highly effective — preserve all of it\n\
             - Named elements with specific quantities (\"three candles\", \"1,247 credits\") render well"
        }
        ("veo", AssetType::Video) | ("grok-video", AssetType::Video) => {
            "PROVIDER NOTES (Video generation):\n\
             - Video models need tighter prompts than image — aim for 60-120 words\n\
             - Lead with the scene, then action, then camera movement\n\
             - Art style in the first sentence\n\
             - Remove static layout details — describe motion and temporal flow"
        }
        ("suno", AssetType::Audio) => {
            "PROVIDER NOTES (Suno music generation):\n\
             - Lead with genre and mood\n\
             - List instruments and describe the overall sound\n\
             - Describe structure as phases (intro/build/climax/outro), not exact timestamps\n\
             - Keep under 200 words — Suno works best with focused descriptions\n\
             - Remove bar-by-bar breakdowns but keep emotional arc descriptions"
        }
        ("elevenlabs" | "openai-tts" | "qwen-tts", AssetType::Audio) => {
            "PROVIDER NOTES (TTS/Voice):\n\
             - Return the speaking text VERBATIM — do not rewrite\n\
             - Only clean formatting (remove bullets, headers)\n\
             - Voice style direction belongs in provider_options, not the prompt"
        }
        _ => match channel {
            PrepChannel::Svg => {
                "PROVIDER NOTES (SVG via chat):\n\
                 - Output contract belongs in system: raw <svg>…</svg>, no fences, no prose\n\
                 - Prefer compact path data and explicit viewBox\n\
                 - Hex brand colors and stroke widths are intentional — keep them\n\
                 - Avoid photographic language"
            }
            PrepChannel::Diagram => {
                "PROVIDER NOTES (Diagram DSL):\n\
                 - System should require raw DSL only (no ``` fences, no explanation)\n\
                 - Preserve entity names and edges from the brief\n\
                 - Prefer low temperature for valid syntax"
            }
            PrepChannel::Html => {
                "PROVIDER NOTES (HTML page):\n\
                 - Prefer self-contained HTML with inline CSS/JS unless brief says otherwise\n\
                 - Preserve feature checklists, CTAs, and interaction requirements\n\
                 - Keep responsive and accessibility notes"
            }
            PrepChannel::Code => {
                "PROVIDER NOTES (React/component):\n\
                 - Require valid code only (no markdown fences, no commentary)\n\
                 - Preserve exports, props, and framework constraints\n\
                 - TypeScript preferred when format is tsx/ts"
            }
            PrepChannel::Document => {
                "PROVIDER NOTES (Document):\n\
                 - Preserve outline and factual claims from the brief\n\
                 - Prefer clean markdown structure"
            }
            PrepChannel::RasterImage => {
                "PROVIDER NOTES (Image generation):\n\
                 - Detailed prompts work well — do NOT shorten or summarize\n\
                 - Front-load subject and art style\n\
                 - Replace hex codes with color names, remove pixel dimensions\n\
                 - Keep all descriptive and mood language"
            }
            PrepChannel::Video => {
                "PROVIDER NOTES (Video):\n\
                 - Lead with scene, action, camera; keep prompts tight"
            }
            PrepChannel::Music => {
                "PROVIDER NOTES (Music):\n\
                 - Genre, mood, instruments, phase structure; avoid bar-level detail"
            }
            PrepChannel::Voice => {
                "PROVIDER NOTES (TTS):\n\
                 - Verbatim speech text only; style in provider_options"
            }
            PrepChannel::Generic => {
                "PROVIDER NOTES:\n\
                 - Clean artifacts but preserve descriptive and structural content"
            }
        },
    }
}

fn strip_reasoning_and_fences(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    let mut rest = s;
    loop {
        match rest.find("<think>") {
            Some(start) => {
                out.push_str(&rest[..start]);
                match rest[start..].find("</think>") {
                    Some(end_rel) => {
                        rest = &rest[start + end_rel + "</think>".len()..];
                    }
                    None => break,
                }
            }
            None => {
                out.push_str(rest);
                break;
            }
        }
    }
    // Sanitize control characters inside JSON string values.
    // LLMs often emit literal newlines/tabs inside JSON strings;
    // replace them with spaces so serde_json can parse.
    let mut sanitized = String::with_capacity(out.len());
    let mut in_string = false;
    let mut prev_backslash = false;
    for ch in out.chars() {
        if in_string {
            if prev_backslash {
                prev_backslash = false;
                sanitized.push(ch);
                continue;
            }
            if ch == '\\' {
                prev_backslash = true;
                sanitized.push(ch);
                continue;
            }
            if ch == '"' {
                in_string = false;
                sanitized.push(ch);
                continue;
            }
            if ch.is_control() {
                sanitized.push(' ');
                continue;
            }
            sanitized.push(ch);
        } else {
            if ch == '"' {
                in_string = true;
            }
            sanitized.push(ch);
        }
    }

    let trimmed = sanitized.trim();
    if trimmed.starts_with("```") {
        let after_fence = if let Some(nl) = trimmed.find('\n') {
            &trimmed[nl + 1..]
        } else {
            trimmed
        };
        return after_fence.trim_end_matches("```").trim_end().to_string();
    }
    trimmed.to_string()
}

fn truncate_at_sentence(text: &str, max: usize) -> String {
    if text.len() <= max {
        return text.to_string();
    }
    let cut = &text[..max];
    // Find the last sentence-ending punctuation
    if let Some(pos) = cut.rfind(|c: char| c == '.' || c == '!' || c == '?') {
        cut[..=pos].trim().to_string()
    } else if let Some(pos) = cut.rfind(',') {
        cut[..pos].trim().to_string()
    } else {
        cut.trim().to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn channel_raster_vs_svg() {
        assert_eq!(
            prep_channel(AssetType::Image, AudioKind::Voice, None, "gemini"),
            PrepChannel::RasterImage
        );
        assert_eq!(
            prep_channel(AssetType::Image, AudioKind::Voice, Some("svg"), "gemini-chat"),
            PrepChannel::Svg
        );
    }

    #[test]
    fn channel_audio_kinds() {
        assert_eq!(
            prep_channel(AssetType::Audio, AudioKind::Music, None, "suno"),
            PrepChannel::Music
        );
        assert_eq!(
            prep_channel(AssetType::Audio, AudioKind::Voice, None, "openai-tts"),
            PrepChannel::Voice
        );
        assert_eq!(
            prep_channel(AssetType::Audio, AudioKind::Voice, None, "elevenlabs"),
            PrepChannel::Voice
        );
    }

    #[test]
    fn channel_chat_types() {
        assert_eq!(
            prep_channel(AssetType::Diagram, AudioKind::Voice, Some("mermaid"), "anthropic"),
            PrepChannel::Diagram
        );
        assert_eq!(
            prep_channel(AssetType::Html, AudioKind::Voice, None, "openai-chat"),
            PrepChannel::Html
        );
        assert_eq!(
            prep_channel(AssetType::ReactPage, AudioKind::Voice, Some("tsx"), "z.ai"),
            PrepChannel::Code
        );
        assert_eq!(
            prep_channel(AssetType::Document, AudioKind::Voice, Some("md"), "groq-chat"),
            PrepChannel::Document
        );
    }

    #[test]
    fn voice_disallows_llm_prep() {
        assert!(!allows_llm_prep(PrepChannel::Voice));
        assert!(allows_llm_prep(PrepChannel::RasterImage));
        assert!(allows_llm_prep(PrepChannel::Svg));
        assert!(allows_llm_prep(PrepChannel::Html));
    }

    #[test]
    fn svg_rules_preserve_hex_not_strip() {
        let rules = prep_change_rules(PrepChannel::Svg);
        assert!(rules.contains("KEEP hex") || rules.contains("hex color"));
        assert!(!rules.contains("Replace hex color codes with descriptive"));

        let raster = prep_change_rules(PrepChannel::RasterImage);
        assert!(raster.contains("Replace hex color codes"));
    }

    #[test]
    fn html_rules_keep_implementation_details() {
        let rules = prep_change_rules(PrepChannel::Html);
        assert!(rules.contains("KEEP layout") || rules.contains("feature checklist"));
        assert!(!rules.contains("Remove implementation/interaction instructions"));
    }

    #[test]
    fn build_instruction_includes_channel_and_rules() {
        let instr = build_prep_instruction(
            PrepChannel::Svg,
            "gemini-chat",
            AssetType::Image,
            "",
            "hex #00D4FF logo",
            "photos",
            "PROVIDER NOTES (SVG)",
            "",
            false,
            "",
            "",
        );
        assert!(instr.contains("PREP CHANNEL: Svg"));
        assert!(instr.contains("KEEP hex") || instr.contains("hex color"));
        assert!(instr.contains("#00D4FF"));
        assert!(!instr.contains("Replace hex color codes with descriptive color names"));
    }

    #[test]
    fn static_guidance_svg_vs_imagen() {
        let svg = provider_prompt_guidance("gemini-chat", AssetType::Image, Some("svg"));
        assert!(svg.to_lowercase().contains("svg"));
        let imagen = provider_prompt_guidance("gemini", AssetType::Image, None);
        assert!(imagen.contains("Imagen") || imagen.contains("hex codes"));
    }
}
