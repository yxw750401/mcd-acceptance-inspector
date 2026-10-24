# WorkBuddy 开发记录（workbuddy.md）

> 本项目全程使用腾讯 WorkBuddy 辅助开发（WorkBuddy 专项奖励提交材料）。
> 本文档记录开发过程中的关键对话与产出，开发完成后补充完整记录。

## 开发时间线

- **2026-10-24 晚**：确定参赛创意「老麦工程验收员」——用工程验收报告格式点评麦当劳订单；WorkBuddy 协助完成仓库骨架、SKILL 设计、MCP 接入文档。

## 创意由来（WorkBuddy 对话摘要）

参赛者从事弱电安防与信息化集成行业，日常打交道的就是《验收报告》《监理意见》《整改通知单》。把"工程验收"这套职业仪式感搬到麦当劳订单上：
- 所有行业外的人也看得懂乐子（验收结论、整改通知）
- 行业内的人会心一笑（隐蔽工程检查、材料进场检验）
- 与榜单上大量"省钱/比价/营养"项目形成差异化

## WorkBuddy 承担的工作

1. 赛事规则调研与核实（官方仓库、必备文件、Issue 格式、截止时间）
2. 参赛创意头脑风暴与差异化分析
3. 仓库骨架与全套参赛文档起草
4. Skill 工作流与输出格式设计
5. （待补充）核心脚本开发、测试调优、宣传文案撰写

## 使用 WorkBuddy 的关键对话摘录

### 2026-10-24 晚 · 接入实测记录（全部由 WorkBuddy 执行）

1. **连通验证**：WorkBuddy 直接以 JSON-RPC 调用 `https://mcp.mcd.cn`，`initialize` 用 2025-03-26 协议版本握手成功，`serverInfo: mcd-mcp 1.0.0`。
2. **工具枚举**：`tools/list` 返回 35 个工具（官方文档写 33 个），已全量归档进 MCP_INTEGRATION.md。
3. **真实数据获取**：`list-nutrition-foods` 返回 160 项营养数据，WorkBuddy 解析出 157 条干净记录存为 `data/nutrition.json`；`available-coupons`、`now-time-info` 实测通过。
4. **踩坑发现**：`query-nearby-stores` 地理编码在实测期间持续报 600014（成都/广州全地址失败，与社区 10 月中旬成功记录不符），WorkBuddy 建议并实现了降级策略：营养链路全真实、门店价格链路标注"待补报"，绝不虚构数据。
5. **验收引擎开发**：WorkBuddy 编写 `scripts/inspect-order.ps1`（验收评分引擎）与 `scripts/mcp_call.ps1`（MCP 通用调用器，PowerShell 版，榜单首个），用样例订单一次跑通完整《验收报告》。
6. **Windows 编码坑**：PS 5.1 下无 BOM UTF-8 中文脚本报语法错误，WorkBuddy 定位并修复（写回带 BOM）。
