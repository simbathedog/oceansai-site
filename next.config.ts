import type { NextConfig } from "next";

const CSP = [
  "default-src 'self'",
  "base-uri 'self'",
  "font-src 'self' data:",
  "img-src 'self' data: https:",
  "object-src 'none'",
  "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://*.vercel.app",
  "style-src 'self' 'unsafe-inline'",
  "connect-src 'self' https://*.vercel.app https://vitals.vercel-insights.com",
  "frame-ancestors 'none'",
  "form-action 'self'",
  "upgrade-insecure-requests"
].join("; ");

const nextConfig: NextConfig = {
  poweredByHeader: false,
  async headers() {
    return [
      {
        source: "/:path*",
        headers: [
          { key: "X-DNS-Prefetch-Control", value: "off" }
        ],
      },{
        source: "/:path*",
        headers: [
          { key: "Origin-Agent-Cluster",              value: "?1" },
          { key: "Cross-Origin-Resource-Policy",      value: "same-origin" },
          { key: "X-Permitted-Cross-Domain-Policies", value: "none" }
          // { key: "Cross-Origin-Opener-Policy",       value: "same-origin" }, // enable after testing popups/embeds
        ],
      },{
        source: "/account",
        headers: [
          { key: "X-Robots-Tag", value: "noindex, nofollow" }
        ],
      },{
        source: "/login",
        headers: [
          { key: "X-Robots-Tag", value: "noindex, nofollow" }
        ],
      },{
        source: "/(login|account)",
        headers: [
          { key: "X-Robots-Tag", value: "noindex, nofollow" }
        ],
      },// Cache sitemap reasonably (1h) and ensure XML content-type
      {
        source: "/sitemap.xml",
        headers: [
          { key: "Cache-Control", value: "public, max-age=3600, s-maxage=3600, stale-while-revalidate=86400" },
          { key: "Content-Type",  value: "application/xml; charset=utf-8" },
        ],
      },
      // Serve well-known security.txt as plain text with modest cache
      {
        source: "/.well-known/security.txt",
        headers: [
          { key: "Content-Type",  value: "text/plain; charset=utf-8" },
          { key: "Cache-Control", value: "public, max-age=86400, s-maxage=86400" },
        ],
      },
      // Global hardening + CSP
      {
        source: "/:path*",
        headers: [
          { key: "Content-Security-Policy", value: CSP },
          { key: "Strict-Transport-Security", value: "max-age=31536000; includeSubDomains; preload" },
          { key: "X-Frame-Options",           value: "DENY" },
          { key: "X-Content-Type-Options",    value: "nosniff" },
          { key: "Referrer-Policy",           value: "strict-origin-when-cross-origin" },
          { key: "Permissions-Policy",        value: "geolocation=(), microphone=(), camera=(), browsing-topics=()" },
        ],
      },
    ];
  },
};

export default nextConfig;




