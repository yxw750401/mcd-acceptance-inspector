# MCP 接入说明（MCP_INTEGRATION）

> 本文档说明「老麦工程验收员」如何接入麦当劳中国开放平台 MCP 服务。
> 所有内容均为 2026-10-24 实测结果。✅=已实测通过 ⚠️=实测存在坑位

## 1. 服务信息

- **服务入口**：麦当劳官方远程 MCP Server，地址 `https://mcp.mcd.cn`（Streamable HTTP）
- **凭证申请**：打开 `open.mcd.cn/mcp` → 手机号登录 → 右上角「控制台」→ 激活 MCP 服务 → 创建并复制 Token
- **认证方式**：`Authorization: Bearer <Token>`，通过环境变量 `MCD_MCP_TOKEN` 注入
- **协议版本**：⚠️ 服务端较旧，`initialize` 使用 `2025-03-26` 实测通过（更新版本握手可能失败）

## 2. 配置示例

见仓库根目录 `mcp-config.example.json`（仅环境变量占位符，不含真实凭证）：

```json
{
  "mcpServers": {
    "mcd-mcp": {
      "type": "streamablehttp",
      "url": "https://mcp.mcd.cn",
      "headers": {
        "Authorization": "Bearer ${MCD_MCP_TOKEN}"
      }
    }
  }
}
```

## 3. 服务端工具全景（tools/list 实测返回 35 个，官方文档写 33 个）

订单与门店：`query-nearby-stores`、`delivery-query-stores`、`query-meals`、`query-meal-detail`、`calculate-price`、`create-order`、`cancel-order`、`query-order`、`order-list`

优惠券与促销：`available-coupons`、`query-my-coupons`、`query-store-coupons`、`query-survey-coupon`、`auto-bind-coupons`、`query-promotions`

营养与时间：`list-nutrition-foods`、`now-time-info`

账户与积分商城：`query-my-account`、`query-my-coupons`、`query-my-prizes`、`query-lottery-info`、`draw-lottery`、`mall-points-products`、`mall-product-detail`、`mall-create-order`、`mall-order-list`、`mall-order-detail`

配送地址：`delivery-query-addresses`、`delivery-create-address`

活动与派对：`campaign-calendar`、`query-meal-assistance`、`query-party-city`、`query-party-store`、`query-party-store-date`、`query-party-store-session`、`party-order-create`

## 4. 本项目实际使用的工具（全部为只读接口）

| # | 工具名 | 用途 | 实测状态 |
|---|--------|------|----------|
| 1 | `list-nutrition-foods` | 获取 160 项真实营养成分数据（热量/蛋白/脂肪/碳水/钠/钙），作为"材料进场检验"与分项评分依据 | ✅ 通过，返回 157 条可解析 |
| 2 | `available-coupons` | 查询可领的"麦麦省"优惠券，用于监理意见中的省钱变更单 | ✅ 通过 |
| 3 | `query-nearby-stores` | 查询门店，获取 storeCode 后查菜单与门店券 | ⚠️ 实测持续返回 600014 |
| 4 | `query-meals` | 查询门店菜单与价格 | ⚠️ 依赖 3 的 storeCode |
| 5 | `query-store-coupons` | 查询指定门店可用优惠券 | ⚠️ 依赖 3 |
| 6 | `now-time-info` | 服务器时间，用于报告编号与数据时点标注 | ✅ 通过 |

**降级策略**：因门店地理编码服务在实测期间异常（见坑位 4），本项目的价格核验模块在门店链路不可用时自动降级为"营养全链路真实 + 价格标注待补报"，绝不虚构价格。

## 5. 调用流程

```
用户输入订单 ──▶ 解析餐品清单(品名×数量)
                    │
                    ├─ [MCP] list-nutrition-foods → 逐项查营养成分
                    ├─ [MCP] query-nearby-stores → storeCode ──▶ [MCP] query-meals 查价格
                    │                                          └─▶ [MCP] query-store-coupons 查门店券
                    ▼
            验收评分引擎 (scripts/inspect-order.ps1)
            · 分部分项验收: 能量/钠/脂肪/蛋白质 对照 GB/M 1024-2026
            · 隐蔽工程检查: 饮品布管/绿化工程/番茄酱包报审
                    │
                    ▼
        生成《工程验收报告》: 验收结论 + 监理意见 + 整改通知单
```

## 6. 踩坑实录（2026-10-24 实测）

1. **工具实际是 35 个**，官方 README 写 33 个；文档还把 `query-party-store-date/session` 拼错为 `partystore`，照文档抄必失败。
2. **`query-meals` 三个参数全必填**：`storeCode`、`orderType`、`beType` 缺一不可，storeCode 必须先从 `query-nearby-stores` 获取。
3. **`query-nearby-stores` 的 `searchType` 必须显式传 2**（按位置搜索），默认值 1 是搜收藏餐厅，未收藏直接报 600050；`city` 和 `keyword` 必须同时传，否则报 600058。
4. **⚠️ 地理编码异常（本项目实测期间未复现社区成功案例）**：`query-nearby-stores` 无论传 `成都市:春熙路`、`成都市:天府广场` 还是社区验证过的 `广州市:琶洲`，均持续返回 600014「没有查询到该地址」。社区 10 月中旬的接入记录均成功，判断为服务端地理编码在赛程后期异常或变更。**接入者请先跑通 nutrition 链路再调试门店链路**，并对门店数据做好降级处理。
5. **响应不是纯 JSON**：`tools/call` 返回的是「给模型看的展示指令 + 原始 JSON」混合 Markdown，且 JSON 起始位置不固定。解法：从 `{\"success\"` 起逐字符尝试 `JSON.parse`，取第一个能完整解析的对象（见 `scripts/mcp_call.ps1`）。
6. **营养表与门店菜单命名不统一**：全角/半角括号混用、新品不同名。归一化三步：Unicode NFKC → 全半角统一 → 去空格转小写，再做双向包含匹配。
7. **Windows 编码坑**：PowerShell 5.1 执行含中文的无 BOM UTF-8 脚本会按 GBK 误解码直接报语法错误。发布 .ps1 必须带 BOM。

## 7. 安全与合规设计

- **只读不写**：本项目不调用任何下单/扣款/领券绑定类写操作接口
- **不虚构数据**：MCP 查不到的信息标注"资料不全，待补报"，不编造
- **凭证隔离**：Token 仅经环境变量或仓库外文件注入，仓库内配置全部使用占位符
- **隐私最小化**：报告不输出用户账号、地址、手机号等个人数据
