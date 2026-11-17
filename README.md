# 爆款小红书笔记拆解（xhs-teardown）

> 版本 **0.3.6**｜输出 PDF / Markdown｜支持 macOS / Linux / Windows / WSL

给一条小红书笔记链接，产出 **6–8 页 A4 PDF 报告**：核心结论、数据基准、结构画面、评论与话术、归因、复刻、商业化与复盘。

## 支持环境

| 系统 / Shell | 预检 | 渲染 PDF | 页码 |
|---|---|---|---|
| macOS（zsh/bash） | `bash scripts/preflight.sh` | `bash scripts/render_pdf.sh` | ✅ |
| Linux（bash） | `bash scripts/preflight.sh` | `bash scripts/render_pdf.sh` | ❌ |
| Windows（PowerShell 5.1+） | `powershell -ExecutionPolicy Bypass -File scripts\preflight.ps1` | `... render_pdf.ps1` | ❌ |
| Windows（Git Bash / MSYS） | `bash scripts/preflight.sh` | `bash scripts/render_pdf.sh` | ❌ |
| WSL | `bash scripts/preflight.sh` | `bash scripts/render_pdf.sh` | ❌ |

- 页码是 macOS 的 PDFKit 增强；其它系统没有页码，不影响内容。
- WSL 里优先用 Linux 的 Chrome；只有 Windows Chrome 时，脚本会自动把报告目录复制到 Windows 临时目录再渲染。
- 路径含空格/中文：脚本已加引号；手动执行时也要加引号。

## 依赖

| 依赖 | 必须 | 说明 |
|---|---|---|
| Chrome / Edge / Chromium / Brave | 出 PDF 必须 | 都没有时交付 HTML（浏览器里 Cmd/Ctrl+P 也能存 PDF） |
| 中文字体 | 必须 | macOS PingFang/Heiti，Windows 微软雅黑，Linux 建议 `fonts-noto-cjk` |
| API Key（`sk_...` / `dk_...` 历史密钥）+ 数据站地址 | 取数必须 | 默认 `https://creatordata.vip`；`http://` 会 301 到 https，建议直接用 https |
| Python 3 | 可选 | 模板填充脚本用；没有就手动改 HTML |
| Swift | 可选 | 仅 macOS 页码 |

## 安装

**Claude Code**

- macOS / Linux：放到 `~/.claude/skills/xhs-teardown/`
- Windows：放到 `%USERPROFILE%\.claude\skills\xhs-teardown\`

**claude.ai / 其它支持 Skill 的平台**：把整个目录打包上传，或把 `SKILL.md` + `reference-pdf.md` 作为知识文件附加。

**Coze / Dify**：把 `SKILL.md` 作为提示词/知识，HTTP 工具按 `reference.md` 的端点配置。

## 配置（三选一，优先级从高到低）

1. 环境变量：`MJ_DATA_API_BASE`、`MJ_DATA_API_KEY`
2. 同目录 `config.json`（复制 `config.example.json` 改名）
3. 在对话里直接告诉 Agent

```bash
export MJ_DATA_API_BASE="https://creatordata.vip"
export MJ_DATA_API_KEY="sk_xxxxxxxx"
```

Windows PowerShell：

```powershell
$env:MJ_DATA_API_BASE="https://creatordata.vip"
$env:MJ_DATA_API_KEY="sk_xxxxxxxx"
```

## 输出格式：PDF / Markdown / 两者

在请求里指定 `format`（默认 `both`）：

| format | 生成 | 适用 |
|---|---|---|
| `md` | `report.md` | 快速看结论、二次编辑、没浏览器 |
| `pdf` | `report.pdf`（内部仍生成 md） | 对外交付、打印、发客户 |
| `both` | `report.md` + `report.pdf` | 运营日常 |

- 只出 Markdown 时**不需要** Chrome，也不需要跑渲染脚本；
- 出 PDF 时先写 `report.md` 作为内容源，再填 `report.html` 渲染，避免两套内容不一致；
- 命名统一：`单篇笔记分析-<主题>.md` / `.pdf`。

## 三步跑通

```bash
# 1. 预检：浏览器、字体、渲染、数据源、key
bash scripts/preflight.sh

# 2. 对 Claude 说：分析这条笔记，目标带货
#    https://www.xiaohongshu.com/explore/...

# 3. 渲染（Agent 生成 report.html 后）
bash scripts/render_pdf.sh report.html report.pdf
```

Windows：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\preflight.ps1
powershell -ExecutionPolicy Bypass -File scripts\render_pdf.ps1 -Html report.html -Out report.pdf
```

## 降级规则（没有条件也能用）

| 缺什么 | 怎么降级 | 报告里怎么写 |
|---|---|---|
| 没有浏览器 | 交付 `report.html` | 说明「PDF 未生成，可用浏览器打印」 |
| 没有 API Key | 手动模式：用户粘贴正文/评论截图；或 demo | 标注「样本由用户提供」 |
| 模型不能读图 | 跳过 OCR | 标注「未做图片 OCR，图文信息可能不完整」 |
| 没有视频字幕 | 用 desc + 评论推断 | 标注「未获取口播，以下为推断」 |
| 没有 Swift | 跳过页码 | 不影响内容 |

## 常见问题

| 现象 | 处理 |
|---|---|
| `Failed to create a unique user data directory` | 用脚本（已带 `--user-data-dir`） |
| PDF 空白 | 检查 HTML 路径；把 `--virtual-time-budget` 加到 8000 |
| 中文变方框 | 安装中文字体；Linux 用 `fonts-noto-cjk` |
| PowerShell 禁止运行脚本 | 加 `-ExecutionPolicy Bypass` |
| 页脚跑到页顶 | 不要用 `position:fixed`，用 `pdf_stamp.swift` |
| WSL 渲染失败 | 优先装 Linux Chrome；脚本对 Windows Chrome 会自动复制目录 |

## 目录

```
SKILL.md              主流程
README.md             本文件
CHECKLIST.md          交付验收（可选）
config.example.json   配置模板
reference-pdf.md      PDF 版式、图表、渲染
reference-pdf.md      PDF 版式、图表、渲染
assets/               模板、md 模板、样例、页码脚本
scripts/              预检与渲染（sh / ps1）
```

## 示例说明

`assets/report-example.html` 为脱敏示例：人物、品牌、账号、链接均已替换为虚构内容，图片使用 `placeholder.svg`，仅用于演示版式。

## 授权

本仓库默认保留所有权利（All rights reserved）。未经作者书面许可，不得将本 Skill 或其模板用于商业再分发、售卖或二次打包销售；个人使用与内部团队使用不受限制。
