import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";
import { fileURLToPath } from "url";

const pkgDir = path.dirname(fileURLToPath(import.meta.url));
const appDir = path.resolve(pkgDir, "..");

const external = [
  "react",
  "react-dom",
  "react/jsx-runtime",
  "sonner",
  "@headlessui/react",
  "@heroicons/react",
  "@monaco-editor/react",
  "monaco-editor",
  "js-yaml",
  "next",
  "next/server",
];

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@styleguide-engine": path.resolve(appDir, "src"),
      "@": path.resolve(appDir, "src"),
    },
  },
  build: {
    outDir: "dist",
    emptyOutDir: false,
    lib: {
      entry: path.resolve(pkgDir, "src/viewer.ts"),
      name: "NoizuStyleguideViewer",
      formats: ["umd"],
      fileName: () => "sg-viewer.js",
    },
    rollupOptions: {
      external,
      output: {
        globals: {
          react: "React",
          "react-dom": "ReactDOM",
          "react/jsx-runtime": "React",
          sonner: "Sonner",
          "@headlessui/react": "HeadlessUIReact",
          "@heroicons/react": "HeroiconsReact",
          "@monaco-editor/react": "MonacoEditorReact",
          "monaco-editor": "MonacoEditor",
          "js-yaml": "jsYaml",
          next: "Next",
          "next/server": "NextServer",
        },
      },
    },
  },
});
