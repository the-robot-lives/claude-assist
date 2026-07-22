import type { NextConfig } from "next";
import path from "path";

const pkgRoot = path.dirname(require.resolve("@noizu/styleguide/components"));
const engineSrc = path.resolve(pkgRoot, "dist", "engine-src");

const nextConfig: NextConfig = {
  output: "standalone",
  transpilePackages: ["@noizu/styleguide"],
  turbopack: {
    resolveAlias: {
      "@styleguide-engine": engineSrc,
      "@/": "./src/",
    },
  },
  webpack: (config) => {
    config.resolve.alias["@styleguide-engine"] = engineSrc;
    // Ensure @/ alias resolves from styleguide package's transpiled source too
    config.resolve.alias["@/"] = path.resolve(__dirname, "src") + "/";
    return config;
  },
  // Serve the standalone quiz SPA (public/quiz/index.html) at the bare /quiz paths.
  async rewrites() {
    return [
      { source: "/quiz", destination: "/quiz/index.html" },
      { source: "/quiz/", destination: "/quiz/index.html" },
    ];
  },
};

export default nextConfig;
