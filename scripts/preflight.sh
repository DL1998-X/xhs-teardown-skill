#!/usr/bin/env bash
# xhs-teardown 环境自检（macOS / Linux / WSL / Git Bash / MSYS / Cygwin）
# 用法：bash scripts/preflight.sh [--base URL] [--key KEY]
# 退出码：0 全部通过或仅警告；2 关键项失败（无法出 PDF）

set -u
BASE="${MJ_DATA_API_BASE:-https://creatordata.vip}"
KEY="${MJ_DATA_API_KEY:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="${2:-}"; shift 2 ;;
    --key)  KEY="${2:-}"; shift 2 ;;
    *) echo "未知参数：$1"; exit 2 ;;
  esac
done

pass=0; warn=0; fail=0
ok(){ printf '  [OK]   %s\n' "$*"; pass=$((pass+1)); }
wa(){ printf '  [WARN] %s\n' "$*"; warn=$((warn+1)); }
no(){ printf '  [FAIL] %s\n' "$*"; fail=$((fail+1)); }

# ---------- 系统 ----------
case "$(uname -s 2>/dev/null || echo Unknown)" in
  Darwin) OS=macOS ;;
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then OS=WSL; else OS=Linux; fi ;;
  MINGW*|MSYS*|CYGWIN*) OS=WindowsGitBash ;;
  *) OS=Unknown ;;
esac
echo "== 系统：$OS / $(uname -m 2>/dev/null) =="

# ---------- 浏览器 ----------
find_browser() {
  if [ -n "${CHROME_PATH:-}" ] && [ -x "${CHROME_PATH}" ]; then echo "$CHROME_PATH"; return; fi
  if [ "$OS" = macOS ]; then
    for p in \
      "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
      "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
      "/Applications/Chromium.app/Contents/MacOS/Chromium" \
      "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"; do
      [ -x "$p" ] && { echo "$p"; return; }
    done
  elif [ "$OS" = Linux ] || [ "$OS" = WSL ]; then
    for c in google-chrome google-chrome-stable chromium chromium-browser microsoft-edge brave-browser; do
      if command -v "$c" >/dev/null 2>&1; then command -v "$c"; return; fi
    done
    # WSL 里用 Windows 的 Chrome
    if [ "$OS" = WSL ]; then
      for p in "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe" \
               "/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"; do
        [ -x "$p" ] && { echo "$p"; return; }
      done
    fi
  else
    for p in \
      "/c/Program Files/Google/Chrome/Application/chrome.exe" \
      "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" \
      "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" \
      "/c/Program Files/Microsoft/Edge/Application/msedge.exe"; do
      [ -x "$p" ] && { echo "$p"; return; }
    done
  fi
}
BROWSER="$(find_browser)"
if [ -n "$BROWSER" ]; then
  ok "浏览器：$BROWSER"
  "$BROWSER" --version 2>/dev/null | head -1 | sed 's/^/         /'
else
  no "未找到 Chrome/Edge/Chromium/Brave。PDF 渲染不可用；可先输出 HTML。"
fi

# ---------- 无头渲染冒烟测试 ----------
if [ -n "$BROWSER" ]; then
  TMP="$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/xhs-preflight-$$")"
  mkdir -p "$TMP" 2>/dev/null || true
  printf '<!doctype html><meta charset="utf-8"><h1>测试 Test</h1>' > "$TMP/t.html"
  case "$OS" in
    WindowsGitBash) OUT="$TMP/t.pdf"; URL="file:///$(cygpath -m "$TMP/t.html" 2>/dev/null || echo "$TMP/t.html")" ;;
    *) OUT="$TMP/t.pdf"; URL="file://$TMP/t.html" ;;
  esac
  if "$BROWSER" --headless=new --disable-gpu --no-sandbox --no-first-run \
      --user-data-dir="$TMP/profile" --no-pdf-header-footer --virtual-time-budget=3000 \
      --print-to-pdf="$OUT" "$URL" >/dev/null 2>&1 && head -c 5 "$OUT" 2>/dev/null | grep -q '%PDF'; then
    ok "无头 PDF 渲染：正常"
  elif "$BROWSER" --headless --disable-gpu --no-sandbox --no-first-run \
      --user-data-dir="$TMP/profile2" --no-pdf-header-footer --virtual-time-budget=3000 \
      --print-to-pdf="$OUT" "$URL" >/dev/null 2>&1 && head -c 5 "$OUT" 2>/dev/null | grep -q '%PDF'; then
    wa "旧版 --headless 可用；脚本会自动回退"
  else
    no "无头渲染失败（检查浏览器权限或沙箱）"
  fi
  rm -rf "$TMP" 2>/dev/null || true
