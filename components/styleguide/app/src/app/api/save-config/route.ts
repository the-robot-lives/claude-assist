import { NextRequest, NextResponse } from "next/server";
import fs from "fs";
import path from "path";
import * as yaml from "js-yaml";

const CONFIG_ROOT = path.join(process.cwd(), "src", "config");
const THEME_DIR = path.join(CONFIG_ROOT, "theme-style-guide");
const OVERRIDES_FILE = path.join(THEME_DIR, "style-guide.overrides.yaml");

function slugify(name: string): string {
  return name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}

function resolveThemeDir(themeSlug?: string): string {
  if (!themeSlug) return THEME_DIR;
  const dir = path.join(CONFIG_ROOT, `theme-${themeSlug}`);
  if (!dir.startsWith(CONFIG_ROOT)) throw new Error("Invalid theme path");
  return dir;
}

function readManifest(dir?: string): { overrides: Record<string, string | null> } {
  const file = path.join(dir || THEME_DIR, "style-guide.overrides.yaml");
  if (!fs.existsSync(file)) return { overrides: {} };
  try {
    const raw = fs.readFileSync(file, "utf-8");
    const parsed = yaml.load(raw) as { overrides?: Record<string, string | null> };
    return { overrides: parsed?.overrides ?? {} };
  } catch {
    return { overrides: {} };
  }
}

