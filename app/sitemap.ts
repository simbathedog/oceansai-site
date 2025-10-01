import type { MetadataRoute } from "next";

export default function sitemap(): MetadataRoute.Sitemap {
  const base = "https://oceansai.org";
  const now = new Date();
  return [
    { url: `${base}/`,        lastModified: now, changeFrequency: "daily",  priority: 1.0 },
    { url: `${base}/login`,   lastModified: now, changeFrequency: "monthly", priority: 0.3 },
    { url: `${base}/account`, lastModified: now, changeFrequency: "monthly", priority: 0.3 },
  ];
}
