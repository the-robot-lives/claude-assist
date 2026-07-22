import type { NextConfig } from "next";

/**
 * Standalone Node server for k8s (matches start-app / helm frontend:3000).
 * Static export was removed so dynamic App Router routes work with live API.
 */
const nextConfig: NextConfig = {
  output: "standalone",
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
