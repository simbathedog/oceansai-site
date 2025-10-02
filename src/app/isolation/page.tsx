"use client";
import { useEffect, useState } from "react";

export default function Isolation() {
  const [client, setClient] = useState<{ coi: boolean | null; sab: boolean; ua: string | null }>({
    coi: null, sab: false, ua: null
  });

  useEffect(() => {
    const coi = typeof globalThis !== "undefined" && (globalThis as any).crossOriginIsolated === true;
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
