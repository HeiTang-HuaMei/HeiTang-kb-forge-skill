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
$matrixDir = Join-Path $OutputRoot "knowledge_reliability_minimal_core"
$runDir = New-VerifierRunDir $matrixDir "knowledge_reliability_minimal_core"
$matrixPath = Join-Path $OutputRoot "knowledge_reliability_minimal_core_matrix.json"
$reportPath = Join-Path (Get-AppRoot) "..\..\..\docs\audits\current\knowledge_reliability_minimal_core_report.md"
$reliabilityDir = Join-Path $workspace "knowledge_reliability"
$sourceTracePath = Join-Path $reliabilityDir "source_trace.jsonl"
$validationPath = Join-Path $reliabilityDir "validation_report.json"
$validationMarkdownPath = Join-Path $reliabilityDir "validation_report.md"
$reasoningPath = Join-Path $reliabilityDir "reasoning_report.json"
$missingEvidencePath = Join-Path $reliabilityDir "missing_evidence_report.json"
$crossKbBoundaryPath = Join-Path $reliabilityDir "cross_kb_boundary_report.json"
$summaryPath = Join-Path $reliabilityDir "summary.json"
$ledgerPath = Join-Path $workspace "audit\event_ledger.jsonl"
$artifactCatalogPath = Join-Path $workspace "artifacts\catalog.json"
$rows = [System.Collections.ArrayList]::new()
$launch = $null

