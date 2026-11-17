# PDF 报告：模板、图表与渲染

单篇分析的默认交付物是 **A4 PDF（6–10 页，含 3–4 个图表）**。本文件是可执行的操作手册。

## 1. 文件怎么放

```
<笔记数据目录>/
├── report.html          # 从 assets/report-example.html 复制后改写
├── cover.png            # 笔记封面（原图）
├── frame_000.jpg …      # 视频抽帧（可选，仅视频笔记）
├── report.pdf           # Chrome 输出
└── report-final.pdf     # 加盖页码后的交付文件
```

- 模板：`assets/report-example.html`（已填好一份完整样例，直接改内容，**不要从零写 CSS**）；
- 页码脚本：`assets/pdf_stamp.swift`（macOS 可选）；
- 图片用**同目录相对路径**（`src="cover.png"`），一起移动即可。

## 2. 改写清单（逐项替换，别漏）

| 位置 | 要改什么 |
|---|---|
| `.cover-title` / `.cover-sub` | 笔记标题、一句话结论 |
| `.cover-stats` | 4 个核心数字（赞 / 藏 / 评 / 粉丝或倍数） |
| `.cover-badge` / `.cover-verdict` | 结论标签与一句诊断 |
| `.cover-meta` | 作者、粉丝、发布日期、noteId |
| `.cover-art img` | 封面图；`object-fit:cover` 会裁切，优先 3:4 原图 |
| `01 结论` | lede、8 个 KPI、基线条形图、3 条读数 |
| `02 结构` | 时间轴分段、结构表 |
| `03 画面` | 两张代表帧 + 图注 + 口播引用 |
| `04 评论` | 环形图、引用、共识/分歧/缺口 |
| `05 归因` | 起量/失效两组原因 + 置信度 + 反事实 |
| `06 复刻` | 三套方案、标题、指标、风险 |
| `07 方法` | 来源、样本量、局限、关键评论清单 |

**去样例化检查**（必须为 0）：

```bash
grep -n "6ad6d551\|王十一\|康尔馨\|开云" report.html
```

## 2.4 版式密度（避免"散"）

- 目标 **7–8 页，每页填充 80–90%**；不要一节强制一页，短章节要合并；
- 内容不足时：放大图表/图片、补一条高赞评论、加"怎么验证""下一步选题"，而不是留白；
- 图片统一容器高度（如 76mm）+ `object-fit:cover`，图注同一基线；
- 每页最多一个 callout（米色框），相邻页不要重复同款；流程用编号 + 竖分隔线，不用浮动箭头；
- 附录页放：说明表 + 评论清单 + 未获取项 + 复盘计划，避免只有一张小表；
- 决策摘要页用「3 个数字 + 3 个动作」代替长段结论，运营者第一眼就能排期。

## 2.5 写作口径（去技术化）

- 正文不出现：接口名、字段名、调用次数、抽帧数量、上游网关、ASR、帧号等技术细节；
- 样本与来源用业务语言：`13 条一级评论（全部）`、`封面与 3 张关键画面`、`视频 147 秒`；
- 局限只写：`字幕为视频音频识别生成，可能存在个别错字，请以画面文字为准。`
- 报告末尾固定放免责声明（内容来自公开信息，仅供参考）。

## 3. 图表规范（至少 3 个）

### 3.1 条形图：本篇 vs 账号基线

```html
<div class="bar-row hl">
  <span>本篇</span>
  <div class="bar-track"><div class="bar-fill" style="width:76%"></div></div>
  <span class="bar-val">2,562</span>
</div>
```

- `width = 本行数值 ÷ 三行最大值 × 100`，保留 1 位小数；
- 本篇一行加 `hl`（红色），基线用绿色；
- 只在数值差异 <20 倍时用条形；差异过大改用「倍数」大字（如 `3.2×`）。

### 3.2 环形图：评论议题占比

```html
<circle cx="70" cy="70" r="54" fill="none" stroke="#B4472F" stroke-width="17"
        stroke-dasharray="210.4 339.3" stroke-dashoffset="0"
        transform="rotate(-90 70 70)"/>
```

- 周长 `C = 2π × 54 = 339.29`；
- 每段 `dasharray = 占比 × C`，后面固定跟 `C`；
- `dashoffset` = 前面所有段长度之和的**负值**（第一段 0，第二段 `-210.4`，第三段 `-261.3`）；
- 段数 ≤ 4；占比 <5% 的合并为「其他」；
- 圆环中心写 `n`，图注写口径与「样本小不作外推」。

### 3.3 时间轴：视频/图文节奏

```html
<div class="tl-bar">
  <div class="tl-seg hook" style="width:3.5%"></div>
  <div class="tl-seg story" style="width:27.7%">名人事实</div>
  <div class="tl-seg product" style="width:22.7%">产品</div>
</div>
```

- `width = (end - start) ÷ 总时长 × 100`，六段合计 100%；
- 颜色语义：`hook` 黑=钩子，`story` 灰绿=故事，`content` 深绿=内容，`product` 红=产品，`cta` 金=收尾；
- 太窄（<8%）的段不放文字，靠下方 legend 标时间；
- legend 必须写清每段起止时间，不要依赖坐标刻度。

