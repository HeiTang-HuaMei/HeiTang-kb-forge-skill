param(
  [string]$ExePath = "",
  [string]$OutputRoot = "",
  [int]$TimeoutSeconds = 420,
  [switch]$ClearWorkspace
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($ExePath)) {
  $ExePath = Get-DefaultExePath
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output"
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
    "路径" = $PathName
    "步骤" = $Step
    "预期结果" = $Expected
    "实际结果" = $Actual
    "截图路径" = $ScreenshotPath
    "数据文件路径" = $DataFilePath
    "是否持久化" = $Persistent
    "是否重新进入验证" = $ReentryVerified
    "是否重启EXE验证" = $RestartVerified
    "当前结论" = $Conclusion
    "阻断原因" = $Blocker
  })
}

function Get-ArtifactRows([string]$CatalogPath) {
  $catalog = Read-JsonFile $CatalogPath
  if ($null -eq $catalog -or $null -eq $catalog.artifacts) { return @() }
  return @($catalog.artifacts)
}

function Get-MissingActiveArtifacts([array]$Artifacts) {
  $missing = @()
  foreach ($artifact in $Artifacts) {
    $status = [string]$artifact.status
    $path = ([string]$artifact.file_path).Trim()
    if ($status -eq "deleted" -or $path.Length -eq 0) { continue }
    if (-not ((Test-Path -LiteralPath $path -PathType Leaf) -or (Test-Path -LiteralPath $path -PathType Container))) {
      $missing += $artifact
    }
  }
  return $missing
}

