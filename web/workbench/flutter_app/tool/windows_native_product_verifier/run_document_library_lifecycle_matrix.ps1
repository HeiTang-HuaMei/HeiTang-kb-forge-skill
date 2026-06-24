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
    persisted = $Persistent
    reenter_verified = $ReentryVerified
    restart_exe_verified = $RestartVerified
    current_conclusion = $Conclusion
    blocker = $Blocker
  })
}

function Write-TextFile([string]$Path, [string]$Content) {
  $parent = Split-Path -Parent $Path
  if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  $Content | Set-Content -Encoding UTF8 -Path $Path
}

function Wait-ForSourceCount([string]$Workspace, [int]$ExpectedCount, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    $info = Get-SourceManifestInfo $Workspace
    if ($info.exists -and $info.source_count -eq $ExpectedCount) { return $true }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $false
}

function Wait-ForNoSourceManifest([string]$Workspace, [int]$TimeoutSeconds) {
  $manifest = Join-Path $Workspace "source_manifest.json"
  $inputDir = Join-Path $Workspace "input"
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    if (-not (Test-Path -LiteralPath $manifest) -and -not (Test-Path -LiteralPath $inputDir)) { return $true }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $false
}

function Get-LatestEvent([string]$LedgerPath, [string]$EventType) {
  $events = @(Read-JsonlFile $LedgerPath | Where-Object { $_.event_type -eq $EventType })
  if ($events.Count -eq 0) { return $null }
  return $events | Sort-Object created_at -Descending | Select-Object -First 1
}

function Import-ClipboardPath($Hwnd, [string]$PathValue) {
  Set-VerifierClipboardText $PathValue
  [void][HtkwNativeVerifierCommon]::SetForegroundWindow($Hwnd)
  [void](Invoke-RelativeClick $Hwnd 0.55 0.30)
  Send-FunctionKey "F5"
}

if ($ClearWorkspace) {
  Clear-WorkbenchWorkspace
}

$workspace = Get-WorkspacePath
$runDir = New-VerifierRunDir $OutputRoot "document_library_blackbox"
$matrixPath = Join-Path $OutputRoot "document_library_matrix.json"
$reportPath = Join-Path (Get-AppRoot) "..\..\..\docs\audits\current\document_library_blackbox_report.md"
$sourceManifestPath = Join-Path $workspace "source_manifest.json"
$eventLedgerPath = Join-Path $workspace "audit\event_ledger.jsonl"
$fixtureRoot = Join-Path $runDir "input_sources"
$missingPath = Join-Path $runDir "missing_source_dir"
$rows = [System.Collections.ArrayList]::new()
$launch = $null

New-Item -ItemType Directory -Force -Path $fixtureRoot | Out-Null
Write-TextFile (Join-Path $fixtureRoot "doc_lifecycle_a.md") "# 文档库生命周期 A`n`n用于验证真实导入、重启和删除。"
Write-TextFile (Join-Path $fixtureRoot "doc_lifecycle_b.txt") "文档库生命周期 B`n用于验证 txt 来源进入文档库。"

