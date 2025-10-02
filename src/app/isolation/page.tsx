"use client";
import { useEffect, useState } from "react";

export default function Isolation() {
  const [client, setClient] = useState<{ coi: boolean | null; sab: boolean; ua: string | null }>({
    coi: null, sab: false, ua: null
  });

  useEffect(() => {
  // Type globalThis instead of casting to `any`
  const gt = globalThis as typeof globalThis & { crossOriginIsolated?: boolean };

  const coi =
    typeof gt.crossOriginIsolated === "boolean" ? gt.crossOriginIsolated : null;

  const sab = typeof SharedArrayBuffer !== "undefined";
  const ua  = typeof navigator !== "undefined" ? navigator.userAgent : null;

  setClient({ coi, sab, ua });
}, []);

  return (
    <main style={{padding:"2rem",maxWidth:820,margin:"0 auto",lineHeight:1.6,fontFamily:"system-ui"}}>
      <h1>Cross-Origin Isolation</h1>
      <p>Live client runtime values:</p>
      <pre style={{background:"#f6f6f6",padding:"1rem",borderRadius:8}}>
        {JSON.stringify(client, null, 2)}
      </pre>
    </main>
  );
}

