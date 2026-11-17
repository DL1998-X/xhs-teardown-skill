# 更新记录

## 0.3.6

- 对外名称改为「爆款小红书笔记拆解」
- 技术标识保留 `xhs-teardown`（目录 / URL / 技能名），不影响已安装用户

## 0.3.5

- 新增 `perspective`：对标参考（reference）/ 作者复盘（author），两套报告骨架
- 评论采样自适应上限：L1 > 500 时默认 2 轮 + 1 轮高赞 + 3 条二级（6 次）
- 标准深度从 8–12 次收紧到 8–10 次

## 0.3.4

- SKILL.md 增加「这个 Skill 是什么」：输入/输出/适合谁/依赖/快速开始
- manifest 增加 description

## 0.3.3

- 默认域名统一写为 `https://creatordata.vip`（teardown / data-api / demand / 站点文档）
- 不再保留 `<数据站域名>` 占位符

## 0.3.2

- 兼容 `sk_` 与 `dk_` 两种 API Key 前缀（历史密钥）
- 作者资料兼容「嵌套」与「扁平」两种返回结构（`statistics.fansCount` / `stats.fansCount`）

## 0.3.1

- 默认数据源改为本项目服务端 `https://creatordata.vip`，不再使用上游网关
- preflight 默认检测 creatordata.vip；仍可用 `MJ_DATA_API_BASE` / `config.json` 覆盖
- README/SKILL 标注：`http://` 会 301 到 https，POST 直接用 https

## 0.3.0

- 输出可选：`pdf` / `md` / `both`（默认 both）；Markdown 可独立阅读
- 目标模式：涨粉 / 带货 / 品牌 / 招聘，按目标调整指标权重
- 决策摘要：3 个数字 + 3 个动作 + 只做一件事
- 评论意图分类 + 置顶/正面/负向话术
- 商业化与复盘：品牌匹配、议价依据、D1/D3/D7 节奏
- 跨平台：preflight / render 脚本（bash + PowerShell），支持 macOS / Linux / Windows / WSL
- 版式：7–8 页、每页 80–90%、图表规范、免责声明

## 0.2.0

- 去技术化：正文不出现接口/字段/调用次数
- 免责声明、核心结论、说明页
- PDF 模板与页码脚本

## 0.1.0

- 初版：单篇拆解、评论抽样、结构/归因/复刻
