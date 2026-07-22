#!/usr/bin/env node

import { closeSync, fsyncSync, openSync, renameSync, unlinkSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { randomUUID } from "node:crypto";

const [, , targetArg, ...flags] = process.argv;

if (!targetArg || flags.includes("--help") || flags.includes("-h")) {
  console.log(`Usage:
  node bin/atomic-write.js <target-path> [--simulate-failure]

Reads UTF-8 content from stdin, writes it to a temporary sibling file, fsyncs it,
then renames it over the target path. --simulate-failure exits before rename so
tests can confirm the previous target remains intact.`);
  process.exit(targetArg ? 0 : 64);
}

const target = resolve(process.cwd(), targetArg);
const temp = resolve(dirname(target), `.${target.split("/").pop()}.${process.pid}.${randomUUID()}.tmp`);

let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => {
  input += chunk;
});

process.stdin.on("end", () => {
  let fd;
  try {
    fd = openSync(temp, "wx", 0o600);
    writeFileSync(fd, input, "utf8");
    fsyncSync(fd);
    closeSync(fd);
    fd = undefined;

    if (flags.includes("--simulate-failure")) {
      throw new Error("Simulated mid-write failure before rename");
    }

    renameSync(temp, target);
  } catch (err) {
    if (fd !== undefined) closeSync(fd);
    try {
      unlinkSync(temp);
    } catch {
      // Best effort cleanup; preserving the target file is the hard guarantee.
    }
    console.error(`atomic-write failed for ${target}: ${err.message}`);
    process.exit(1);
  }
});

