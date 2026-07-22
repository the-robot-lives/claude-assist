import type { NextConfig } from "next";

/**
 * Static export (ADR-001) was for the portfolio prototype.
 * Product API integration needs dynamic routes + client fetch; export removed.
 * Revisit CDN/static strategy once SSR/edge deploy is decided.
 */
const nextConfig: NextConfig = {
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
