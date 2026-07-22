//! FIM (Fill-in-the-Middle) solution loader.
//!
//! The media-tool bundles a FIM reference library under
//! `skill/content-media-engine/references/fim/solution/`. These markdown files are
//! machine-reference knowledge consumed by text generation (`pipeline.rs`) and the
//! prompt-PREP agent (`prep.rs`) to shape the best possible prompt for a given target.
//!
//! This module resolves the right solution file for a (service, asset_type, text_format)
//! target and returns its content with low-value sections stripped to bound token cost.
//! All operations are fallible-by-None: a missing dir, missing file, or read error
//! silently falls back to the caller's static guidance so generation never breaks.

use crate::schema::AssetType;
use std::path::{Path, PathBuf};

/// Sections whose heading title (case-insensitive, prefix-matched) is dropped during
/// load. These are author-context sections that add tokens without helping prompt prep.
const LOW_VALUE_SECTION_PREFIXES: &[&str] = &[
    "official resources",
    "installation",
    "see also",
    "best for",
    "avoid for",
];

/// Resolve the absolute path to the bundled `fim/solution/` directory, if it can be found.
///
/// Search order:
/// 1. `MEDIA_FIM_DIR` env var (explicit override, may point anywhere)
/// 2. `$INFRA_ROOT/utilities/agent/media-tool/skill/content-media-engine/references/fim/solution`
/// 3. Walk up from the current working directory looking for the same relative path
///
/// Returns `None` if nothing resolves — callers fall back to static guidance.
// ⟦𓎍𓈑𓉨𓃫⟧ resolve_solution_dir :: Resolve the absolute path to the bundled `fim/solution/` directory, if it can be found.
pub fn resolve_solution_dir() -> Option<PathBuf> {
    // 1. Explicit override
    if let Ok(dir) = std::env::var("MEDIA_FIM_DIR") {
        let p = PathBuf::from(&dir);
        if p.is_dir() {
            return Some(p);
        }
    }

    const TAIL: &str =
        "utilities/agent/media-tool/skill/content-media-engine/references/fim/solution";

    // 2. INFRA_ROOT-relative (matches main.rs:173 convention)
    if let Ok(root) = std::env::var("INFRA_ROOT") {
        let p = PathBuf::from(&root).join(TAIL);
        if p.is_dir() {
            return Some(p);
        }
    }

    // 3. Walk up from CWD
    if let Ok(cwd) = std::env::current_dir() {
        let mut cursor: Option<&Path> = Some(&cwd);
        while let Some(dir) = cursor {
            let candidate = dir.join(TAIL);
            if candidate.is_dir() {
                return Some(candidate);
            }
            cursor = dir.parent();
        }
    }

    None
}

/// Resolve the solution file for a text-format target (chat types).
///
/// Handles the `fim-index.md` aliases where the `text_format` value differs from the
/// file name, then falls back to `solution/<text_format>.md` if present. Also maps a
/// handful of output extensions / diagram_type values to their solution files.
fn text_format_solution(dir: &Path, text_format: &str) -> Option<PathBuf> {
    let tf = text_format.trim().to_lowercase();
    if tf.is_empty() {
        return None;
    }

    // 1. Explicit aliases (name != file). Try each candidate; first existing wins.
    let candidates: &[&str] = match tf.as_str() {
        "graphviz" | "dot" | "graphviz-dot" => &["graphviz-dot.md", "graphviz.md"],
        "drawio" | "draw.io" => &["drawio-xml.md"],
        "abc" | "abcjs" => &["abcjs.md"],
        "plantuml" | "puml" => &["plantuml.md"],
        "mermaid" | "mmd" => &["mermaid.md"],
        "latex" | "tex" => &["latex.md"],
        "typst" => &["typst.md"],
        "lilypond" | "ly" => &["lilypond.md"],
        "wavedrom" | "wavejson" => &["wavedrom.md"],
        "katex" | "mathjax" => &["katex.md"],
        // Markup / page formats used by demos and skill templates
        "html" | "htm" => &["html.md"],
        "md" | "markdown" | "document" => &["markdown.md"],
        // No dedicated pure-SVG solution yet; svg_js is the closest vector guidance.
        "svg" => &["svg_js.md"],
        // React / TS component formats — no dedicated solution; leave unmapped
        // so static chat guidance applies (react-three-fiber is 3D-specific).
        "react" | "react-page" | "tsx" | "jsx" | "component" => &[],
        _ => &[],
    };
    for cand in candidates {
        let p = dir.join(cand);
        if p.is_file() {
            return Some(p);
        }
    }

    // 2. Diagram-type / extension fallbacks (e.g. user wrote the output ext, not the format)
    if let Some(mapped) = match tf.as_str() {
        "mmd" => Some("mermaid.md"),
        "puml" => Some("plantuml.md"),
        "dot" => Some("graphviz-dot.md"),
        "tex" => Some("latex.md"),
        "ly" => Some("lilypond.md"),
        "abc" => Some("abcjs.md"),
        _ => None,
    } {
        let p = dir.join(mapped);
        if p.is_file() {
            return Some(p);
        }
    }

    // 3. Direct: solution/<text_format>.md
    let direct = dir.join(format!("{tf}.md"));
    if direct.is_file() {
        return Some(direct);
    }

    None
}