function writeManifest(manifest: { overrides: Record<string, string | null> }, dir?: string) {
  const file = path.join(dir || THEME_DIR, "style-guide.overrides.yaml");
  fs.writeFileSync(file, yaml.dump(manifest, { lineWidth: -1 }), "utf-8");
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { action } = body as { action: string };

    // ─── Save a named variant ───
    if (action === "save") {
      const { section, variant, content } = body as {
        action: string; section: string; variant: string; content: string;
      };
      if (!section || !variant || !content) {
        return NextResponse.json({ error: "Missing section, variant, or content" }, { status: 400 });
      }
      const filename = `style-guide.${section}.${variant}.yaml`;
      const filePath = path.join(THEME_DIR, filename);
      if (!filePath.startsWith(THEME_DIR)) {
        return NextResponse.json({ error: "Invalid path" }, { status: 400 });
      }
      fs.writeFileSync(filePath, content, "utf-8");
      return NextResponse.json({ saved: filename });
    }

    // ─── Set override: activate a variant for a section ───
    if (action === "set-override") {
      const { section, variant } = body as { action: string; section: string; variant: string | null };
      const manifest = readManifest();
      if (variant) {
        manifest.overrides[section] = variant;
      } else {
        delete manifest.overrides[section];
      }
      writeManifest(manifest);
      return NextResponse.json({ overrides: manifest.overrides });
    }

    // ─── Get manifest + available variants ───
    if (action === "get-overrides") {
      const manifest = readManifest();
      const files = fs.readdirSync(THEME_DIR).filter((f) =>
        f.startsWith("style-guide.") && f.endsWith(".yaml") && f !== "style-guide.overrides.yaml"
      );
      const variants: Record<string, string[]> = {};
      for (const f of files) {
        const withoutExt = f.replace(".yaml", "").replace("style-guide.", "");
        const parts = withoutExt.split(".");
        if (parts.length === 2) {
          const [sec, v] = parts;
          if (!variants[sec]) variants[sec] = [];
          variants[sec].push(v);
        }
      }
      return NextResponse.json({ overrides: manifest.overrides, variants });
    }

    // ─── List all themes ───
    if (action === "list-themes") {
      const dirs = fs.readdirSync(CONFIG_ROOT)
        .filter((d) => d.startsWith("theme-") && fs.statSync(path.join(CONFIG_ROOT, d)).isDirectory());
      const themes = dirs.map((d) => {
        const metaFile = path.join(CONFIG_ROOT, d, "style-guide.meta.yaml");
        if (!fs.existsSync(metaFile)) return null;
        const meta = yaml.load(fs.readFileSync(metaFile, "utf-8")) as { slug?: string; name?: string; title?: string; description?: string };
        const themeDir = path.join(CONFIG_ROOT, d);
        const files = fs.readdirSync(themeDir).filter((f) => f.endsWith(".yaml")).sort();
        return {
          slug: meta.slug || d.replace("theme-", ""),
          name: meta.name || d,
          title: meta.title || "",
          description: meta.description || "",
          dir: d,
          files,
        };
      }).filter(Boolean);
      return NextResponse.json({ themes });
    }

    // ─── Get theme files (read all YAML for a theme) ───
    if (action === "get-theme-files") {
      const { theme } = body as { action: string; theme: string };
      if (!theme) return NextResponse.json({ error: "Missing theme" }, { status: 400 });
      const dir = resolveThemeDir(theme);
      if (!fs.existsSync(dir)) {
        return NextResponse.json({ error: `Theme '${theme}' not found` }, { status: 404 });
      }
      const files = fs.readdirSync(dir).filter((f) => f.endsWith(".yaml")).sort();
      const contents: Record<string, string> = {};
      for (const f of files) {
        contents[f] = fs.readFileSync(path.join(dir, f), "utf-8");
      }
      return NextResponse.json({ theme, files, contents });
    }

    // ─── Save a single theme file ───
    if (action === "save-theme-file") {
      const { theme, filename, content } = body as {
        action: string; theme: string; filename: string; content: string;
      };
      if (!theme || !filename || content === undefined) {
        return NextResponse.json({ error: "Missing theme, filename, or content" }, { status: 400 });
      }
      if (!filename.endsWith(".yaml")) {
        return NextResponse.json({ error: "Only .yaml files allowed" }, { status: 400 });
      }
      const dir = resolveThemeDir(theme);
      const filePath = path.join(dir, path.basename(filename));
      if (!filePath.startsWith(dir)) {
        return NextResponse.json({ error: "Invalid path" }, { status: 400 });
      }
      if (!fs.existsSync(dir)) {
        return NextResponse.json({ error: `Theme '${theme}' not found` }, { status: 404 });
      }
      // Validate YAML parses
      try { yaml.load(content); } catch (e) {
        return NextResponse.json({ error: `Invalid YAML: ${e}` }, { status: 400 });
      }
      fs.writeFileSync(filePath, content, "utf-8");
      return NextResponse.json({ saved: filename, theme });
    }

    // ─── Clone a theme ───
    if (action === "clone-theme") {
      const { source, newSlug, newName } = body as {
        action: string; source: string; newSlug: string; newName: string;
      };
      if (!source || !newSlug || !newName) {
        return NextResponse.json({ error: "Missing source, newSlug, or newName" }, { status: 400 });
      }
      const slug = slugify(newSlug);
      if (!slug) return NextResponse.json({ error: "Invalid slug" }, { status: 400 });

      const sourceDir = resolveThemeDir(source);
      const targetDir = path.join(CONFIG_ROOT, `theme-${slug}`);
      if (!targetDir.startsWith(CONFIG_ROOT)) {
        return NextResponse.json({ error: "Invalid path" }, { status: 400 });
      }
      if (fs.existsSync(targetDir)) {
        return NextResponse.json({ error: `Theme 'theme-${slug}' already exists` }, { status: 409 });
      }
      if (!fs.existsSync(sourceDir)) {
        return NextResponse.json({ error: `Source theme '${source}' not found` }, { status: 404 });
      }

      fs.mkdirSync(targetDir, { recursive: true });
      const files = fs.readdirSync(sourceDir).filter((f) => f.endsWith(".yaml"));
      for (const f of files) {
        let content = fs.readFileSync(path.join(sourceDir, f), "utf-8");
        // Update meta file with new slug/name
        if (f === "style-guide.meta.yaml") {
          try {
            const meta = yaml.load(content) as Record<string, unknown>;
            meta.slug = slug;
            meta.name = newName;
            content = yaml.dump(meta, { lineWidth: -1 });
          } catch { /* keep original if parse fails */ }
        }
        fs.writeFileSync(path.join(targetDir, f), content, "utf-8");
      }
      return NextResponse.json({ slug, dir: `theme-${slug}`, files: files.length });
    }

    // ─── Upload YAML files to a theme (create or update) ───
    if (action === "upload-theme") {
      const { theme, files: uploadFiles } = body as {
        action: string;
        theme: string;
        files: { filename: string; content: string }[];
      };
      if (!theme || !uploadFiles || !Array.isArray(uploadFiles) || uploadFiles.length === 0) {
        return NextResponse.json({ error: "Missing theme or files" }, { status: 400 });
      }
      const slug = slugify(theme);
      if (!slug) return NextResponse.json({ error: "Invalid theme slug" }, { status: 400 });

      const dir = path.join(CONFIG_ROOT, `theme-${slug}`);
      if (!dir.startsWith(CONFIG_ROOT)) {
        return NextResponse.json({ error: "Invalid path" }, { status: 400 });
      }

      const isNew = !fs.existsSync(dir);
      if (isNew) fs.mkdirSync(dir, { recursive: true });

      const saved: string[] = [];
      const errors: { filename: string; error: string }[] = [];

      for (const { filename, content } of uploadFiles) {
        if (!filename.endsWith(".yaml")) {
          errors.push({ filename, error: "Only .yaml files allowed" });
          continue;
        }
        const safe = path.basename(filename);
        const filePath = path.join(dir, safe);
        if (!filePath.startsWith(dir)) {
          errors.push({ filename, error: "Invalid path" });
          continue;
        }
        try {
          yaml.load(content);
        } catch (e) {
          errors.push({ filename, error: `Invalid YAML: ${e}` });
          continue;
        }
        fs.writeFileSync(filePath, content, "utf-8");
        saved.push(safe);
      }

      // Ensure meta file exists for new themes
      const metaPath = path.join(dir, "style-guide.meta.yaml");
      if (isNew && !fs.existsSync(metaPath)) {
        const meta = { name: slug, slug, title: `${slug} Style Guide`, description: `Uploaded theme: ${slug}` };
        fs.writeFileSync(metaPath, yaml.dump(meta, { lineWidth: -1 }), "utf-8");
        saved.push("style-guide.meta.yaml");
      }

      return NextResponse.json({ theme: slug, created: isNew, saved, errors });
    }

    // ─── Delete a theme file ───
    if (action === "delete-theme-file") {
      const { theme, filename } = body as { action: string; theme: string; filename: string };
      if (!theme || !filename) {
        return NextResponse.json({ error: "Missing theme or filename" }, { status: 400 });
      }
      if (filename === "style-guide.meta.yaml") {
        return NextResponse.json({ error: "Cannot delete meta file" }, { status: 400 });
      }
      const dir = resolveThemeDir(theme);
      const filePath = path.join(dir, path.basename(filename));
      if (!filePath.startsWith(dir) || !fs.existsSync(filePath)) {
        return NextResponse.json({ error: "File not found" }, { status: 404 });
      }
      fs.unlinkSync(filePath);
      return NextResponse.json({ deleted: filename, theme });
    }

    return NextResponse.json({ error: `Unknown action: ${action}` }, { status: 400 });
  } catch (err) {
    return NextResponse.json({ error: String(err) }, { status: 500 });
  }
}
