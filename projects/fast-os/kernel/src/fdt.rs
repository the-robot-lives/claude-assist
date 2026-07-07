//! Minimal flattened-device-tree (DTB) scanner.
//! Just enough to find nodes by `compatible` string and read their `reg`
//! — no allocation, no full property model.

use core::ptr::read_unaligned;

const FDT_MAGIC: u32 = 0xd00d_feed;
const FDT_BEGIN_NODE: u32 = 1;
const FDT_END_NODE: u32 = 2;
const FDT_PROP: u32 = 3;
const FDT_NOP: u32 = 4;
const FDT_END: u32 = 9;

const MAX_DEPTH: usize = 24;

pub struct Fdt {
    base: *const u8,
    total: usize,
    off_struct: usize,
    off_strings: usize,
}

#[derive(Copy, Clone, Default)]
struct Frame {
    compat_match: bool,
    reg: Option<(u64, u64)>,
}

impl Fdt {
    /// # Safety
    /// `p` must point at a readable DTB blob (or garbage — we validate the
    /// header before touching anything else).
    pub unsafe fn new(p: *const u8) -> Option<Fdt> {
        if p.is_null() || (p as usize) & 0x3 != 0 {
            return None;
        }
        let be32 = |off: usize| -> u32 { u32::from_be(read_unaligned(p.add(off) as *const u32)) };
        if be32(0) != FDT_MAGIC {
            return None;
        }
        let total = be32(4) as usize;
        if total < 64 || total > 16 * 1024 * 1024 {
            return None;
        }
        Some(Fdt {
            base: p,
            total,
            off_struct: be32(8) as usize,
            off_strings: be32(12) as usize,
        })
    }

    fn be32(&self, off: usize) -> u32 {
        unsafe { u32::from_be(read_unaligned(self.base.add(off) as *const u32)) }
    }

    fn be64(&self, off: usize) -> u64 {
        unsafe { u64::from_be(read_unaligned(self.base.add(off) as *const u64)) }
    }

    fn byte(&self, off: usize) -> u8 {
        unsafe { *self.base.add(off) }
    }

    /// Does the C string at strings-block offset `nameoff` equal `name`?
    fn prop_name_is(&self, nameoff: usize, name: &[u8]) -> bool {
        let start = self.off_strings + nameoff;
        if start + name.len() + 1 > self.total {
            return false;
        }
        for (i, &b) in name.iter().enumerate() {
            if self.byte(start + i) != b {
                return false;
            }
        }
        self.byte(start + name.len()) == 0
    }

    /// Is `needle` one of the nul-separated strings in prop data [off, off+len)?
    fn compat_contains(&self, off: usize, len: usize, needle: &[u8]) -> bool {
        let mut item_start = 0usize;
        let mut i = 0usize;
        while i < len {
            if self.byte(off + i) == 0 {
                if i - item_start == needle.len() {
                    let mut ok = true;
                    for (j, &b) in needle.iter().enumerate() {
                        if self.byte(off + item_start + j) != b {
                            ok = false;
                            break;
                        }
                    }
                    if ok {
                        return true;
                    }
                }
                item_start = i + 1;
            }
            i += 1;
        }
        false
    }

    fn parse_reg(&self, off: usize, len: usize) -> Option<(u64, u64)> {
        if len >= 16 {
            Some((self.be64(off), self.be64(off + 8))) // #address/#size-cells = 2/2
        } else if len >= 8 {
            Some((self.be32(off) as u64, self.be32(off + 4) as u64)) // 1/1
        } else {
            None
        }
    }

    /// Find every node whose `compatible` list contains `needle`; write its
    /// (reg base, reg size) into `out`. Returns the match count (capped at
    /// `out.len()`).
    pub fn find_all(&self, needle: &[u8], out: &mut [(u64, u64)]) -> usize {
        let mut frames = [Frame::default(); MAX_DEPTH];
        let mut depth: usize = 0;
        let mut found = 0usize;
        let mut off = self.off_struct;

        loop {
            if off + 4 > self.total || found >= out.len() {
                break;
            }
            match self.be32(off) {
                FDT_BEGIN_NODE => {
                    off += 4;
                    while off < self.total && self.byte(off) != 0 {
                        off += 1; // skip node name
                    }
                    off = (off + 1 + 3) & !3;
                    if depth < MAX_DEPTH {
                        frames[depth] = Frame::default();
                    }
                    depth += 1;
                }
                FDT_PROP => {
                    let len = self.be32(off + 4) as usize;
                    let nameoff = self.be32(off + 8) as usize;
                    let data = off + 12;
                    if data + len > self.total {
                        break;
                    }
                    if depth >= 1 && depth <= MAX_DEPTH {
                        let f = &mut frames[depth - 1];
                        if self.prop_name_is(nameoff, b"compatible")
                            && self.compat_contains(data, len, needle)
                        {
                            f.compat_match = true;
                        } else if self.prop_name_is(nameoff, b"reg") {
                            f.reg = self.parse_reg(data, len);
                        }
                    }
                    off = (data + len + 3) & !3;
                }
                FDT_END_NODE => {
                    if depth >= 1 && depth <= MAX_DEPTH {
                        let f = frames[depth - 1];
                        if f.compat_match {
                            if let Some(r) = f.reg {
                                out[found] = r;
                                found += 1;
                            }
                        }
                    }
                    depth = depth.saturating_sub(1);
                    off += 4;
                }
                FDT_NOP => off += 4,
                FDT_END => break,
                _ => break, // corrupt tree — bail with what we have
            }
        }
        found
    }
}
