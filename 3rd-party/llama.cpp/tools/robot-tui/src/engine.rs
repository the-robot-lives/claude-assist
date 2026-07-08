//! Model lifecycle + turn-based generation over the C-ABI, using the robot-ffi
//! sampler (common_sampler parity) and llama.cpp's own chat template.

use crate::ffi;
use anyhow::{anyhow, Result};
use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::ptr;

pub struct Engine {
    model: *const ffi::llama_model,
    ctx: *mut ffi::llama_context,
    vocab: *const ffi::llama_vocab,
    sampler: *mut ffi::robot_sampler,
    n_vocab: i32,
    tmpl: *const c_char, // borrowed from the model; may be null
    sp: ffi::robot_sampler_params,

    // chat state
    msgs_role: Vec<CString>,
    msgs_content: Vec<CString>,
    fmt: Vec<c_char>,
    prev_len: i32,
    first: bool,

    // in-flight generation
    pub generating: bool,
    pub current: String, // assistant text so far this turn
}

impl Engine {
    pub fn load(path: &str, n_ctx: u32) -> Result<Engine> {
        unsafe {
            ffi::robot_silence_logs(); // mute llama + ggml/Metal logs so they don't corrupt the TUI
            ffi::llama_backend_init();
            let mp = ffi::llama_model_default_params();
            let cpath = CString::new(path)?;
            let model = ffi::llama_model_load_from_file(cpath.as_ptr(), mp);
            if model.is_null() {
                return Err(anyhow!("failed to load model: {path}"));
            }
            let mut cp = ffi::llama_context_default_params();
            cp.n_ctx = n_ctx;
            cp.n_batch = n_ctx.max(2048);
            let ctx = ffi::llama_init_from_model(model, cp);
            if ctx.is_null() {
                return Err(anyhow!("failed to create context"));
            }
            let vocab = ffi::llama_model_get_vocab(model);
            let n_vocab = ffi::llama_vocab_n_tokens(vocab);

            let sp = ffi::robot_sampler_default_params();
            let sampler = ffi::robot_sampler_init(model, sp);
            if sampler.is_null() {
                return Err(anyhow!("failed to init sampler"));
            }
            let tmpl = ffi::llama_model_chat_template(model, ptr::null());

            Ok(Engine {
                model,
                ctx,
                vocab,
                sampler,
                n_vocab,
                tmpl,
                sp,
                msgs_role: Vec::new(),
                msgs_content: Vec::new(),
                fmt: vec![0 as c_char; n_ctx as usize],
                prev_len: 0,
                first: true,
                generating: false,
                current: String::new(),
            })
        }
    }

    pub fn robot_enabled(&self) -> bool {
        unsafe { ffi::llama_robot_enabled(self.model) }
    }
    pub fn ctx(&self) -> *mut ffi::llama_context {
        self.ctx
    }
    pub fn model(&self) -> *const ffi::llama_model {
        self.model
    }

    fn push_msg(&mut self, role: &str, content: &str) {
        self.msgs_role.push(CString::new(role).unwrap());
        self.msgs_content.push(CString::new(content).unwrap());
    }

    fn chat_messages(&self) -> Vec<ffi::llama_chat_message> {
        self.msgs_role
            .iter()
            .zip(self.msgs_content.iter())
            .map(|(r, c)| ffi::llama_chat_message {
                role: r.as_ptr(),
                content: c.as_ptr(),
            })
            .collect()
    }

    /// Format the running conversation, feed the new delta to the context, and
    /// begin streaming an assistant turn. Falls back to raw text if no template.
    pub fn begin_turn(&mut self, user: &str) -> Result<()> {
        self.push_msg("user", user);
        let prompt: String = if !self.tmpl.is_null() {
            let msgs = self.chat_messages();
            let mut new_len = unsafe {
                ffi::llama_chat_apply_template(
                    self.tmpl,
                    msgs.as_ptr(),
                    msgs.len(),
                    true,
                    self.fmt.as_mut_ptr(),
                    self.fmt.len() as i32,
                )
            };
            if new_len > self.fmt.len() as i32 {
                self.fmt.resize(new_len as usize, 0);
                new_len = unsafe {
                    ffi::llama_chat_apply_template(
                        self.tmpl,
                        msgs.as_ptr(),
                        msgs.len(),
                        true,
                        self.fmt.as_mut_ptr(),
                        self.fmt.len() as i32,
                    )
                };
            }
            if new_len < 0 {
                return Err(anyhow!("chat template apply failed"));
            }
            let slice = &self.fmt[self.prev_len as usize..new_len as usize];
            let bytes: Vec<u8> = slice.iter().map(|&c| c as u8).collect();
            String::from_utf8_lossy(&bytes).into_owned()
        } else {
            user.to_string()
        };

        let mut toks = self.tokenize(&prompt, self.first);
        self.first = false;
        unsafe {
            let batch = ffi::llama_batch_get_one(toks.as_mut_ptr(), toks.len() as i32);
            if ffi::llama_decode(self.ctx, batch) != 0 {
                return Err(anyhow!("prompt decode failed"));
            }
        }
        self.current.clear();
        self.generating = true;
        Ok(())
    }

