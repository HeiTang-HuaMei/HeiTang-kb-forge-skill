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

function Test-HasField($Object, [string]$Name) {
  if ($null -eq $Object) { return $false }
  return $null -ne ($Object.PSObject.Properties[$Name])
}

function Test-Fields($Object, [string[]]$Fields) {
  $missing = @()
  foreach ($field in $Fields) {
    if (-not (Test-HasField $Object $field)) { $missing += $field }
  }
  return $missing
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
$matrixDir = Join-Path $OutputRoot "memory_evidence"
$runDir = New-VerifierRunDir $matrixDir "memory_evidence_metadata"
$matrixPath = Join-Path $matrixDir "memory_evidence_metadata_reservation_matrix.json"
$reportPath = Join-Path (Get-AppRoot) "..\..\..\docs\audits\current\memory_evidence_metadata_reservation_report.md"
$manifestPath = Join-Path $workspace "memory_evidence\metadata_reservation_manifest.json"
$sourceTracePath = Join-Path $workspace "memory_evidence\source_trace_reservation.json"
$gapReservationPath = Join-Path $workspace "memory_evidence\validation_gap_reservation.json"
$evidenceGraphReferencePath = Join-Path $workspace "memory_evidence\evidence_graph_reference.json"
$summaryPath = Join-Path $workspace "acceptance\memory_evidence_metadata_reservation_summary.json"
$ledgerPath = Join-Path $workspace "audit\event_ledger.jsonl"
$artifactCatalogPath = Join-Path $workspace "artifacts\catalog.json"
$rows = [System.Collections.ArrayList]::new()
$launch = $null

try {
  $launch = Start-WorkbenchExeWithEnv $ExePath @{ HEITANG_P0_MEMORY_EVIDENCE_E2E = "1" }
  Set-NativeWindowSize $launch.hwnd 1440 900

  $requiredPaths = @(
    $manifestPath,
    $sourceTracePath,
    $gapReservationPath,
    $evidenceGraphReferencePath,
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

  $manifest = Read-JsonFile $manifestPath
  $manifestMissing = Test-Fields $manifest @(
    "memory_layer_type",
    "evidence_graph_refs",
    "citation_status",
    "gap_analysis",
    "retrieval_eval_status",
    "not_implemented_boundaries"
  )
  $manifestOk = $pathsReady -and $restartReady -and $manifest.status -eq "memory_evidence_metadata_reserved_needs_review" -and $manifestMissing.Count -eq 0
  Add-MatrixRow $rows "P0-9 Memory / Evidence" "reservation manifest" `
    "metadata_reservation_manifest.json 必须保留 memory_layer_type、evidence_graph_refs、citation_status、gap_analysis、retrieval_eval_status。" `
    "status=$($manifest.status); missing=$($manifestMissing -join ',')" `
    $manifestPath $manifestOk $restartReady `
    ($(if ($manifestOk) { "memory_evidence_metadata_reserved_needs_review" } else { "blocked" })) `
    ($(if ($manifestOk) { "" } else { "memory_evidence_manifest_fields_missing" }))

  $sourceTrace = Read-JsonFile $sourceTracePath
  $sourceMissing = Test-Fields $sourceTrace @(
    "memory_layer_type",
    "citation_status",
    "source_trace_reserved",
    "source_document_ids",
    "source_chunk_ids",
    "evidence_graph_refs"
  )
  $sourceOk = $pathsReady -and $restartReady -and $sourceTrace.source_trace_reserved -eq $true -and $sourceMissing.Count -eq 0
  Add-MatrixRow $rows "Source Trace" "citation status reservation" `
    "source_trace reservation 必须保留 citation_status 且不假装引用已验证。" `
    "citation_status=$($sourceTrace.citation_status); missing=$($sourceMissing -join ',')" `
    $sourceTracePath $sourceOk $restartReady `
    ($(if ($sourceOk) { "memory_evidence_metadata_reserved_needs_review" } else { "blocked" })) `
    ($(if ($sourceOk) { "" } else { "source_trace_reservation_fields_missing" }))

  $gapReservation = Read-JsonFile $gapReservationPath
  $gapMissing = Test-Fields $gapReservation @(
    "memory_layer_type",
    "gap_analysis",
    "citation_status",
    "retrieval_eval_status"
  )
  $gapShapeOk = Test-HasField $gapReservation.gap_analysis "missing_claims" -and
    (Test-HasField $gapReservation.gap_analysis "missing_rules") -and
    (Test-HasField $gapReservation.gap_analysis "missing_sources")
  $gapOk = $pathsReady -and $restartReady -and $gapMissing.Count -eq 0 -and $gapShapeOk
  Add-MatrixRow $rows "Gap Analysis" "gap fields reservation" `
    "gap_analysis 必须保留 missing_claims/missing_rules/missing_sources，且 retrieval_eval_status 只能是 not_run。" `
    "retrieval_eval_status=$($gapReservation.retrieval_eval_status); missing=$($gapMissing -join ','); gap_shape_ok=$gapShapeOk" `
    $gapReservationPath $gapOk $restartReady `
    ($(if ($gapOk) { "memory_evidence_metadata_reserved_needs_review" } else { "blocked" })) `
    ($(if ($gapOk) { "" } else { "gap_analysis_reservation_fields_missing" }))

  $graphReference = Read-JsonFile $evidenceGraphReferencePath
  $graphMissing = Test-Fields $graphReference @(
    "memory_layer_type",
    "evidence_graph_refs",
    "typed_links_reserved",
    "graph_runtime_executed"
  )
  $graphOk = $pathsReady -and $restartReady -and $graphReference.status -eq "evidence_graph_not_implemented" -and $graphReference.graph_runtime_executed -eq $false -and $graphMissing.Count -eq 0
  Add-MatrixRow $rows "Evidence Graph" "non-implementation boundary" `
    "P0 只能预留 evidence_graph_refs 和 typed link 名称，不得执行 graph runtime。" `
    "status=$($graphReference.status); graph_runtime_executed=$($graphReference.graph_runtime_executed); missing=$($graphMissing -join ',')" `
    $evidenceGraphReferencePath $graphOk $restartReady `
    ($(if ($graphOk) { "evidence_graph_not_implemented" } else { "blocked" })) `
    ($(if ($graphOk) { "" } else { "evidence_graph_boundary_invalid" }))

  $summary = Read-JsonFile $summaryPath
  $summaryOk = $pathsReady -and $restartReady -and
    $summary.status -eq "memory_evidence_metadata_reserved_needs_review" -and
    $summary.external_gbrain_integrated -eq $false -and
    $summary.night_dream_cycle_executed -eq $false -and
    $summary.automatic_kb_modification_executed -eq $false -and
    $summary.production_ready_claimed -eq $false -and
    $summary.release_ready_claimed -eq $false -and
    $summary.industrial_acceptance_passed_claimed -eq $false
  Add-MatrixRow $rows "Summary" "forbidden capability boundary" `
    "summary 必须明确未接入 GBrain、未执行 dream cycle、未自动修改知识库，且不声明生产/发布/工业级完成。" `
    "status=$($summary.status); gbrain=$($summary.external_gbrain_integrated); dream=$($summary.night_dream_cycle_executed); auto_kb=$($summary.automatic_kb_modification_executed)" `
    $summaryPath $summaryOk $restartReady `
    ($(if ($summaryOk) { "memory_evidence_metadata_reserved_needs_review" } else { "blocked" })) `
    ($(if ($summaryOk) { "" } else { "memory_evidence_forbidden_boundary_invalid" }))

  $events = @(Read-JsonlFile $ledgerPath)
  $event = $events | Where-Object { $_.event_type -eq "memory_evidence_metadata_reserved" } | Select-Object -Last 1
  $eventMissing = Test-Fields $event @(
    "memory_layer_type",
    "evidence_graph_refs",
    "citation_status",
    "gap_analysis",
    "retrieval_eval_status"
  )
  $eventOk = $pathsReady -and $restartReady -and $null -ne $event -and $eventMissing.Count -eq 0
  Add-MatrixRow $rows "Event Ledger" "memory evidence event scope" `
    "Event Ledger 必须记录 memory/evidence 预留事件，并保留五个 GBrain 启发字段。" `
    "event_found=$($null -ne $event); missing=$($eventMissing -join ',')" `
    $ledgerPath $eventOk $restartReady `
    ($(if ($eventOk) { "memory_evidence_metadata_reserved_needs_review" } else { "blocked" })) `
    ($(if ($eventOk) { "" } else { "event_memory_evidence_fields_missing" }))

  $artifactCatalog = Read-JsonFile $artifactCatalogPath
  [array]$artifactRows = if ($null -ne $artifactCatalog -and $null -ne $artifactCatalog.artifacts) { $artifactCatalog.artifacts } else { @() }
  $artifact = $artifactRows | Where-Object { $_.artifact_id -eq "memory_evidence_metadata_reservation" } | Select-Object -First 1
  $artifactMissing = Test-Fields $artifact @(
    "memory_layer_type",
    "evidence_graph_refs",
    "citation_status",
    "gap_analysis",
    "retrieval_eval_status"
  )
  $artifactOk = $pathsReady -and $restartReady -and $null -ne $artifact -and $artifactMissing.Count -eq 0
  Add-MatrixRow $rows "Artifact Lifecycle" "memory evidence artifact scope" `
    "Artifact Catalog 必须登记 P0-9 预留成果，并保留五个 GBrain 启发字段。" `
    "artifact_found=$($null -ne $artifact); missing=$($artifactMissing -join ',')" `
    $artifactCatalogPath $artifactOk $restartReady `
    ($(if ($artifactOk) { "memory_evidence_metadata_reserved_needs_review" } else { "blocked" })) `
    ($(if ($artifactOk) { "" } else { "artifact_memory_evidence_fields_missing" }))

  $blocked = @($rows | Where-Object { $_.current_conclusion -eq "blocked" })
  $status = if ($blocked.Count -eq 0) {
    "memory_evidence_metadata_reserved_needs_review"
  } else {
    "memory_evidence_metadata_reservation_blocked"
  }
  $payload = [ordered]@{
    schema_version = "heitang_p0_memory_evidence_metadata_reservation_matrix.v1"
    status = $status
    workspace = $workspace
    matrix = $rows
    run_dir = $runDir
    paths_ready = $pathsReady
    restart_verified = $restartReady
    evidence_graph_status = "evidence_graph_not_implemented"
    dream_cycle_status = "dream_cycle_not_implemented"
    retrieval_eval_status = "retrieval_eval_not_implemented"
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Json $matrixPath $payload
  Write-Json (Join-Path $runDir "memory_evidence_metadata_reservation_matrix.json") $payload

  $blockerText = if ($blocked.Count -eq 0) {
    "- 无 P0-9 直接阻断项，等待 Owner 复核。"
  } else {
    ($blocked | ForEach-Object { "- $($_.blocker)" }) -join "`n"
  }
  $report = @(
    "# P0-9 Memory and Evidence Metadata Reservation Report",
    "",
    "状态：$status",
    "",
    "## 验收范围",
    "",
    "- 验证 memory_layer_type、evidence_graph_refs、citation_status、gap_analysis、retrieval_eval_status 的结构预留。",
    "- 本 Gate 不实现 Evidence Graph、Night Dream Cycle、GBrain 接入、自动知识库修改或 Company Brain 权限系统。",
    "",
    "## 数据文件路径",
    "",
    "- workspace: $workspace",
    "- matrix: $matrixPath",
    "- run dir: $runDir",
    "- manifest: $manifestPath",
    "- summary: $summaryPath",
    "",
    "## 验证结论",
    "",
    "- rows: $($rows.Count)",
    "- blocked rows: $($blocked.Count)",
    "- restart_verified: $restartReady",
    "- evidence_graph_status: evidence_graph_not_implemented",
    "- dream_cycle_status: dream_cycle_not_implemented",
    "- retrieval_eval_status: retrieval_eval_not_implemented",
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
  if ($blocked.Count -gt 0) { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
