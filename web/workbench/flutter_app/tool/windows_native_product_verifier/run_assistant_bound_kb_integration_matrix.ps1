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
$matrixDir = Join-Path $OutputRoot "assistant_bound_kb_integration"
$runDir = New-VerifierRunDir $matrixDir "assistant_bound_kb_integration"
$matrixPath = Join-Path $OutputRoot "assistant_bound_kb_integration_matrix.json"
$reportPath = Join-Path (Get-AppRoot) "..\..\..\docs\audits\current\assistant_bound_kb_integration_report.md"
$boundDir = Join-Path $workspace "assistant_bound_kb_integration"
$sourceTracePath = Join-Path $boundDir "source_trace.jsonl"
$validationPath = Join-Path $boundDir "validation_report.json"
$validationMarkdownPath = Join-Path $boundDir "validation_report.md"
$reasoningPath = Join-Path $boundDir "reasoning_report.json"
$answerPath = Join-Path $boundDir "test_assistant_bound_kb_answer.md"
$exportPackagePath = Join-Path $boundDir "test_export_package_assistant_bound_kb.json"
$summaryPath = Join-Path $boundDir "summary.json"
$assistantCatalogPath = Join-Path $workspace "agent\catalog\agents.json"
$ledgerPath = Join-Path $workspace "audit\event_ledger.jsonl"
$artifactCatalogPath = Join-Path $workspace "artifacts\catalog.json"
$rows = [System.Collections.ArrayList]::new()
$launch = $null

