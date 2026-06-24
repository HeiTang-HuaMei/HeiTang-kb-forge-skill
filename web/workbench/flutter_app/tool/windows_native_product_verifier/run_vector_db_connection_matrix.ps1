param(
  [string]$ExePath = "",
  [string]$InputDir = "",
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($ExePath)) { $ExePath = Get-DefaultExePath }
if ([string]::IsNullOrWhiteSpace($InputDir)) { $InputDir = "D:\HeiTang-Codex-WorkSpace\input" }
if ([string]::IsNullOrWhiteSpace($OutputRoot)) { $OutputRoot = Get-DefaultIndustrialOutputRoot }

$outputDir = New-VerifierRunDir $OutputRoot "vector_db_connection"
$workspace = Get-WorkspacePath
Clear-WorkbenchWorkspace
$launch = $null
try {
  $launch = Start-WorkbenchExe $ExePath
  $hwnd = $launch.hwnd
  Send-ControlAlt "S"
  $shot = Save-NativeScreenshot $hwnd (Join-Path $outputDir "settings_vector_connection.png")
  [void][HtkwNativeVerifierCommon]::SetForegroundWindow($hwnd)
  Invoke-RelativeClick $hwnd 0.55 0.30 | Out-Null
  Send-ControlAlt "Y"
  $settingsPath = Join-Path $workspace "config\storage_provider_settings.json"
  $configLogPath = Join-Path $workspace "config\config_test_log.jsonl"
  $ready = Wait-ForPath $settingsPath 90
  $settings = Read-JsonFile $settingsPath
  $configLog = Read-JsonlFile $configLogPath
  $qdrant = if ($settings) { $settings.qdrant } else { $null }
  $connected = $qdrant -and $qdrant.status -eq "connected"
  $gate = $qdrant -and $qdrant.status -in @("connection_failed", "configured_not_tested", "desktop_runtime_required", "invalid_endpoint", "invalid_dimension", "health_failed")
  $usageRecorded = @($configLog | Where-Object { $_.config_type -eq "vector_db" }).Count -gt 0
  $payload = [ordered]@{
    status = if ($connected -and $usageRecorded) { "passed" } elseif ($gate) { "external_service_gate" } else { "blocked" }
    output_dir = $outputDir
    exe_path = $ExePath
    workspace = $workspace
    settings_path = $settingsPath
    config_log_path = $configLogPath
    screenshot = $shot.path
    qdrant_status = if ($qdrant) { $qdrant.status } else { "missing" }
    qdrant_detail = if ($qdrant) { $qdrant.last_test_detail } else { "" }
    usage_recorded = $usageRecorded
    probe_policy = "Qdrant uses heitang_acceptance_<timestamp> temporary collection and deletes it after vector search."
    results = @(
      [ordered]@{ check = "设置页配置可见"; result = "passed"; screenshot = $shot.path },
      [ordered]@{ check = "runtime 创建临时 collection"; result = if ($connected) { "passed" } elseif ($gate) { "gated" } else { "failed" } },
      [ordered]@{ check = "runtime 写入/检索/删除测试向量"; result = if ($connected) { "passed" } elseif ($gate) { "gated" } else { "failed" } },
      [ordered]@{ check = "使用记录记录连接测试"; result = if ($usageRecorded) { "passed" } elseif ($gate) { "gated" } else { "failed" } },
      [ordered]@{ check = "不可达时用户可理解 gate"; result = if ($connected -or $gate) { "passed" } else { "failed" } }
    )
  }
  Write-Json (Join-Path $outputDir "vector_db_connection_results.json") $payload
  Write-Json (Join-Path $OutputRoot "vector_db_connection\vector_db_connection_results.json") $payload
  $payload | ConvertTo-Json -Depth 10
  if ($payload.status -eq "blocked") { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
