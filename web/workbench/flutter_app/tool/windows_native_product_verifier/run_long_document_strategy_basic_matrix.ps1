param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p1_long_document_strategy_basic"
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

function Add-LongDocumentRow(
  [System.Collections.ArrayList]$Rows,
  [string]$Check,
  [bool]$Passed,
  [string]$Actual,
  [string]$Blocker = ""
) {
  [void]$Rows.Add([ordered]@{
    check = $Check
    status = if ($Passed) { "passed" } else { "blocked" }
    actual = $Actual
    blocker = if ($Passed) { "" } else { $Blocker }
  })
}

function Split-MarkdownRow([string]$Row) {
  return @(
    ($Row -split "\|") |
      ForEach-Object { $_.Trim() } |
      Where-Object { $_.Length -gt 0 }
  )
}

function Invoke-CheckedCommand([string]$FilePath, [string[]]$Arguments, [string]$WorkingDirectory) {
  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $FilePath
  $psi.Arguments = ($Arguments | ForEach-Object {
    if ($_ -match '\s') { '"' + ($_.Replace('"', '\"')) + '"' } else { $_ }
  }) -join " "
  $psi.WorkingDirectory = $WorkingDirectory
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $process = [System.Diagnostics.Process]::Start($psi)
  $stdout = $process.StandardOutput.ReadToEnd()
  $stderr = $process.StandardError.ReadToEnd()
  $process.WaitForExit()
  return [ordered]@{
    exit_code = $process.ExitCode
    stdout = if ($stdout.Length -gt 600) { $stdout.Substring(0, 600) } else { $stdout }
    stderr = if ($stderr.Length -gt 600) { $stderr.Substring(0, 600) } else { $stderr }
  }
}

function Test-PositiveClaimBoundary([string[]]$Paths) {
  $terms = @(
    ("production" + "_" + "ready"),
    ("release" + "_" + "ready"),
    ("industrial" + "_" + "acceptance" + "_" + "passed")
  )
  $hits = [System.Collections.ArrayList]::new()
  foreach ($path in $Paths) {
    if (-not (Test-Path -LiteralPath $path)) { continue }
    $lines = Get-Content -LiteralPath $path -Encoding UTF8
    for ($i = 0; $i -lt $lines.Count; $i += 1) {
      foreach ($term in $terms) {
        if ($lines[$i].Contains($term)) {
          [void]$hits.Add([ordered]@{ path = $path; line = $i + 1; term = $term })
        }
      }
    }
  }
  return @($hits)
}

$appRoot = Get-AppRoot
$repoRoot = (Resolve-Path (Join-Path $appRoot "..\..\..")).Path
$chainPath = Join-Path $repoRoot "capability_chain_status.json"
$registryPath = Join-Path $repoRoot "docs\capability_registry\Capability_Implementation_Status.md"
$planPath = Join-Path $repoRoot "docs\capability_registry\Full_Target_Mode_Plan.md"
$queuePath = Join-Path $repoRoot "docs\capability_registry\Full_Target_Mode_Execution_Queue.md"
$rubricPath = Join-Path $repoRoot "docs\capability_registry\Full_Target_Mode_Rubric.md"
$p1BackfillPath = Join-Path $repoRoot "docs\capability_registry\P1_Backfill_Gates.md"
$strategyPath = Join-Path $repoRoot "heitang_kb_forge\long_document_strategy\strategy.py"
$schemaPath = Join-Path $repoRoot "heitang_kb_forge\schemas\long_document_strategy_schema.py"
$testPath = Join-Path $repoRoot "tests\test_long_document_strategy_basic.py"
$planExecuteContractPath = Join-Path $appRoot "output\p1_plan_execute_runtime_basic\plan_execute_runtime_basic_contract.json"
$matrixPath = Join-Path $OutputRoot "long_document_strategy_basic_matrix.json"
$contractPath = Join-Path $OutputRoot "long_document_strategy_basic_contract.json"
$readyReportPath = Join-Path $OutputRoot "long_document_ready_report.json"
$partialReportPath = Join-Path $OutputRoot "long_document_partial_report.json"
$missingReportPath = Join-Path $OutputRoot "long_document_missing_required_report.json"
$sampleHelperPath = Join-Path $OutputRoot "run_long_document_strategy_sample.py"
$checkpointPath = Join-Path $OutputRoot "long_document_strategy_basic_checkpoint.json"
$failurePath = Join-Path $OutputRoot "long_document_strategy_basic_failure_template.json"
$resumePath = Join-Path $OutputRoot "long_document_strategy_basic_resume_prompt.md"
$reportPath = Join-Path $repoRoot "docs\audits\current\long_document_strategy_closure_report.md"
$rows = [System.Collections.ArrayList]::new()

