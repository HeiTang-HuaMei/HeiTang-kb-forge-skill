param(
  [string]$ExePath = "",
  [string]$OutputRoot = "",
  [int]$TimeoutSeconds = 180,
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
  [string]$DataFilePath,
  [bool]$Persistent,
  [bool]$RestartVerified,
  [string]$Conclusion,
  [string]$Blocker = ""
) {
  [void]$Rows.Add([ordered]@{
    path = $PathName
    step = $Step
    expected = $Expected
    actual = $Actual
    data_file_path = $DataFilePath
    persisted = $Persistent
    exe_restart_verified = $RestartVerified
    current_conclusion = $Conclusion
    blocker = $Blocker
  })
}

function Wait-ForArtifacts([string[]]$Paths, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    $missing = @($Paths | Where-Object { -not (Test-Path -LiteralPath $_) })
    if ($missing.Count -eq 0) { return $true }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $false
}

if ($ClearWorkspace) {
  Clear-WorkbenchWorkspace
}

$workspace = Get-WorkspacePath
$matrixDir = Join-Path $OutputRoot "agent_memory_minimal_core"
$runDir = New-VerifierRunDir $matrixDir "agent_memory_minimal_core"
$matrixPath = Join-Path $OutputRoot "agent_memory_minimal_core_matrix.json"
$reportPath = Join-Path (Get-AppRoot) "..\..\..\docs\audits\current\agent_memory_minimal_core_report.md"
$snapshotPath = Join-Path $workspace "task_memory\task_memory_snapshot.json"
$checkpointPath = Join-Path $workspace "task_memory\task_checkpoint.json"
$failurePath = Join-Path $workspace "task_memory\failure_placeholder.json"
$resumePath = Join-Path $workspace "task_memory\resume_pointer.json"
$summaryPath = Join-Path $workspace "acceptance\agent_memory_minimal_core_summary.json"
$ledgerPath = Join-Path $workspace "audit\event_ledger.jsonl"
$artifactCatalogPath = Join-Path $workspace "artifacts\catalog.json"
$rows = [System.Collections.ArrayList]::new()
$launch = $null

