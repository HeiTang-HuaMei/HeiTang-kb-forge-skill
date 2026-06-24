param(
  [string]$ExePath = "",
  [string]$OutputRoot = "",
  [int]$TimeoutSeconds = 240,
  [switch]$ClearWorkspace
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($ExePath)) {
  $ExePath = Get-DefaultExePath
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\capability_blackbox"
}

function Add-MatrixRow(
  [System.Collections.ArrayList]$Rows,
  [string]$PathName,
  [string]$Step,
  [string]$Expected,
  [string]$Actual,
  [string]$ScreenshotPath,
  [string]$DataFilePath,
  [bool]$Persistent,
  [bool]$ReentryVerified,
  [bool]$RestartVerified,
  [string]$Conclusion,
  [string]$Blocker = ""
) {
  [void]$Rows.Add([ordered]@{
    path = $PathName
    step = $Step
    expected_result = $Expected
    actual_result = $Actual
    screenshot_path = $ScreenshotPath
    data_file_path = $DataFilePath
    is_persistent = $Persistent
    reentry_verified = $ReentryVerified
    restart_exe_verified = $RestartVerified
    conclusion = $Conclusion
    blocker = $Blocker
  })
}

function Test-HasRows($Rows, [string]$ConfigType) {
  return @($Rows | Where-Object { $_.config_type -eq $ConfigType }).Count -gt 0
}

function Test-SecretMasked($ProviderSettings, $StorageSettings) {
  $providerMasked = $ProviderSettings.secret_plaintext_written -eq $false -and
    ([string]$ProviderSettings.llm.api_key_display).Contains("*")
  $storageMasked = ([string]$StorageSettings.redis.password_display).Contains("*")
  return $providerMasked -and $storageMasked
}

function Wait-ForSettingsSummary([string]$Path, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    if (Test-Path -LiteralPath $Path) {
      $summary = Read-JsonFile $Path
      if ($summary -and $summary.status) { return $true }
    }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $false
}

if ($ClearWorkspace) {
  Clear-WorkbenchWorkspace
}

$workspace = Get-WorkspacePath
$runDir = New-VerifierRunDir $OutputRoot "settings_export"
$matrixPath = Join-Path $OutputRoot "settings_export_matrix.json"
$reportPath = Join-Path (Get-AppRoot) "..\..\..\docs\audits\current\settings_export_blackbox_report.md"
$summaryPath = Join-Path $workspace "acceptance\settings_export_basic_summary.json"
$providerSettingsPath = Join-Path $workspace "config\provider_runtime_settings.json"
$providerValidationPath = Join-Path $workspace "config\provider_validation_report.json"
$exporterSettingsPath = Join-Path $workspace "config\exporter_settings.json"
$exporterValidationPath = Join-Path $workspace "config\exporter_validation_report.json"
$storageSettingsPath = Join-Path $workspace "config\storage_provider_settings.json"
$configLogPath = Join-Path $workspace "config\config_test_log.jsonl"
$profilesPath = Join-Path $workspace "config\project_config_profiles.json"
$runtimeStatusPath = Join-Path $workspace "config\project_config_runtime_status.json"
$profileSmokePath = Join-Path $workspace "acceptance\stage3_profile_persistence_smoke_report.json"
$rows = [System.Collections.ArrayList]::new()
$launch = $null