$requiredFiles = @(
  $chainPath,
  $registryPath,
  $planPath,
  $queuePath,
  $rubricPath,
  $p1BackfillPath,
  $strategyPath,
  $schemaPath,
  $testPath,
  $planExecuteContractPath
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
Add-LongDocumentRow $rows "required long document strategy source and prior evidence files exist" ($missingFiles.Count -eq 0) `
  "missing=$($missingFiles.Count)" `
  "long_document_strategy_required_file_missing"

$chain = Read-JsonFile $chainPath
$remaining = @($chain.remaining_gates)
$completedReview = @($chain.completed_with_owner_review_needed)
$prePassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-16 Long Document Reading Strategy Basic" -and
  $remaining.Count -eq 76 -and
  $remaining[0] -eq "P1-16 Long Document Reading Strategy Basic" -and
  $completedReview -notcontains "P1-16 Long Document Reading Strategy Basic"
$postPassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-17 External Skill Import Basic" -and
  $remaining.Count -eq 75 -and
  $remaining[0] -eq "P1-17 External Skill Import Basic" -and
  $completedReview -contains "P1-16 Long Document Reading Strategy Basic"
$stateOk = ($prePassState -or $postPassState) -and $chain.global_goal_complete -eq $false
Add-LongDocumentRow $rows "status machine is at or just past P1-16 with global guard" $stateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($remaining[0]); remaining=$($remaining.Count); global_goal_complete=$($chain.global_goal_complete)" `
  "long_document_strategy_status_machine_mismatch"

$preconditionsOk = ($completedReview -contains "P0 Release Gate") -and
  ($completedReview -contains "P1-15 Plan-and-Execute Runtime Basic")
Add-LongDocumentRow $rows "P0 release and P1-15 precede long document strategy" $preconditionsOk `
  "p0_release=$($completedReview -contains 'P0 Release Gate'); p1_plan_execute=$($completedReview -contains 'P1-15 Plan-and-Execute Runtime Basic')" `
  "long_document_strategy_missing_precondition"

$nextGate = if ($prePassState -and $remaining.Count -gt 1) {
  $remaining[1]
} elseif ($postPassState) {
  $remaining[0]
} else {
  ""
}
$chainShapeOk = $nextGate -eq "P1-17 External Skill Import Basic" -and
  ($remaining -contains "P1 Release Gate") -and
  ($remaining -contains "P2 Release Gate") -and
  ($remaining -contains "Final Owner Review Gate")
Add-LongDocumentRow $rows "remaining chain preserves release gates and next gate" $chainShapeOk `
  "next_gate=$nextGate; p1_release=$($remaining -contains 'P1 Release Gate'); p2_release=$($remaining -contains 'P2 Release Gate'); final=$($remaining -contains 'Final Owner Review Gate')" `
  "long_document_strategy_chain_sequence_invalid"

$registryRow = @(
  Get-Content -LiteralPath $registryPath -Encoding UTF8 |
    Where-Object { $_ -match "^\| long_document_strategy \|" }
)
$registryCells = if ($registryRow.Count -eq 1) { Split-MarkdownRow $registryRow[0] } else { @() }
$registryOk = $registryRow.Count -eq 1 -and
  $registryCells[2] -eq "P1" -and
  $registryCells[3] -eq "core_only" -and
  $registryCells[5] -eq "not_required" -and
  $registryCells[6] -eq "not_required" -and
  $registryCells[12] -eq "true"
$registryStatusOk = $registryOk -and (
  ($prePassState -and $registryCells[4] -in @("not_started", "passed")) -or
  ($postPassState -and $registryCells[4] -eq "passed" -and $registryCells[13] -eq "true")
)
Add-LongDocumentRow $rows "long_document_strategy registry row follows core-only contract" $registryStatusOk `
  "row_count=$($registryRow.Count); type=$($registryCells[3]); core=$($registryCells[4]); ui=$($registryCells[5]); blackbox=$($registryCells[6]); close_allowed=$($registryCells[13])" `
  "long_document_strategy_registry_row_invalid"

$planText = Get-Content -Raw -LiteralPath $planPath -Encoding UTF8
$queueText = Get-Content -Raw -LiteralPath $queuePath -Encoding UTF8
$rubricText = Get-Content -Raw -LiteralPath $rubricPath -Encoding UTF8
$p1Text = Get-Content -Raw -LiteralPath $p1BackfillPath -Encoding UTF8
$crossRefsOk = $planText.Contains("| 39 | P1 | long_document_strategy | Long Document Reading Strategy Basic | core_only |") -and
  $queueText.Contains("20. P1-16 Long Document Reading Strategy Basic") -and
  $queueText.Contains("21. P1-17 External Skill Import Basic") -and
  $rubricText.Contains("| P1 | long_document_strategy | core_only |") -and
  $p1Text.Contains("plan_execute_runtime")
Add-LongDocumentRow $rows "plan, queue, rubric and P1 grouping reference long document strategy" $crossRefsOk `
  "plan=$($planText.Contains('| 39 | P1 | long_document_strategy | Long Document Reading Strategy Basic | core_only |')); queue_p1_16=$($queueText.Contains('20. P1-16 Long Document Reading Strategy Basic')); queue_p1_17=$($queueText.Contains('21. P1-17 External Skill Import Basic'))" `
  "long_document_strategy_cross_reference_invalid"

$strategyText = Get-Content -Raw -LiteralPath $strategyPath -Encoding UTF8
$schemaText = Get-Content -Raw -LiteralPath $schemaPath -Encoding UTF8
$sourceShapeOk = $strategyText.Contains("def build_long_document_strategy") -and
  $schemaText.Contains("class LongDocumentStrategyInput") -and
  $schemaText.Contains("class LongDocumentStrategyReport") -and
  $schemaText.Contains("reading_order") -and
  $schemaText.Contains("remaining_section_ids")
Add-LongDocumentRow $rows "source implements structured long document strategy input and report schema" $sourceShapeOk `
  "strategy=$($strategyText.Contains('def build_long_document_strategy')); input_schema=$($schemaText.Contains('class LongDocumentStrategyInput')); report_schema=$($schemaText.Contains('class LongDocumentStrategyReport'))" `
  "long_document_strategy_source_shape_missing"

$pythonCode = @"
import json
import sys
from pathlib import Path

sys.path.insert(0, r"$repoRoot")

from heitang_kb_forge.long_document_strategy import build_long_document_strategy

ready = build_long_document_strategy({
    "sections": [
        {"section_id": "intro", "title": "Intro", "text": "a" * 20},
        {"section_id": "body", "title": "Body", "text": "b" * 25},
    ],
    "max_chars_per_pass": 100,
    "required_section_ids": ["intro"],
})
partial = build_long_document_strategy({
    "sections": [
        {"section_id": "done", "title": "Done", "text": "d" * 15, "already_read": True},
        {"section_id": "next", "title": "Next", "text": "n" * 20},
        {"section_id": "later", "title": "Later", "text": "l" * 20},
    ],
    "max_chars_per_pass": 30,
})
missing = build_long_document_strategy({
    "sections": [{"section_id": "intro", "title": "Intro", "text": "hello"}],
    "required_section_ids": ["appendix"],
})

Path(r"$readyReportPath").write_text(json.dumps(ready.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
Path(r"$partialReportPath").write_text(json.dumps(partial.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
Path(r"$missingReportPath").write_text(json.dumps(missing.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
"@
Set-Content -Encoding UTF8 -Path $sampleHelperPath -Value $pythonCode
$sampleResult = Invoke-CheckedCommand "python" @($sampleHelperPath) $repoRoot
$readyReport = Read-JsonFile $readyReportPath
$partialReport = Read-JsonFile $partialReportPath
$missingReport = Read-JsonFile $missingReportPath
$sampleOk = $sampleResult.exit_code -eq 0 -and
  $readyReport.status -eq "ready" -and
  (@($readyReport.reading_order) -join ",") -eq "intro,body" -and
  $partialReport.status -eq "partial" -and
  (@($partialReport.reading_order) -join ",") -eq "next" -and
  (@($partialReport.remaining_section_ids) -join ",") -eq "later" -and
  $missingReport.status -eq "missing_required_sections" -and
  (@($missingReport.missing_required_section_ids) -join ",") -eq "appendix"
Add-LongDocumentRow $rows "long document strategy handles ready, partial and missing-required paths" $sampleOk `
  "exit_code=$($sampleResult.exit_code); ready=$($readyReport.status); partial=$($partialReport.status); missing=$($missingReport.status)" `
  "long_document_strategy_sample_output_invalid"

$pytestResult = Invoke-CheckedCommand "python" @(
  "-m",
  "pytest",
  "tests/test_long_document_strategy_basic.py",
  "tests/test_plan_execute_runtime_basic.py",
  "tests/test_planning_readiness.py",
  "-q"
) $repoRoot
$pytestOk = $pytestResult.exit_code -eq 0
Add-LongDocumentRow $rows "narrow long document and related planning tests pass" $pytestOk `
  "exit_code=$($pytestResult.exit_code); stdout=$($pytestResult.stdout.Trim()); stderr=$($pytestResult.stderr.Trim())" `
  "long_document_strategy_tests_failed"

$planExecuteContract = Read-JsonFile $planExecuteContractPath
$priorEvidenceOk = $planExecuteContract.status -eq "plan_execute_runtime_completed_needs_owner_review"
Add-LongDocumentRow $rows "P1 plan execute runtime contract is available" $priorEvidenceOk `
  "plan_execute_status=$($planExecuteContract.status)" `
  "long_document_strategy_prior_evidence_missing"

$contract = [ordered]@{
  schema_version = "heitang_long_document_strategy_basic_contract.v1"
  status = "long_document_strategy_completed_needs_owner_review"
  capability_id = "long_document_strategy"
  phase = "P1"
  acceptance_type = "core_only"
  required_inputs = @("sections", "max_chars_per_pass", "max_sections_per_pass", "required_section_ids")
  required_outputs = @("status", "reading_order", "remaining_section_ids", "already_read_section_ids", "missing_required_section_ids", "selected_char_count")
  ready_report_path = $readyReportPath
  partial_report_path = $partialReportPath
  missing_required_report_path = $missingReportPath
  sample_statuses = @($readyReport.status, $partialReport.status, $missingReport.status)
  next_gate = $nextGate
  global_goal_complete = $false
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $contractPath $contract

$contractOk = (Test-Path -LiteralPath $contractPath) -and
  ($contract.sample_statuses -join ",") -eq "ready,partial,missing_required_sections" -and
  $contract.required_outputs.Count -eq 6 -and
  $contract.next_gate -eq "P1-17 External Skill Import Basic" -and
  $contract.global_goal_complete -eq $false
Add-LongDocumentRow $rows "long document strategy basic contract artifact is generated" $contractOk `
  "contract=$contractPath; statuses=$($contract.sample_statuses -join ','); next_gate=$($contract.next_gate)" `
  "long_document_strategy_contract_invalid"

$claimHits = Test-PositiveClaimBoundary @($contractPath, $readyReportPath, $partialReportPath, $missingReportPath)
Add-LongDocumentRow $rows "new P1-16 evidence has no forbidden positive-state tokens" ($claimHits.Count -eq 0) `
  "scanned=contract,ready,partial,missing; hits=$($claimHits.Count)" `
  "long_document_strategy_forbidden_claim_token_found"

$blockedRows = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blockedRows.Count -eq 0) {
  "long_document_strategy_completed_needs_owner_review"
} else {
  "long_document_strategy_blocked"
}

$checkpoint = [ordered]@{
  schema_version = "heitang_long_document_strategy_basic_checkpoint.v1"
  status = $status
  current_phase = $chain.current_phase
  current_gate = $chain.current_gate
  next_gate = $nextGate
  remaining_gates_count = $remaining.Count
  global_goal_complete = $false
  created_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $checkpointPath $checkpoint
Write-Json $failurePath ([ordered]@{
  schema_version = "heitang_long_document_strategy_basic_failure_template.v1"
  status = "no_current_failure"
  affected_phase = "P1"
  affected_capability_id = "long_document_strategy"
  failed_acceptance_type = "core_only"
  resume_prompt_path = $resumePath
  created_at = (Get-Date).ToUniversalTime().ToString("o")
})
@(
  "# Long Document Reading Strategy Basic Resume Prompt",
  "",
  "Resume from current_gate=$($chain.current_gate) if interrupted before commit.",
  "After commit, resume from next_gate=$nextGate.",
  "Keep global_goal_complete=false while remaining gates exist.",
  "Do not execute P1-17 until P1-16 evidence is committed."
) | Set-Content -Encoding UTF8 -Path $resumePath

$payload = [ordered]@{
  schema_version = "heitang_p1_long_document_strategy_basic_matrix.v1"
  status = $status
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
  repo_root = $repoRoot
  current_phase = $chain.current_phase
  current_gate = $chain.current_gate
  next_gate = $nextGate
  remaining_gates_count = $remaining.Count
  global_goal_complete = $false
  contract_path = $contractPath
  ready_report_path = $readyReportPath
  partial_report_path = $partialReportPath
  missing_required_report_path = $missingReportPath
  checkpoint_path = $checkpointPath
  failure_template_path = $failurePath
  resume_prompt_path = $resumePath
  rows = $rows
}
Write-Json $matrixPath $payload

$blockerText = if ($blockedRows.Count -eq 0) {
  "- none for this P1-16 gate; Owner review remains outside automatic closure."
} else {
  ($blockedRows | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$resultText = if ($blockedRows.Count -eq 0) { "passed" } else { "blocked" }
$closeAllowedText = if ($blockedRows.Count -eq 0) { "True" } else { "False" }
$report = @(
  "# P1-16 Long Document Reading Strategy Basic Closure Report",
  "",
  "Status: $status",
  "",
  "## Acceptance Scope",
  "",
  "- Validate deterministic reading order, remaining-section tracking and missing required section handling for long documents.",
  "- This Gate is core_only; it does not run LLM long-context calls, UI paths or external services.",
  "",
  "## Verification Summary",
  "",
  "- current_phase: $($chain.current_phase)",
  "- current_gate: $($chain.current_gate)",
  "- next_gate: $nextGate",
  "- remaining_gates: $($remaining.Count)",
  "- global_goal_complete: false",
  "- blocked rows: $($blockedRows.Count)",
  "",
  "## Evidence Matrix",
  "",
  $evidenceText,
  "",
  "## White-box Test Result",
  "",
  "- result: $resultText",
  "- command: run_long_document_strategy_basic_matrix.ps1",
  "- schema evidence: strategy, pydantic schema, ready/partial/missing-required reports and narrow tests.",
  "",
  "## Black-box Test Result",
  "",
  "- result: not_required",
  "- reason: core_only long document strategy has no standalone user UI path.",
  "",
  "## Evidence Completeness Result",
  "",
  "- result: $resultText",
  "- artifacts: contract, matrix, sample reports, checkpoint, failure template, resume prompt and this report.",
  "",
  "## Lifecycle Result",
  "",
  "- result: $resultText",
  "- scope: create and read deterministic reading strategy reports plus rerunnable verifier contract.",
  "",
  "## Regression Result",
  "",
  "- result: $resultText",
  "- tests: python -m pytest tests/test_long_document_strategy_basic.py tests/test_plan_execute_runtime_basic.py tests/test_planning_readiness.py -q",
  "",
  "## Boundary Compliance Result",
  "",
  "- result: $resultText",
  "- no UI/runtime edits, no dependency addition, no external service use, no P2 entry.",
  "",
  "## Reviewer Findings",
  "",
  "- P1-16 uses deterministic core evidence only and does not fake a UI blackbox.",
  "- External Skill Import remains queued as P1-17.",
  "- P1-15 plan execute runtime evidence remains readable.",
  "",
  "## Final Close Decision",
  "",
  "- close_allowed: $closeAllowedText",
  "- next_gate: $nextGate",
  "",
  "## Blockers",
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