### 3.4 硬规则

- **不虚构数据**：没有的数据用「未获取」，不要画空图或补数；
- **标样本量**：每张图右下角写 `n = ?` / 「全量」；
- **不用双轴、3D、渐变填充**；颜色不超过 5 种；
- 图表结论写在图注里（一句话），不要让读者自己算。

## 4. 渲染成 PDF

**优先用脚本**，不要手拼 Chrome 参数：

```bash
bash scripts/preflight.sh                    # 先自检：浏览器/字体/数据源
bash scripts/render_pdf.sh report.html report.pdf
```

Windows PowerShell：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\preflight.ps1
powershell -ExecutionPolicy Bypass -File scripts\render_pdf.ps1 -Html report.html -Out report.pdf
```

脚本会做这些事：

- 按 Chrome → Edge → Chromium → Brave 探测（`CHROME_PATH` 可覆盖）；
- 自动加 `--user-data-dir`、`--no-pdf-header-footer`、`--virtual-time-budget`；
- 路径含空格/中文自动加引号；
- Windows Git Bash 用 `cygpath` 转 `file://`；WSL 只有 Windows Chrome 时自动复制目录；
- 校验 `%PDF-`、统计页数；macOS 自动加页码，其它系统跳过。

手动命令（仅脚本不可用时）：

```bash
"$CHROME" --headless=new --disable-gpu --no-sandbox --no-first-run \
  --user-data-dir=/tmp/xhs-render \
  --no-pdf-header-footer --virtual-time-budget=5000 \
  --print-to-pdf="$PWD/report.pdf" "file://$PWD/report.html"
```

要点：

- `--user-data-dir` **必加**，否则 macOS 上报 `Failed to create a unique user data directory for headless`；
- 用 `file://` 绝对路径，不用 `http://localhost`；
- 检查输出：存在、`%PDF-` 开头、页数 7–8；
- 没有浏览器：交付 HTML，说明「浏览器 Cmd/Ctrl+P 可存 PDF」。

## 5. 页码（可选，macOS）

Chrome 打印**不支持** `@page` 页边距框，也不要用 `position:fixed` 做页脚（会跑到页面顶部）。需要页码时用 PDFKit 叠加，保留矢量：

```bash
swift assets/pdf_stamp.swift report.pdf report-final.pdf "数据站 · 单篇笔记分析 · 内容来自公开信息"
```

- 跳过封面；页脚左侧为传入文案，右侧为 `02 / 08`；
- 页脚文案默认带「内容来自公开信息」，与末页免责声明呼应；
- 没有 Swift / 非 macOS：跳过此步，报告本身已完整，不要用 CSS 伪造页码。

## 6. 质检清单（交付前逐条过）

1. **页数** 6–10 页，无空白页、无半页孤行；
2. **封面** 标题无单字换行（「的？」掉行），封面图未被裁掉关键文字；
3. **图表** 条形比例正确、环形合计 100%、时间轴合计 100%；
4. **文字** 没有被裁切/溢出（逐页渲染成图看一遍）；
5. **字体** 中文正常（无方框/豆腐块），标题 Songti、正文 PingFang；
6. **图片** 全部加载（没有灰块/裂图），图注带来源与时间；
7. **页码** 若加了，编号连续、与总页数一致；
8. **无样例残留** 旧 noteId、旧作者名、旧品牌名 grep 为 0；
9. **样本与局限** 评论 n、抽帧数、未获取项都写明；
10. **体积** 2–15MB（过大通常是原图未压缩）。

## 7. 常见问题

| 现象 | 原因 | 处理 |
|---|---|---|
| 生成失败，提示 user data directory | 缺 `--user-data-dir` | 加参数，指向 `/tmp` 下目录 |
| PDF 空白 | `file://` 路径错 / 等待时间太短 | 用绝对路径，`--virtual-time-budget` 加到 8000 |
| 背景色、深色封面丢失 | 未开彩色打印 | `html{-webkit-print-color-adjust:exact}` |
| 整页被缩小、四周留白 | 有元素宽于版心，触发 shrink-to-fit | 去掉超宽元素或改用 `max-width:100%` |
| 页脚出现在页顶 | 用了 `position:fixed` | 删掉，改用 PDFKit 叠加 |
| 中文变方框 | 字体不存在 | 换 `Noto Sans CJK SC` / `Microsoft YaHei` |
| 页码不显示 | Chrome 不支持 `@page` margin box | 用 `pdf_stamp.swift` |

## 8. 只交 Markdown 的情况

`format=md`，或用户明确只要文字/在聊天里快速看结论时，不生成 PDF：

- 按 `assets/report-template.md` 输出 `report.md`；
- 不跑 preflight / render；
- Markdown 要能独立阅读：结论、数据、评论原话、归因、复刻、免责声明齐全；
- 交付时说明「未生成 PDF 版，可随时补渲染」。