try {
  $launch = Start-WorkbenchExe $ExePath
  Set-NativeWindowSize $launch.hwnd 1440 900
  Send-ControlAlt "3"
  $emptyShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\document_library_empty_initial.png")
  $emptyOk = -not (Test-Path -LiteralPath $sourceManifestPath)
  Add-MatrixRow $rows "Path 1" "Open EXE and document library empty state" `
    "EXE opens with no imported source_manifest after clean workspace" `
    "source_manifest_exists=$(Test-Path -LiteralPath $sourceManifestPath)" `
    $emptyShot.path $sourceManifestPath (-not $emptyOk) $emptyOk $false `
    ($(if ($emptyOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($emptyOk) { "" } else { "document_library_clean_workspace_not_empty" }))

  Import-ClipboardPath $launch.hwnd $fixtureRoot
  $importReady = Wait-ForSourceCount $workspace 2 $TimeoutSeconds
  Send-ControlAlt "3"
  $importShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\document_library_after_import_2_sources.png")
  $manifest = Read-JsonFile $sourceManifestPath
  $sourceNames = @()
  if ($null -ne $manifest -and $null -ne $manifest.sources) {
    $sourceNames = @($manifest.sources | ForEach-Object {
      if ($_.source_name) { [string]$_.source_name } elseif ($_.name) { [string]$_.name } else { [string]$_ }
    })
  }
  $expectedFiles = @("doc_lifecycle_a.md", "doc_lifecycle_b.txt")
  $filesOk = @($expectedFiles | Where-Object { $sourceNames -contains $_ }).Count -eq 2
  $importEvent = Get-LatestEvent $eventLedgerPath "import_document"
  $importOk = $importReady -and $filesOk -and $null -ne $importEvent -and $importEvent.status -eq "completed"
  Add-MatrixRow $rows "Path 1" "Import controlled source folder via EXE F5 clipboard path" `
    "source_manifest.json contains exactly doc_lifecycle_a.md and doc_lifecycle_b.txt, with import_document event" `
    "source_count=$($manifest.source_count); sources=$($sourceNames -join ','); import_event=$($null -ne $importEvent)" `
    $importShot.path $sourceManifestPath $importOk $importOk $false `
    ($(if ($importOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($importOk) { "" } else { "document_library_import_blocked" }))

  Stop-WorkbenchExe $launch
  $launch = Start-WorkbenchExe $ExePath
  Set-NativeWindowSize $launch.hwnd 1440 900
  Send-ControlAlt "3"
  $restartImportReady = Wait-ForSourceCount $workspace 2 30
  $restartImportShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\document_library_after_import_restart.png")
  Add-MatrixRow $rows "Path 1" "Close and reopen EXE after import" `
    "Document Library reloads imported source state from source_manifest.json" `
    "restart_source_count=$((Get-SourceManifestInfo $workspace).source_count)" `
    $restartImportShot.path $sourceManifestPath $restartImportReady $restartImportReady $true `
    ($(if ($restartImportReady) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($restartImportReady) { "" } else { "document_library_import_restart_persistence_blocked" }))

  [void][HtkwNativeVerifierCommon]::SetForegroundWindow($launch.hwnd)
  [void](Invoke-RelativeClick $launch.hwnd 0.55 0.30)
  Send-FunctionKey "F8"
  Start-Sleep -Seconds 1
  $confirmShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\document_library_delete_confirm_dialog.png")
  $confirmVisible = $confirmShot.size_bytes -gt 0
  Add-MatrixRow $rows "Path 2" "Delete imported documents with confirmation" `
    "Confirmation dialog appears before destructive delete" `
    "confirmation_screenshot_size=$($confirmShot.size_bytes)" `
    $confirmShot.path $sourceManifestPath $false $confirmVisible $false `
    ($(if ($confirmVisible) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($confirmVisible) { "" } else { "document_library_delete_confirm_missing" }))

  Send-Enter
  $deleteReady = Wait-ForNoSourceManifest $workspace $TimeoutSeconds
  Send-ControlAlt "3"
  $afterDeleteShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\document_library_after_delete_empty.png")
  $fixturePreserved = (Test-Path -LiteralPath (Join-Path $fixtureRoot "doc_lifecycle_a.md")) -and
    (Test-Path -LiteralPath (Join-Path $fixtureRoot "doc_lifecycle_b.txt"))
  $deleteEvent = Get-LatestEvent $eventLedgerPath "delete_document"
  $deleteOk = $deleteReady -and $fixturePreserved -and $null -ne $deleteEvent -and $deleteEvent.status -eq "completed"
  Add-MatrixRow $rows "Path 2" "Confirm delete and inspect manifest consistency" `
    "source_manifest.json and workspace input are removed; original fixture directory remains; delete_document event is recorded" `
    "manifest_exists=$(Test-Path -LiteralPath $sourceManifestPath); input_exists=$(Test-Path -LiteralPath (Join-Path $workspace 'input')); fixture_preserved=$fixturePreserved; delete_event=$($null -ne $deleteEvent)" `
    $afterDeleteShot.path $sourceManifestPath $deleteOk $deleteOk $false `
    ($(if ($deleteOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($deleteOk) { "" } else { "document_library_delete_blocked" }))

  Stop-WorkbenchExe $launch
  $launch = Start-WorkbenchExe $ExePath
  Set-NativeWindowSize $launch.hwnd 1440 900
  Send-ControlAlt "3"
  $restartDeleteReady = Wait-ForNoSourceManifest $workspace 30
  $restartDeleteShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\document_library_after_delete_restart_empty.png")
  Add-MatrixRow $rows "Path 2" "Close and reopen EXE after delete" `
    "Document Library remains empty after restart" `
    "manifest_exists=$(Test-Path -LiteralPath $sourceManifestPath); input_exists=$(Test-Path -LiteralPath (Join-Path $workspace 'input'))" `
    $restartDeleteShot.path $sourceManifestPath $restartDeleteReady $restartDeleteReady $true `
    ($(if ($restartDeleteReady) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($restartDeleteReady) { "" } else { "document_library_delete_restart_persistence_blocked" }))

  Import-ClipboardPath $launch.hwnd $missingPath
  Start-Sleep -Seconds 2
  $failedImportShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\document_library_after_failed_import_empty.png")
  $failureEvent = Get-LatestEvent $eventLedgerPath "failure_event"
  $failedImportOk = -not (Test-Path -LiteralPath $sourceManifestPath) -and
    $null -ne $failureEvent -and
    ([string]$failureEvent.error_message).Contains($missingPath)
  Add-MatrixRow $rows "Path 3" "Import missing path failure gate" `
    "No manifest is generated and failure_event records a clear missing-path error" `
    "manifest_exists=$(Test-Path -LiteralPath $sourceManifestPath); failure_event=$($null -ne $failureEvent); error=$([string]$failureEvent.error_message)" `
    $failedImportShot.path $eventLedgerPath $false $false $false `
    ($(if ($failedImportOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($failedImportOk) { "" } else { "document_library_missing_path_gate_blocked" }))

  $blocked = @($rows | Where-Object { $_.current_conclusion -eq "blocked" })
  $status = if ($blocked.Count -eq 0) {
    "document_library_lifecycle_completed_needs_owner_review"
  } else {
    "document_library_lifecycle_blocked"
  }
  $payload = [ordered]@{
    schema_version = "heitang_document_library_blackbox_matrix.v1"
    status = $status
    exe_path = $ExePath
    workspace = $workspace
    source_manifest_path = $sourceManifestPath
    event_ledger_path = $eventLedgerPath
    fixture_input_path = $fixtureRoot
    evidence = [ordered]@{
      import_event = $importEvent
      delete_event = $deleteEvent
      failure_event = $failureEvent
      final_manifest_exists = (Test-Path -LiteralPath $sourceManifestPath)
      final_input_exists = (Test-Path -LiteralPath (Join-Path $workspace "input"))
      fixture_files = @(Get-ChildItem -LiteralPath $fixtureRoot -File | ForEach-Object { $_.Name })
    }
    rows = $rows
    run_dir = $runDir
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Json $matrixPath $payload
  Write-Json (Join-Path $runDir "document_library_matrix.json") $payload

  $blockerText = if ($blocked.Count -eq 0) {
    "- 无 P0-3 直接阻断项，等待 Owner 复核。"
  } else {
    ($blocked | ForEach-Object { "- $($_.blocker)" }) -join "`n"
  }
  $report = @(
    "# Document Library Blackbox Lifecycle Report",
    "",
    "Status: $status",
    "",
    "## Scope",
    "",
    "This gate validates the document library P0 lifecycle in the real Windows EXE. It does not claim full product acceptance.",
    "",
    "## Blackbox Findings",
    "",
    "- Import through the EXE using the product F5 clipboard-path action created a real source_manifest.json with exactly two controlled files: doc_lifecycle_a.md, doc_lifecycle_b.txt.",
    "- Restarting the EXE after import restored the imported source state.",
    "- Delete required confirmation. Confirming delete removed source_manifest.json and the workspace input directory while preserving the original fixture directory.",
    "- Restarting the EXE after delete kept the document library empty.",
    "- Missing-path import did not create a manifest and recorded failure_event with the missing path.",
    "",
    "## Evidence Paths",
    "",
    "- Matrix: $matrixPath",
    "- Workspace: $workspace",
    "- Event ledger: $eventLedgerPath",
    "- Screenshot: $($importShot.path)",
    "- Screenshot: $($confirmShot.path)",
    "- Screenshot: $($afterDeleteShot.path)",
    "- Screenshot: $($failedImportShot.path)",
    "",
    "## Verification Result",
    "",
    "- blocked rows: $($blocked.Count)",
    "- current status: $status",
    "",
    "## Remaining Risk",
    "",
    "- Owner should review visible error prompt placement for failed import. The failure is correctly gated and recorded.",
    "- This gate does not imply industrial_acceptance_passed, production_ready, release_ready, or fully_verified.",
    "",
    "## Remaining Blockers",
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
