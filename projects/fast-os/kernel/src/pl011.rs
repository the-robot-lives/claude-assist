//! PL011 UART, polled. Present on QEMU's `virt` machine (not on Apple
//! Virtualization — that path uses virtio-console instead).

pub struct Pl011 {
    base: usize,
}

const DR: usize = 0x00;
const FR: usize = 0x18;
const FR_TXFF: u32 = 1 << 5;
const FR_RXFE: u32 = 1 << 4;

impl Pl011 {
    pub fn new(base: usize) -> Pl011 {
        Pl011 { base }
    }

    fn reg(&self, off: usize) -> *mut u32 {
        (self.base + off) as *mut u32
    }

    pub fn putb(&mut self, b: u8) {
        unsafe {
            while self.reg(FR).read_volatile() & FR_TXFF != 0 {}
            self.reg(DR).write_volatile(b as u32);
        }
    }

    pub fn getb(&mut self) -> Option<u8> {
        unsafe {
            if self.reg(FR).read_volatile() & FR_RXFE != 0 {
                None
            } else {
                Some((self.reg(DR).read_volatile() & 0xff) as u8)
            }
        }
    }
}
