//! File-backed block device. Fixed 4 KiB blocks, auto-extending.
//!
//! Blocks 0 and 1 are reserved for the double-buffered superblock; the bump
//! allocator hands out blocks from index 2 upward.

use crate::Result;
use std::fs::{File, OpenOptions};
use std::io::{Read, Seek, SeekFrom, Write};
use std::path::Path;

pub const BLOCK_SIZE: usize = 4096;
pub const SUPERBLOCK_A: u64 = 0;
pub const SUPERBLOCK_B: u64 = 1;
pub const FIRST_ALLOC_BLOCK: u64 = 2;

pub struct FileDevice {
    file: File,
}

impl FileDevice {
    pub fn create<P: AsRef<Path>>(path: P) -> Result<Self> {
        let file = OpenOptions::new()
            .read(true)
            .write(true)
            .create(true)
            .truncate(true)
            .open(path)?;
        // reserve the two superblock slots so the first data alloc lands at 2
        file.set_len((FIRST_ALLOC_BLOCK * BLOCK_SIZE as u64) as u64)?;
        Ok(FileDevice { file })
    }

    pub fn open<P: AsRef<Path>>(path: P) -> Result<Self> {
        let file = OpenOptions::new().read(true).write(true).open(path)?;
        Ok(FileDevice { file })
    }

    pub fn block_count(&self) -> Result<u64> {
        let len = self.file.metadata()?.len();
        Ok(len / BLOCK_SIZE as u64)
    }

    /// Read one block; zero-fills if the block is past the current file end.
    pub fn read_block(&mut self, idx: u64) -> Result<Vec<u8>> {
        let mut buf = vec![0u8; BLOCK_SIZE];
        let off = idx * BLOCK_SIZE as u64;
        let len = self.file.metadata()?.len();
        if off >= len {
            return Ok(buf); // unwritten region reads as zeros
        }
        self.file.seek(SeekFrom::Start(off))?;
        let avail = (len - off).min(BLOCK_SIZE as u64) as usize;
        self.file.read_exact(&mut buf[..avail])?;
        Ok(buf)
    }

    /// Write one block, extending the file as needed. Caller pads to <= BLOCK_SIZE.
    pub fn write_block(&mut self, idx: u64, data: &[u8]) -> Result<()> {
        assert!(data.len() <= BLOCK_SIZE);
        let off = idx * BLOCK_SIZE as u64;
        let end = off + BLOCK_SIZE as u64;
        if self.file.metadata()?.len() < end {
            self.file.set_len(end)?;
        }
        let mut block = vec![0u8; BLOCK_SIZE];
        block[..data.len()].copy_from_slice(data);
        self.file.seek(SeekFrom::Start(off))?;
        self.file.write_all(&block)?;
        Ok(())
    }

    pub fn flush(&mut self) -> Result<()> {
        self.file.flush()?;
        self.file.sync_all()?;
        Ok(())
    }
}
