import type { NextConfig } from "next";
import path from "path";

const pkgRoot = path.dirname(require.resolve("@noizu/styleguide/components"));
const engineSrc = path.resolve(pkgRoot, "dist", "engine-src");

const nextConfig: NextConfig = {
  transpilePackages: ["@noizu/styleguide"],
  turbopack: {
    // `@/*` is resolved from tsconfig.json paths automatically by Turbopack.
    resolveAlias: {
      "@styleguide-engine": engineSrc,
    },
  },
};

export default nextConfig;
