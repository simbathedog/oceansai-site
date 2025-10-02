param(
  [string]$Url = 'https://oceansai.org/isolation',
  [ValidateSet('auto','chrome','edge')] [string]$BrowserChoice = 'auto',
  [ValidateSet('','require-corp','credentialless')] [string]$ExpectCOEP = '',
  [int]$TimeoutSec = 15,
  [switch]$StayOpen
)
$ErrorActionPreference = 'Stop'

function Get-BrowserPath([string]$choice){
  $cands = @()
  if ($choice -eq 'chrome' -or $choice -eq 'auto') {
    $cands += @(
      "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
      "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe",
      "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )
    try { $whereChrome = & where.exe chrome 2>$null; if ($whereChrome) { $cands += $whereChrome } } catch {}
  }
  if ($choice -eq 'edge' -or $choice -eq 'auto') {
    $cands += @(
      "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
      "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe",
      "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe",
      "$env:ProgramFiles\Microsoft\Edge Beta\Application\msedge.exe",
      "$env:ProgramFiles(x86)\Microsoft\Edge Beta\Application\msedge.exe",
      "$env:LOCALAPPDATA\Microsoft\Edge Beta\Application\msedge.exe",
      "$env:ProgramFiles\Microsoft\Edge Dev\Application\msedge.exe",
      "$env:ProgramFiles(x86)\Microsoft\Edge Dev\Application\msedge.exe",
      "$env:LOCALAPPDATA\Microsoft\Edge Dev\Application\msedge.exe"
    )
    foreach ($rk in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe',
                      'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe') {
      try {
        $prop = Get-ItemProperty -LiteralPath $rk -ErrorAction SilentlyContinue
        if ($prop.'(default)') { $cands += $prop.'(default)' }
        elseif ($prop.Path)    { $cands += $prop.Path }
      } catch {}
    }
    try { $whereEdge = & where.exe msedge 2>$null; if ($whereEdge) { $cands += $whereEdge } } catch {}
  }
  foreach($p in ($cands | Where-Object { $_ } | Select-Object -Unique)) { if (Test-Path -LiteralPath $p) { return $p } }
  throw "Need Edge or Chrome installed. Searched:`n$([string]::Join([Environment]::NewLine,$cands))"
}

function Get-FreePort([int]$start=9222,[int]$tries=50){
  for($p=$start; $p -lt $start+$tries; $p++){
    try{ $l = [System.Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,$p); $l.Start(); $l.Stop(); return $p } catch {}
  }
  throw "Could not find a free TCP port near $start"
}

$browser = Get-BrowserPath $BrowserChoice
$devtoolsPort = Get-FreePort 9222 100
$userDir = Join-Path $env:TEMP ("headless-profile-" + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Force -Path $userDir | Out-Null
$stdOut = Join-Path $userDir 'headless-stdout.log'
$stdErr = Join-Path $userDir 'headless-stderr.log'

$args = @(
  "--headless=new",
  "--remote-debugging-port=$devtoolsPort",
  "--user-data-dir=$userDir",
  "--disable-gpu",
  "--no-first-run",
  "--no-default-browser-check",
  "--disable-logging",
  "--log-level=3",
  "--disable-features=UseGCMNetworkChannel,NotificationTriggers,Translate",
  "about:blank"
)
$proc = Start-Process -FilePath $browser -ArgumentList $args -RedirectStandardOutput $stdOut -RedirectStandardError $stdErr -PassThru

try {
  $base = "http://127.0.0.1:$devtoolsPort"
  for ($i=0; $i -lt 60; $i++) { try { Invoke-RestMethod "$base/json/version" -TimeoutSec 2 | Out-Null; break } catch { Start-Sleep -Milliseconds 200 } }
  if ($i -ge 60) { throw "DevTools endpoint not responding on $base (browser may not have started). Logs:`n  $stdErr`n  $stdOut" }

  $wsUrl = $null
  try   { $wsUrl = (Invoke-RestMethod -Method Put -Uri "$base/json/new?$( [uri]::EscapeDataString($Url) )" -TimeoutSec 5).webSocketDebuggerUrl } catch {}
  if (-not $wsUrl) {
    try { $wsUrl = (Invoke-RestMethod -Method Put -Uri "$base/json/new" -Body $Url -ContentType "text/plain; charset=utf-8" -TimeoutSec 5).webSocketDebuggerUrl } catch {}
  }
  if (-not $wsUrl) {
    $page = (Invoke-RestMethod "$base/json" -TimeoutSec 5 | Where-Object { $_.type -eq 'page' } | Select-Object -First 1)
    if (-not $page) { throw "No page target found to attach." }
    $wsUrl = $page.webSocketDebuggerUrl
  }

  Add-Type -AssemblyName System.Net.WebSockets
  $ws = [System.Net.WebSockets.ClientWebSocket]::new()
  $ws.ConnectAsync([Uri]$wsUrl, [System.Threading.CancellationToken]::None).Wait()

  function Send-Json($obj){
    $json  = ($obj | ConvertTo-Json -Depth 20 -Compress)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $seg   = [ArraySegment[byte]]::new($bytes,0,$bytes.Length)
    $ws.SendAsync($seg,[System.Net.WebSockets.WebSocketMessageType]::Text,$true,[System.Threading.CancellationToken]::None).Wait()
  }
  function Receive-Text(){
    $buffer = New-Object byte[] 32768
    $seg = [ArraySegment[byte]]::new($buffer)
    $sb = [System.Text.StringBuilder]::new()
    do {
      $res = $ws.ReceiveAsync($seg,[System.Threading.CancellationToken]::None).Result
      if ($res.Count -gt 0) { $null = $sb.Append([System.Text.Encoding]::UTF8.GetString($buffer,0,$res.Count)) }
    } while (-not $res.EndOfMessage)
    $sb.ToString()
  }
  function Get-HeaderVal([object]$hdrs,[string]$name){
    if (-not $hdrs) { return $null }
    $n = $name.ToLower()
    foreach($p in $hdrs.PSObject.Properties){ if ($p.Name.ToLower() -eq $n) { return $p.Value } }
    return $null
  }

  Send-Json @{ id = 1; method = "Page.enable" }    ; Receive-Text | Out-Null
  Send-Json @{ id = 2; method = "Runtime.enable" } ; Receive-Text | Out-Null
  Send-Json @{ id = 3; method = "Network.enable" } ; Receive-Text | Out-Null
  Send-Json @{ id = 4; method = "Page.navigate"; params = @{ url = $Url } }

  $coopHdr = $null; $coepHdr = $null; $loaded = $false
  $deadline = [DateTime]::UtcNow.AddSeconds([Math]::Max(5,$TimeoutSec))
  while ([DateTime]::UtcNow -lt $deadline -and -not $loaded) {
    $msg = Receive-Text
    if ($msg -match '"method"\s*:\s*"Network\.responseReceived"') {
      try {
        $obj = $msg | ConvertFrom-Json
        if ($obj.params.type -eq 'Document') {
          $hdrs = $obj.params.response.headers
          if (-not $coopHdr) { $coopHdr = Get-HeaderVal $hdrs 'cross-origin-opener-policy' }
          if (-not $coepHdr) { $coepHdr = Get-HeaderVal $hdrs 'cross-origin-embedder-policy' }
        }
      } catch {}
    }
    if ($msg -match '"method"\s*:\s*"Page\.loadEventFired"') { $loaded = $true }
  }

  $expr = @"
(() => {
  const coi = globalThis.crossOriginIsolated ?? null;
  const sabAvail = typeof SharedArrayBuffer !== 'undefined';
  let sabConstructable = false;
  if (sabAvail) { try { new SharedArrayBuffer(8); sabConstructable = true; } catch(e) { sabConstructable = false; } }
  const ua = (typeof navigator !== 'undefined' && navigator.userAgent) || null;
  return { coi, sabAvail, sabConstructable, ua };
})()
"@
  Send-Json @{ id = 5; method = "Runtime.evaluate"; params = @{ expression = $expr; returnByValue = $true; awaitPromise = $true } }
  do { $msg5 = Receive-Text } while ($msg5 -notmatch '"id"\s*:\s*5')
  $parsed = $msg5 | ConvertFrom-Json
  $val = if ($parsed.error) { $null } else { $parsed.result.result.value }

  "COOP (from Network)          → {0}" -f ($coopHdr ?? '(missing)')
  "COEP (from Network)          → {0}" -f ($coepHdr ?? '(missing)')
  if ($val) {
    "crossOriginIsolated (client) → {0}" -f $val.coi
    "SharedArrayBuffer available  → {0}" -f $val.sabAvail
    "SAB constructable            → {0}" -f $val.sabConstructable
    "User-Agent                   → {0}" -f $val.ua
  }

  $coopOk = ($coopHdr -eq 'same-origin')
  $coepOk = if ($ExpectCOEP) { $coepHdr -eq $ExpectCOEP } else { @('require-corp','credentialless') -contains $coepHdr }
  $clientOk = ($val -and $val.coi -eq $true -and $val.sabConstructable -eq $true)

  if ($coopOk -and $coepOk -and $clientOk) {
    Write-Host "COI OK ✅" -ForegroundColor Green
    if ($StayOpen) { $global:LASTEXITCODE = 0; Read-Host "Done. Press Enter to continue" | Out-Null; return } else { exit 0 }
  } else {
    Write-Host ("COI check FAILED ❌  (COOP={0}, COEP={1}, coi={2}, SAB={3})" -f $coopHdr,$coepHdr,($val.coi),($val.sabConstructable)) -ForegroundColor Red
    Write-Host ("Logs → stdout: {0} | stderr: {1}" -f $stdOut,$stdErr) -ForegroundColor Yellow
    if ($StayOpen) { $global:LASTEXITCODE = 1; Read-Host "Press Enter to continue" | Out-Null; return } else { exit 1 }
  }
}
finally {
  try { if ($ws) { $ws.Dispose() } } catch {}
  try { if ($proc -and -not $proc.HasExited) { Stop-Process -Id $proc.Id -Force } } catch {}
  Start-Sleep -Milliseconds 200
  try { Remove-Item -Recurse -Force $userDir -ErrorAction SilentlyContinue | Out-Null } catch {}
}

