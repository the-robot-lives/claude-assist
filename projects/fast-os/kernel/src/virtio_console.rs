//! virtio-console driver (virtio-mmio, modern/v2, polled split virtqueues).
//! This is the console device Apple Virtualization exposes to Linux-protocol
//! guests (UTM "Serial" on the Apple backend). Port 0 only, no MULTIPORT.

use core::ptr::{addr_of, addr_of_mut, read_volatile, write_volatile};
use core::sync::atomic::{fence, Ordering};

// ── virtio-mmio registers ───────────────────────────────────────────────────
const MAGIC: usize = 0x00; // 0x74726976 "virt"
const VERSION: usize = 0x04; // 2 = modern
const DEVICE_ID: usize = 0x08; // 3 = console
const DEV_FEAT: usize = 0x10;
const DEV_FEAT_SEL: usize = 0x14;
const DRV_FEAT: usize = 0x20;
const DRV_FEAT_SEL: usize = 0x24;
const QUEUE_SEL: usize = 0x30;
const QUEUE_NUM_MAX: usize = 0x34;
const QUEUE_NUM: usize = 0x38;
const QUEUE_READY: usize = 0x44;
const QUEUE_NOTIFY: usize = 0x50;
const STATUS: usize = 0x70;
const Q_DESC_LO: usize = 0x80;
const Q_DESC_HI: usize = 0x84;
const Q_DRV_LO: usize = 0x90; // avail ring
const Q_DRV_HI: usize = 0x94;
const Q_DEV_LO: usize = 0xa0; // used ring
const Q_DEV_HI: usize = 0xa4;

const ST_ACK: u32 = 1;
const ST_DRIVER: u32 = 2;
const ST_DRIVER_OK: u32 = 4;
const ST_FEATURES_OK: u32 = 8;
const ST_FAILED: u32 = 128;

const F_VERSION_1_HI: u32 = 1; // feature bit 32, in the sel=1 window

const QSZ: usize = 8;
const RXBUF_LEN: usize = 64;
const TXBUF_LEN: usize = 512;
const DESC_F_WRITE: u16 = 2; // device-writable (RX buffers)

// ── virtqueue memory (identity-mapped: VA == PA, MMU off) ───────────────────
#[repr(C)]
#[derive(Copy, Clone)]
struct Desc {
    addr: u64,
    len: u32,
    flags: u16,
    next: u16,
}

#[repr(C)]
struct Avail {
    flags: u16,
    idx: u16,
    ring: [u16; QSZ],
}

#[repr(C)]
#[derive(Copy, Clone)]
struct UsedElem {
    id: u32,
    len: u32,
}

#[repr(C)]
struct Used {
    flags: u16,
    idx: u16,
    ring: [UsedElem; QSZ],
}

#[repr(C, align(4096))]
struct QueueMem {
    desc: [Desc; QSZ], // offset 0, 16-byte entries
    avail: Avail,      // offset 128 (2-aligned: ok)
    _pad: [u8; 108],   // push used ring to offset 256 (4-aligned)
    used: Used,
}

const ZDESC: Desc = Desc { addr: 0, len: 0, flags: 0, next: 0 };
const ZQUEUE: QueueMem = QueueMem {
    desc: [ZDESC; QSZ],
    avail: Avail { flags: 0, idx: 0, ring: [0; QSZ] },
    _pad: [0; 108],
    used: Used { flags: 0, idx: 0, ring: [UsedElem { id: 0, len: 0 }; QSZ] },
};

static mut RXQ: QueueMem = ZQUEUE;
static mut TXQ: QueueMem = ZQUEUE;
static mut RXBUF: [[u8; RXBUF_LEN]; QSZ] = [[0; RXBUF_LEN]; QSZ];
static mut TXBUF: [u8; TXBUF_LEN] = [0; TXBUF_LEN];

// ── driver ──────────────────────────────────────────────────────────────────
pub struct VirtioConsole {
    base: usize,
    rx_last_used: u16,
    tx_last_used: u16,
    /// (desc id, consumed offset, total len) of the RX buffer being drained
    rx_cur: Option<(usize, usize, usize)>,
}

impl VirtioConsole {
    fn rd(base: usize, off: usize) -> u32 {
        unsafe { read_volatile((base + off) as *const u32) }
    }
    fn wr(base: usize, off: usize, v: u32) {
        unsafe { write_volatile((base + off) as *mut u32, v) }
    }

    /// Probe `base`; if it's a modern virtio-mmio console, initialize and
    /// claim it. Only one instance may exist (static queue memory).
    pub fn init(base: usize) -> Option<VirtioConsole> {
        if Self::rd(base, MAGIC) != 0x7472_6976 {
            return None;
        }
        if Self::rd(base, VERSION) != 2 || Self::rd(base, DEVICE_ID) != 3 {
            return None;
        }

        // reset, acknowledge, driver
        Self::wr(base, STATUS, 0);
        Self::wr(base, STATUS, ST_ACK);
        Self::wr(base, STATUS, ST_ACK | ST_DRIVER);

        // negotiate exactly VIRTIO_F_VERSION_1 (bit 32)
        Self::wr(base, DEV_FEAT_SEL, 1);
        if Self::rd(base, DEV_FEAT) & F_VERSION_1_HI == 0 {
            Self::wr(base, STATUS, ST_FAILED);
            return None;
        }
        Self::wr(base, DRV_FEAT_SEL, 0);
        Self::wr(base, DRV_FEAT, 0);
        Self::wr(base, DRV_FEAT_SEL, 1);
        Self::wr(base, DRV_FEAT, F_VERSION_1_HI);
        Self::wr(base, STATUS, ST_ACK | ST_DRIVER | ST_FEATURES_OK);
        if Self::rd(base, STATUS) & ST_FEATURES_OK == 0 {
            Self::wr(base, STATUS, ST_FAILED);
            return None;
        }

        // queue 0 = receiveq, queue 1 = transmitq
        unsafe {
            if !Self::setup_queue(base, 0, addr_of_mut!(RXQ)) {
                Self::wr(base, STATUS, ST_FAILED);
                return None;
            }
            if !Self::setup_queue(base, 1, addr_of_mut!(TXQ)) {
                Self::wr(base, STATUS, ST_FAILED);
                return None;
            }
        }

        Self::wr(base, STATUS, ST_ACK | ST_DRIVER | ST_FEATURES_OK | ST_DRIVER_OK);

        let mut con = VirtioConsole { base, rx_last_used: 0, tx_last_used: 0, rx_cur: None };
        con.post_all_rx();
        Some(con)
    }

