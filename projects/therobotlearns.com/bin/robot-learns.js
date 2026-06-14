#!/usr/bin/env node

import { execSync, execFileSync } from "node:child_process";
import { existsSync, cpSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { randomUUID } from "node:crypto";
import { homedir } from "node:os";

const __dirname = dirname(fileURLToPath(import.meta.url));
const CONFIG_DIR = join(homedir(), ".config", "the-robot-learns-kb");
const TEMPLATE = join(__dirname, "..", "template");

if (!existsSync(CONFIG_DIR)) {
  console.log(`First run — bootstrapping knowledge base at ${CONFIG_DIR}`);

  if (!existsSync(TEMPLATE)) {
    console.error(`Error: template not found at ${TEMPLATE}`);
    process.exit(1);
  }

  cpSync(TEMPLATE, CONFIG_DIR, { recursive: true });
  writeFileSync(join(CONFIG_DIR, ".system-id"), randomUUID() + "\n");
  console.log("Done. Launching knowledge base agent...");
}

const args = process.argv.slice(2);
const claudeArgs = args.length > 0
  ? ["/knowledge-base-query", args.join(" ")]
  : [];

try {
  execFileSync("claude", claudeArgs, {
    cwd: CONFIG_DIR,
    stdio: "inherit",
  });
} catch (err) {
  if (err.status) process.exit(err.status);
  throw err;
}