function Select-ReconcileProbeArtifact([array]$Artifacts, [string]$Workspace) {
  $workspaceRoot = [System.IO.Path]::GetFullPath($Workspace)
  foreach ($artifact in $Artifacts) {
    $status = [string]$artifact.status
    $path = ([string]$artifact.file_path).Trim()
    if ($status -eq "deleted" -or $path.Length -eq 0) { continue }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    $resolved = [System.IO.Path]::GetFullPath($path)
    if (-not $resolved.StartsWith($workspaceRoot, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
    return $artifact
  }
  return $null
}

function Wait-ForEventTypes([string]$LedgerPath, [string[]]$EventTypes, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    $events = @(Read-JsonlFile $LedgerPath)
    $missing = @($EventTypes | Where-Object {
      $required = $_
      (@($events | Where-Object { $_.event_type -eq $required -and $_.status -eq "completed" }).Count -eq 0)
    })
    if ($missing.Count -eq 0) { return $true }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $false
}

function Wait-ForCatalogArtifacts([string]$CatalogPath, [int]$MinimumActive, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    $artifacts = @(Get-ArtifactRows $CatalogPath)
    $active = @($artifacts | Where-Object { $_.status -ne "deleted" -and ([string]$_.file_path).Trim().Length -gt 0 })
    if ($active.Count -ge $MinimumActive) { return $true }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $false
}

function Wait-ForReconciledArtifact([string]$CatalogPath, [string]$ArtifactId, [string]$LedgerPath, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    $artifacts = @(Get-ArtifactRows $CatalogPath)
    $target = @($artifacts | Where-Object { $_.artifact_id -eq $ArtifactId } | Select-Object -First 1)
    $events = @(Read-JsonlFile $LedgerPath)
    $hasDeleteEvent = @($events | Where-Object {
      $_.event_type -eq "delete_artifact" -and $_.action -eq "artifact_catalog_reconcile" -and $_.status -eq "completed"
    }).Count -gt 0
    if ($target.Count -gt 0 -and $target[0].status -eq "deleted" -and $hasDeleteEvent) {
      return $true
    }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $false
}

function Write-GateReport(
  [string]$Path,
  [string]$Title,
  [string]$Status,
  [string]$Scope,
  [string]$MatrixPath,
  [string]$Workspace,
  [string]$PrimaryDataPath,
  [string]$ScreenshotPath,
  [int]$BlockedCount,
  [string[]]$Blockers
) {
  $blockerText = if ($BlockedCount -eq 0) {
    "- 无 P0 直接阻断项，等待 Owner 复核。"
  } else {
    ($Blockers | ForEach-Object { "- $_" }) -join "`n"
  }
  $report = @(
    "# $Title",
    "",
    "## Current Status",
    "",
    $Status,
    "",
    "## Scope",
    "",
    $Scope,
    "",
    "## Blackbox Evidence",
    "",
    "- Matrix: $MatrixPath",
    "- Workspace: $Workspace",
    "- Data: $PrimaryDataPath",
    "- EXE screenshot after restart: $ScreenshotPath",
    "",
    "## Validation",
    "",
    "- Windows EXE blackbox lifecycle matrix: completed for this gate when blocked rows is 0.",
    "- This proof is limited to Event Ledger and Artifact Lifecycle P0 evidence; it does not imply full product acceptance.",
    "",
    "## Verification Result",
    "",
    "- blocked rows: $BlockedCount",
    "- current status: $Status",
    "",
    "## Unverified Content",
    "",
    "- Manual open/export/delete for every artifact type is not exhaustively verified in this gate.",
    "- Full all-capability blackbox lifecycle remains outside this gate.",
    "",
    "## Remaining Blockers",
    "",
    $blockerText
  ) -join "`n"
  $parent = Split-Path -Parent $Path
  if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  $report | Set-Content -Encoding UTF8 -Path $Path
}

if ($ClearWorkspace) {
  Clear-WorkbenchWorkspace
}

$workspace = Get-WorkspacePath
$eventOutput = Join-Path $OutputRoot "event_ledger"
$artifactOutput = Join-Path $OutputRoot "artifact_lifecycle"
$runDir = New-VerifierRunDir $artifactOutput "event_artifact_lifecycle"
$eventMatrixPath = Join-Path $eventOutput "event_ledger_blackbox_matrix.json"
$artifactMatrixPath = Join-Path $artifactOutput "artifact_lifecycle_blackbox_matrix.json"
$eventReportPath = Join-Path (Get-AppRoot) "..\..\..\docs\audits\current\event_ledger_repair_report.md"
$artifactReportPath = Join-Path (Get-AppRoot) "..\..\..\docs\audits\current\artifact_lifecycle_repair_report.md"
$ledgerPath = Join-Path $workspace "audit\event_ledger.jsonl"
$catalogPath = Join-Path $workspace "artifacts\catalog.json"
$eventRows = [System.Collections.ArrayList]::new()
$artifactRows = [System.Collections.ArrayList]::new()
$launch = $null

try {
  $launch = Start-WorkbenchExeWithEnv $ExePath @{ HEITANG_RC10_DOCUMENT_FLOW_E2E = "1" }
  Set-NativeWindowSize $launch.hwnd 1440 900
  $initialShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\event_artifact_initial.png")

  $requiredEvents = @(
    "import_document",
    "organize_document",
    "generate_knowledge_base",
    "generate_document",
    "export_document"
  )
  $eventsReady = Wait-ForEventTypes $ledgerPath $requiredEvents $TimeoutSeconds
  $catalogReady = Wait-ForCatalogArtifacts $catalogPath 6 $TimeoutSeconds
  $afterRunShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\event_artifact_after_run.png")

  $events = @(Read-JsonlFile $ledgerPath)
  $eventTypes = @($events | ForEach-Object { $_.event_type } | Sort-Object -Unique)
  $missingEvents = @($requiredEvents | Where-Object {
    $required = $_
    (@($events | Where-Object { $_.event_type -eq $required -and $_.status -eq "completed" }).Count -eq 0)
  })
  $eventOk = $eventsReady -and $missingEvents.Count -eq 0 -and $events.Count -ge 5

  Add-MatrixRow $eventRows "Event Ledger" "append real lifecycle events" `
    "真实 EXE 运行后写入导入、整理、知识库、文档生成、导出事件" `
    "event_count=$($events.Count); event_types=$($eventTypes -join ','); missing=$($missingEvents -join ',')" `
    $afterRunShot.path $ledgerPath $eventOk $eventOk $false `
    ($(if ($eventOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($eventOk) { "" } else { "event_ledger_required_events_missing" }))

  $artifacts = @(Get-ArtifactRows $catalogPath)
  $activeArtifacts = @($artifacts | Where-Object { $_.status -ne "deleted" -and ([string]$_.file_path).Trim().Length -gt 0 })
  $missingActive = @(Get-MissingActiveArtifacts $artifacts)
  $catalogOk = $catalogReady -and $activeArtifacts.Count -ge 6 -and $missingActive.Count -eq 0

  Add-MatrixRow $artifactRows "Artifact Catalog" "register artifacts from real actions" `
    "真实动作写入 artifacts/catalog.json，active 成果路径必须存在" `
    "artifact_count=$($artifacts.Count); active=$($activeArtifacts.Count); missing_active=$($missingActive.Count)" `
    $afterRunShot.path $catalogPath $catalogOk $catalogOk $false `
    ($(if ($catalogOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($catalogOk) { "" } else { "artifact_catalog_registration_blocked" }))

  $probe = Select-ReconcileProbeArtifact $artifacts $workspace
  $probeId = if ($null -ne $probe) { [string]$probe.artifact_id } else { "" }
  $probePath = if ($null -ne $probe) { [string]$probe.file_path } else { "" }
  $probeReady = $probeId.Length -gt 0 -and $probePath.Length -gt 0
  if ($probeReady) {
    Remove-Item -LiteralPath $probePath -Force
  }
  Stop-WorkbenchExe $launch
  $launch = $null

  $launch = Start-WorkbenchExe $ExePath
  Set-NativeWindowSize $launch.hwnd 1440 900
  $reconcileOk = $false
  if ($probeReady) {
    $reconcileOk = Wait-ForReconciledArtifact $catalogPath $probeId $ledgerPath $TimeoutSeconds
  }
  $restartShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\event_artifact_after_restart.png")

  $reconciledArtifacts = @(Get-ArtifactRows $catalogPath)
  $deletedArtifacts = @($reconciledArtifacts | Where-Object { $_.status -eq "deleted" })
  $remainingMissingActive = @(Get-MissingActiveArtifacts $reconciledArtifacts)
  $deleteEvents = @(Read-JsonlFile $ledgerPath | Where-Object {
    $_.event_type -eq "delete_artifact" -and $_.status -eq "completed"
  })

  Add-MatrixRow $artifactRows "Artifact Reconcile" "mark missing active path deleted after restart" `
    "删除一个工作区内真实成果文件后，重启 EXE 必须调和为 deleted 并写 delete_artifact 事件" `
    "probe_artifact=$probeId; probe_path=$probePath; reconciled=$reconcileOk; deleted_records=$($deletedArtifacts.Count); missing_active=$($remainingMissingActive.Count); delete_events=$($deleteEvents.Count)" `
    $restartShot.path "$catalogPath; $ledgerPath" $reconcileOk $reconcileOk $true `
    ($(if ($reconcileOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($reconcileOk) { "" } else { "artifact_reconcile_delete_event_blocked" }))

  $reloadOk = (Test-Path -LiteralPath $ledgerPath) -and (Test-Path -LiteralPath $catalogPath) -and $remainingMissingActive.Count -eq 0
  Add-MatrixRow $eventRows "Restart Reload" "reload ledger/catalog from disk" `
    "EXE 重启后仍能读取账本和成果目录，且 active 成果不指向缺失路径" `
    "event_exists=$(Test-Path -LiteralPath $ledgerPath); catalog_exists=$(Test-Path -LiteralPath $catalogPath); missing_active=$($remainingMissingActive.Count)" `
    $restartShot.path "$ledgerPath; $catalogPath" $reloadOk $reloadOk $true `
    ($(if ($reloadOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($reloadOk) { "" } else { "event_artifact_restart_reload_blocked" }))

  Add-MatrixRow $artifactRows "Artifact Active Path Integrity" "validate active paths after reconcile" `
    "active 成果必须指向存在路径；缺失路径必须转为 deleted" `
    "active=$(@($reconciledArtifacts | Where-Object { $_.status -ne 'deleted' }).Count); deleted=$($deletedArtifacts.Count); missing_active=$($remainingMissingActive.Count)" `
    $restartShot.path $catalogPath $reloadOk $reloadOk $true `
    ($(if ($reloadOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($reloadOk) { "" } else { "artifact_active_path_integrity_blocked" }))

  $eventBlocked = @($eventRows | Where-Object { $_."当前结论" -eq "blocked" })
  $artifactBlocked = @($artifactRows | Where-Object { $_."当前结论" -eq "blocked" })
  $eventStatus = if ($eventBlocked.Count -eq 0) {
    "event_ledger_repair_completed_needs_owner_review"
  } else {
    "event_ledger_repair_blocked"
  }
  $artifactStatus = if ($artifactBlocked.Count -eq 0) {
    "artifact_lifecycle_repair_completed_needs_owner_review"
  } else {
    "artifact_lifecycle_repair_blocked"
  }

  $eventPayload = [ordered]@{
    status = $eventStatus
    workspace = $workspace
    event_ledger_path = $ledgerPath
    event_count = $events.Count
    required_events = $requiredEvents
    missing_required_events = $missingEvents
    matrix = $eventRows
    run_dir = $runDir
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  $artifactPayload = [ordered]@{
    status = $artifactStatus
    workspace = $workspace
    artifact_catalog_path = $catalogPath
    artifact_count = $reconciledArtifacts.Count
    active_artifact_count = @($reconciledArtifacts | Where-Object { $_.status -ne "deleted" }).Count
    deleted_artifact_count = $deletedArtifacts.Count
    missing_active_artifact_paths = @($remainingMissingActive | ForEach-Object { $_.file_path })
    reconcile_probe_artifact_id = $probeId
    reconcile_probe_path = $probePath
    matrix = $artifactRows
    run_dir = $runDir
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Json $eventMatrixPath $eventPayload
  Write-Json $artifactMatrixPath $artifactPayload
  Write-Json (Join-Path $runDir "event_ledger_blackbox_matrix.json") $eventPayload
  Write-Json (Join-Path $runDir "artifact_lifecycle_blackbox_matrix.json") $artifactPayload

  Write-GateReport `
    -Path $eventReportPath `
    -Title "Event Ledger Repair Report" `
    -Status $eventStatus `
    -Scope "- Append-only event ledger at $ledgerPath.`n- Real EXE lifecycle events for document import, organization, knowledge-base generation, document generation, and export.`n- Restart reload evidence after artifact reconciliation." `
    -MatrixPath $eventMatrixPath `
    -Workspace $workspace `
    -PrimaryDataPath $ledgerPath `
    -ScreenshotPath $restartShot.path `
    -BlockedCount $eventBlocked.Count `
    -Blockers @($eventBlocked | ForEach-Object { $_."阻断原因" })

  Write-GateReport `
    -Path $artifactReportPath `
    -Title "Artifact Lifecycle Repair Report" `
    -Status $artifactStatus `
    -Scope "- Unified artifact catalog at $catalogPath.`n- Real EXE lifecycle artifact registration from generated/imported/exported outputs.`n- Missing active path reconciliation to deleted with delete_artifact event evidence." `
    -MatrixPath $artifactMatrixPath `
    -Workspace $workspace `
    -PrimaryDataPath $catalogPath `
    -ScreenshotPath $restartShot.path `
    -BlockedCount $artifactBlocked.Count `
    -Blockers @($artifactBlocked | ForEach-Object { $_."阻断原因" })

  Write-Json (Join-Path $runDir "summary.json") ([ordered]@{
    event_status = $eventStatus
    artifact_status = $artifactStatus
    event_matrix_path = $eventMatrixPath
    artifact_matrix_path = $artifactMatrixPath
    event_report_path = $eventReportPath
    artifact_report_path = $artifactReportPath
    event_blocked_count = $eventBlocked.Count
    artifact_blocked_count = $artifactBlocked.Count
  })
  Write-Output "event_status=$eventStatus"
  Write-Output "artifact_status=$artifactStatus"
  Write-Output "event_matrix=$eventMatrixPath"
  Write-Output "artifact_matrix=$artifactMatrixPath"
  if ($eventBlocked.Count -gt 0 -or $artifactBlocked.Count -gt 0) { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
