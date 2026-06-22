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

$outputDir = New-VerifierRunDir $OutputRoot "usage_mapping"
$screenshotsDir = Join-Path $outputDir "screenshots"
$workspace = Get-WorkspacePath
Clear-WorkbenchWorkspace
$launch = $null
try {
  $launch = Start-WorkbenchExeForMainChain $ExePath
  $hwnd = $launch.hwnd
  $mainReady = Wait-ForCondition { (Get-ArtifactChecks $workspace).agent_dialogue } 300
  [void][HtkwNativeVerifierCommon]::SetForegroundWindow($hwnd)
  $focusClick = Invoke-RelativeClick $hwnd 0.55 0.30
  Send-FunctionKey "F12"
  $parallelReady = Wait-ForPath (Join-Path $workspace "tasks\parallel_validation\parallel_task_capacity_report.json") 90
  [void][HtkwNativeVerifierCommon]::SetForegroundWindow($hwnd)
  $focusClick = Invoke-RelativeClick $hwnd 0.55 0.30
  Send-FunctionKey "F10"
  $profileReady = Wait-ForPath (Join-Path $workspace "acceptance\stage3_profile_persistence_smoke_report.json") 120
  [void][HtkwNativeVerifierCommon]::SetForegroundWindow($hwnd)
  $focusClick = Invoke-RelativeClick $hwnd 0.55 0.30
  Send-FunctionKey "F11"
  $auditPath = Join-Path $workspace "audit\audit_report.json"
  $auditReady = Wait-ForPath $auditPath 60
  Send-ControlAlt "0"
  $shot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir "usage_records_page.png")
  $audit = Read-JsonFile $auditPath
  $records = if ($audit -and $audit.records) { @($audit.records) } else { @() }

  $required = @(
    @{ action = "导入路径"; event = "source_import"; required = $true },
    @{ action = "导入文件"; event = "source_import"; required = $true },
    @{ action = "导入失败"; event = "last_message"; required = $false; expected = "失败动作如最后一次失败可进入 runtime 记录；本轮主链路无失败则记录为 gated。" },
    @{ action = "资料整理"; event = "parse_chunk"; required = $true },
    @{ action = "知识库创建"; event = "build"; required = $true },
    @{ action = "知识库测试"; event = "query"; required = $true },
    @{ action = "检索"; event = "query"; required = $true },
    @{ action = "Markdown 生成"; event = "export"; required = $true },
    @{ action = "Markdown 导出"; event = "export"; required = $true },
    @{ action = "Skill 生成"; event = "generate_skill"; required = $true },
    @{ action = "外部 Skill 导入"; event = "external_skill_import"; required = $false; expected = "当前能力 gated/not_implemented 时不得假成功。" },
    @{ action = "Agent 创建"; event = "generate_agent"; required = $true },
    @{ action = "Agent 对话"; event = "agent_dialogue"; required = $true },
    @{ action = "多助手协作 gate"; event = "a2a_discussion"; required = $false; expected = "已有 A2A/多助手产物则 passed，否则 gated。" },
    @{ action = "成果打开"; event = "artifact_records"; required = $true },
    @{ action = "成果删除"; event = "delete_artifact"; required = $false; expected = "危险操作由 smoke 验证二次确认；逐条 audit 记录未设计为删除事件则 gated。" },
    @{ action = "清空记录"; event = "clear_records"; required = $false; expected = "当前未提供清空使用记录产品语义；不得伪造。" },
    @{ action = "设置保存"; event = "provider_crud_validation"; required = $false; expected = "未配置设置时可 gated。" },
    @{ action = "配置切换"; event = "stage3_profile_persistence_smoke"; required = $false; expected = "profile smoke 写入 config test log。" },
    @{ action = "配置失败"; event = "fallback_corrupt_profile"; required = $false; expected = "配置损坏 fallback 在 hotplug 矩阵验证。" },
    @{ action = "危险操作取消"; event = "dangerous_cancel"; required = $false; expected = "由危险操作 smoke 截图和产物保持验证。" },
    @{ action = "危险操作确认"; event = "dangerous_confirm"; required = $false; expected = "由危险操作 smoke 截图和产物删除验证。" }
  )

  $configLog = Read-JsonlFile (Join-Path $workspace "config\config_test_log.jsonl")
  $profileChangeLog = Read-JsonlFile (Join-Path $workspace "config\profile_change_log.jsonl")
  $artifactChecks = Get-ArtifactChecks $workspace
  $results = @()
  foreach ($item in $required) {
    $matching = @()
    if ($item.event -eq "artifact_records") {
      $matching = @($records | Where-Object {
        ($_.artifact -ne $null -and $_.artifact.ToString().Length -gt 0) -and
        ($_.status -ne "not_run" -and $_.result -ne "not_run")
      })
    } elseif ($item.event -eq "stage3_profile_persistence_smoke") {
      $matching = @($configLog | Where-Object { $_.config_type -eq "stage3_profile_persistence_smoke" })
    } elseif ($item.event -eq "fallback_corrupt_profile") {
      $matching = @($profileChangeLog | Where-Object { $_.action -eq "fallback_corrupt_profile" })
    } else {
      $matching = @($records | Where-Object {
        ($_.event -eq $item.event -or $_.action_type -eq $item.event) -and
        ($_.status -ne "not_run" -and $_.result -ne "not_run")
      })
    }
    $hasFields = $false
    foreach ($record in $matching) {
      if ($record.PSObject.Properties.Name -contains "action_type" -and
          $record.PSObject.Properties.Name -contains "time" -and
          $record.PSObject.Properties.Name -contains "object" -and
          $record.PSObject.Properties.Name -contains "result") {
        $hasFields = $true
      }
    }
    $requiredAction = [bool]$item.required
    $result = if ($matching.Count -gt 0 -and ($hasFields -or $item.event -like "stage3*" -or $item.event -eq "fallback_corrupt_profile")) {
      "passed"
    } elseif ($requiredAction) {
      "failed"
    } else {
      "gated"
    }
    $results += [ordered]@{
      action = $item.action
      event = $item.event
      result = $result
      record_count = $matching.Count
      has_action_type_time_object_result = $hasFields
      expected = if ($item.expected) { $item.expected } else { "真实操作应映射到使用记录。" }
      note = if ($result -eq "gated") { "可选或未配置能力，不写 passed。" } else { "" }
    }
  }
  $failed = @($results | Where-Object { $_.result -eq "failed" })
  $requiredMapped = @($results | Where-Object { $_.result -eq "passed" -and $_.record_count -gt 0 }).Count -ge 10
  $mainEvidenceReady = $mainReady -or $requiredMapped
  $status = if ($mainEvidenceReady -and $auditReady -and $failed.Count -eq 0) { "passed_with_gated_optional_capabilities" } else { "blocked" }
  $payload = [ordered]@{
    status = $status
    output_dir = $outputDir
    exe_path = $ExePath
    workspace = $workspace
    main_chain_ready = $mainReady
    main_evidence_ready = $mainEvidenceReady
    required_mapped_record_groups = @($results | Where-Object { $_.result -eq "passed" -and $_.record_count -gt 0 }).Count
    parallel_ready = $parallelReady
    profile_ready = $profileReady
    audit_report_path = $auditPath
    audit_ready = $auditReady
    audit_record_count = $records.Count
    artifact_checks = $artifactChecks
    screenshot = $shot.path
    results = $results
  }
  Write-Json (Join-Path $outputDir "usage_record_mapping_results.json") $payload
  Write-Json (Join-Path $OutputRoot "usage_mapping\usage_record_mapping_results.json") $payload
  $payload | ConvertTo-Json -Depth 14
  if ($status -eq "blocked") { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