    unsafe fn setup_queue(base: usize, q: u32, mem: *mut QueueMem) -> bool {
        Self::wr(base, QUEUE_SEL, q);
        let max = Self::rd(base, QUEUE_NUM_MAX);
        if max == 0 || (max as usize) < QSZ {
            return false;
        }
        Self::wr(base, QUEUE_NUM, QSZ as u32);
        let desc = addr_of!((*mem).desc) as u64;
        let avail = addr_of!((*mem).avail) as u64;
        let used = addr_of!((*mem).used) as u64;
        Self::wr(base, Q_DESC_LO, desc as u32);
        Self::wr(base, Q_DESC_HI, (desc >> 32) as u32);
        Self::wr(base, Q_DRV_LO, avail as u32);
        Self::wr(base, Q_DRV_HI, (avail >> 32) as u32);
        Self::wr(base, Q_DEV_LO, used as u32);
        Self::wr(base, Q_DEV_HI, (used >> 32) as u32);
        Self::wr(base, QUEUE_READY, 1);
        true
    }

    fn post_all_rx(&mut self) {
        unsafe {
            let q = addr_of_mut!(RXQ);
            for i in 0..QSZ {
                (*q).desc[i] = Desc {
                    addr: addr_of!(RXBUF[i]) as u64,
                    len: RXBUF_LEN as u32,
                    flags: DESC_F_WRITE,
                    next: 0,
                };
                let idx = read_volatile(addr_of!((*q).avail.idx));
                write_volatile(
                    addr_of_mut!((*q).avail.ring[(idx as usize) % QSZ]),
                    i as u16,
                );
                fence(Ordering::SeqCst);
                write_volatile(addr_of_mut!((*q).avail.idx), idx.wrapping_add(1));
            }
        }
        fence(Ordering::SeqCst);
        Self::wr(self.base, QUEUE_NOTIFY, 0);
    }

    fn repost_rx(&mut self, desc_id: usize) {
        unsafe {
            let q = addr_of_mut!(RXQ);
            let idx = read_volatile(addr_of!((*q).avail.idx));
            write_volatile(
                addr_of_mut!((*q).avail.ring[(idx as usize) % QSZ]),
                desc_id as u16,
            );
            fence(Ordering::SeqCst);
            write_volatile(addr_of_mut!((*q).avail.idx), idx.wrapping_add(1));
        }
        fence(Ordering::SeqCst);
        Self::wr(self.base, QUEUE_NOTIFY, 0);
    }

    pub fn write_bytes(&mut self, s: &[u8]) {
        for chunk in s.chunks(TXBUF_LEN) {
            unsafe {
                let q = addr_of_mut!(TXQ);
                TXBUF[..chunk.len()].copy_from_slice(chunk);
                (*q).desc[0] = Desc {
                    addr: addr_of!(TXBUF) as u64,
                    len: chunk.len() as u32,
                    flags: 0,
                    next: 0,
                };
                let idx = read_volatile(addr_of!((*q).avail.idx));
                write_volatile(addr_of_mut!((*q).avail.ring[(idx as usize) % QSZ]), 0u16);
                fence(Ordering::SeqCst);
                write_volatile(addr_of_mut!((*q).avail.idx), idx.wrapping_add(1));
                fence(Ordering::SeqCst);
                Self::wr(self.base, QUEUE_NOTIFY, 1);

                // poll for completion (single in-flight TX descriptor)
                let target = self.tx_last_used.wrapping_add(1);
                while read_volatile(addr_of!((*q).used.idx)) != target {
                    core::hint::spin_loop();
                }
                self.tx_last_used = target;
            }
        }
    }

    pub fn getb(&mut self) -> Option<u8> {
        unsafe {
            let q = addr_of_mut!(RXQ);
            if self.rx_cur.is_none() {
                if read_volatile(addr_of!((*q).used.idx)) == self.rx_last_used {
                    return None;
                }
                fence(Ordering::SeqCst);
                let elem = read_volatile(addr_of!(
                    (*q).used.ring[(self.rx_last_used as usize) % QSZ]
                ));
                self.rx_last_used = self.rx_last_used.wrapping_add(1);
                let len = (elem.len as usize).min(RXBUF_LEN);
                if len == 0 {
                    self.repost_rx(elem.id as usize);
                    return None;
                }
                self.rx_cur = Some((elem.id as usize, 0, len));
            }
            let (id, off, len) = self.rx_cur.unwrap();
            let b = read_volatile(addr_of!(RXBUF[id][off]));
            if off + 1 >= len {
                self.rx_cur = None;
                self.repost_rx(id);
            } else {
                self.rx_cur = Some((id, off + 1, len));
            }
            Some(b)
        }
    }
}