try {
  $launch = Start-WorkbenchExeWithEnv $ExePath @{ HEITANG_P0_AGENT_MEMORY_MINIMAL_CORE_E2E = "1" }
  Set-NativeWindowSize $launch.hwnd 1440 900

  $requiredPaths = @(
    $snapshotPath,
    $checkpointPath,
    $failurePath,
    $resumePath,
    $summaryPath,
    $ledgerPath,
    $artifactCatalogPath
  )
  $pathsReady = Wait-ForArtifacts $requiredPaths $TimeoutSeconds

  Stop-WorkbenchExe $launch
  $launch = $null
  $launch = Start-WorkbenchExe $ExePath
  Set-NativeWindowSize $launch.hwnd 1440 900
  $restartReady = Wait-ForArtifacts $requiredPaths 60

  $snapshot = Read-JsonFile $snapshotPath
  $checkpoint = Read-JsonFile $checkpointPath
  $resume = Read-JsonFile $resumePath
  $summary = Read-JsonFile $summaryPath
  $events = @(Read-JsonlFile $ledgerPath)
  $artifactCatalog = Read-JsonFile $artifactCatalogPath
  [array]$artifacts = if ($null -ne $artifactCatalog -and $null -ne $artifactCatalog.artifacts) { $artifactCatalog.artifacts } else { @() }
  $memoryEvent = $events | Where-Object { $_.event_type -eq "memory_snapshot_created" } | Select-Object -Last 1
  $snapshotArtifact = $artifacts | Where-Object { $_.artifact_id -eq "task_memory_snapshot" } | Select-Object -First 1

  [array]$remaining = if ($null -ne $snapshot -and $null -ne $snapshot.remaining) { $snapshot.remaining } else { @() }
  [array]$needsOwnerReview = if ($null -ne $snapshot -and $null -ne $snapshot.needs_owner_review) { $snapshot.needs_owner_review } else { @() }
  [array]$blocked = if ($null -ne $snapshot -and $null -ne $snapshot.blocked) { $snapshot.blocked } else { @() }
  $expectedGate = "P0-4C Agent Memory Minimal Core Gate"

  $snapshotOk = $pathsReady -and $restartReady -and
    $snapshot.schema_version -eq "heitang_task_memory_snapshot.v1" -and
    $snapshot.snapshot_type -eq "task_memory_snapshot" -and
    $snapshot.current_gate -eq $expectedGate -and
    $needsOwnerReview.Count -gt 0 -and
    $remaining.Count -gt 0 -and
    $snapshot.global_goal_complete -eq $false
  Add-MatrixRow $rows "P0-4C Agent Memory Minimal Core" "task memory snapshot" `
    "task_memory_snapshot 必须持久化 current_gate、needs_owner_review、blocked、remaining，并在 remaining 非空时 global_goal_complete=false。" `
    "gate=$($snapshot.current_gate); remaining=$($remaining.Count); needs_owner_review=$($needsOwnerReview.Count); blocked=$($blocked.Count); global_goal_complete=$($snapshot.global_goal_complete)" `
    $snapshotPath $snapshotOk $restartReady `
    ($(if ($snapshotOk) { "agent_memory_minimal_core_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($snapshotOk) { "" } else { "task_memory_snapshot_blocked" }))

  $checkpointOk = $pathsReady -and $restartReady -and
    $checkpoint.schema_version -eq "heitang_task_memory_checkpoint.v1" -and
    $checkpoint.current_gate -eq $expectedGate -and
    $resume.schema_version -eq "heitang_task_memory_resume_pointer.v1" -and
    $resume.current_gate -eq $expectedGate -and
    $resume.global_goal_complete -eq $false
  Add-MatrixRow $rows "P0-4C Agent Memory Minimal Core" "checkpoint and resume pointer" `
    "checkpoint / resume 必须能从磁盘恢复当前 Gate，不能把单 Gate 当全局完成。" `
    "checkpoint_gate=$($checkpoint.current_gate); resume_gate=$($resume.current_gate); resume_global_goal_complete=$($resume.global_goal_complete)" `
    $resumePath $checkpointOk $restartReady `
    ($(if ($checkpointOk) { "agent_memory_minimal_core_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($checkpointOk) { "" } else { "agent_memory_resume_blocked" }))

  $summaryOk = $pathsReady -and $restartReady -and
    $summary.status -eq "agent_memory_minimal_core_completed_needs_owner_review" -and
    $summary.remaining_gates_guarded -eq $true -and
    $summary.restart_recoverable_from_disk -eq $true -and
    $summary.tencentdb_agent_memory_integrated -eq $false -and
    $summary.node_22_dependency_added -eq $false -and
    $summary.full_l0_l3_memory_implemented -eq $false -and
    $summary.shipping_claim_absent -eq $true -and
    $summary.stage_exit_claim_absent -eq $true -and
    $summary.final_acceptance_claim_absent -eq $true
  Add-MatrixRow $rows "P0-4C Agent Memory Minimal Core" "summary and forbidden boundaries" `
    "summary 必须写 needs_owner_review，证明重启恢复，同时不得接 TencentDB、Node 22、完整 L0-L3 或发布声明。" `
    "status=$($summary.status); guarded=$($summary.remaining_gates_guarded); restart=$($summary.restart_recoverable_from_disk); tencentdb=$($summary.tencentdb_agent_memory_integrated); node22=$($summary.node_22_dependency_added)" `
    $summaryPath $summaryOk $restartReady `
    ($(if ($summaryOk) { "agent_memory_minimal_core_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($summaryOk) { "" } else { "agent_memory_summary_boundary_blocked" }))

  $ledgerArtifactOk = $pathsReady -and $restartReady -and
    $null -ne $memoryEvent -and
    $memoryEvent.status -eq "agent_memory_minimal_core_completed_needs_owner_review" -and
    $memoryEvent.artifact_path -eq $snapshotPath -and
    $null -ne $snapshotArtifact -and
    $snapshotArtifact.artifact_type -eq "task_memory_snapshot" -and
    $snapshotArtifact.status -eq "agent_memory_minimal_core_completed_needs_owner_review"
  Add-MatrixRow $rows "P0-4C Agent Memory Minimal Core" "Event Ledger and Artifact Lifecycle" `
    "memory_snapshot_created 必须写入 Event Ledger，task_memory_snapshot 必须登记 Artifact Lifecycle。" `
    "event_found=$($null -ne $memoryEvent); event_status=$($memoryEvent.status); artifact_found=$($null -ne $snapshotArtifact); artifact_type=$($snapshotArtifact.artifact_type)" `
    $artifactCatalogPath $ledgerArtifactOk $restartReady `
    ($(if ($ledgerArtifactOk) { "agent_memory_minimal_core_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($ledgerArtifactOk) { "" } else { "agent_memory_event_artifact_blocked" }))

  $blockedRows = @($rows | Where-Object { $_.current_conclusion -eq "blocked" })
  $status = if ($blockedRows.Count -eq 0) {
    "agent_memory_minimal_core_completed_needs_owner_review"
  } else {
    "agent_memory_minimal_core_blocked"
  }
  $payload = [ordered]@{
    schema_version = "heitang_p0_agent_memory_minimal_core_matrix.v1"
    status = $status
    workspace = $workspace
    matrix = $rows
    run_dir = $runDir
    paths_ready = $pathsReady
    restart_verified = $restartReady
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Json $matrixPath $payload
  Write-Json (Join-Path $runDir "agent_memory_minimal_core_matrix.json") $payload

  $blockerText = if ($blockedRows.Count -eq 0) {
    "- 无 P0-4C 直接阻断项，等待 Owner 复核。"
  } else {
    ($blockedRows | ForEach-Object { "- $($_.blocker)" }) -join "`n"
  }
  $report = @(
    "# P0-4C Agent Memory Minimal Core Report",
    "",
    "状态：$status",
    "",
    "## 验收范围",
    "",
    "- 验证 task_memory_snapshot、completed / remaining / blocked / needs_owner_review 状态持久化、remaining_gates 防误闭口、Event Ledger、Artifact Lifecycle、重启恢复。",
    "- 本 Gate 不接 TencentDB Agent Memory，不新增 Node 22 依赖，不做完整 L0-L3，不写越界发布或最终验收声明。",
    "",
    "## 数据文件路径",
    "",
    "- workspace: $workspace",
    "- matrix: $matrixPath",
    "- run dir: $runDir",
    "- snapshot: $snapshotPath",
    "- summary: $summaryPath",
    "- event ledger: $ledgerPath",
    "- artifact catalog: $artifactCatalogPath",
    "",
    "## 验证结论",
    "",
    "- rows: $($rows.Count)",
    "- blocked rows: $($blockedRows.Count)",
    "- restart_verified: $restartReady",
    "- remaining_gates: $($remaining.Count)",
    "- global_goal_complete: $($snapshot.global_goal_complete)",
    "",
    "## 仍阻断项",
    "",
    $blockerText
  ) -join "`n"
  $reportParent = Split-Path -Parent $reportPath
  if ($reportParent) { New-Item -ItemType Directory -Force -Path $reportParent | Out-Null }
  $report | Set-Content -Encoding UTF8 -Path $reportPath

  Write-Output "status=$status"
  Write-Output "matrix=$matrixPath"
  Write-Output "report=$reportPath"
  if ($blockedRows.Count -gt 0) { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