try {
  $launch = Start-WorkbenchExeWithEnv $ExePath @{ HEITANG_P0_SETTINGS_EXPORT_E2E = "1" }
  Set-NativeWindowSize $launch.hwnd 1440 900
  $initialShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\settings_export_initial.png")
  $summaryReady = Wait-ForSettingsSummary $summaryPath $TimeoutSeconds
  $afterShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\settings_export_after_e2e.png")

  $summary = Read-JsonFile $summaryPath
  $providerSettings = Read-JsonFile $providerSettingsPath
  $providerValidation = Read-JsonFile $providerValidationPath
  $exporterSettings = Read-JsonFile $exporterSettingsPath
  $exporterValidation = Read-JsonFile $exporterValidationPath
  $storageSettings = Read-JsonFile $storageSettingsPath
  $configLog = Read-JsonlFile $configLogPath
  $profiles = Read-JsonFile $profilesPath
  $runtimeStatus = Read-JsonFile $runtimeStatusPath
  $profileSmoke = Read-JsonFile $profileSmokePath

  $providerOk = $summaryReady -and
    (Test-Path -LiteralPath $providerSettingsPath) -and
    (Test-Path -LiteralPath $providerValidationPath) -and
    $providerSettings.secret_plaintext_written -eq $false -and
    ([string]$providerSettings.llm.api_key_display).Contains("*") -and
    $providerValidation.status -in @("pass", "passed", "saved", "configuration_valid")
  Add-MatrixRow $rows "P0-8 Settings / Path / Export" "Provider 设置保存与验证" `
    "Provider settings 和 validation report 必须真实落盘，密钥只保存掩码或引用。" `
    "settings=$(Test-Path -LiteralPath $providerSettingsPath); validation=$(Test-Path -LiteralPath $providerValidationPath); secret_plaintext=$($providerSettings.secret_plaintext_written)" `
    $afterShot.path $providerValidationPath $providerOk $providerOk $false `
    ($(if ($providerOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($providerOk) { "" } else { "provider_settings_validation_blocked" }))

  $exporterRoot = [string]$exporterSettings.export_root
  $exporterOk = $summaryReady -and
    (Test-Path -LiteralPath $exporterSettingsPath) -and
    (Test-Path -LiteralPath $exporterValidationPath) -and
    $exporterRoot.StartsWith($workspace, [System.StringComparison]::OrdinalIgnoreCase) -and
    $exporterValidation.status -in @("pass", "passed", "ready", "validated")
  Add-MatrixRow $rows "P0-8 Settings / Path / Export" "导出路径与导出器验证" `
    "Exporter settings 必须保存本地 export_root，validation report 必须真实落盘。" `
    "export_root=$exporterRoot; validation_status=$($exporterValidation.status)" `
    $afterShot.path $exporterValidationPath $exporterOk $exporterOk $false `
    ($(if ($exporterOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($exporterOk) { "" } else { "exporter_settings_validation_blocked" }))

  $storageOk = $summaryReady -and
    (Test-Path -LiteralPath $storageSettingsPath) -and
    ($storageSettings.redis.status -in @("connected", "connection_failed", "configured_not_tested", "invalid_port", "auth_failed", "ping_failed", "probe_failed")) -and
    ($storageSettings.qdrant.status -in @("connected", "connection_failed", "configured_not_tested", "invalid_endpoint", "health_failed", "collection_create_failed", "collection_check_failed", "vector_write_failed", "vector_search_failed", "vector_delete_failed")) -and
    (Test-SecretMasked $providerSettings $storageSettings)
  Add-MatrixRow $rows "P0-8 Settings / Path / Export" "存储连接 Gate" `
    "Redis / Qdrant 未配置时不得假成功，必须写入可理解状态且不泄露密钥。" `
    "redis=$($storageSettings.redis.status); qdrant=$($storageSettings.qdrant.status); secret_masked=$(Test-SecretMasked $providerSettings $storageSettings)" `
    $afterShot.path $storageSettingsPath $storageOk $storageOk $false `
    ($(if ($storageOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($storageOk) { "" } else { "storage_connection_gate_blocked" }))

  $configLogOk = $summaryReady -and
    (Test-Path -LiteralPath $configLogPath) -and
    (Test-HasRows $configLog "provider_runtime") -and
    (Test-HasRows $configLog "exporter") -and
    (Test-HasRows $configLog "settings_export_basic")
  Add-MatrixRow $rows "P0-8 Settings / Path / Export" "配置测试记录" `
    "config_test_log.jsonl 必须记录 provider、exporter 和 settings_export_basic 验收。" `
    "log_count=$($configLog.Count); provider=$(Test-HasRows $configLog 'provider_runtime'); exporter=$(Test-HasRows $configLog 'exporter'); settings=$(Test-HasRows $configLog 'settings_export_basic')" `
    $afterShot.path $configLogPath $configLogOk $configLogOk $false `
    ($(if ($configLogOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($configLogOk) { "" } else { "config_test_log_missing" }))

  $profileOk = $summaryReady -and
    (Test-Path -LiteralPath $profilesPath) -and
    (Test-Path -LiteralPath $runtimeStatusPath) -and
    (Test-Path -LiteralPath $profileSmokePath) -and
    $profileSmoke.status -eq "passed" -and
    $profileSmoke.active_profile_persisted -eq $true
  Add-MatrixRow $rows "P0-8 Settings / Path / Export" "配置档持久化与重载" `
    "Project config profile 必须能保存、切换、回滚保护，并在 reload 后保持 active profile。" `
    "profile_smoke=$($profileSmoke.status); active_persisted=$($profileSmoke.active_profile_persisted); active_profile=$($runtimeStatus.active_profile.profile_id)" `
    $afterShot.path $profileSmokePath $profileOk $profileOk $false `
    ($(if ($profileOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($profileOk) { "" } else { "project_config_profile_persistence_blocked" }))

  $summaryOk = $summaryReady -and $summary.status -eq "settings_export_basic_completed_needs_owner_review"
  Add-MatrixRow $rows "P0-8 Settings / Path / Export" "基础验收 Summary" `
    "settings_export_basic_summary.json 必须写入 needs_owner_review 状态，且不声明生产/发布/工业级完成。" `
    "summary_status=$($summary.status); external_provider_executed=$($summary.external_provider_executed); office_adapter=$($summary.external_office_adapter_executed)" `
    $afterShot.path $summaryPath $summaryOk $summaryOk $false `
    ($(if ($summaryOk) { "settings_export_basic_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($summaryOk) { "" } else { "settings_export_summary_blocked" }))

  Stop-WorkbenchExe $launch
  $launch = Start-WorkbenchExe $ExePath
  Set-NativeWindowSize $launch.hwnd 1440 900
  $restartShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\settings_export_after_restart.png")
  $restartPaths = @(
    $summaryPath,
    $providerSettingsPath,
    $providerValidationPath,
    $exporterSettingsPath,
    $exporterValidationPath,
    $storageSettingsPath,
    $configLogPath,
    $profilesPath,
    $runtimeStatusPath,
    $profileSmokePath
  )
  $restartMissing = @($restartPaths | Where-Object { -not (Test-Path -LiteralPath $_) })
  $restartOk = $restartMissing.Count -eq 0
  Add-MatrixRow $rows "P0-8 Settings / Path / Export" "重启 EXE 后配置仍可查看" `
    "重启后 settings/export/config/profile 验收产物仍存在。" `
    "missing_after_restart=$($restartMissing -join ',')" `
    $restartShot.path $workspace $restartOk $restartOk $true `
    ($(if ($restartOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($restartOk) { "" } else { "settings_export_restart_persistence_blocked" }))

  $blocked = @($rows | Where-Object { $_.conclusion -eq "blocked" })
  $status = if ($blocked.Count -eq 0) {
    "settings_export_basic_completed_needs_owner_review"
  } else {
    "settings_export_basic_blocked"
  }

  $payload = [ordered]@{
    schema_version = "heitang_p0_settings_export_blackbox_matrix.v1"
    status = $status
    workspace = $workspace
    run_dir = $runDir
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    rows = $rows
    summary_path = $summaryPath
    provider_settings_path = $providerSettingsPath
    provider_validation_path = $providerValidationPath
    exporter_settings_path = $exporterSettingsPath
    exporter_validation_path = $exporterValidationPath
    storage_settings_path = $storageSettingsPath
    config_test_log_path = $configLogPath
    profiles_path = $profilesPath
    runtime_status_path = $runtimeStatusPath
    profile_smoke_path = $profileSmokePath
  }
  Write-Json $matrixPath $payload
  Write-Json (Join-Path $runDir "settings_export_matrix.json") $payload

  $blockerText = if ($blocked.Count -eq 0) {
    "- 无 P0-8 直接阻断项，等待 Owner 复核。"
  } else {
    ($blocked | ForEach-Object { "- $($_.blocker)" }) -join "`n"
  }
  $report = @(
    "# P0-8 Settings / Path / Export Blackbox Report",
    "",
    "状态：$status",
    "",
    "## 黑盒路径",
    "",
    "1. 启动真实 Windows EXE，并通过 HEITANG_P0_SETTINGS_EXPORT_E2E=1 执行设置、路径与导出基础验收。",
    "2. 保存并验证 Provider 设置，检查密钥只保留掩码或引用。",
    "3. 保存并验证 Exporter 设置，检查 export_root 在当前工作区内。",
    "4. 执行 Redis / Qdrant 连接 Gate，未配置时不得假成功。",
    "5. 执行 Project Config Profile 持久化 smoke。",
    "6. 检查 config_test_log、runtime status、summary 产物。",
    "7. 重启 EXE 后复核配置和验收产物仍存在。",
    "",
    "## 数据文件路径",
    "",
    "- workspace: $workspace",
    "- matrix: $matrixPath",
    "- run dir: $runDir",
    "- summary: $summaryPath",
    "- provider settings: $providerSettingsPath",
    "- exporter settings: $exporterSettingsPath",
    "- storage settings: $storageSettingsPath",
    "- config log: $configLogPath",
    "- profile smoke: $profileSmokePath",
    "",
    "## 截图路径",
    "",
    "- initial: $($initialShot.path)",
    "- after e2e: $($afterShot.path)",
    "- after restart: $($restartShot.path)",
    "",
    "## 验证结论",
    "",
    "- blocked rows: $($blocked.Count)",
    "- current status: $status",
    "",
    "## 补充计划动态合并检查",
    "",
    "本 Gate 只合并与 P0-8 设置、路径、导出基础能力直接重叠的内容：配置持久化、导出路径、连接 Gate、密钥掩码、重启恢复和审计记录。",
    "",
    "延后内容：连接配置工业化、Credential Proxy、Policy Governance、Office Adapter、远程控制、多模型调度和发布 Gate 均未在本 Gate 实现。",
    "",
    "## 未验证内容",
    "",
    "- 未验证真实外部 Redis/Qdrant 服务连接成功；未配置时只验证 Gate 和失败记录。",
    "- 未接入 OfficeCLI 或外部 Office Adapter。",
    "- 未做 Release / Tag / Push。",
    "",
    "## 仍阻断项",
    "",
    $blockerText
  ) -join "`n"
  $reportParent = Split-Path -Parent $reportPath
  if ($reportParent) { New-Item -ItemType Directory -Force -Path $reportParent | Out-Null }
  $report | Set-Content -Encoding UTF8 -Path $reportPath

  Write-Json (Join-Path $runDir "summary.json") ([ordered]@{
    status = $status
    matrix_path = $matrixPath
    report_path = $reportPath
    blocked_count = $blocked.Count
  })
  Write-Output "status=$status"
  Write-Output "matrix=$matrixPath"
  Write-Output "report=$reportPath"
  if ($blocked.Count -gt 0) { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
