//! fast-os phase-0 kernel: boot on QEMU aarch64 `virt`, print a banner,
//! and serve a tiny polling shell (`fsh0`) over the PL011 UART.
//!
//! Deliberately minimal — no interrupts, no MMU config, no allocator.
//! This exists to prove the toolchain, boot path, and dev loop
//! (roadmap.md Phase 0).

#![no_std]
#![no_main]

use core::fmt::{self, Write};
use core::panic::PanicInfo;

core::arch::global_asm!(include_str!("boot.s"));

// ─── PL011 UART (QEMU virt board, fixed at 0x0900_0000) ────────────────────

const UART_BASE: usize = 0x0900_0000;
const UART_DR: *mut u32 = UART_BASE as *mut u32;
const UART_FR: *mut u32 = (UART_BASE + 0x18) as *mut u32;
const FR_TXFF: u32 = 1 << 5; // transmit FIFO full
const FR_RXFE: u32 = 1 << 4; // receive FIFO empty

fn putb(b: u8) {
    unsafe {
        while UART_FR.read_volatile() & FR_TXFF != 0 {}
        UART_DR.write_volatile(b as u32);
    }
}

fn getb() -> Option<u8> {
    unsafe {
        if UART_FR.read_volatile() & FR_RXFE != 0 {
            None
        } else {
            Some((UART_DR.read_volatile() & 0xff) as u8)
        }
    }
}

struct Uart;

impl Write for Uart {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for b in s.bytes() {
            if b == b'\n' {
                putb(b'\r');
            }
            putb(b);
        }
        Ok(())
    }
}

macro_rules! kprint {
    ($($arg:tt)*) => {{ let _ = write!(Uart, $($arg)*); }};
}
macro_rules! kprintln {
    () => {{ let _ = writeln!(Uart); }};
    ($($arg:tt)*) => {{ let _ = writeln!(Uart, $($arg)*); }};
}

// ─── Generic timer ──────────────────────────────────────────────────────────

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

// ─── fsh0: the polling proto-shell ──────────────────────────────────────────

fn read_line(buf: &mut [u8]) -> usize {
    let mut len = 0;
    loop {
        let Some(b) = getb() else {
            core::hint::spin_loop();
            continue;
        };
        match b {
            b'\r' | b'\n' => {
                kprintln!();
                return len;
            }
            0x08 | 0x7f => {
                // backspace / delete
                if len > 0 {
                    len -= 1;
                    kprint!("\x08 \x08");
                }
            }
            0x20..=0x7e => {
                if len < buf.len() {
                    buf[len] = b;
                    len += 1;
                    putb(b);
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
            kprintln!("  (exit qemu:   Ctrl-a x)");
        }
        "info" => {
            kprintln!("fast-os {} · aarch64 · QEMU virt", env!("CARGO_PKG_VERSION"));
            kprintln!("exception level: EL{}", current_el());
            kprintln!("timer freq:      {} Hz", counter_freq());
            kprintln!("uart:            PL011 @ {:#x} (polled)", UART_BASE);
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
pub extern "C" fn kmain() -> ! {
    let boot_ms = uptime_ms();
    kprintln!();
    kprintln!("+------------------------------------+");
    kprintln!("|  fast-os  --  phase-0 proto-kernel |");
    kprintln!("+------------------------------------+");
    kprintln!("fast-os {}", env!("CARGO_PKG_VERSION"));
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
    kprintln!("(system halted — Ctrl-a x to exit qemu)");
    loop {
        unsafe { core::arch::asm!("wfe") };
    }
}
