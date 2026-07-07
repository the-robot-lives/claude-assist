//! fast-os phase-0 kernel: boots via the Linux Image protocol on QEMU
//! aarch64 `virt` *and* Apple Virtualization (UTM), autodetects its console
//! from the device tree (PL011 on QEMU, virtio-console on Apple VZ), prints
//! a banner, and serves the tiny polling shell `fsh0`.
//!
//! Deliberately minimal — no interrupts, no MMU config, no allocator.
//! This is the roadmap.md Phase 0 exit artifact.

#![no_std]
#![no_main]

mod fdt;
mod pl011;
mod virtio_console;

use core::fmt::{self, Write};
use core::panic::PanicInfo;
use fdt::Fdt;
use pl011::Pl011;
use virtio_console::VirtioConsole;

core::arch::global_asm!(include_str!("boot.s"));

// ─── console abstraction ────────────────────────────────────────────────────

enum Console {
    Pl011(Pl011),
    Virtio(VirtioConsole),
    None,
}

impl Console {
    fn write_bytes(&mut self, s: &[u8]) {
        match self {
            Console::Pl011(u) => {
                for &b in s {
                    u.putb(b);
                }
            }
            Console::Virtio(v) => v.write_bytes(s),
            Console::None => {}
        }
    }

    fn getb(&mut self) -> Option<u8> {
        match self {
            Console::Pl011(u) => u.getb(),
            Console::Virtio(v) => v.getb(),
            Console::None => None,
        }
    }

    fn name(&self) -> &'static str {
        match self {
            Console::Pl011(_) => "PL011 uart (QEMU virt)",
            Console::Virtio(_) => "virtio-console (Apple Virtualization / virtio-mmio)",
            Console::None => "none",
        }
    }
}

static mut CONSOLE: Console = Console::None;

fn console() -> &'static mut Console {
    // Single core, no interrupts: exclusive access by construction.
    unsafe { &mut *core::ptr::addr_of_mut!(CONSOLE) }
}

struct Out;

impl Write for Out {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        // convert \n → \r\n without allocating
        let mut rest = s.as_bytes();
        while let Some(pos) = rest.iter().position(|&b| b == b'\n') {
            console().write_bytes(&rest[..pos]);
            console().write_bytes(b"\r\n");
            rest = &rest[pos + 1..];
        }
        console().write_bytes(rest);
        Ok(())
    }
}

macro_rules! kprint {
    ($($arg:tt)*) => {{ let _ = write!(Out, $($arg)*); }};
}
macro_rules! kprintln {
    () => {{ let _ = writeln!(Out); }};
    ($($arg:tt)*) => {{ let _ = writeln!(Out, $($arg)*); }};
}

// ─── generic timer ──────────────────────────────────────────────────────────

fn counter_ticks() -> u64 {
    let v: u64;
    unsafe { core::arch::asm!("mrs {}, cntvct_el0", out(reg) v) };
    v
}

fn counter_freq() -> u64 {
    let v: u64;
    unsafe { core::arch::asm!("mrs {}, cntfrq_el0", out(reg) v) };
    v
}

fn uptime_ms() -> u64 {
    let f = counter_freq();
    if f == 0 {
        return 0;
    }
    counter_ticks() / (f / 1000).max(1)
}

fn current_el() -> u64 {
    let v: u64;
    unsafe { core::arch::asm!("mrs {}, CurrentEL", out(reg) v) };
    (v >> 2) & 0b11
}

// ─── console detection ──────────────────────────────────────────────────────

fn detect_console(dtb: *const u8) -> Console {
    if let Some(tree) = unsafe { Fdt::new(dtb) } {
        let mut regs = [(0u64, 0u64); 8];

        // QEMU virt: PL011 serial
        if tree.find_all(b"arm,pl011", &mut regs) > 0 {
            return Console::Pl011(Pl011::new(regs[0].0 as usize));
        }

        // Apple VZ (and others): probe virtio-mmio nodes for a console
        let n = tree.find_all(b"virtio,mmio", &mut regs);
        for i in 0..n {
            if let Some(vc) = VirtioConsole::init(regs[i].0 as usize) {
                return Console::Virtio(vc);
            }
        }
        Console::None
    } else {
        // No DTB (unexpected) — assume QEMU virt's fixed PL011.
        Console::Pl011(Pl011::new(0x0900_0000))
    }
}

// ─── fsh0: the polling proto-shell ──────────────────────────────────────────

fn read_line(buf: &mut [u8]) -> usize {
    let mut len = 0;
    loop {
        let Some(b) = console().getb() else {
            core::hint::spin_loop();
            continue;
        };
        match b {
            b'\r' | b'\n' => {
                kprintln!();
                return len;
            }
            0x08 | 0x7f => {
                if len > 0 {
                    len -= 1;
                    kprint!("\x08 \x08");
                }
            }
            0x20..=0x7e => {
                if len < buf.len() {
                    buf[len] = b;
                    len += 1;
                    console().write_bytes(&[b]);
                }
            }
            _ => {}
        }
    }
}

fn run_command(line: &str) {
    let line = line.trim();
    let (cmd, rest) = match line.find(' ') {
        Some(i) => (&line[..i], line[i + 1..].trim()),
        None => (line, ""),
    };
    match cmd {
        "" => {}
        "help" => {
            kprintln!("fsh0 commands:");
            kprintln!("  help          this text");
            kprintln!("  info          kernel/machine info");
            kprintln!("  uptime        ms since boot");
            kprintln!("  echo <text>   print <text>");
            kprintln!("  clear         clear screen");
            kprintln!("  panic         test the panic handler");
        }
        "info" => {
            kprintln!("fast-os {} · aarch64 · Linux Image protocol", env!("CARGO_PKG_VERSION"));
            kprintln!("console:         {}", console().name());
            kprintln!("exception level: EL{}", current_el());
            kprintln!("timer freq:      {} Hz", counter_freq());
        }
        "uptime" => kprintln!("{} ms", uptime_ms()),
        "echo" => kprintln!("{}", rest),
        "clear" => kprint!("\x1b[2J\x1b[H"),
        "panic" => panic!("user-requested test panic"),
        other => kprintln!("fsh0: unknown command '{}' (try: help)", other),
    }
}

// ─── entry ──────────────────────────────────────────────────────────────────

#[no_mangle]
pub extern "C" fn kmain(dtb: *const u8) -> ! {
    unsafe {
        *core::ptr::addr_of_mut!(CONSOLE) = detect_console(dtb);
    }

    let boot_ms = uptime_ms();
    kprintln!();
    kprintln!("+------------------------------------+");
    kprintln!("|  fast-os  --  phase-0 proto-kernel |");
    kprintln!("+------------------------------------+");
    kprintln!("fast-os {}", env!("CARGO_PKG_VERSION"));
    kprintln!("console: {}", console().name());
    kprintln!("boot-to-banner: {} ms · EL{} · type 'help'", boot_ms, current_el());
    kprintln!();

    let mut buf = [0u8; 128];
    loop {
        kprint!("fsh0> ");
        let n = read_line(&mut buf);
        if let Ok(s) = core::str::from_utf8(&buf[..n]) {
            run_command(s);
        }
    }
}

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    kprintln!();
    kprintln!("*** KERNEL PANIC ***");
    kprintln!("{}", info);
    kprintln!("(system halted)");
    loop {
        unsafe { core::arch::asm!("wfe") };
    }
}
