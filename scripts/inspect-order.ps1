# 老麦工程验收员 · 验收报告生成引擎
# 数据来源: 麦当劳中国 MCP list-nutrition-foods (真实营养数据, 见 data/nutrition.json)
# 用法: .\inspect-order.ps1 -OrderFile .\sample-order.json [-People 2] [-OutFile report.txt]

param(
    [Parameter(Mandatory = $true)][string]$OrderFile,
    [int]$People = 1,
    [string]$OutFile
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

# ---------- 载入真实营养数据 ----------
$nutrition = Get-Content (Join-Path $repoRoot 'data\nutrition.json') -Raw -Encoding UTF8 | ConvertFrom-Json

function Get-Normalized([string]$s) {
    # 全角/半角归一 + 去空格 + 转小写 (源自实测踩坑: 营养表与菜单写法不统一)
    $s = $s -replace '（', '(' -replace '）', ')'
    $s = ($s -replace '\s+', '').ToLower()
    return $s
}

$nutritionIndex = @{}
foreach ($item in $nutrition) {
    $nutritionIndex[(Get-Normalized $item.name)] = $item
}

function Find-Food([string]$query) {
    $q = Get-Normalized $query
    if ($nutritionIndex.ContainsKey($q)) { return $nutritionIndex[$q] }
    foreach ($k in $nutritionIndex.Keys) {
        if ($k.Contains($q) -or $q.Contains($k)) { return $nutritionIndex[$k] }
    }
    return $null
}

# ---------- 读取订单 ----------
$order = Get-Content $OrderFile -Raw -Encoding UTF8 | ConvertFrom-Json

# ---------- 验收规范 (《麦门工程质量验收统一标准》GB/M 1024-2026) ----------
function Grade-Intake([double]$kcal, [double]$sodium, [double]$fat, [double]$protein) {
    $items = @()
    # 分部1: 能量供应系统
    if ($kcal -le 800) { $g1 = '合格'; $c1 = '✅' } elseif ($kcal -le 1000) { $g1 = '整改后复验'; $c1 = '⚠️' } else { $g1 = '不予验收'; $c1 = '❌' }
    $items += [pscustomobject]@{ part = '能量供应系统'; spec = '≤800 kcal'; value = ('{0:N0} kcal' -f $kcal); grade = $g1; mark = $c1 }
    # 分部2: 流体压力管线 (钠)
    if ($sodium -le 1500) { $g2 = '合格'; $c2 = '✅' } elseif ($sodium -le 2000) { $g2 = '整改后复验'; $c2 = '⚠️' } else { $g2 = '不予验收'; $c2 = '❌' }
    $items += [pscustomobject]@{ part = '钠负荷管线'; spec = '≤1500 mg'; value = ('{0:N0} mg' -f $sodium); grade = $g2; mark = $c2 }
    # 分部3: 油脂防水层
    if ($fat -le 30) { $g3 = '合格'; $c3 = '✅' } elseif ($fat -le 40) { $g3 = '整改后复验'; $c3 = '⚠️' } else { $g3 = '不予验收'; $c3 = '❌' }
    $items += [pscustomobject]@{ part = '油脂防水层'; spec = '≤30 g'; value = ('{0:N1} g' -f $fat); grade = $g3; mark = $c3 }
    # 分部4: 结构强度 (蛋白质)
    if ($protein -ge 15) { $g4 = '合格'; $c4 = '✅' } elseif ($protein -ge 10) { $g4 = '整改后复验'; $c4 = '⚠️' } else { $g4 = '不予验收'; $c4 = '❌' }
    $items += [pscustomobject]@{ part = '结构强度(蛋白质)'; spec = '≥15 g'; value = ('{0:N1} g' -f $protein); grade = $g4; mark = $c4 }
    return $items
}

# ---------- 隐蔽工程检查 ----------
function Get-HiddenFindings($orderLines) {
    $findings = @()
    $hasDrink = $false; $hasVeg = $false; $hasDessert = $false; $hasCorn = $false
    foreach ($line in $orderLines) {
        $n = Get-Normalized $line.name
        if ($n -match '可乐|雪碧|芬达|咖啡|奶茶|果汁|柠檬|冰|茶') { $hasDrink = $true }
        if ($n -match '玉米|沙拉|生菜|蔬') { $hasCorn = $true; $hasVeg = $true }
        if ($n -match '新地|旋风|派|冰淇淋|圣代') { $hasDessert = $true }
    }
    if (-not $hasDrink) { $findings += '流体输送系统未布管(未点饮品), 建议按规范补充中杯饮品一路' }
    else { $findings += '流体输送系统布管到位 ✅' }
    if (-not $hasVeg) { $findings += '绿化工程缺失(无蔬菜类配置), 出具整改通知: 建议加购玉米杯或沙拉一路' }
    else { $findings += '绿化工程覆盖到位 ✅' }
    if ($hasDessert) { $findings += '装饰装修工程已施工(检测到甜品), 结算时注意装饰造价占比' }
    $findings += '番茄酱包按需申领, 建议进场时按 2包/人 报审'
    return $findings
}

# ---------- 逐项验收 ----------
$unknown = @(); $totalKcal = 0.0; $totalProtein = 0.0; $totalFat = 0.0; $totalCarb = 0.0; $totalSodium = 0.0; $totalKj = 0.0
$lineRows = @()
foreach ($line in $order) {
    $qty = if ($line.qty) { [int]$line.qty } else { 1 }
    $food = Find-Food $line.name
    if ($null -eq $food) {
        $unknown += $line.name
        $lineRows += [pscustomobject]@{ name = $line.name; qty = $qty; kcal = '—'; status = '资料不全,待补报' }
        continue
    }
    $totalKcal += $food.energyKcal * $qty
    $totalKj += $food.energyKj * $qty
    $totalProtein += $food.protein * $qty
    $totalFat += $food.fat * $qty
    $totalCarb += $food.carbohydrate * $qty
    $totalSodium += $food.sodium * $qty
    $lineRows += [pscustomobject]@{ name = $food.name; qty = $qty; kcal = ('{0}' -f ($food.energyKcal * $qty)); status = '已进场' }
}

$perKcal = $totalKcal / $People; $perSodium = $totalSodium / $People; $perFat = $totalFat / $People; $perProtein = $totalProtein / $People
$grades = Grade-Intake $perKcal $perSodium $perFat $perProtein
$failedCount = ($grades | Where-Object { $_.grade -eq '不予验收' }).Count
$reworkCount = ($grades | Where-Object { $_.grade -eq '整改后复验' }).Count

if ($failedCount -gt 0) { $conclusion = '不予验收 (返工重配)' }
elseif ($reworkCount -gt 0) { $conclusion = '整改后复验' }
else { $conclusion = '验收合格' }

# ---------- 监理意见 ----------
$opinions = @()
if ($perKcal -gt 1000) { $opinions += '能量预算严重超支。责令: 削减主食规模一个数量级, 或将部分工程量转移至下一餐期实施。' }
elseif ($perKcal -gt 800) { $opinions += '能量预算超支。建议砍掉一份小食作为设计变更。' }
if ($perSodium -gt 2000) { $opinions += '钠负荷管线超压运行, 存在爆管风险。整改: 饮品更换为无糖/矿泉水路线。' }
if ($perProtein -lt 10) { $opinions += '结构强度不足, 主体结构存在偷工减料嫌疑。建议加购板烧鸡腿堡等承重构件。' }
if ($unknown.Count -gt 0) { $opinions += ('以下材料报审资料不全, 暂缓计量: ' + ($unknown -join '、') + '。') }
if ($opinions.Count -eq 0) { $opinions += '各分部工程均按规范施工, 监理予以放行。本报告仅供娱乐, 不构成营养建议。' } else { $opinions += '本报告仅供娱乐, 不构成营养建议。' }

# ---------- 输出报告 ----------
$now = Get-Date -Format 'yyyy-MM-dd HH:mm'
$reportNo = 'LM-YS-' + (Get-Date -Format 'yyyyMMddHHmm')
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('╔══════════════════════════════════════════════╗')
[void]$sb.AppendLine('║     麦当劳订单工程质量验收报告               ║')
[void]$sb.AppendLine("║     编号: $reportNo              ║")
[void]$sb.AppendLine('╠══════════════════════════════════════════════╣')
[void]$sb.AppendLine('一、材料进场检验清单')
foreach ($r in $lineRows) { [void]$sb.AppendLine(('   {0} x{1}  {2} kcal   [{3}]' -f $r.name, $r.qty, $r.kcal, $r.status)) }
[void]$sb.AppendLine('──────────────────────────────────────────────')
[void]$sb.AppendLine(('   合计: {0:N0} kcal | 蛋白 {1:N1} g | 脂肪 {2:N1} g | 碳水 {3:N1} g | 钠 {4:N0} mg' -f $totalKcal, $totalProtein, $totalFat, $totalCarb, $totalSodium))
[void]$sb.AppendLine(('   折算人均(就餐人数 {0} 人): {1:N0} kcal/人' -f $People, $perKcal))
[void]$sb.AppendLine('──────────────────────────────────────────────')
[void]$sb.AppendLine('二、分部分项验收 (规范: GB/M 1024-2026)')
foreach ($g in $grades) { [void]$sb.AppendLine(('   {0}  实测 {1} / 规范 {2}   {3} {4}' -f $g.part, $g.value, $g.spec, $g.mark, $g.grade)) }
[void]$sb.AppendLine('──────────────────────────────────────────────')
[void]$sb.AppendLine('三、隐蔽工程检查记录')
foreach ($f in (Get-HiddenFindings $order)) { [void]$sb.AppendLine('   · ' + $f) }
[void]$sb.AppendLine('──────────────────────────────────────────────')
[void]$sb.AppendLine(('四、验收结论: 【 {0} 】' -f $conclusion))
[void]$sb.AppendLine('五、监理意见')
foreach ($o in $opinions) { [void]$sb.AppendLine('   · ' + $o) }
[void]$sb.AppendLine('──────────────────────────────────────────────')
[void]$sb.AppendLine(('   监理单位: 老麦工程验收员    验收日期: {0}' -f $now))
[void]$sb.AppendLine('   数据来源: 麦当劳中国开放平台 MCP (真实营养数据)')
[void]$sb.AppendLine('╚══════════════════════════════════════════════╝')

$text = $sb.ToString()
if ($OutFile) { $text | Out-File $OutFile -Encoding UTF8; Write-Output "报告已保存: $OutFile" }
Write-Output $text
