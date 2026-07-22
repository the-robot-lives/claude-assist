//! Deterministic structural scoring for audio/video (and basic file probes).
//! Used when LLM vision/audio eval is unavailable or when `eval.mode` is
//! `structural` / `hybrid`.

use std::collections::HashMap;
use std::path::Path;
use std::process::Command;

use crate::eval::EvalScore;
use crate::schema::EvalSection;
use crate::ui;

/// Result of a structural probe.
#[derive(Debug, Clone)]
pub struct StructuralProbe {
    pub ok: bool,
    pub duration_secs: Option<f64>,
    pub mean_volume_db: Option<f64>,
    pub has_video: bool,
    pub has_audio: bool,
    pub notes: String,
    pub reject_hits: Vec<String>,
    /// Normalized quality signal in [0,1] from heuristics.
    pub quality: f64,
}

/// Score an artifact with structural probes. Returns None if extension is not
/// audio/video or tools (ffprobe/ffmpeg) are unavailable for a required check.
// ⟦𓐆𓍨𓋻𓉾⟧ score_structural :: Score an artifact with structural probes.
pub async fn score_structural(
    path: &Path,
    eval: &EvalSection,
    expected_duration: Option<f64>,
    verbose: bool,
) -> Option<EvalScore> {
    let ext = path
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("")
        .to_lowercase();

    let probe = match ext.as_str() {
        "mp3" | "wav" | "ogg" | "flac" | "m4a" => probe_audio(path, expected_duration, verbose).await?,
        "mp4" | "webm" | "mov" | "mkv" => probe_video(path, expected_duration, verbose).await?,
        _ => return None,
    };

    Some(probe_to_eval_score(&probe, eval))
}

/// True when structural scoring can apply to this path's extension.
// ⟦𓐦𓐦𓀚𓌥⟧ is_structural_candidate :: True when structural scoring can apply to this path's extension.
pub fn is_structural_candidate(path: &Path) -> bool {
    matches!(
        path.extension()
            .and_then(|e| e.to_str())
            .unwrap_or("")
            .to_lowercase()
            .as_str(),
        "mp3" | "wav" | "ogg" | "flac" | "m4a" | "mp4" | "webm" | "mov" | "mkv"
    )
}

fn probe_to_eval_score(probe: &StructuralProbe, eval: &EvalSection) -> EvalScore {
    let q = probe.quality.clamp(0.0, 1.0);
    let mut per_criterion: HashMap<String, f64> = HashMap::new();

    if eval.criteria.is_empty() {
        per_criterion.insert("technical".into(), q);
        per_criterion.insert("relevance".into(), if probe.ok { q } else { q * 0.5 });
    } else {
        for name in eval.criteria.keys() {
            let lower = name.to_lowercase();
            let score = if lower.contains("silence") || lower.contains("intelligib") {
                // map volume-ish
                if let Some(db) = probe.mean_volume_db {
                    if db < -50.0 {
                        0.1
                    } else if db < -35.0 {
                        0.5
                    } else {
                        q
                    }
                } else {
                    q
                }
            } else if lower.contains("duration") || lower.contains("technical") {
                q
            } else if lower.contains("motion") {
                if probe.has_video {
                    q
                } else {
                    0.2
                }
            } else {
                // generic: use overall quality
                q
            };
            per_criterion.insert(name.clone(), score);
        }
    }

    // Weighted average matching EvalScore convention
    let mut weighted_sum = 0.0;
    let mut weight_total = 0.0;
    if eval.criteria.is_empty() {
        weighted_sum = q;
        weight_total = 1.0;
    } else {
        for (name, crit) in &eval.criteria {
            let w = crit.weight.unwrap_or(1.0);
            let s = per_criterion.get(name).copied().unwrap_or(0.0);
            weighted_sum += w * s;
            weight_total += w;
        }
    }
    let weighted = if weight_total > 0.0 {
        weighted_sum / weight_total
    } else {
        q
    };

    EvalScore {
        weighted,
        per_criterion,
        reject_hits: probe.reject_hits.clone(),
        notes: format!("[structural] {}", probe.notes),
    }
}

