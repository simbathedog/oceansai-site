import type { NextRequest } from "next/server";
import { NextResponse } from "next/server";

const PRIMARY = "oceansai.org";
const WWW = "www.oceansai.org";

export function middleware(req: NextRequest) {
  const host = (req.headers.get("host") || "").toLowerCase();

  // www → apex
  if (host === WWW) {
    const url = new URL(req.nextUrl.pathname + req.nextUrl.search, `https://${PRIMARY}`);
    return NextResponse.redirect(url, 308);
  }

  const res = NextResponse.next();

  // Noindex everything that isn't the canonical host (e.g., preview *.vercel.app)
  if (host !== PRIMARY) {
    res.headers.set("X-Robots-Tag", "noindex, nofollow");
  }

  // Never index API routes
  if (req.nextUrl.pathname.startsWith("/api/")) {
    res.headers.set("X-Robots-Tag", "noindex, nofollow");
  }

  return res;
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|robots.txt|sitemap.xml|\\.well-known).*)",
  ],
};

