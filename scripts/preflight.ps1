# xhs-teardown 环境自检（Windows PowerShell 5.1+ / PowerShell 7）
# 用法：powershell -ExecutionPolicy Bypass -File scripts\preflight.ps1
param(
  [string]$Base = "",
  [string]$Key  = $env:MJ_DATA_API_KEY
)
$ErrorActionPreference = "Continue"
if (-not $Base) { $Base = if ($env:MJ_DATA_API_BASE) { $env:MJ_DATA_API_BASE } else { "https://creatordata.vip" } }
$script:pass = 0; $script:warn = 0; $script:fail = 0
function Ok($m)   { Write-Host "  [OK]   $m"; $script:pass++ }
function Warn($m) { Write-Host "  [WARN] $m"; $script:warn++ }
function Fail($m) { Write-Host "  [FAIL] $m"; $script:fail++ }

Write-Host "== 系统：Windows $([Environment]::OSVersion.VersionString) =="

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

if ($browser) {
  Ok "浏览器：$browser"
  try { & $browser --version 2>$null | Select-Object -First 1 | ForEach-Object { Write-Host "         $_" } } catch {}
} else {
  Fail "未找到 Chrome/Edge/Chromium；PDF 渲染不可用，可交付 HTML"
}

if ($browser) {
  $tmp = Join-Path $env:TEMP ("xhs-preflight-" + [guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null
  $html = Join-Path $tmp "t.html"
  Set-Content -Path $html -Value '<!doctype html><meta charset="utf-8"><h1>测试 Test</h1>' -Encoding UTF8
  $pdf = Join-Path $tmp "t.pdf"
  $uri = ([uri]$html).AbsoluteUri
  $argsNew = @("--headless=new","--disable-gpu","--no-sandbox","--no-first-run",
    "--user-data-dir=$tmp\p1","--no-pdf-header-footer","--virtual-time-budget=3000",
    "--print-to-pdf=$pdf",$uri)
  & $browser @argsNew 2>$null | Out-Null
  $okPdf = $false
  if (Test-Path $pdf) {
    $b = [IO.File]::ReadAllBytes($pdf)
    if ($b.Length -gt 4 -and [Text.Encoding]::ASCII.GetString($b[0..4]) -eq "%PDF-") { $okPdf = $true }
  }
  if (-not $okPdf) {
    $argsOld = @("--headless","--disable-gpu","--no-sandbox","--no-first-run",
      "--user-data-dir=$tmp\p2","--no-pdf-header-footer","--virtual-time-budget=3000",
      "--print-to-pdf=$pdf",$uri)
    & $browser @argsOld 2>$null | Out-Null
    if (Test-Path $pdf) {
      $b = [IO.File]::ReadAllBytes($pdf)
      if ($b.Length -gt 4 -and [Text.Encoding]::ASCII.GetString($b[0..4]) -eq "%PDF-") {
        $okPdf = $true; Warn "旧版 --headless 可用；脚本会自动回退"
      }
    }
  }
  if ($okPdf) { Ok "无头 PDF 渲染：正常" } else { Fail "无头渲染失败（检查安全软件/浏览器权限）" }
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

if (Test-Path "$env:WINDIR\Fonts\msyh.ttc") { Ok "中文字体：Microsoft YaHei" }
elseif (Test-Path "$env:WINDIR\Fonts\msyhbd.ttc") { Ok "中文字体：Microsoft YaHei" }
else { Warn "未检测到微软雅黑，PDF 可能缺字；建议安装中文字体" }

$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command py -ErrorAction SilentlyContinue }
if ($py) { Ok "Python：$(& $py.Source --version 2>&1)" } else { Warn "无 Python；模板填充脚本不可用（可手动改 HTML）" }
Warn "PDF 页码仅 macOS 支持；Windows 版不页码，不影响内容"

if (-not $Base) { Warn "未配置 MJ_DATA_API_BASE；可只跑 demo/手动模式" }
else {
  try {
    $r = Invoke-WebRequest -UseBasicParsing -Uri "$Base/data/api/pricing" -TimeoutSec 8
    if ($r.StatusCode -eq 200) { Ok "数据源可达：$Base" } else { Fail "数据源返回 $($r.StatusCode)：$Base" }
  } catch { Fail "数据源不可达：$Base" }
}
if (-not $Key) { Warn "未配置 MJ_DATA_API_KEY；首次调用会返回 401" }
elseif ($Key.StartsWith("sk_") -or $Key.StartsWith("dk_")) { Ok "API Key 格式：sk_/dk_ 开头" }
else { Warn "API Key 不是 sk_ 开头，请确认" }

Write-Host ""
Write-Host "结果：通过 $($script:pass) ｜ 警告 $($script:warn) ｜ 失败 $($script:fail)"
if ($script:fail -gt 0) { exit 2 } else { exit 0 }