async fn probe_audio(
    path: &Path,
    expected_duration: Option<f64>,
    verbose: bool,
) -> Option<StructuralProbe> {
    if !path.is_file() {
        return Some(StructuralProbe {
            ok: false,
            duration_secs: None,
            mean_volume_db: None,
            has_video: false,
            has_audio: false,
            notes: "file missing".into(),
            reject_hits: vec!["file missing".into()],
            quality: 0.0,
        });
    }

    let meta = std::fs::metadata(path).ok()?;
    if meta.len() == 0 {
        return Some(StructuralProbe {
            ok: false,
            duration_secs: None,
            mean_volume_db: None,
            has_video: false,
            has_audio: false,
            notes: "zero-byte audio".into(),
            reject_hits: vec!["silence or near-silence".into()],
            quality: 0.0,
        });
    }

    let duration = ffprobe_duration(path).await;
    let mean_db = ffmpeg_mean_volume(path).await;

    if verbose {
        ui::verbose(&format!(
            "structural audio: duration={:?}s mean_vol={:?}dB size={}",
            duration,
            mean_db,
            meta.len()
        ));
    }

    let mut notes = Vec::new();
    let mut reject = Vec::new();
    let mut quality: f64 = 0.4; // non-empty file

    if let Some(d) = duration {
        notes.push(format!("duration={d:.2}s"));
        if d < 0.15 {
            reject.push("silence or near-silence".into());
            quality = 0.1;
        } else {
            quality += 0.25;
        }
        if let Some(exp) = expected_duration {
            if exp > 0.0 {
                let ratio = d / exp;
                if (0.5..=1.5).contains(&ratio) {
                    quality += 0.15;
                    notes.push(format!("duration within 50% of expected {exp}"));
                } else {
                    notes.push(format!("duration off expected {exp} (ratio {ratio:.2})"));
                    quality += 0.05;
                }
            }
        }
    } else {
        notes.push("ffprobe duration unavailable".into());
        // still scorable if file has bytes
        quality += 0.1;
    }

    if let Some(db) = mean_db {
        notes.push(format!("mean_volume={db:.1}dB"));
        if db < -50.0 {
            reject.push("silence or near-silence".into());
            quality = quality.min(0.2);
        } else if db < -40.0 {
            quality += 0.05;
        } else {
            quality += 0.2;
        }
    }

    let ok = reject.is_empty() && quality >= 0.45;
    Some(StructuralProbe {
        ok,
        duration_secs: duration,
        mean_volume_db: mean_db,
        has_video: false,
        has_audio: true,
        notes: notes.join("; "),
        reject_hits: reject,
        quality: quality.clamp(0.0, 1.0),
    })
}

async fn probe_video(
    path: &Path,
    expected_duration: Option<f64>,
    verbose: bool,
) -> Option<StructuralProbe> {
    if !path.is_file() {
        return Some(StructuralProbe {
            ok: false,
            duration_secs: None,
            mean_volume_db: None,
            has_video: false,
            has_audio: false,
            notes: "file missing".into(),
            reject_hits: vec!["file missing".into()],
            quality: 0.0,
        });
    }
    let meta = std::fs::metadata(path).ok()?;
    if meta.len() == 0 {
        return Some(StructuralProbe {
            ok: false,
            duration_secs: None,
            mean_volume_db: None,
            has_video: false,
            has_audio: false,
            notes: "zero-byte video".into(),
            reject_hits: vec!["empty video".into()],
            quality: 0.0,
        });
    }

    let duration = ffprobe_duration(path).await;
    let has_video = ffprobe_has_stream(path, "v").await.unwrap_or(false);
    let has_audio = ffprobe_has_stream(path, "a").await.unwrap_or(false);

    if verbose {
        ui::verbose(&format!(
            "structural video: duration={:?}s has_v={has_video} has_a={has_audio} size={}",
            duration,
            meta.len()
        ));
    }

    let mut notes = Vec::new();
    let mut reject = Vec::new();
    let mut quality: f64 = 0.3;

    if has_video {
        quality += 0.35;
        notes.push("video stream present".into());
    } else {
        reject.push("no video stream".into());
        notes.push("missing video stream".into());
    }
    if has_audio {
        notes.push("audio stream present".into());
        quality += 0.05;
    }
    if let Some(d) = duration {
        notes.push(format!("duration={d:.2}s"));
        if d < 0.2 {
            reject.push("video too short".into());
            quality = quality.min(0.25);
        } else {
            quality += 0.15;
        }
        if let Some(exp) = expected_duration {
            if exp > 0.0 {
                let ratio = d / exp;
                if (0.6..=1.4).contains(&ratio) {
                    quality += 0.15;
                } else {
                    notes.push(format!("duration off expected {exp}"));
                }
            }
        }
    } else {
        notes.push("ffprobe duration unavailable".into());
    }

    let ok = has_video && reject.is_empty();
    Some(StructuralProbe {
        ok,
        duration_secs: duration,
        mean_volume_db: None,
        has_video,
        has_audio,
        notes: notes.join("; "),
        reject_hits: reject,
        quality: quality.clamp(0.0, 1.0),
    })
}