fi

# ---------- 中文字体 ----------
case "$OS" in
  macOS)
    if command -v fc-list >/dev/null 2>&1 && fc-list :lang=zh 2>/dev/null | grep -q .; then
      FAM="$(fc-list :lang=zh family 2>/dev/null | tr ',' '\n' | grep -E 'PingFang|Heiti|Songti|Noto Sans CJK|Noto Serif CJK|Microsoft YaHei|Source Han' | head -1 | sed 's/^ *//')"
      if [ -n "$FAM" ]; then ok "中文字体：$FAM"; else
        ok "中文字体：系统 CJK 可用"
        wa "未找到 PingFang/黑体/宋体等首选字体，将使用其它 CJK 字体"
      fi
    elif ls /System/Library/Fonts/*Heiti* /System/Library/Fonts/*Songti* /System/Library/Fonts/*Hiragino* >/dev/null 2>&1; then
      ok "中文字体：系统 CJK 字体可用"
    else
      wa "未检测到中文字体，PDF 可能缺字"
    fi ;;
  Linux|WSL)
    if command -v fc-list >/dev/null 2>&1 && fc-list :lang=zh 2>/dev/null | head -1 | grep -q .; then
      ok "中文字体：$(fc-list :lang=zh 2>/dev/null | head -1 | cut -d: -f1)"
    else wa "未检测到中文字体，建议安装 fonts-noto-cjk"; fi ;;
  WindowsGitBash)
    if [ -f "/c/Windows/Fonts/msyh.ttc" ] || [ -f "/c/Windows/Fonts/msyhbd.ttc" ]; then
      ok "中文字体：Microsoft YaHei"
    else wa "未检测到微软雅黑，PDF 可能缺字"; fi ;;
esac

# ---------- 可选工具 ----------
if command -v python3 >/dev/null 2>&1; then
  ok "Python：$(python3 -V 2>&1)"
else
  wa "无 Python；模板填充脚本不可用（可手动改 HTML）"
fi
if [ "$OS" = macOS ] && command -v swift >/dev/null 2>&1; then
  ok "Swift：可用（PDF 页码）"
else
  wa "Swift 不可用：跳过页码（macOS 专属，其它系统正常）"
fi

# ---------- 数据源 ----------
if [ -z "$BASE" ]; then
  wa "未配置 MJ_DATA_API_BASE；可只跑 demo/手动模式"
else
  CODE="$(curl -s -o /dev/null -w '%{http_code}' -m 8 "$BASE/data/api/pricing" 2>/dev/null || echo 000)"
  if [ "$CODE" = "200" ]; then ok "数据源可达：$BASE"
  else no "数据源不可达（HTTP $CODE）：$BASE"; fi
fi
if [ -z "$KEY" ]; then
  wa "未配置 MJ_DATA_API_KEY；首次调用会返回 401"
else
  case "$KEY" in sk_*|dk_*) ok "API Key 格式：sk_/dk_ 开头" ;; *) wa "API Key 不是 sk_/dk_ 开头，请确认" ;; esac
fi

echo
echo "结果：通过 ${pass} ｜ 警告 ${warn} ｜ 失败 ${fail}"
[ "$fail" -eq 0 ] || exit 2
exit 0
