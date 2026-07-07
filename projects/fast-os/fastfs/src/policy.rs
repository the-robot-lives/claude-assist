//! Per-directory/-file redundancy placement policy.
//!
//! This is the design's headline feature: redundancy is an inheritable
//! attribute on any directory subtree, resolved at write time — not a
//! property of the whole pool.

use crate::codec::{Reader, Writer};
use crate::{FsError, Result};
use std::fmt;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Policy {
    /// One copy — fastest, no redundancy.
    Single,
    /// N real replicas (RAID1-style). `scrub` verifies and self-heals.
    Mirror(u8),
    /// N-way striping for throughput (modeled as N logical slots; no parity).
    Stripe(u8),
}

impl Policy {
    /// How many physical copies of each data block this policy writes.
    pub fn replicas(&self) -> usize {
        match self {
            Policy::Single => 1,
            Policy::Mirror(n) => (*n).max(1) as usize,
            Policy::Stripe(_) => 1,
        }
    }

    pub fn encode(&self, w: &mut Writer) {
        match self {
            Policy::Single => {
                w.u8(0);
                w.u8(1);
            }
            Policy::Mirror(n) => {
                w.u8(1);
                w.u8(*n);
            }
            Policy::Stripe(n) => {
                w.u8(2);
                w.u8(*n);
            }
        }
    }

    pub fn decode(r: &mut Reader) -> Result<Policy> {
        let mode = r.u8()?;
        let n = r.u8()?;
        match mode {
            0 => Ok(Policy::Single),
            1 => Ok(Policy::Mirror(n.max(1))),
            2 => Ok(Policy::Stripe(n.max(1))),
            other => Err(FsError::Corrupt(format!("bad policy mode {other}"))),
        }
    }

    /// Parse `single`, `mirror:2`, `stripe:4`.
    pub fn parse(s: &str) -> Result<Policy> {
        let s = s.trim();
        if s == "single" {
            return Ok(Policy::Single);
        }
        let (kind, n) = match s.split_once(':') {
            Some((k, n)) => (
                k,
                n.parse::<u8>()
                    .map_err(|_| FsError::Invalid(format!("bad replica count in '{s}'")))?,
            ),
            None => (s, 0),
        };
        match kind {
            "mirror" => {
                if n < 1 {
                    return Err(FsError::Invalid("mirror needs :N >= 1".into()));
                }
                Ok(Policy::Mirror(n))
            }
            "stripe" => {
                if n < 1 {
                    return Err(FsError::Invalid("stripe needs :N >= 1".into()));
                }
                Ok(Policy::Stripe(n))
            }
            _ => Err(FsError::Invalid(format!("unknown policy '{s}'"))),
        }
    }
}

impl fmt::Display for Policy {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Policy::Single => write!(f, "single"),
            Policy::Mirror(n) => write!(f, "mirror:{n}"),
            Policy::Stripe(n) => write!(f, "stripe:{n}"),
        }
    }
}
