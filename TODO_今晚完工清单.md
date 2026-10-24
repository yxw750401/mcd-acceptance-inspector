# 今晚完工清单（截止 10-25 23:59，Star 统计到 10-26 00:00）

## 阶段 0：账号准备（只能本人做，现在就去）
- [ ] open.mcd.cn 注册，领取 MCP Token（需手机号）
- [ ] GitHub 账号确认可用（没有先注册）
- [ ] git 可用：`git --version`；未安装先装 Git for Windows

## 阶段 1：接入验证（拿到 Token 后 30 分钟）
- [ ] 把真实 MCP 服务地址/工具清单填进 MCP_INTEGRATION.md 第 3 节表格
- [ ] 用一个只读工具（如查菜单）实测连通，记录实际工具名

## 阶段 2：核心开发（2—3 小时）
- [ ] scripts/ 实现验收评分逻辑（解析订单 → 查真实数据 → 出报告）
- [ ] 用一份真实订单跑通完整《验收报告》输出
- [ ] 生成 1—2 份示例报告截图放 assets/

## 阶段 3：发布（1 小时）
- [ ] 补齐 workbuddy.md 开发对话记录
- [ ] 自查敏感信息：真实 Token / 手机号 / 邮箱 绝不能进仓库
- [ ] git init → 推送到 GitHub 公开仓库（仓库名建议 mcd-acceptance-inspector）
- [ ] 加 Description、Topics（mcdonalds / mcp / workbuddy / skill）+ 仓库 Banner 图

## 阶段 4：报名提交（15 分钟）
- [ ] 到 M-China/mcd-developer-innovation-challenge 发 Issue
- [ ] 格式（注意：字段与内容之间不要换行符，地址不用 Markdown 链接）：

【参赛申请】
项目名称:老麦工程验收员(mcd-acceptance-inspector) 项目地址:https://github.com/<你的用户名>/mcd-acceptance-inspector 项目简介:用工程验收报告的格式点评麦当劳订单——分部分项验收、隐蔽工程检查、材料进场检验,基于麦当劳MCP真实菜单/营养/优惠券数据出具《验收报告》与《整改通知单》,监理意见毒舌点评,附省钱变更单

## 阶段 5：拉 Star（提交后立刻开始，越早越多）
- [ ] 朋友圈 + 微信群（行业群、同学群）发报告截图 + 仓库链接
- [ ] 写一篇短文发掘金 / 腾讯云社区（WorkBuddy 可代笔，10—20 分钟）
- [ ] 求朋友点 Star：点开仓库 → 右上角 Star，一步都不能少

## 红线自查（提交前最后过一遍）
- [ ] CONTEST_DECLARATION.md 与官方原文一致，未改动
- [ ] 仓库内无真实 Token、密码、个人凭证
- [ ] 报告输出不含用户隐私