    /// Advance generation by one token. Returns Some(piece) while streaming,
    /// None when the turn finished (assistant message committed).
    pub fn step(&mut self) -> Option<String> {
        if !self.generating {
            return None;
        }
        unsafe {
            let tok = ffi::robot_sampler_sample(self.sampler, self.ctx, -1);
            if tok < 0 || ffi::llama_vocab_is_eog(self.vocab, tok) {
                self.finish_turn();
                return None;
            }
            ffi::robot_sampler_accept(self.sampler, tok);
            let piece = self.piece(tok);
            self.current.push_str(&piece);
            let mut one = [tok];
            let b = ffi::llama_batch_get_one(one.as_mut_ptr(), 1);
            if ffi::llama_decode(self.ctx, b) != 0 {
                self.finish_turn();
                return None;
            }
            Some(piece)
        }
    }

    fn finish_turn(&mut self) {
        self.generating = false;
        let content = self.current.clone();
        self.push_msg("assistant", &content);
        if !self.tmpl.is_null() {
            let msgs = self.chat_messages();
            let n = unsafe {
                ffi::llama_chat_apply_template(
                    self.tmpl,
                    msgs.as_ptr(),
                    msgs.len(),
                    false,
                    self.fmt.as_mut_ptr(),
                    self.fmt.len() as i32,
                )
            };
            self.prev_len = if n > 0 { n } else { 0 };
        }
    }

    /// current sampler params (for the editor to seed itself)
    pub fn sampler_params(&self) -> ffi::robot_sampler_params {
        self.sp
    }

    /// Rebuild the sampler chain from new params. Safe between decode steps
    /// (generation is main-thread here, so no concurrent backend use).
    pub fn set_sampler_params(&mut self, sp: ffi::robot_sampler_params) {
        self.sp = sp;
        unsafe {
            if !self.sampler.is_null() {
                ffi::robot_sampler_free(self.sampler);
            }
            self.sampler = ffi::robot_sampler_init(self.model, self.sp);
        }
    }

    /// Prime the modulator's first channel (arousal). No-op for stock models.
    pub fn set_arousal(&mut self, arousal: f32) {
        unsafe {
            let md = ffi::llama_robot_mod_dim(self.model);
            if md > 0 {
                let mut mm = vec![0f32; md as usize];
                mm[0] = arousal;
                ffi::llama_robot_mod_set(self.ctx, mm.as_mut_ptr());
            }
        }
    }

    pub fn reset_session(&mut self, forget_memory: bool) {
        unsafe {
            ffi::llama_robot_session_reset(self.ctx, forget_memory);
            ffi::llama_memory_clear(ffi::llama_get_memory(self.ctx), true);
            ffi::robot_sampler_reset(self.sampler);
        }
        self.msgs_role.clear();
        self.msgs_content.clear();
        self.prev_len = 0;
        self.first = true;
        self.generating = false;
        self.current.clear();
    }

    fn tokenize(&self, s: &str, bos: bool) -> Vec<ffi::llama_token> {
        unsafe {
            let n = -ffi::llama_tokenize(
                self.vocab,
                s.as_ptr() as *const c_char,
                s.len() as i32,
                ptr::null_mut(),
                0,
                bos,
                true,
            );
            let mut out = vec![0 as ffi::llama_token; n as usize];
            ffi::llama_tokenize(
                self.vocab,
                s.as_ptr() as *const c_char,
                s.len() as i32,
                out.as_mut_ptr(),
                n,
                bos,
                true,
            );
            out
        }
    }

    fn piece(&self, tok: ffi::llama_token) -> String {
        unsafe {
            let mut buf = [0 as c_char; 256];
            let n = ffi::llama_token_to_piece(self.vocab, tok, buf.as_mut_ptr(), buf.len() as i32, 0, true);
            if n <= 0 {
                return String::new();
            }
            let bytes: Vec<u8> = buf[..n as usize].iter().map(|&c| c as u8).collect();
            String::from_utf8_lossy(&bytes).into_owned()
        }
    }
}

impl Drop for Engine {
    fn drop(&mut self) {
        unsafe {
            if !self.sampler.is_null() {
                ffi::robot_sampler_free(self.sampler);
            }
            if !self.ctx.is_null() {
                ffi::llama_free(self.ctx);
            }
            if !self.model.is_null() {
                ffi::llama_model_free(self.model as *mut _);
            }
            ffi::llama_backend_free();
        }
    }
}

/// Utility: read a C string pointer into an owned String (empty if null).
pub fn cstr(p: *const c_char) -> String {
    if p.is_null() {
        return String::new();
    }
    unsafe { CStr::from_ptr(p).to_string_lossy().into_owned() }
}
