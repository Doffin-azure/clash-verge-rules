# ============================================================
# rebuild.ps1 - 用模板重建 Clash Verge 运行时配置
#
# 背景：
#   Clash Verge 只在 GUI 里"激活订阅"时才重新合并 Merge/Rules 模板。
#   命令行下无法触发。本脚本用同样的合并语义，手动重建运行时配置
#   (clash-verge.yaml)，并通过 mihomo 命名管道 reload，使其立即生效。
#
# 用法（管理员 PowerShell 可选）：
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\rebuild.ps1
#
# 说明：
#   - 会先备份当前 clash-verge.yaml 到 clash-verge.yaml.rebuildbak
#   - 需要 Clash Verge 正在运行（verge-mihomo 命名管道存在）
#   - 若之后在 GUI 里手动重载订阅，Verge 会用模板生成等价配置，效果一致
# ============================================================

$ErrorActionPreference = 'Stop'

# ---- 配置区：按需修改 ----
$VergeDir   = "$env:APPDATA\io.github.clash-verge-rev.clash-verge-rev"
$SubFile    = "$VergeDir\profiles\Ro7TtLvQPhJ2.yaml"    # 订阅原始文件
$RulesTpl   = "$VergeDir\profiles\rfM7F3l6g1MO.yaml"    # Rules 模板
$Runtime    = "$VergeDir\clash-verge.yaml"              # 运行时配置
$PipeName   = 'verge-mihomo'
# --------------------------

function Read-Utf8Lines($p) { return [System.IO.File]::ReadAllLines($p, [System.Text.Encoding]::UTF8) }
function Write-Utf8Lines($p, $lines) {
  [System.IO.File]::WriteAllLines($p, $lines, (New-Object System.Text.UTF8Encoding($false)))
}

Write-Host "[1/5] 读取文件..."
$subLines = Read-Utf8Lines $SubFile
$tplLines = Read-Utf8Lines $RulesTpl
$rtLines  = Read-Utf8Lines $Runtime

# ---- 提取运行时头部（rules: 之前的所有内容：dns / tun / proxies / proxy-groups ...）----
$rtRulesStart = -1
for ($i = 0; $i -lt $rtLines.Count; $i++) {
  if ($rtLines[$i] -match '^rules:\s*$') { $rtRulesStart = $i; break }
}
if ($rtRulesStart -lt 0) { throw '运行时配置中未找到 rules: 段' }
$head = @($rtLines[0..($rtRulesStart-1)])

# ---- 提取 Rules 模板的 prepend 规则 ----
$inPrepend = $false
$prepend = @()
foreach ($ln in $tplLines) {
  if ($ln -match '^prepend:\s*$') { $inPrepend = $true; continue }
  if ($ln -match '^(append|delete):\s*$') { $inPrepend = $false; continue }
  if ($inPrepend -and $ln -match '^\s*-\s*(.+)$') { $prepend += ('- ' + $matches[1]) }
}
Write-Host ("     prepend 规则数: " + $prepend.Count)

# ---- 提取订阅规则体（去重）----
$subRulesStart = -1
for ($i = 0; $i -lt $subLines.Count; $i++) {
  if ($subLines[$i] -match '^rules:\s*$') { $subRulesStart = $i; break }
}
if ($subRulesStart -lt 0) { throw '订阅文件中未找到 rules: 段' }

$prependSet = @{}
foreach ($r in $prepend) { $prependSet[$r] = $true }

$subBody = @()
for ($i = $subRulesStart + 1; $i -lt $subLines.Count; $i++) {
  $ln = $subLines[$i]
  if ($ln.Trim() -eq '') { continue }
  if ($ln -match '^\s*-\s*(.+)$') {
    $norm = '- ' + $matches[1]
    if (-not $prependSet.ContainsKey($norm)) { $subBody += $norm }
  } else { $subBody += $ln }
}
Write-Host ("     订阅规则数（去重后）: " + $subBody.Count)

# ---- 组装 ----
Write-Host "[2/5] 组装配置..."
$out = @()
$out += $head
$out += 'rules:'
$out += '# ===== custom direct rules (from Clash Verge Rules template prepend) ====='
$out += $prepend
$out += '# ===== subscription rules ====='
$out += $subBody

$tmp = Join-Path $env:TEMP 'clash-rebuilt.yaml'
Write-Utf8Lines $tmp $out
Write-Host ("     总行数: " + $out.Count)

# ---- 验证 ----
Write-Host "[3/5] 验证配置..."
$mihomo = 'C:\Program Files\Clash Verge\verge-mihomo.exe'
if (Test-Path $mihomo) {
  $res = & $mihomo -t -f $tmp -d $VergeDir 2>&1
  if ($res -match 'test is successful') { Write-Host '     验证成功' }
  else { Write-Host '     验证失败:'; $res | Select-Object -Last 5; throw '配置验证失败，已中止' }
} else { Write-Host '     未找到 verge-mihomo.exe，跳过验证' }

# ---- 备份并写入 ----
Write-Host "[4/5] 备份并应用..."
Copy-Item $Runtime "$Runtime.rebuildbak" -Force
Copy-Item $tmp $Runtime -Force

# ---- 通过命名管道 reload ----
Write-Host "[5/5] 重载核心..."
try {
  $pipe = New-Object System.IO.Pipes.NamedPipeClientStream('.', $PipeName, [System.IO.Pipes.PipeDirection]::InOut, [System.IO.Pipes.PipeOptions]::None)
  $pipe.Connect(2000)
  $writer = New-Object System.IO.StreamWriter($pipe); $writer.AutoFlush = $true
  $reader = New-Object System.IO.StreamReader($pipe)
  $body = '{"path":"' + ($Runtime -replace '\\','/') + '"}'
  $req = "PUT /configs HTTP/1.1`r`nHost: localhost`r`nContent-Type: application/json`r`nContent-Length: $([System.Text.Encoding]::UTF8.GetByteCount($body))`r`n`r`n$body"
  $writer.Write($req)
  Start-Sleep -Milliseconds 800
  $sb = New-Object System.Text.StringBuilder
  $buf = New-Object char[] 2048
  while ($reader.Peek() -ge 0) { $n = $reader.Read($buf,0,2048); if ($n -le 0){break}; [void]$sb.Append(-join $buf[0..($n-1)]) }
  $pipe.Dispose()
  $resp = $sb.ToString()
  if ($resp -match '204') { Write-Host '     重载成功 (204)' } else { Write-Host ('     重载返回: ' + ($resp -split "`r`n")[0]) }
} catch {
  Write-Host ('     命名管道重载失败: ' + $_.Exception.Message)
  Write-Host '     你可以手动在 Clash Verge GUI 里重新激活订阅。'
}

Write-Host ''
Write-Host '完成。当前配置已由模板重建并生效。'
