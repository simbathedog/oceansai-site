import { NextResponse } from "next/server";
export const dynamic = "force-static";
export async function GET() {
  return NextResponse.json({
    status: "ok",
    time: new Date().toISOString(),
    commit: process.env.VERCEL_GIT_COMMIT_SHA || null,
  });
}