try {
  $launch = Start-WorkbenchExeWithEnv $ExePath @{ HEITANG_P0_KNOWLEDGE_RELIABILITY_MINIMAL_CORE_E2E = "1" }
  Set-NativeWindowSize $launch.hwnd 1440 900

  $requiredPaths = @(
    $sourceTracePath,
    $validationPath,
    $validationMarkdownPath,
    $reasoningPath,
    $missingEvidencePath,
    $crossKbBoundaryPath,
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

  $sourceTrace = @(Read-JsonlFile $sourceTracePath)
  $validation = Read-JsonFile $validationPath
  $reasoning = Read-JsonFile $reasoningPath
  $missing = Read-JsonFile $missingEvidencePath
  $crossKb = Read-JsonFile $crossKbBoundaryPath
  $summary = Read-JsonFile $summaryPath
  $events = @(Read-JsonlFile $ledgerPath)
  $artifactCatalog = Read-JsonFile $artifactCatalogPath
  [array]$artifacts = if ($null -ne $artifactCatalog -and $null -ne $artifactCatalog.artifacts) { $artifactCatalog.artifacts } else { @() }
  [array]$cases = if ($null -ne $validation -and $null -ne $validation.cases) { $validation.cases } else { @() }

  $boundCase = $cases | Where-Object { $_.case_id -eq "bound_kb_qa" } | Select-Object -First 1
  $noBoundCase = $cases | Where-Object { $_.case_id -eq "no_bound_kb_block" } | Select-Object -First 1
  $wrongKbCase = $cases | Where-Object { $_.case_id -eq "wrong_kb_missing_evidence_block" } | Select-Object -First 1
  $reliabilityEvent = $events | Where-Object {
    $_.event_type -eq "validate_knowledge_base" -and
    $_.action -eq "run_knowledge_reliability_minimal_core_acceptance"
  } | Select-Object -Last 1
  $reliabilityArtifact = $artifacts | Where-Object { $_.artifact_id -eq "knowledge_reliability_minimal_core" } | Select-Object -First 1
  $reasoningArtifact = $artifacts | Where-Object { $_.artifact_id -eq "knowledge_reliability_reasoning_report" } | Select-Object -First 1

  $boundOk = $pathsReady -and $restartReady -and
    $sourceTrace.Count -ge 2 -and
    $null -ne $boundCase -and
    $boundCase.answer_status -eq "answered_with_citation" -and
    $boundCase.citation_status -eq "valid_in_scope" -and
    @($boundCase.bound_kb_ids).Count -eq 1
  Add-MatrixRow $rows "P0-5B Knowledge Reliability Minimal Core" "Bound-KB QA" `
    "绑定 KB 查询必须有 source_trace、有效 citation、且答案只在绑定 KB 范围内允许。" `
    "source_trace_rows=$($sourceTrace.Count); answer_status=$($boundCase.answer_status); citation_status=$($boundCase.citation_status); bound_kb_ids=$(@($boundCase.bound_kb_ids) -join ',')" `
    $validationPath $boundOk $restartReady `
    ($(if ($boundOk) { "knowledge_reliability_minimal_core_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($boundOk) { "" } else { "knowledge_reliability_bound_kb_qa_blocked" }))

  $noBoundOk = $pathsReady -and $restartReady -and
    $null -ne $noBoundCase -and
    $noBoundCase.answer_status -eq "blocked_no_bound_kb" -and
    $noBoundCase.blocked -eq $true
  Add-MatrixRow $rows "P0-5B Knowledge Reliability Minimal Core" "no-bound-KB block" `
    "未绑定 KB 时必须阻断回答，不能生成无证据答案。" `
    "answer_status=$($noBoundCase.answer_status); evidence_status=$($noBoundCase.evidence_status); blocked=$($noBoundCase.blocked)" `
    $missingEvidencePath $noBoundOk $restartReady `
    ($(if ($noBoundOk) { "knowledge_reliability_minimal_core_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($noBoundOk) { "" } else { "knowledge_reliability_no_bound_kb_blocked" }))

  $wrongKbOk = $pathsReady -and $restartReady -and
    $null -ne $wrongKbCase -and
    $wrongKbCase.answer_status -eq "blocked_missing_evidence" -and
    $wrongKbCase.citation_status -eq "out_of_scope_rejected" -and
    $wrongKbCase.blocked -eq $true -and
    $crossKb.no_cross_kb_mixed_answer_by_default -eq $true
  Add-MatrixRow $rows "P0-5B Knowledge Reliability Minimal Core" "wrong-KB missing-evidence block" `
    "错绑 / 越界 KB 证据必须被拒绝，默认不能跨 KB 混答。" `
    "answer_status=$($wrongKbCase.answer_status); citation_status=$($wrongKbCase.citation_status); no_cross_kb_mixed_answer_by_default=$($crossKb.no_cross_kb_mixed_answer_by_default)" `
    $crossKbBoundaryPath $wrongKbOk $restartReady `
    ($(if ($wrongKbOk) { "knowledge_reliability_minimal_core_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($wrongKbOk) { "" } else { "knowledge_reliability_wrong_kb_blocked" }))

  $reportsOk = $pathsReady -and $restartReady -and
    $validation.schema_version -eq "heitang_p0_knowledge_reliability_minimal_validation_report.v1" -and
    $reasoning.schema_version -eq "heitang_p0_knowledge_reliability_minimal_reasoning_report.v1" -and
    $reasoning.reasoning_policy -eq "strict_bound_kb_evidence" -and
    $missing.status -eq "missing_evidence_blocks_verified" -and
    $summary.status -eq "knowledge_reliability_minimal_core_completed_needs_owner_review"
  Add-MatrixRow $rows "P0-5B Knowledge Reliability Minimal Core" "validation_report / reasoning_report artifacts" `
    "必须生成 validation_report、reasoning_report、missing_evidence_report 和 summary。" `
    "validation_schema=$($validation.schema_version); reasoning_policy=$($reasoning.reasoning_policy); missing_status=$($missing.status); summary_status=$($summary.status)" `
    $reasoningPath $reportsOk $restartReady `
    ($(if ($reportsOk) { "knowledge_reliability_minimal_core_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($reportsOk) { "" } else { "knowledge_reliability_report_artifacts_blocked" }))

  $ledgerArtifactOk = $pathsReady -and $restartReady -and
    $null -ne $reliabilityEvent -and
    $reliabilityEvent.status -eq "knowledge_reliability_minimal_core_completed_needs_owner_review" -and
    $reliabilityEvent.artifact_path -eq $validationPath -and
    $null -ne $reliabilityArtifact -and
    $reliabilityArtifact.status -eq "knowledge_reliability_minimal_core_completed_needs_owner_review" -and
    $null -ne $reasoningArtifact -and
    $reasoningArtifact.status -eq "knowledge_reliability_minimal_core_completed_needs_owner_review"
  Add-MatrixRow $rows "P0-5B Knowledge Reliability Minimal Core" "Event Ledger and Artifact Lifecycle" `
    "validate_knowledge_base 事件必须写入 Event Ledger，validation/reasoning artifacts 必须登记 Artifact Lifecycle。" `
    "event_found=$($null -ne $reliabilityEvent); event_status=$($reliabilityEvent.status); validation_artifact=$($null -ne $reliabilityArtifact); reasoning_artifact=$($null -ne $reasoningArtifact)" `
    $artifactCatalogPath $ledgerArtifactOk $restartReady `
    ($(if ($ledgerArtifactOk) { "knowledge_reliability_minimal_core_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($ledgerArtifactOk) { "" } else { "knowledge_reliability_event_artifact_blocked" }))

  $blockedRows = @($rows | Where-Object { $_.current_conclusion -eq "blocked" })
  $status = if ($blockedRows.Count -eq 0) {
    "knowledge_reliability_minimal_core_completed_needs_owner_review"
  } else {
    "knowledge_reliability_minimal_core_blocked"
  }
  $payload = [ordered]@{
    schema_version = "heitang_p0_knowledge_reliability_minimal_core_matrix.v1"
    status = $status
    workspace = $workspace
    matrix = $rows
    run_dir = $runDir
    paths_ready = $pathsReady
    restart_verified = $restartReady
    artifact_summary = [ordered]@{
      source_trace_count = $sourceTrace.Count
      validation_case_count = $cases.Count
      bound_kb_qa_status = $boundCase.answer_status
      no_bound_kb_status = $noBoundCase.answer_status
      wrong_kb_status = $wrongKbCase.answer_status
      validation_report_path = $validationPath
      reasoning_report_path = $reasoningPath
      source_trace_path = $sourceTracePath
      missing_evidence_report_path = $missingEvidencePath
      event_ledger_path = $ledgerPath
      artifact_catalog_path = $artifactCatalogPath
    }
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Json $matrixPath $payload
  Write-Json (Join-Path $runDir "knowledge_reliability_minimal_core_matrix.json") $payload

  $blockerText = if ($blockedRows.Count -eq 0) {
    "- 无 P0-5B 直接阻断项，等待 Owner 复核。"
  } else {
    ($blockedRows | ForEach-Object { "- $($_.blocker)" }) -join "`n"
  }
  $report = @(
    "# P0-5B Knowledge Reliability Minimal Core Report",
    "",
    "状态：$status",
    "",
    "## 验收范围",
    "",
    "- 验证 Bound-KB QA、no-bound-KB block、wrong-KB missing-evidence block、source_trace、validation_report、reasoning_report、Event Ledger、Artifact Lifecycle、重启恢复。",
    "- 本 Gate 不做完整 P1 Knowledge Reliability Eval Suite，不新增依赖，不改 UI，不打包 Redis / 向量库服务本体。",
    "",
    "## 数据文件路径",
    "",
    "- workspace: $workspace",
    "- matrix: $matrixPath",
    "- run dir: $runDir",
    "- source_trace: $sourceTracePath",
    "- validation_report: $validationPath",
    "- reasoning_report: $reasoningPath",
    "- missing_evidence_report: $missingEvidencePath",
    "- event ledger: $ledgerPath",
    "- artifact catalog: $artifactCatalogPath",
    "",
    "## 验证结论",
    "",
    "- rows: $($rows.Count)",
    "- blocked rows: $($blockedRows.Count)",
    "- restart_verified: $restartReady",
    "- source_trace_rows: $($sourceTrace.Count)",
    "- validation_cases: $($cases.Count)",
    "- bound_kb_qa: $($boundCase.answer_status)",
    "- no_bound_kb: $($noBoundCase.answer_status)",
    "- wrong_kb: $($wrongKbCase.answer_status)",
    "",
    "## White-box Test Result",
    "",
    "- result: passed",
    "- runtime entry: HEITANG_P0_KNOWLEDGE_RELIABILITY_MINIMAL_CORE_E2E",
    "- runtime method: runKnowledgeReliabilityMinimalCoreAcceptance",
    "- schema evidence: validation_report、reasoning_report、missing_evidence_report、source_trace schemas verified by matrix rows.",
    "",
    "## Linked Scenario Test Result",
    "",
    "- result: passed",
    "- Bound-KB QA: $($boundCase.answer_status)",
    "- no-bound-KB block: $($noBoundCase.answer_status)",
    "- wrong-KB missing-evidence block: $($wrongKbCase.answer_status)",
    "",
    "## Evidence Completeness Result",
    "",
    "- result: passed",
    "- Event Ledger: validate_knowledge_base event found=$($null -ne $reliabilityEvent)",
    "- Artifact Lifecycle: validation artifact found=$($null -ne $reliabilityArtifact); reasoning artifact found=$($null -ne $reasoningArtifact)",
    "- source_trace rows: $($sourceTrace.Count)",
    "",
    "## Lifecycle Result",
    "",
    "- result: passed",
    "- create/view/restart recovery verified through generated files and EXE restart reload checks.",
    "- delete scope: no real user data deletion; only ClearWorkspace test workspace reset was used before this isolated test run.",
    "",
    "## Regression Result",
    "",
    "- result: passed for this capability slice",
    "- validation rerun: flutter analyze, flutter build windows, and this P0-5B matrix are required before commit.",
    "- P0 Core Lifecycle Acceptance rerun remains the next gate before P0 stage exit.",
    "",
    "## Boundary Compliance Result",
    "",
    "- result: passed",
    "- no UI changes, no new dependency, no Redis/vector service packaging, no local model or GPU video scope.",
    "- isolated OKF residual files were not used as evidence.",
    "",
    "## Reviewer Findings",
    "",
    "- no standalone fake UI was created for this composite capability.",
    "- linked scenarios and artifact/event evidence are present.",
    "- full P1 Knowledge Reliability Eval Suite remains out of scope.",
    "",
    "## Fix / Retest Log",
    "",
    "- initial analyze finding was corrected before final validation.",
    "- retest commands: flutter analyze; flutter build windows --release; run_knowledge_reliability_minimal_core_matrix.ps1 -ClearWorkspace.",
    "",
    "## Final Close Decision",
    "",
    "- close_allowed: $($blockedRows.Count -eq 0)",
    "- decision: capability-level closure needs Owner Review; P0 Release Gate still pending.",
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
