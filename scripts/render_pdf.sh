#!/usr/bin/env bash
# 一键把 report.html 渲染成 PDF（macOS / Linux / WSL / Git Bash）
# 用法：bash scripts/render_pdf.sh report.html report.pdf ["页脚文案"]
# 可选：NO_STAMP=1 跳过页码；CHROME_PATH=/path/to/chrome 指定浏览器

set -u
HTML="${1:-}"; OUT="${2:-}"; FOOTER="${3:-数据站 · 单篇笔记分析 · 内容来自公开信息}"
if [ -z "$HTML" ] || [ -z "$OUT" ]; then
  echo "用法：bash scripts/render_pdf.sh <report.html> <report.pdf> [footer]"; exit 2
fi
[ -f "$HTML" ] || { echo "[FAIL] HTML 不存在：$HTML"; exit 2; }

case "$HTML" in /*) ;; *) HTML="$PWD/$HTML" ;; esac
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac
HTML_DIR="$(cd "$(dirname "$HTML")" && pwd)"
HTML_NAME="$(basename "$HTML")"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

case "$(uname -s 2>/dev/null || echo Unknown)" in
  Darwin) OS=macOS ;;
  Linux) if grep -qi microsoft /proc/version 2>/dev/null; then OS=WSL; else OS=Linux; fi ;;
  MINGW*|MSYS*|CYGWIN*) OS=WindowsGitBash ;;
  *) OS=Unknown ;;
esac

find_browser() {
  if [ -n "${CHROME_PATH:-}" ] && [ -x "${CHROME_PATH}" ]; then echo "$CHROME_PATH"; return; fi
  if [ "$OS" = macOS ]; then
    for p in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
             "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
             "/Applications/Chromium.app/Contents/MacOS/Chromium" \
             "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"; do
      [ -x "$p" ] && { echo "$p"; return; }
    done
  elif [ "$OS" = Linux ] || [ "$OS" = WSL ]; then
    for c in google-chrome google-chrome-stable chromium chromium-browser microsoft-edge brave-browser; do
      command -v "$c" >/dev/null 2>&1 && { command -v "$c"; return; }
    done
    if [ "$OS" = WSL ]; then
      for p in "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe" \
               "/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" \
               "/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"; do
        [ -x "$p" ] && { echo "$p"; return; }
      done
    fi
  else
    for p in "/c/Program Files/Google/Chrome/Application/chrome.exe" \
             "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" \
             "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" \
             "/c/Program Files/Microsoft/Edge/Application/msedge.exe"; do
      [ -x "$p" ] && { echo "$p"; return; }
    done
  fi
}

BROWSER="$(find_browser)"
if [ -z "$BROWSER" ]; then
  cat <<'EOF'
[FAIL] 没找到 Chrome/Edge/Chromium。
  方案 A：安装 Google Chrome 后重试
  方案 B：直接交付 HTML（样式完整，浏览器里 Ctrl/Cmd+P 也能存 PDF）
  方案 C：Linux 安装 chromium；Windows 安装 Edge
EOF
  exit 2
fi

TMPBASE="${TMPDIR:-/tmp}"
PROFILE="$(mktemp -d "$TMPBASE/xhs-render.XXXXXX" 2>/dev/null || echo "$TMPBASE/xhs-render-$$")"
mkdir -p "$PROFILE" 2>/dev/null || true
RENDER_HTML="$HTML"
RENDER_OUT="$OUT"
URL="file://$HTML"
OUT_ARG="$OUT"

case "$OS" in
  WindowsGitBash)
    URL="file:///$(cygpath -m "$HTML")"
    OUT_ARG="$(cygpath -m "$OUT")"
    ;;
  WSL)
    if printf '%s' "$BROWSER" | grep -qi '\.exe$'; then
      # 只有 Windows 浏览器：把整个报告目录复制到 Windows 临时目录再渲染
      WINTMP="$(cmd.exe /c "echo %TEMP%" 2>/dev/null | tr -d '\r')"
      STAGE="$(wslpath -u "$WINTMP" 2>/dev/null)/xhs-render-$$"
      mkdir -p "$STAGE"
      # 只复制报告相关资源，避免把几十 MB 的视频也拷进 Windows 临时目录
      find "$HTML_DIR" -maxdepth 1 -type f \( -name '*.html' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.webp' -o -name '*.svg' -o -name '*.css' \) -exec cp {} "$STAGE"/ \; 2>/dev/null
      RENDER_HTML="$STAGE/$HTML_NAME"
      RENDER_OUT="$STAGE/out.pdf"
      URL="file:///$(wslpath -w "$RENDER_HTML" | sed 's#\\#/#g')"
      OUT_ARG="$(wslpath -w "$RENDER_OUT" | sed 's#\\#/#g')"
      echo "[info] WSL 检测到 Windows 浏览器，已复制到临时目录渲染"
    else
      URL="file://$HTML"
    fi
    ;;
esac

echo "[1/3] 渲染：$BROWSER"
if ! "$BROWSER" --headless=new --disable-gpu --no-sandbox --no-first-run \
      --user-data-dir="$PROFILE/p1" --no-pdf-header-footer --virtual-time-budget=5000 \
      --print-to-pdf="$OUT_ARG" "$URL" >/dev/null 2>&1; then
  echo "[warn] --headless=new 失败，回退 --headless"
  "$BROWSER" --headless --disable-gpu --no-sandbox --no-first-run \
    --user-data-dir="$PROFILE/p2" --no-pdf-header-footer --virtual-time-budget=5000 \
    --print-to-pdf="$OUT_ARG" "$URL" >/dev/null 2>&1 || true
fi

[ "$RENDER_OUT" = "$OUT" ] || { [ -f "$RENDER_OUT" ] && cp "$RENDER_OUT" "$OUT"; }

if [ ! -s "$OUT" ] || [ "$(head -c 5 "$OUT" 2>/dev/null)" != "%PDF-" ]; then
  echo "[FAIL] 没有生成有效 PDF。检查：HTML 路径、浏览器权限、是否被安全软件拦截。"
  exit 2
fi

SIZE="$(wc -c < "$OUT" | tr -d ' ')"
PAGES="$(grep -a -o '/Type */Page[^s]' "$OUT" 2>/dev/null | wc -l | tr -d ' ')"
if [ "${PAGES:-0}" = "0" ]; then
  N1="$(strings "$OUT" 2>/dev/null | grep -o '/Type /Page' | wc -l | tr -d ' ')"
  N2="$(strings "$OUT" 2>/dev/null | grep -o '/Type /Pages' | wc -l | tr -d ' ')"
  PAGES=$((N1 - N2))
