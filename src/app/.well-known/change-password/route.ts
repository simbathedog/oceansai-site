import { NextResponse } from "next/server";

export const dynamic = "force-static";

export async function GET(request: Request) {
  const origin = new URL(request.url).origin;
  return NextResponse.redirect(new URL("/account", origin), 302);
}
