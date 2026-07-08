//! Host-side snapshot of the therobot extension state for the right pane.
//!
//! Metal-safety note: `llama_robot_probe_eval` runs a compute graph on the
//! backend, so probes are only refreshed when `with_probes` is true — call that
//! ONLY between turns while no decode is in flight. The other fields are plain
//! host-side struct reads, safe to sample every frame.

use crate::engine::{cstr, Engine};
use crate::ffi;

#[derive(Default, Clone)]
pub struct Snapshot {
    pub enabled: bool,
    pub modulator: Vec<(String, f32)>,   // named mood channels only
    pub mod_latent: Option<(usize, f32)>, // (count, ‖·‖) of the unnamed latent dims
    pub probes: Vec<ProbeTap>,          // cached between idle refreshes
    pub memory: Vec<MemEntry>,
    pub mem_count: i32,
    pub recall_norm: Option<f32>,
    pub delta: Option<(f32, u64)>,      // (keep_rate, tokens)
}

#[derive(Clone)]
pub struct ProbeTap {
    pub name: String,
    pub attrs: Vec<(String, i32, f32)>, // (attr, class, confidence)
}

#[derive(Clone)]
pub struct MemEntry {
    pub idx: i32,
    pub salience: f32,
    pub age_tokens: u64,
    pub inject: Option<(String, f32)>, // dominant modulator channel of the value
    pub match_cos: f32,                // cosine vs current context (firing now?)
}

impl Snapshot {
    /// Refresh from the engine. `prev` carries cached probe rows forward when
    /// with_probes is false.
    pub fn sample(eng: &Engine, with_probes: bool, prev: &Snapshot) -> Snapshot {
        let ctx = eng.ctx();
        let model = eng.model();
        let mut s = Snapshot::default();
        s.enabled = eng.robot_enabled();
        if !s.enabled {
            return s;
        }
        unsafe {
            // modulator: named channels as gauges; unnamed latent dims summarized
            let md = ffi::llama_robot_mod_dim(model);
            if md > 0 {
                let mut mv = vec![0f32; md as usize];
                ffi::llama_robot_mod_get(ctx, mv.as_mut_ptr());
                let mut latent_n = 0usize;
                let mut latent_sq = 0f32;
                for i in 0..md {
                    let name = cstr(ffi::llama_robot_mod_channel(model, i));
                    if name.is_empty() {
                        latent_n += 1;
                        latent_sq += mv[i as usize] * mv[i as usize];
                    } else {
                        s.modulator.push((name, mv[i as usize]));
                    }
                }
                if latent_n > 0 {
                    s.mod_latent = Some((latent_n, latent_sq.sqrt()));
                }
            }

            // probes (backend compute — idle only)
            if with_probes {
                let taps = ffi::llama_robot_tap_count(model);
                for t in 0..taps {
                    let name = cstr(ffi::llama_robot_tap_name(model, t));
                    let mut attrs = Vec::new();
                    let na = ffi::llama_robot_tap_attr_count(model, t);
                    for a in 0..na {
                        let attr_p = ffi::llama_robot_tap_attr(model, t, a);
                        let attr = cstr(attr_p);
                        let dim = ffi::llama_robot_probe_dim(model, t, attr_p);
                        if dim <= 0 {
                            continue;
                        }
                        let mut out = vec![0f32; dim as usize];
                        if ffi::llama_robot_probe_eval(ctx, t, attr_p, out.as_mut_ptr()) {
                            let (cls, conf) = softmax_top(&out);
                            attrs.push((attr, cls, conf));
                        }
                    }
                    s.probes.push(ProbeTap { name, attrs });
                }
            } else {
                s.probes = prev.probes.clone();
            }

            // memory list (newest first). For each entry also read its value
            // vector (modulator space) and report the channel it most strongly
            // re-instates when recalled.
            let md = ffi::llama_robot_mod_dim(model);
            let chan_names: Vec<String> = (0..md)
                .map(|i| {
                    let n = cstr(ffi::llama_robot_mod_channel(model, i));
                    if n.is_empty() { format!("m{i}") } else { n } // latent (unnamed) dims
                })
                .collect();
            let n = ffi::llama_robot_memory_count(ctx);
            s.mem_count = n;
            let show = n.min(64); // ui clips to the memory pane height
            for k in 0..show {
                let idx = n - 1 - k;
                let mut sal = 0f32;
                let mut age = 0u64;
                if ffi::llama_robot_memory_get(ctx, idx, &mut sal, std::ptr::null_mut(), &mut age) {
                    let inject = if md > 0 {
                        let mut val = vec![0f32; md as usize];
                        if ffi::llama_robot_memory_value(ctx, idx, val.as_mut_ptr()) {
                            let mut best = 0usize;
                            for j in 1..val.len() {
                                if val[j].abs() > val[best].abs() {
                                    best = j;
                                }
                            }
                            chan_names.get(best).map(|nm| (nm.clone(), val[best]))
                        } else {
                            None
                        }
                    } else {
                        None
                    };
                    let match_cos = ffi::llama_robot_memory_match(ctx, idx);
                    s.memory.push(MemEntry { idx, salience: sal, age_tokens: age, inject, match_cos });
                }
            }

            // recall magnitude
            if md > 0 {
                let mut r = vec![0f32; md as usize];
                if ffi::llama_robot_memory_recall(ctx, r.as_mut_ptr()) {
                    let nr = r.iter().map(|v| v * v).sum::<f32>().sqrt();
                    s.recall_norm = Some(nr);
                }
            }

            // delta
            if ffi::llama_robot_delta_enabled(ctx) {
                let keep = ffi::llama_robot_delta_keep_rate(ctx);
                let toks = ffi::llama_robot_delta_tokens(ctx);
                s.delta = Some((keep, toks));
            }
        }
        s
    }
}

fn softmax_top(logits: &[f32]) -> (i32, f32) {
    let mx = logits.iter().cloned().fold(f32::NEG_INFINITY, f32::max);
    let z: f32 = logits.iter().map(|v| (v - mx).exp()).sum();
    let mut cls = 0;
    for i in 1..logits.len() {
        if logits[i] > logits[cls] {
            cls = i;
        }
    }
    (cls as i32, (logits[cls] - mx).exp() / z)
}