fi
echo "[2/3] 已生成：${OUT}（${PAGES:-?} 页，${SIZE} bytes）"

if [ "${NO_STAMP:-0}" = "1" ]; then
  echo "[3/3] 跳过页码（NO_STAMP=1）"
elif [ "$OS" = macOS ] && command -v swift >/dev/null 2>&1 && [ -f "$SCRIPT_DIR/../assets/pdf_stamp.swift" ]; then
  CACHE="${TMPBASE}/xhs-swift-cache"; mkdir -p "$CACHE"
  if CLANG_MODULE_CACHE_PATH="$CACHE" SWIFT_MODULE_CACHE_PATH="$CACHE" \
     swift -module-cache-path "$CACHE" "$SCRIPT_DIR/../assets/pdf_stamp.swift" \
     "$OUT" "$OUT.stamped.pdf" "$FOOTER" >/dev/null 2>&1; then
    mv "$OUT.stamped.pdf" "$OUT"
    echo "[3/3] 已加页脚与页码"
  else
    echo "[3/3] 页码失败，保留无页码 PDF"
  fi
else
  echo "[3/3] 跳过页码（仅 macOS 支持；不影响 PDF 使用）"
fi

rm -rf "$PROFILE" 2>/dev/null || true
echo "完成：$OUT"