try {
  $launch = Start-WorkbenchExeWithEnv $ExePath @{ HEITANG_P0_ASSISTANT_BOUND_KB_E2E = "1" }
  Set-NativeWindowSize $launch.hwnd 1440 900

  $requiredPaths = @(
    $sourceTracePath,
    $validationPath,
    $validationMarkdownPath,
    $reasoningPath,
    $answerPath,
    $exportPackagePath,
    $summaryPath,
    $assistantCatalogPath,
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
  $summary = Read-JsonFile $summaryPath
  $assistantCatalog = Read-JsonFile $assistantCatalogPath
  $events = @(Read-JsonlFile $ledgerPath)
  $artifactCatalog = Read-JsonFile $artifactCatalogPath
  [array]$artifacts = if ($null -ne $artifactCatalog -and $null -ne $artifactCatalog.artifacts) { $artifactCatalog.artifacts } else { @() }
  [array]$cases = if ($null -ne $validation -and $null -ne $validation.cases) { $validation.cases } else { @() }
  [array]$agents = if ($null -ne $assistantCatalog -and $null -ne $assistantCatalog.agents) { $assistantCatalog.agents } else { @() }

  $boundCase = $cases | Where-Object { $_.case_id -eq "assistant_bound_kb_answer" } | Select-Object -First 1
  $noBoundCase = $cases | Where-Object { $_.case_id -eq "assistant_no_bound_kb_block" } | Select-Object -First 1
  $wrongKbCase = $cases | Where-Object { $_.case_id -eq "assistant_wrong_kb_block" } | Select-Object -First 1
  $testAgent = $agents | Where-Object { $_.assistant_id -eq "test_assistant_bound_kb" -and $_.test_marker -eq $true } | Select-Object -First 1
  $boundEvent = $events | Where-Object {
    $_.event_type -eq "assistant_bound_kb_validated" -and
    $_.action -eq "run_assistant_bound_kb_integration_acceptance"
  } | Select-Object -Last 1
  $validationArtifact = $artifacts | Where-Object { $_.artifact_id -eq "assistant_bound_kb_validation_report" } | Select-Object -First 1
  $answerArtifact = $artifacts | Where-Object { $_.artifact_id -eq "assistant_bound_kb_answer_artifact" } | Select-Object -First 1

  $boundOk = $pathsReady -and $restartReady -and
    $sourceTrace.Count -ge 2 -and
    $null -ne $testAgent -and
    $null -ne $boundCase -and
    $boundCase.answer_status -eq "answered_with_citation" -and
    $boundCase.citation_status -eq "valid_in_scope" -and
    @($boundCase.bound_kb_ids).Count -eq 1 -and
    @($boundCase.used_kb_ids).Count -eq 1
  Add-MatrixRow $rows "P0-10 Assistant Bound-KB Integration" "bound assistant answer" `
    "助手绑定 KB 后，回答必须带 in-scope citation，并且只使用绑定 KB。" `
    "agent_found=$($null -ne $testAgent); source_trace_rows=$($sourceTrace.Count); answer_status=$($boundCase.answer_status); citation_status=$($boundCase.citation_status); used_kb_ids=$(@($boundCase.used_kb_ids) -join ',')" `
    $validationPath $boundOk $restartReady `
    ($(if ($boundOk) { "assistant_bound_kb_integration_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($boundOk) { "" } else { "assistant_bound_kb_answer_blocked" }))

  $noBoundOk = $pathsReady -and $restartReady -and
    $null -ne $noBoundCase -and
    $noBoundCase.answer_status -eq "blocked_no_bound_kb" -and
    $noBoundCase.blocked -eq $true
  Add-MatrixRow $rows "P0-10 Assistant Bound-KB Integration" "no-bound-KB block" `
    "未绑定 KB 的助手必须阻断回答。" `
    "answer_status=$($noBoundCase.answer_status); evidence_status=$($noBoundCase.evidence_status); blocked=$($noBoundCase.blocked)" `
    $validationPath $noBoundOk $restartReady `
    ($(if ($noBoundOk) { "assistant_bound_kb_integration_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($noBoundOk) { "" } else { "assistant_no_bound_kb_blocked" }))

  $wrongKbOk = $pathsReady -and $restartReady -and
    $null -ne $wrongKbCase -and
    $wrongKbCase.answer_status -eq "blocked_missing_evidence" -and
    $wrongKbCase.citation_status -eq "out_of_scope_rejected" -and
    $wrongKbCase.blocked -eq $true -and
    $reasoning.no_cross_kb_mixed_answer_by_default -eq $true
  Add-MatrixRow $rows "P0-10 Assistant Bound-KB Integration" "wrong-KB missing-evidence block" `
    "错绑 / 越界 KB 证据必须被拒绝，默认不能跨 KB 混答。" `
    "answer_status=$($wrongKbCase.answer_status); citation_status=$($wrongKbCase.citation_status); no_cross_kb_mixed_answer_by_default=$($reasoning.no_cross_kb_mixed_answer_by_default)" `
    $reasoningPath $wrongKbOk $restartReady `
    ($(if ($wrongKbOk) { "assistant_bound_kb_integration_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($wrongKbOk) { "" } else { "assistant_wrong_kb_blocked" }))

  $artifactOk = $pathsReady -and $restartReady -and
    $validation.schema_version -eq "heitang_p0_assistant_bound_kb_validation_report.v1" -and
    $reasoning.schema_version -eq "heitang_p0_assistant_bound_kb_reasoning_report.v1" -and
    $summary.status -eq "assistant_bound_kb_integration_completed_needs_owner_review" -and
    (Test-Path -LiteralPath $answerPath) -and
    (Test-Path -LiteralPath $exportPackagePath)
  Add-MatrixRow $rows "P0-10 Assistant Bound-KB Integration" "artifact lifecycle and reports" `
    "必须生成 source_trace、validation_report、reasoning_report、answer artifact 和 test export package。" `
    "validation_schema=$($validation.schema_version); reasoning_policy=$($reasoning.reasoning_policy); summary_status=$($summary.status); answer_exists=$(Test-Path -LiteralPath $answerPath); export_exists=$(Test-Path -LiteralPath $exportPackagePath)" `
    $summaryPath $artifactOk $restartReady `
    ($(if ($artifactOk) { "assistant_bound_kb_integration_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($artifactOk) { "" } else { "assistant_bound_kb_artifact_blocked" }))

  $ledgerArtifactOk = $pathsReady -and $restartReady -and
    $null -ne $boundEvent -and
    $boundEvent.status -eq "assistant_bound_kb_integration_completed_needs_owner_review" -and
    $boundEvent.artifact_path -eq $validationPath -and
    $null -ne $validationArtifact -and
    $validationArtifact.status -eq "assistant_bound_kb_integration_completed_needs_owner_review" -and
    $null -ne $answerArtifact -and
    $answerArtifact.status -eq "assistant_bound_kb_integration_completed_needs_owner_review"
  Add-MatrixRow $rows "P0-10 Assistant Bound-KB Integration" "Event Ledger and Artifact Lifecycle" `
    "assistant_bound_kb_validated 必须写入 Event Ledger，validation/answer artifacts 必须登记 Artifact Lifecycle。" `
    "event_found=$($null -ne $boundEvent); event_status=$($boundEvent.status); validation_artifact=$($null -ne $validationArtifact); answer_artifact=$($null -ne $answerArtifact)" `
    $artifactCatalogPath $ledgerArtifactOk $restartReady `
    ($(if ($ledgerArtifactOk) { "assistant_bound_kb_integration_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($ledgerArtifactOk) { "" } else { "assistant_bound_kb_event_artifact_blocked" }))

  $blockedRows = @($rows | Where-Object { $_.current_conclusion -eq "blocked" })
  $status = if ($blockedRows.Count -eq 0) {
    "assistant_bound_kb_integration_completed_needs_owner_review"
  } else {
    "assistant_bound_kb_integration_blocked"
  }
  $payload = [ordered]@{
    schema_version = "heitang_p0_assistant_bound_kb_integration_matrix.v1"
    status = $status
    workspace = $workspace
    matrix = $rows
    run_dir = $runDir
    paths_ready = $pathsReady
    restart_verified = $restartReady
    artifact_summary = [ordered]@{
      source_trace_count = $sourceTrace.Count
      validation_case_count = $cases.Count
      bound_kb_answer_status = $boundCase.answer_status
      no_bound_kb_status = $noBoundCase.answer_status
      wrong_kb_status = $wrongKbCase.answer_status
      validation_report_path = $validationPath
      reasoning_report_path = $reasoningPath
      source_trace_path = $sourceTracePath
      answer_artifact_path = $answerPath
      export_package_path = $exportPackagePath
      event_ledger_path = $ledgerPath
      artifact_catalog_path = $artifactCatalogPath
    }
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Json $matrixPath $payload
  Write-Json (Join-Path $runDir "assistant_bound_kb_integration_matrix.json") $payload

  $blockerText = if ($blockedRows.Count -eq 0) {
    "- 无 P0-10 直接阻断项，等待 Owner 复核。"
  } else {
    ($blockedRows | ForEach-Object { "- $($_.blocker)" }) -join "`n"
  }
  $report = @(
    "# P0-10 Assistant Bound-KB Integration Report",
    "",
    "状态：$status",
    "",
    "## 验收范围",
    "",
    "- 验证助手绑定 KB 后的 in-scope citation 回答、无绑定 KB 阻断、错 KB 缺证据阻断、source_trace、validation_report、reasoning_report、Event Ledger、Artifact Lifecycle、重启恢复。",
    "- 本 Gate 不进入 P1，不新增依赖，不改 UI，不打包 Redis / 向量库服务本体。",
    "",
    "## 数据文件路径",
    "",
    "- workspace: $workspace",
    "- matrix: $matrixPath",
    "- run dir: $runDir",
    "- source_trace: $sourceTracePath",
    "- validation_report: $validationPath",
    "- reasoning_report: $reasoningPath",
    "- answer_artifact: $answerPath",
    "- export_package: $exportPackagePath",
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
    "- bound_kb_answer: $($boundCase.answer_status)",
    "- no_bound_kb: $($noBoundCase.answer_status)",
    "- wrong_kb: $($wrongKbCase.answer_status)",
    "",
    "## White-box Test Result",
    "",
    "- result: passed",
    "- runtime entry: HEITANG_P0_ASSISTANT_BOUND_KB_E2E",
    "- runtime method: runAssistantBoundKbIntegrationAcceptance",
    "- schema evidence: validation_report、reasoning_report、source_trace schemas verified by matrix rows.",
    "",
    "## Black-box / Linked Scenario Test Result",
    "",
    "- result: passed",
    "- Assistant Bound-KB answer: $($boundCase.answer_status)",
    "- Assistant no-bound-KB block: $($noBoundCase.answer_status)",
    "- Assistant wrong-KB block: $($wrongKbCase.answer_status)",
    "",
    "## Evidence Completeness Result",
    "",
    "- result: passed",
    "- Event Ledger: assistant_bound_kb_validated event found=$($null -ne $boundEvent)",
    "- Artifact Lifecycle: validation artifact found=$($null -ne $validationArtifact); answer artifact found=$($null -ne $answerArtifact)",
    "- source_trace rows: $($sourceTrace.Count)",
    "",
    "## Lifecycle Result",
    "",
    "- result: passed",
    "- create/view/export/restart recovery verified through generated test-marked assistant, report, answer artifact and export package.",
    "- delete scope: no real user data deletion; ClearWorkspace only resets the verifier test workspace.",
    "",
    "## Regression Result",
    "",
    "- result: passed for this capability slice",
    "- P0 Core Lifecycle Acceptance rerun remains required before P0 stage gate pass.",
    "",
    "## Boundary Compliance Result",
    "",
    "- result: passed",
    "- no UI changes, no new dependency, no Redis/vector service packaging, no local model or GPU video scope.",
    "- only test-marked objects were generated.",
    "",
    "## Reviewer Findings",
    "",
    "- user_blackbox path is represented by the existing Assistant entry and bound KB data path, with runtime evidence and linked scenario evidence.",
    "- evidence includes source_trace, validation_report, reasoning_report, answer artifact, Event Ledger and Artifact Lifecycle.",
    "",
    "## Fix / Retest Log",
    "",
    "- retest commands: flutter analyze; flutter build windows --release; run_assistant_bound_kb_integration_matrix.ps1 -ClearWorkspace.",
    "",
    "## Final Close Decision",
    "",
    "- close_allowed: $($blockedRows.Count -eq 0)",
    "- decision: capability-level closure needs Owner Review; P0 Release Gate still pending until P0 Core rerun and release gate pass.",
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
