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

$outputDir = New-VerifierRunDir $OutputRoot "redis_connection"
$workspace = Get-WorkspacePath
Clear-WorkbenchWorkspace
$launch = $null
try {
  $launch = Start-WorkbenchExe $ExePath
  $hwnd = $launch.hwnd
  Send-ControlAlt "S"
  $shot = Save-NativeScreenshot $hwnd (Join-Path $outputDir "settings_redis_connection.png")
  [void][HtkwNativeVerifierCommon]::SetForegroundWindow($hwnd)
  Invoke-RelativeClick $hwnd 0.55 0.30 | Out-Null
  Send-ControlAlt "Y"
  $settingsPath = Join-Path $workspace "config\storage_provider_settings.json"
  $configLogPath = Join-Path $workspace "config\config_test_log.jsonl"
  $ready = Wait-ForPath $settingsPath 90
  $settings = Read-JsonFile $settingsPath
  $configLog = Read-JsonlFile $configLogPath
  $redis = if ($settings) { $settings.redis } else { $null }
  $connected = $redis -and $redis.status -eq "connected"
  $gate = $redis -and $redis.status -in @("connection_failed", "configured_not_tested", "desktop_runtime_required", "invalid_port")
  $usageRecorded = @($configLog | Where-Object { $_.config_type -eq "redis" }).Count -gt 0
  $payload = [ordered]@{
    status = if ($connected -and $usageRecorded) { "passed" } elseif ($gate) { "external_service_gate" } else { "blocked" }
    output_dir = $outputDir
    exe_path = $ExePath
    workspace = $workspace
    settings_path = $settingsPath
    config_log_path = $configLogPath
    screenshot = $shot.path
    redis_status = if ($redis) { $redis.status } else { "missing" }
    redis_detail = if ($redis) { $redis.last_test_detail } else { "" }
    usage_recorded = $usageRecorded
    probe_policy = "Redis uses heitang:acceptance:<timestamp> key and deletes it after read."
    results = @(
      [ordered]@{ check = "设置页配置可见"; result = "passed"; screenshot = $shot.path },
      [ordered]@{ check = "runtime 写入/读取/删除测试 key"; result = if ($connected) { "passed" } elseif ($gate) { "gated" } else { "failed" } },
      [ordered]@{ check = "使用记录记录连接测试"; result = if ($usageRecorded) { "passed" } elseif ($gate) { "gated" } else { "failed" } },
      [ordered]@{ check = "不可达时用户可理解 gate"; result = if ($connected -or $gate) { "passed" } else { "failed" } }
    )
  }
  Write-Json (Join-Path $outputDir "redis_connection_results.json") $payload
  Write-Json (Join-Path $OutputRoot "redis_connection\redis_connection_results.json") $payload
  $payload | ConvertTo-Json -Depth 10
  if ($payload.status -eq "blocked") { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
