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
  "@monaco-editor/react",
  "monaco-editor",
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
      entry: path.resolve(pkgDir, "src/primitives.ts"),
      name: "NoizuStyleguide",
      formats: ["umd"],
      fileName: () => "sg.js",
    },
    rollupOptions: {
      external,
      output: {
        globals: {
          react: "React",
          "react-dom": "ReactDOM",
          "react/jsx-runtime": "React",
          sonner: "Sonner",
          "@monaco-editor/react": "MonacoEditorReact",
          "monaco-editor": "MonacoEditor",
        },
      },
    },
  },
});
