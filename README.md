# 老麦工程验收员 · mcd-acceptance-inspector

> 用一份正经的《工程验收报告》，验收你的麦当劳订单。
> —— 2026 麦当劳程序员创意开发大赛（1024 程序员节）参赛作品

## 这是什么

你把麦当劳订单递过来，"老麦工程验收员"——一位干了三十年弱电工程的老监理——戴上老花镜，用**工程验收报告**的格式，一本正经地给你的订单出具验收结论：

- **分部分项验收**：主食结构、饮品配置、小食配比逐项打分
- **隐蔽工程检查**：酱包有没有多要、吸管塞没塞到位、番茄酱给了几包
- **材料进场检验**：食材新鲜度、出品温度是否符合"规范"
- **验收结论**：合格 / 整改后复验 / 不予验收（返工重配）
- **监理意见**：老工程师毒舌点评，附整改通知单

把点麦当劳这件小事，做成一份能发朋友圈的《验收报告》。

## 解决什么问题

- 好玩：工程人点餐时独有的职业梗，甲方乙方都懂
- 有据：所有点评基于麦当劳 MCP 返回的**真实菜单、价格、营养数据**，不瞎编
- 能用：输入订单（或自选搭配），立即生成可分享的验收报告

## 快速开始

1. 前往 [麦当劳中国开放平台](https://open.mcd.cn/mcp) 注册并申请 MCP Token
2. 将 Token 存放到**仓库上一级**的 `mcd-token.local.txt`（或设置环境变量 `MCD_MCP_TOKEN`），切勿提交到仓库
3. 跑一份验收报告：

```powershell
.\scripts\inspect-order.ps1 -OrderFile .\assets\sample-order.json -People 1
```

4. 也可以在 WorkBuddy 中装载本 Skill（见 SKILL.md），直接说："帮我验收一下这份麦当劳订单"

## 仓库结构

```
mcd-acceptance-inspector/
├── README.md                  # 本文件
├── CONTEST_DECLARATION.md     # 官方参赛声明（原文，未改动）
├── MCP_INTEGRATION.md         # MCP 接入说明 + 35 工具全景 + 实测踩坑实录
├── SKILL.md                   # Skill 定义（触发条件与工作流）
├── workbuddy.md               # WorkBuddy 开发记录（专项奖励材料）
├── mcp-config.example.json    # 脱敏 MCP 配置示例（仅环境变量占位符）
├── LICENSE                    # MIT
├── scripts/
│   ├── inspect-order.ps1      # 验收报告生成引擎（核心）
│   └── mcp_call.ps1           # 麦当劳 MCP 通用调用器（PowerShell 版）
├── data/
│   ├── nutrition.json         # 真实营养数据（157 条，来自 MCP list-nutrition-foods）
│   └── nutrition_raw.json     # MCP 原始返回（存档）
└── assets/
    ├── sample-order.json      # 示例订单
    └── sample-report.txt      # 示例验收报告
```

## 亮点

- **榜单首个 PowerShell 实现**：无需 Python 环境，Windows 用户开箱即跑
- **数据全真实**：营养数据来自麦当劳 MCP 实时接口，查不到就标"待补报"，绝不编造
- **踩坑实录**：MCP_INTEGRATION.md 里 7 条实测坑位（协议版本、地理编码异常、混合响应解析等），后来者少走弯路

## 目标用户

- **工程行业从业者**：监理、施工、弱电、造价——验收报告就是他们的日常
- **麦门信徒**：喜欢给点餐找点乐子的普通消费者
- **想给同事整活的打工人**：帮同事的订单"出验收结论"，办公室社交货币

## 声明

本项目为麦当劳程序员节创意开发大赛参赛作品，由参赛者独立开发，非麦当劳官方产品。项目输出仅供参考，不构成营养或专业建议；餐品信息、价格及供应状态以麦当劳官方渠道实时结果为准。

## License

MIT
