import type { NextRequest } from "next/server";
import { NextResponse } from "next/server";

const PRIMARY = "oceansai.org";
const WWW = "www.oceansai.org";

export function middleware(req: NextRequest) {
  const host = req.headers.get("host") || "";
  if (host.toLowerCase() === WWW.toLowerCase()) {
    const url = new URL(req.nextUrl.pathname + req.nextUrl.search, `https://${PRIMARY}`);
    return NextResponse.redirect(url, 308);
  }
  return NextResponse.next();
}

// Redirect everything except Next assets
export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|robots.txt|sitemap.xml).*)",
  ],
};
