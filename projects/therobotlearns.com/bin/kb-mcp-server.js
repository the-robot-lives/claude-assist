#!/usr/bin/env node

import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { basename, extname, join, relative } from "node:path";
import { homedir } from "node:os";

const CONFIG_DIR = process.env.TRL_KB_DIR || join(homedir(), ".config", "the-robot-learns-kb");
let buffer = Buffer.alloc(0);

function walk(dir, predicate = () => true) {
  if (!existsSync(dir)) return [];
  const out = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const path = join(dir, entry.name);
    if (entry.name === ".DS_Store" || entry.name === ".lock") continue;
    if (entry.isDirectory()) out.push(...walk(path, predicate));
    else if (predicate(path)) out.push(path);
  }
  return out;
}

function extractFrontmatter(text) {
  if (!text.startsWith("---\n")) return {};
  const end = text.indexOf("\n---", 4);
  if (end === -1) return {};
  const data = {};
  for (const line of text.slice(4, end).split(/\r?\n/)) {
    const match = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (match) data[match[1]] = match[2].replace(/^["']|["']$/g, "");
  }
  return data;
}

function articleFiles() {
  return walk(join(CONFIG_DIR, "knowledge"), (path) => path.endsWith(".md"));
}

function readArticle(path) {
  const text = readFileSync(path, "utf8");
  const meta = extractFrontmatter(text);
  return {
    path,
    rel: relative(join(CONFIG_DIR, "knowledge"), path),
    text,
    title: meta.title || basename(path, extname(path)),
    updated: meta.updated || statSync(path).mtime.toISOString().slice(0, 10),
  };
}

function textContent(text) {
  return { content: [{ type: "text", text }] };
}

function callTool(name, args = {}) {
  if (name === "stats") {
    const articles = articleFiles();
    const decks = walk(join(CONFIG_DIR, "flashcards"), (p) => p.endsWith(".yaml")).length;
    const quizzes = walk(join(CONFIG_DIR, "quizzes"), (p) => p.endsWith(".yaml")).length;
    return textContent(`Articles: ${articles.length}\nFlashcard decks: ${decks}\nQuizzes: ${quizzes}`);
  }
  if (name === "search") {
    const term = String(args.term || "").toLowerCase();
    const rows = articleFiles()
      .map(readArticle)
      .filter((article) => `${article.title}\n${article.text}`.toLowerCase().includes(term))
      .slice(0, 20)
      .map((article) => `${article.rel}: ${article.title}`);
    return textContent(rows.length ? rows.join("\n") : "No results.");
  }
  if (name === "view_article") {
    const wanted = String(args.path || "");
    const article = articleFiles().map(readArticle).find((item) => item.rel === wanted || item.rel === `${wanted}.md` || item.title === wanted);
    if (!article) return textContent(`Article not found: ${wanted}`);
    return textContent(article.text.replace(/^---[\s\S]*?---\n/, "").trim());
  }
  throw new Error(`Unknown tool: ${name}`);
}

function send(message) {
  const body = Buffer.from(JSON.stringify(message), "utf8");
  process.stdout.write(`Content-Length: ${body.length}\r\n\r\n`);
  process.stdout.write(body);
}

function handle(message) {
  if (!message.id && message.method?.startsWith("notifications/")) return;
  try {
    if (message.method === "initialize") {
      send({
        jsonrpc: "2.0",
        id: message.id,
        result: {
          protocolVersion: "2024-11-05",
          capabilities: { tools: {} },
          serverInfo: { name: "the-robot-learns-kb", version: "0.1.0" },
        },
      });
      return;
    }
    if (message.method === "tools/list") {
      send({
        jsonrpc: "2.0",
        id: message.id,
        result: {
          tools: [
            { name: "stats", description: "Show workspace KB counts.", inputSchema: { type: "object", properties: {} } },
            { name: "search", description: "Search workspace KB articles.", inputSchema: { type: "object", properties: { term: { type: "string" } }, required: ["term"] } },
            { name: "view_article", description: "Read a KB article.", inputSchema: { type: "object", properties: { path: { type: "string" } }, required: ["path"] } },
          ],
        },
      });
      return;
    }
    if (message.method === "tools/call") {
      send({ jsonrpc: "2.0", id: message.id, result: callTool(message.params?.name, message.params?.arguments) });
      return;
    }
    send({ jsonrpc: "2.0", id: message.id, result: {} });
  } catch (err) {
    send({ jsonrpc: "2.0", id: message.id, error: { code: -32000, message: err.message } });
  }
}

function drain() {
  while (true) {
    const headerEnd = buffer.indexOf("\r\n\r\n");
    if (headerEnd === -1) return;
    const header = buffer.slice(0, headerEnd).toString("utf8");
    const match = header.match(/Content-Length:\s*(\d+)/i);
    if (!match) {
      buffer = buffer.slice(headerEnd + 4);
      continue;
    }
    const length = Number(match[1]);
    const bodyStart = headerEnd + 4;
    if (buffer.length < bodyStart + length) return;
    const body = buffer.slice(bodyStart, bodyStart + length).toString("utf8");
    buffer = buffer.slice(bodyStart + length);
    handle(JSON.parse(body));
  }
}

process.stdin.on("data", (chunk) => {
  buffer = Buffer.concat([buffer, chunk]);
  drain();
});
