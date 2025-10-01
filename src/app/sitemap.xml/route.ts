export const dynamic = "force-static";

export async function GET() {
  const now = new Date().toISOString();
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://oceansai.org/</loc><lastmod>${now}</lastmod><changefreq>daily</changefreq><priority>1.0</priority></url>
  <url><loc>https://oceansai.org/login</loc><lastmod>${now}</lastmod><changefreq>monthly</changefreq><priority>0.3</priority></url>
  <url><loc>https://oceansai.org/account</loc><lastmod>${now}</lastmod><changefreq>monthly</changefreq><priority>0.3</priority></url>
</urlset>`;
  return new Response(xml, {
    status: 200,
    headers: { "content-type": "application/xml; charset=utf-8" },
  });
}