/// Resolve the provider/generator solution file for a binary-media service (image/video/audio).
///
/// Maps the media-tool `service` id to a file under `providers/`. Returns `None` for
/// services with no generator solution file (e.g. chat-only services like anthropic/openai-chat).
fn provider_solution(dir: &Path, service: &str) -> Option<PathBuf> {
    let svc = service.trim().to_lowercase();
    let name: &str = match svc.as_str() {
        // image
        "gemini" => "providers/imagen.md", // Imagen via the gemini provider
        "stable-diffusion" | "sd" | "sdxl" | "a1111" | "comfyui" => "providers/stable-diffusion.md",
        "flux" | "flux.1" => "providers/flux.md",
        "midjourney" | "mj" => "providers/midjourney.md",
        // video
        "veo" => "providers/veo.md",
        "grok-video" => "providers/grok-video.md",
        "runway" | "runway-gen3" | "runway-gen4" => "providers/runway-gen3.md",
        "sora" => "providers/sora.md",
        // audio
        "suno" => "providers/suno.md",
        "elevenlabs" => "providers/elevenlabs.md",
        "openai-tts" => "providers/openai-tts.md",
        "qwen-tts" => "providers/qwen-tts.md",
        "udio" => "providers/udio.md",
        _ => return None,
    };
    let p = dir.join(name);
    if p.is_file() {
        Some(p)
    } else {
        None
    }
}

/// Resolve the solution file path for a generation target.
///
/// `text_format` (when set) always wins — it is the most specific signal of what
/// is being authored (mermaid, svg, html, …). This includes non-chat asset types
/// that still emit text (e.g. `type: image` + `text_format: svg` via a chat
/// provider). Binary-media targets without a text format resolve via `service`.
// ⟦𓋘𓈿𓁀𓃌⟧ solution_for :: Resolve the solution file path for a generation target.
pub fn solution_for(
    service: &str,
    asset_type: AssetType,
    text_format: Option<&str>,
) -> Option<PathBuf> {
    let dir = resolve_solution_dir()?;

    // Text-format targets first (diagrams, SVG, documents, components, etc.)
    if let Some(tf) = text_format {
        if let Some(p) = text_format_solution(&dir, tf) {
            return Some(p);
        }
    }

    // Chat types with no resolvable text_format: no provider solution for
    // anthropic/openai-chat/etc., so fall through to None → static guidance.
    let _ = asset_type;

    provider_solution(&dir, service)
}

/// Read a solution file and strip low-value sections to bound token cost.
///
/// Drops any `## ` section whose title (case-insensitive) starts with one of
/// `LOW_VALUE_SECTION_PREFIXES` (Official Resources, Installation, See Also, Best For,
/// Avoid For). Keeps the `# Title` line and all other sections. Returns `None` on read
/// error so callers fall back gracefully.
// ⟦𓈠𓁎𓊃𓀫⟧ load_solution :: Read a solution file and strip low-value sections to bound token cost.
pub fn load_solution(path: &Path) -> Option<String> {
    let raw = std::fs::read_to_string(path).ok()?;
    Some(strip_low_value_sections(&raw))
}

/// Pure extractor: drop low-value `## ` sections, keep the rest (incl. `# Title`).
fn strip_low_value_sections(raw: &str) -> String {
    let mut out = String::with_capacity(raw.len());
    let mut skip = false;

    for line in raw.split_inclusive('\n') {
        // A line starting with "## " begins a new h2 section.
        let trimmed_start = line.trim_start();
        if trimmed_start.starts_with("## ") {
            let title = trimmed_start.trim_start_matches('#').trim().to_lowercase();
            skip = LOW_VALUE_SECTION_PREFIXES
                .iter()
                .any(|p| title.starts_with(p));
        } else if trimmed_start.starts_with('#') && !trimmed_start.starts_with("## ") {
            // A higher-level or single-# heading: stop skipping (e.g. a new "# Part").
            // '#' alone (h1) is the title; '### ' subsections stay with their parent h2.
            if !trimmed_start.starts_with("###") {
                skip = false;
            }
        }

        if !skip {
            out.push_str(line);
        }
    }

    // Collapse 3+ blank lines that the stripping can leave behind.
    while out.contains("\n\n\n") {
        out = out.replace("\n\n\n", "\n\n");
    }
    out.trim_end().to_string()
}