async fn ffprobe_duration(path: &Path) -> Option<f64> {
    let output = tokio::process::Command::new("ffprobe")
        .args([
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "default=noprint_wrappers=1:nokey=1",
            path.to_str()?,
        ])
        .output()
        .await
        .ok()?;
    if !output.status.success() {
        return None;
    }
    String::from_utf8_lossy(&output.stdout)
        .trim()
        .parse()
        .ok()
}

async fn ffprobe_has_stream(path: &Path, kind: &str) -> Option<bool> {
    // kind: "v" or "a"
    let sel = format!("stream=index");
    let output = tokio::process::Command::new("ffprobe")
        .args([
            "-v",
            "error",
            "-select_streams",
            kind,
            "-show_entries",
            &sel,
            "-of",
            "csv=p=0",
            path.to_str()?,
        ])
        .output()
        .await
        .ok()?;
    if !output.status.success() {
        return Some(false);
    }
    let s = String::from_utf8_lossy(&output.stdout);
    Some(!s.trim().is_empty())
}

/// Parse mean_volume from ffmpeg volumedetect (stderr).
async fn ffmpeg_mean_volume(path: &Path) -> Option<f64> {
    let output = tokio::process::Command::new("ffmpeg")
        .args([
            "-i",
            path.to_str()?,
            "-af",
            "volumedetect",
            "-f",
            "null",
            "-",
        ])
        .output()
        .await
        .ok()?;
    let stderr = String::from_utf8_lossy(&output.stderr);
    // mean_volume: -23.5 dB
    for line in stderr.lines() {
        if let Some(rest) = line.split("mean_volume:").nth(1) {
            let num = rest.trim().split_whitespace().next()?;
            return num.parse().ok();
        }
    }
    None
}

/// Synchronous availability check for unit tests / dry diagnostics.
// ⟦𓌥𓈸𓀙𓀓⟧ ffprobe_available :: Synchronous availability check for unit tests / dry diagnostics.
pub fn ffprobe_available() -> bool {
    Command::new("ffprobe")
        .arg("-version")
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::schema::EvalCriterion;
    use std::io::Write;

    fn sample_eval() -> EvalSection {
        let mut criteria = HashMap::new();
        criteria.insert(
            "technical".into(),
            EvalCriterion {
                weight: Some(2.0),
                scale: None,
                description: Some("tech".into()),
                fail_signals: vec![],
            },
        );
        criteria.insert(
            "relevance".into(),
            EvalCriterion {
                weight: Some(1.0),
                scale: None,
                description: Some("rel".into()),
                fail_signals: vec![],
            },
        );
        EvalSection {
            pass_threshold: Some(0.5),
            max_attempts: None,
            required_pass: vec![],
            criteria,
            reject_if: vec!["silence or near-silence".into()],
            mode: None,
            visual: None,
        }
    }

    #[test]
    fn empty_file_is_structural_candidate_by_ext() {
        assert!(is_structural_candidate(Path::new("x.mp3")));
        assert!(is_structural_candidate(Path::new("x.mp4")));
        assert!(!is_structural_candidate(Path::new("x.png")));
    }

    #[tokio::test]
    async fn zero_byte_audio_fails() {
        let dir = tempfile_dir();
        let path = dir.join("empty.mp3");
        std::fs::File::create(&path).unwrap();
        let score = score_structural(&path, &sample_eval(), None, false)
            .await
            .expect("score");
        assert!(!score.reject_hits.is_empty() || score.weighted < 0.5);
    }

    #[tokio::test]
    async fn real_demo_audio_scores_if_ffprobe() {
        if !ffprobe_available() {
            eprintln!("ffprobe missing — skip");
            return;
        }
        let path = Path::new("demos/music/sample-lofi-beat.mp3");
        if !path.is_file() {
            eprintln!("demo audio missing — skip");
            return;
        }
        let score = score_structural(path, &sample_eval(), Some(30.0), false)
            .await
            .expect("score");
        assert!(
            score.weighted >= 0.4,
            "expected reasonable structural score, got {}",
            score.weighted
        );
        assert!(score.notes.contains("[structural]") || score.notes.contains("duration"));
    }

    fn tempfile_dir() -> std::path::PathBuf {
        let dir = std::env::temp_dir().join(format!(
            "media_struct_{}",
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        std::fs::create_dir_all(&dir).unwrap();
        dir
    }

    #[allow(dead_code)]
    fn write_bytes(path: &Path, data: &[u8]) {
        let mut f = std::fs::File::create(path).unwrap();
        f.write_all(data).unwrap();
    }
}
