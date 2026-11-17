# 一键把 report.html 渲染成 PDF（Windows PowerShell 5.1+ / PowerShell 7）
# 用法：powershell -ExecutionPolicy Bypass -File scripts\render_pdf.ps1 -Html report.html -Out report.pdf
param(
  [Parameter(Mandatory=$true)][string]$Html,
  [Parameter(Mandatory=$true)][string]$Out,
  [string]$Footer = "数据站 · 单篇笔记分析 · 内容来自公开信息"
)
$ErrorActionPreference = "Continue"
if (-not (Test-Path $Html)) { Write-Host "[FAIL] HTML 不存在：$Html"; exit 2 }
$Html = (Resolve-Path $Html).Path
$Out  = [IO.Path]::GetFullPath($Out)
$outDir = Split-Path -Parent $Out
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$candidates = @(
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe"
)
$browser = $null
if ($env:CHROME_PATH -and (Test-Path $env:CHROME_PATH)) { $browser = $env:CHROME_PATH }
else { $browser = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1 }
if (-not $browser) {
  Write-Host "[FAIL] 没找到 Chrome/Edge。安装 Chrome 后重试，或直接交付 HTML。"
  exit 2
}

$profileDir = Join-Path $env:TEMP ("xhs-render-" + [guid]::NewGuid().ToString("N"))
$uri = ([uri]$Html).AbsoluteUri
Write-Host "[1/3] 渲染：$browser"

$argsNew = @("--headless=new","--disable-gpu","--no-sandbox","--no-first-run",
  "--user-data-dir=$profileDir","--no-pdf-header-footer","--virtual-time-budget=5000",
  "--print-to-pdf=$Out",$uri)
& $browser @argsNew 2>$null | Out-Null

function Test-Pdf($p) {
  if (-not (Test-Path $p)) { return $false }
  $b = [IO.File]::ReadAllBytes($p)
  if ($b.Length -lt 1024) { return $false }
  return ([Text.Encoding]::ASCII.GetString($b[0..4]) -eq "%PDF-")
}

if (-not (Test-Pdf $Out)) {
  Write-Host "[warn] --headless=new 失败，回退 --headless"
  $argsOld = @("--headless","--disable-gpu","--no-sandbox","--no-first-run",
    "--user-data-dir=${profileDir}-old","--no-pdf-header-footer","--virtual-time-budget=5000",
    "--print-to-pdf=$Out",$uri)
  & $browser @argsOld 2>$null | Out-Null
}
if (-not (Test-Pdf $Out)) {
  Write-Host "[FAIL] 没有生成有效 PDF。检查 HTML 路径、浏览器权限、安全软件拦截。"
  exit 2
}

$raw = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($Out))
$pages = ([regex]::Matches($raw, '/Type\s*/Page[^s]')).Count
if ($pages -eq 0) {
  $p1 = ([regex]::Matches($raw, '/Type\s*/Page\b')).Count
  $p2 = ([regex]::Matches($raw, '/Type\s*/Pages')).Count
  $pages = $p1 - $p2
}
$size = (Get-Item $Out).Length
Write-Host "[2/3] 已生成：$Out（$pages 页，$size bytes）"
Write-Host "[3/3] 跳过页码（仅 macOS 支持；不影响内容）"
Remove-Item -Recurse -Force $profileDir -ErrorAction SilentlyContinue
Write-Host "完成：$Out"
