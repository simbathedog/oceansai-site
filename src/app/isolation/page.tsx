"use client";

export default function Isolation() {
  const data = {
    crossOriginIsolated: typeof self !== "undefined" ? self.crossOriginIsolated : null,
    sharedArrayBuffer: typeof SharedArrayBuffer !== "undefined",
    userAgent: typeof navigator !== "undefined" ? navigator.userAgent : null,
  };
  return (
    <main style={{padding:"2rem",maxWidth:820,margin:"0 auto",lineHeight:1.6,fontFamily:"system-ui"}}>
      <h1>Cross-Origin Isolation</h1>
      <p>This page shows whether the browser considers this context isolated.</p>
      <pre style={{background:"#f6f6f6",padding:"1rem",borderRadius:8}}>
        {JSON.stringify(data, null, 2)}
      </pre>
    </main>
  );
}
