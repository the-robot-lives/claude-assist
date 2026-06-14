import type { NextConfig } from "next";
import path from "path";

const pkgRoot = path.dirname(require.resolve("@noizu/styleguide/components"));
const engineSrc = path.resolve(pkgRoot, "..", "..", "src");
const localNodeModules = path.resolve(__dirname, "node_modules");

const nextConfig: NextConfig = {
  output: "export",
  transpilePackages: ["@noizu/styleguide"],
  webpack: (config) => {
    config.resolve.alias["@styleguide-engine"] = engineSrc;
    config.resolve.alias["@/components/generated"] = path.resolve(__dirname, "src", "components", "generated");
    if (!config.resolve.modules) config.resolve.modules = [];
    config.resolve.modules.unshift(localNodeModules);
    return config;
  },
};

export default nextConfig;
