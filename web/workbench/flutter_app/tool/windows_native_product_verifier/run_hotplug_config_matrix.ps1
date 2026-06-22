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

$outputDir = New-VerifierRunDir $OutputRoot "hotplug_config"
$screenshotsDir = Join-Path $outputDir "screenshots"
$workspace = Get-WorkspacePath
Clear-WorkbenchWorkspace
$launch = $null
try {
  $launch = Start-WorkbenchExe $ExePath
  $hwnd = $launch.hwnd
  Send-ControlAlt "S"
  $settingsShot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir "settings_before_hotplug.png")
  [void][HtkwNativeVerifierCommon]::SetForegroundWindow($hwnd)
  $focusClick = Invoke-RelativeClick $hwnd 0.55 0.30
  Send-FunctionKey "F10"
  $smokePath = Join-Path $workspace "acceptance\stage3_profile_persistence_smoke_report.json"
  $profileSmokeReady = Wait-ForPath $smokePath 120
  $profileSmoke = Read-JsonFile $smokePath
  $profilesPath = Join-Path $workspace "config\project_config_profiles.json"
  $runtimeStatusPath = Join-Path $workspace "config\project_config_runtime_status.json"
  $changeLogPath = Join-Path $workspace "config\profile_change_log.jsonl"
  $activationLogPath = Join-Path $workspace "config\profile_activation_log.jsonl"
  $profiles = Read-JsonFile $profilesPath
  $runtimeStatus = Read-JsonFile $runtimeStatusPath
  $changeLog = Read-JsonlFile $changeLogPath
  $activationLog = Read-JsonlFile $activationLogPath

  $rows = @()
  function Add-Row([string]$Case, [string]$Expected, [string]$Result, [string]$Artifact, [string]$Note) {
    $script:rows += [ordered]@{
      case = $Case
      expected_behavior = $Expected
      result = $Result
      artifact = $Artifact
      note = $Note
    }
  }

  Add-Row "创建项目配置 A/B" "EXE 触发 profile smoke 后应存在默认配置、云机/混合配置或复制配置。" `
    ($(if ($profileSmokeReady -and $profileSmoke.profile_count_after_smoke -ge 2) { "passed" } else { "failed" })) $profilesPath "profile_count=$($profileSmoke.profile_count_after_smoke)"
  Add-Row "切换 A/B" "激活配置应写入 activation log，runtime status 应同步 active_profile。" `
    ($(if ($profileSmokeReady -and $profileSmoke.active_profile_persisted -eq $true -and $activationLog.Count -gt 0) { "passed" } else { "failed" })) $activationLogPath "active=$($profileSmoke.final_active_profile_id)"
  Add-Row "删除 active 配置保护" "当前启用配置不得被删除。" `
    ($(if ($profileSmokeReady -and $profileSmoke.delete_active_blocked -eq $true) { "passed" } else { "failed" })) $smokePath "delete_active_blocked=$($profileSmoke.delete_active_blocked)"
  Add-Row "删除未启用配置" "未启用配置可删除，UI 路径已有二次确认。" `
    ($(if ($profileSmokeReady -and $profileSmoke.delete_inactive_succeeded -eq $true) { "passed" } else { "failed" })) $smokePath "delete_inactive_succeeded=$($profileSmoke.delete_inactive_succeeded)"
  Add-Row "配置切换后 UI 状态刷新" "runtime status module_status 应包含下游模块状态。" `
    ($(if ($profileSmokeReady -and $profileSmoke.downstream_modules_synced -eq $true) { "passed" } else { "failed" })) $runtimeStatusPath "downstream_modules_synced=$($profileSmoke.downstream_modules_synced)"
  Add-Row "导入目录隔离" "当前产品使用单本地工作区配置；独立导入目录配置未作为用户级热插拔能力暴露。" `
    "gated" $runtimeStatusPath "需要设置/本地模式"
  Add-Row "输出目录隔离" "当前产品使用单本地工作区输出；独立输出目录配置未作为用户级热插拔能力暴露。" `
    "gated" $runtimeStatusPath "需要设置/本地模式"
  Add-Row "Skill 配置隔离" "profile assets 中记录 Skill/Agent 受影响模块；细粒度 Skill profile 未实现。" `
    "gated" $runtimeStatusPath "not_implemented"
  Add-Row "Agent 配置隔离" "profile assets 中记录 Agent 模块；细粒度 Agent profile 未实现。" `
    "gated" $runtimeStatusPath "not_implemented"
  Add-Row "记忆配置隔离" "Redis/向量库未内置服务本体；本地记忆模式可用，外部记忆 gated。" `
    "gated" $runtimeStatusPath "本地模式"
  Add-Row "禁用/重新启用某项能力" "增强项启用/回滚使用 settings capability gate；未配置时不得假成功。" `
    "gated" (Join-Path $workspace "config\provider_lifecycle_history.jsonl") "需要设置/暂不可用"
  Add-Row "配置导出/导入" "当前未提供用户级配置导入/导出按钮。" `
    "not_implemented" $runtimeStatusPath "not_implemented"

  $corruptProfilesPath = $profilesPath
  if (Test-Path -LiteralPath $corruptProfilesPath) {
    "{ invalid json" | Set-Content -Encoding UTF8 -Path $corruptProfilesPath
    Stop-WorkbenchExe $launch
    $launch = Start-WorkbenchExe $ExePath
    Send-ControlAlt "S"
    Start-Sleep -Seconds 3
    $fallbackProfiles = Read-JsonFile $profilesPath
    $fallbackLog = Read-JsonlFile $changeLogPath
    $fallbackAction = @($fallbackLog | Where-Object { $_.action -eq "fallback_corrupt_profile" }).Count -gt 0
    Add-Row "配置损坏 fallback" "损坏 profile JSON 应备份并回退默认本地配置，不崩溃。" `
      ($(if ($fallbackProfiles -and $fallbackProfiles.profile_count -ge 1 -and $fallbackAction) { "passed" } else { "failed" })) $profilesPath "fallback_action=$fallbackAction"
  } else {
    Add-Row "配置损坏 fallback" "缺少 profile 文件时应创建默认配置。" "failed" $profilesPath "profile file missing after smoke"
  }
  $afterShot = Save-NativeScreenshot $launch.hwnd (Join-Path $screenshotsDir "settings_after_hotplug.png")

  $failed = @($rows | Where-Object { $_.result -eq "failed" })
  $status = if ($failed.Count -eq 0) { "passed_with_gated_optional_capabilities" } else { "blocked" }
  $payload = [ordered]@{
    status = $status
    output_dir = $outputDir
    exe_path = $ExePath
    workspace = $workspace
    settings_screenshots = @($settingsShot.path, $afterShot.path)
    profile_smoke_report = $smokePath
    profiles_path = $profilesPath
    runtime_status_path = $runtimeStatusPath
    change_log_path = $changeLogPath
    activation_log_path = $activationLogPath
    profile_smoke = $profileSmoke
    results = $rows
  }
  Write-Json (Join-Path $outputDir "hotplug_project_config_results.json") $payload
  Write-Json (Join-Path $OutputRoot "hotplug_config\hotplug_project_config_results.json") $payload
  $payload | ConvertTo-Json -Depth 14
  if ($status -eq "blocked") { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
