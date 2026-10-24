# 老麦工程验收员 · 麦当劳 MCP 通用调用器 (PowerShell 版)
# 已实测适配麦当劳 MCP Server (https://mcp.mcd.cn) 的三个坑:
#   1) 协议版本较旧, initialize 需用 2025-03-26
#   2) 响应可能是 JSON 或 SSE, 统一按文本接收
#   3) 返回体是 "说明文字 + JSON" 混合, 需提取内层 JSON
# 用法:
#   .\mcp_call.ps1 -ToolName now-time-info -Arguments '{}' [-Raw]
#   .\mcp_call.ps1 -ToolName query-meals -Arguments '{"storeCode":"xxx","orderType":1,"beType":1}' -Raw

param(
    [Parameter(Mandatory = $true)][string]$ToolName,
    [string]$Arguments = '{}',
    [switch]$Raw
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

# Token 读取优先级: 环境变量 MCD_MCP_TOKEN > 仓库外 mcd-token.local.txt (绝不入库)
$token = $env:MCD_MCP_TOKEN
if (-not $token) {
    $localTokenFile = Join-Path (Split-Path -Parent $repoRoot) 'mcd-token.local.txt'
    if (Test-Path $localTokenFile) { $token = (Get-Content $localTokenFile -Raw).Trim() }
}
if (-not $token) { throw '未找到 MCP Token。请设置环境变量 MCD_MCP_TOKEN, 或将 Token 存放到仓库上一级 mcd-token.local.txt' }

function Invoke-McdMcp([string]$jsonBody) {
    Invoke-WebRequest -Uri 'https://mcp.mcd.cn' -Method Post `
        -Headers @{ 'Authorization' = "Bearer $token"; 'Accept' = 'application/json, text/event-stream' } `
        -ContentType 'application/json' -Body $jsonBody -TimeoutSec 120 -UseBasicParsing
}

# 1) initialize (协议版本按实测: 2025-03-26 可用)
$initBody = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"mcd-acceptance-inspector","version":"1.0.0"}}}'
[void](Invoke-McdMcp $initBody)

# 2) tools/call
$callBody = '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"' + $ToolName + '","arguments":' + $Arguments + '}}'
$r = Invoke-McdMcp $callBody
$content = $r.Content

if ($Raw) { Write-Output $content; exit 0 }

# 3) 提取内层 JSON (响应 = 展示说明 + 真实JSON, 位置不固定)
$obj = $null
$idx = 0
while ($true) {
    $idx = $content.IndexOf('{"success"', $idx)
    if ($idx -lt 0) { break }
    try { $obj = $content.Substring($idx) | ConvertFrom-Json; break } catch { $idx++ }
}
if ($obj) {
    Write-Output ('success : ' + $obj.success)
    Write-Output ('code    : ' + $obj.code)
    Write-Output ('message : ' + $obj.message)
    Write-Output ('data    :')
    Write-Output ($obj.data | ConvertTo-Json -Depth 6)
} else {
    Write-Output $content
}
