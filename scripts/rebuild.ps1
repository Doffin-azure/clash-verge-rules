param(
  [Parameter(Mandatory = $true)][string]$SubFile,
  [Parameter(Mandatory = $true)][string]$RulesTpl,
  [string]$VergeDir = "$env:APPDATA\io.github.clash-verge-rev.clash-verge-rev",
  [string]$MihomoPath,
  [string]$PipeName = 'verge-mihomo'
)

$ErrorActionPreference = 'Stop'
$arguments = @(
  "$PSScriptRoot/rebuild.py",
  '--subscription', $SubFile,
  '--template', $RulesTpl,
  '--verge-dir', $VergeDir,
  '--pipe-name', $PipeName
)
if ($MihomoPath) {
  $arguments += @('--mihomo', $MihomoPath)
}

& python @arguments
if ($LASTEXITCODE -ne 0) {
  throw "Mihomo rebuild failed (exit $LASTEXITCODE)."
}