/// Compose: resolve the solution file for a target, load + strip it, return the
/// ready-to-embed guidance string. Returns `None` when disabled, no dir, no file, or
/// read error — the caller then falls back to its static guidance.
// ⟦𓌕𓂴𓄲𓏎⟧ guidance_for :: Compose: resolve the solution file for a target, load + strip it, return the
pub fn guidance_for(
    service: &str,
    asset_type: AssetType,
    text_format: Option<&str>,
    fim_enabled: bool,
) -> Option<String> {
    if !fim_enabled {
        return None;
    }
    let path = solution_for(service, asset_type, text_format)?;
    let content = load_solution(&path)?;
    if content.trim().is_empty() {
        None
    } else {
        Some(content)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn strip_removes_low_value_sections_keeps_rest() {
        let raw = "# Mermaid\n\
                   ## Overview\nkeep this\n\
                   ## Official Resources & Documentation\ndrop this\nstill dropped\n\
                   ## Installation & Setup\ndrop install\n\
                   ## Core Syntax\nkeep core\n\
                   ## See Also\ndrop seealso\n\
                   ## Best For / Avoid For\ndrop bestfor\n";
        let out = strip_low_value_sections(raw);
        assert!(out.contains("keep this"));
        assert!(out.contains("keep core"));
        assert!(!out.contains("drop this"));
        assert!(!out.contains("drop install"));
        assert!(!out.contains("drop seealso"));
        assert!(!out.contains("drop bestfor"));
        assert!(out.starts_with("# Mermaid"));
    }

    #[test]
    fn strip_preserves_h3_subsections_inside_kept_h2() {
        let raw = "# X\n## Core Syntax\n### Sub\nbody\n## See Also\ndrop\n";
        let out = strip_low_value_sections(raw);
        assert!(out.contains("### Sub"));
        assert!(out.contains("body"));
    }

    #[test]
    fn guidance_disabled_returns_none() {
        assert!(guidance_for("gemini", AssetType::Image, None, false).is_none());
    }

    /// Integration guard: when the bundled solution tree is resolvable, a real
    /// text-format target loads non-empty guidance and the static guidance is bypassed.
    /// Skipped automatically when the tree isn't on disk (e.g. cargo test in a bare
    /// checkout or a release install without the skill assets).
    #[test]
    fn guidance_loads_real_solution_when_tree_present() {
        if resolve_solution_dir().is_none() {
            eprintln!("[fim] solution dir not resolvable — skipping integration check");
            return;
        }
        // mermaid.md ships in every checkout that has the skill assets.
        let g = guidance_for("anthropic", AssetType::Diagram, Some("mermaid"), true);
        assert!(
            g.is_some(),
            "mermaid solution should load when tree present"
        );
        let g = g.unwrap();
        assert!(g.contains("Mermaid") || g.contains("mermaid"));
        // stripped sections must be gone
        assert!(
            !g.contains("## Official Resources"),
            "low-value section should be stripped"
        );
    }

    #[test]
    fn unknown_text_format_returns_none() {
        assert!(guidance_for(
            "anthropic",
            AssetType::Diagram,
            Some("totally-not-a-format-xyz"),
            true
        )
        .is_none());
    }

    #[test]
    fn text_format_aliases_map_to_files_when_tree_present() {
        let Some(dir) = resolve_solution_dir() else {
            eprintln!("[fim] solution dir not resolvable — skipping alias map check");
            return;
        };
        let cases = [
            ("mermaid", true),
            ("mmd", true),
            ("plantuml", true),
            ("puml", true),
            ("dot", true),
            ("html", true),
            ("md", true),
            ("svg", true), // maps to svg_js.md
            ("react-page", false), // intentionally unmapped
            ("totally-not-a-format-xyz", false),
        ];
        for (tf, expect_some) in cases {
            let got = text_format_solution(&dir, tf);
            assert_eq!(
                got.is_some(),
                expect_some,
                "text_format '{tf}' expected some={expect_some}, got={got:?}"
            );
        }
    }

    #[test]
    fn svg_text_format_resolves_for_image_asset_type() {
        // Regression: type:image + text_format:svg must still hit text_format map
        // (not only is_chat_type paths).
        if resolve_solution_dir().is_none() {
            return;
        }
        let path = solution_for("gemini-chat", AssetType::Image, Some("svg"));
        assert!(
            path.is_some(),
            "image+svg should resolve a FIM solution via text_format"
        );
    }

    #[test]
    fn provider_solution_maps_core_media_services() {
        if resolve_solution_dir().is_none() {
            return;
        }
        for svc in ["gemini", "veo", "grok-video", "suno", "openai-tts", "elevenlabs"] {
            let p = solution_for(svc, AssetType::Image, None);
            // gemini maps via provider; non-image types still use provider map by service
            let p = p.or_else(|| {
                // force provider path only
                let dir = resolve_solution_dir().unwrap();
                provider_solution(&dir, svc)
            });
            assert!(p.is_some(), "provider solution missing for {svc}");
        }
    }
}
