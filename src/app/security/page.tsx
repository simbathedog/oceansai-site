export default function SecurityPage() {
  return (
    <main style={{padding:'2rem',maxWidth:820,margin:'0 auto',lineHeight:1.6}}>
      <h1>Vulnerability Disclosure</h1>
      <p>If you believe you&#39;ve found a security issue affecting <strong>oceansai.org</strong>,
      please email <a href="mailto:security@oceansai.org">security@oceansai.org</a>. We aim to acknowledge new reports within 3 business days.</p>
      <h2>Scope</h2>
      <ul>
        <li>oceansai.org production site and subdomains</li>
      </ul>
      <h2>Out of Scope</h2>
      <ul>
        <li>Denial of Service, volumetric issues, or spam reports</li>
        <li>Findings requiring physical access or social engineering</li>
      </ul>
      <h2>Safe Harbor</h2>
      <p>We will not pursue legal action for good-faith research that avoids privacy violations and service disruption.</p>
    </main>
  );
}

