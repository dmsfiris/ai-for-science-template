import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  basePath: process.env.NEXT_PUBLIC_BASE_PATH || process.env.BASE_PATH || "/ai-for-science",
  trailingSlash: true,
};

export default nextConfig;

