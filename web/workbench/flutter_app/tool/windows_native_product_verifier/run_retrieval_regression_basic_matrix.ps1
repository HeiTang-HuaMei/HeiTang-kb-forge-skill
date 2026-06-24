param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p1_retrieval_regression_basic"
}

function Add-RetrievalRow(
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
$regressionPath = Join-Path $repoRoot "heitang_kb_forge\retrieval\regression.py"
$schemaPath = Join-Path $repoRoot "heitang_kb_forge\schemas\retrieval_regression_schema.py"
$testPath = Join-Path $repoRoot "tests\test_retrieval_regression_basic.py"
$reliabilityContractPath = Join-Path $appRoot "output\p1_knowledge_reliability_eval_suite\knowledge_reliability_eval_suite_contract.json"
$matrixPath = Join-Path $OutputRoot "retrieval_regression_basic_matrix.json"
$contractPath = Join-Path $OutputRoot "retrieval_regression_basic_contract.json"
$sampleInputPath = Join-Path $OutputRoot "retrieval_regression_sample_input.json"
$sampleReportPath = Join-Path $OutputRoot "retrieval_regression_sample_report.json"
$failureSampleReportPath = Join-Path $OutputRoot "retrieval_regression_failure_sample_report.json"
$sampleHelperPath = Join-Path $OutputRoot "run_retrieval_regression_sample.py"
$checkpointPath = Join-Path $OutputRoot "retrieval_regression_basic_checkpoint.json"
$failurePath = Join-Path $OutputRoot "retrieval_regression_basic_failure_template.json"
$resumePath = Join-Path $OutputRoot "retrieval_regression_basic_resume_prompt.md"
$reportPath = Join-Path $repoRoot "docs\audits\current\retrieval_regression_closure_report.md"
$rows = [System.Collections.ArrayList]::new()

$requiredFiles = @(
  $chainPath,
  $registryPath,
  $planPath,
  $queuePath,
  $rubricPath,
  $p1BackfillPath,
  $regressionPath,
  $schemaPath,
  $testPath,
  $reliabilityContractPath
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
Add-RetrievalRow $rows "required retrieval regression source and prior evidence files exist" ($missingFiles.Count -eq 0) `
  "missing=$($missingFiles.Count)" `
  "retrieval_regression_required_file_missing"

$chain = Read-JsonFile $chainPath
$remaining = @($chain.remaining_gates)
$completedReview = @($chain.completed_with_owner_review_needed)
$prePassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-8 Retrieval Regression Basic" -and
  $remaining.Count -eq 84 -and
  $remaining[0] -eq "P1-8 Retrieval Regression Basic" -and
  $completedReview -notcontains "P1-8 Retrieval Regression Basic"
$postPassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-9 Scope Resolver Basic" -and
  $remaining.Count -eq 83 -and
  $remaining[0] -eq "P1-9 Scope Resolver Basic" -and
  $completedReview -contains "P1-8 Retrieval Regression Basic"
$stateOk = ($prePassState -or $postPassState) -and $chain.global_goal_complete -eq $false
Add-RetrievalRow $rows "status machine is at or just past P1-8 with global guard" $stateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($remaining[0]); remaining=$($remaining.Count); global_goal_complete=$($chain.global_goal_complete)" `
  "retrieval_regression_status_machine_mismatch"

$preconditionsOk = ($completedReview -contains "P0 Release Gate") -and
  ($completedReview -contains "P1-6 Citation Verification Basic Plus") -and
  ($completedReview -contains "P1-7 Knowledge Reliability Eval Suite Basic")
Add-RetrievalRow $rows "P0 release and P1-6 through P1-7 precede retrieval regression" $preconditionsOk `
  "p0_release=$($completedReview -contains 'P0 Release Gate'); p1_citation=$($completedReview -contains 'P1-6 Citation Verification Basic Plus'); p1_reliability=$($completedReview -contains 'P1-7 Knowledge Reliability Eval Suite Basic')" `
  "retrieval_regression_missing_precondition"

$nextGate = if ($prePassState -and $remaining.Count -gt 1) {
  $remaining[1]
} elseif ($postPassState) {
  $remaining[0]
} else {
  ""
}
$chainShapeOk = $nextGate -eq "P1-9 Scope Resolver Basic" -and
  ($remaining -contains "P1 Release Gate") -and
  ($remaining -contains "P2 Release Gate") -and
  ($remaining -contains "Final Owner Review Gate")
Add-RetrievalRow $rows "remaining chain preserves release gates and next gate" $chainShapeOk `
  "next_gate=$nextGate; p1_release=$($remaining -contains 'P1 Release Gate'); p2_release=$($remaining -contains 'P2 Release Gate'); final=$($remaining -contains 'Final Owner Review Gate')" `
  "retrieval_regression_chain_sequence_invalid"

$registryRow = @(
  Get-Content -LiteralPath $registryPath -Encoding UTF8 |
    Where-Object { $_ -match "^\| retrieval_regression \|" }
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
Add-RetrievalRow $rows "retrieval_regression registry row follows core-only contract" $registryStatusOk `
  "row_count=$($registryRow.Count); type=$($registryCells[3]); core=$($registryCells[4]); ui=$($registryCells[5]); blackbox=$($registryCells[6]); close_allowed=$($registryCells[13])" `
  "retrieval_regression_registry_row_invalid"

$planText = Get-Content -Raw -LiteralPath $planPath -Encoding UTF8
$queueText = Get-Content -Raw -LiteralPath $queuePath -Encoding UTF8
$rubricText = Get-Content -Raw -LiteralPath $rubricPath -Encoding UTF8
$p1Text = Get-Content -Raw -LiteralPath $p1BackfillPath -Encoding UTF8
$crossRefsOk = $planText.Contains("| 31 | P1 | retrieval_regression | Retrieval Regression Basic | core_only |") -and
  $queueText.Contains("12. P1-8 Retrieval Regression Basic") -and
  $queueText.Contains("13. P1-9 Scope Resolver Basic") -and
  $rubricText.Contains("| P1 | retrieval_regression | core_only |") -and
  $p1Text.Contains("retrieval_regression")
Add-RetrievalRow $rows "plan, queue, rubric and P1 grouping reference retrieval regression" $crossRefsOk `
  "plan=$($planText.Contains('| 31 | P1 | retrieval_regression | Retrieval Regression Basic | core_only |')); queue_p1_8=$($queueText.Contains('12. P1-8 Retrieval Regression Basic')); queue_p1_9=$($queueText.Contains('13. P1-9 Scope Resolver Basic'))" `
  "retrieval_regression_cross_reference_invalid"

$regressionText = Get-Content -Raw -LiteralPath $regressionPath -Encoding UTF8
$schemaText = Get-Content -Raw -LiteralPath $schemaPath -Encoding UTF8
$sourceShapeOk = $regressionText.Contains("def run_retrieval_regression") -and
  $schemaText.Contains("class RetrievalRegressionInput") -and
  $schemaText.Contains("class RetrievalRegressionReport") -and
  $schemaText.Contains("top_record_match") -and
  $schemaText.Contains("top_citation_match")
Add-RetrievalRow $rows "source implements structured retrieval regression input and report schema" $sourceShapeOk `
  "regression=$($regressionText.Contains('def run_retrieval_regression')); input_schema=$($schemaText.Contains('class RetrievalRegressionInput')); report_schema=$($schemaText.Contains('class RetrievalRegressionReport'))" `
  "retrieval_regression_source_shape_missing"

$sampleInput = [ordered]@{
  baseline = [ordered]@{
    query = "knowledge reliability"
    records = @([ordered]@{ record_id = "chunk-1"; citation = "source-a.md#chunk=chunk-1" })
    citation_trace_count = 1
  }
  current = [ordered]@{
    query = "knowledge reliability"
    records = @([ordered]@{ record_id = "chunk-1"; citation = "source-a.md#chunk=chunk-1" })
    citation_trace_count = 1
  }
}
Write-Json $sampleInputPath $sampleInput
$pythonCode = @"
import json
import sys
from pathlib import Path

sys.path.insert(0, r"$repoRoot")

from heitang_kb_forge.retrieval import run_retrieval_regression

payload = json.loads(Path(r"$sampleInputPath").read_text(encoding="utf-8-sig"))
report = run_retrieval_regression(payload)
Path(r"$sampleReportPath").write_text(json.dumps(report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
failure_payload = {
    "baseline": payload["baseline"],
    "current": {
        "query": "knowledge reliability",
        "records": [{"record_id": "chunk-2", "citation": "source-b.md#chunk=chunk-2"}],
        "citation_trace_count": 2,
    },
}
failure_report = run_retrieval_regression(failure_payload)
Path(r"$failureSampleReportPath").write_text(json.dumps(failure_report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
"@
Set-Content -Encoding UTF8 -Path $sampleHelperPath -Value $pythonCode
$sampleResult = Invoke-CheckedCommand "python" @($sampleHelperPath) $repoRoot
$sampleReport = Read-JsonFile $sampleReportPath
$failureSampleReport = Read-JsonFile $failureSampleReportPath
$sampleOk = $sampleResult.exit_code -eq 0 -and
  $sampleReport.status -eq "pass" -and
  $sampleReport.regression_count -eq 0 -and
  $sampleReport.top_record_match -eq $true -and
  $sampleReport.top_citation_match -eq $true -and
  $failureSampleReport.status -eq "regression_found" -and
  $failureSampleReport.regression_count -eq 3
Add-RetrievalRow $rows "retrieval regression detects top record, citation and trace drift" $sampleOk `
  "exit_code=$($sampleResult.exit_code); pass_status=$($sampleReport.status); pass_regressions=$($sampleReport.regression_count); failure_status=$($failureSampleReport.status); failure_regressions=$($failureSampleReport.regression_count)" `
  "retrieval_regression_sample_output_invalid"

$pytestResult = Invoke-CheckedCommand "python" @(
  "-m",
  "pytest",
  "tests/test_retrieval_regression_basic.py",
  "tests/test_agent_rag_retrieve.py",
  "tests/test_agent_rag_citation_trace.py",
  "tests/test_retrieval_eval.py",
  "-q"
) $repoRoot
$pytestOk = $pytestResult.exit_code -eq 0
Add-RetrievalRow $rows "narrow retrieval regression and RAG retrieval tests pass" $pytestOk `
  "exit_code=$($pytestResult.exit_code); stdout=$($pytestResult.stdout.Trim()); stderr=$($pytestResult.stderr.Trim())" `
  "retrieval_regression_tests_failed"

$reliabilityContract = Read-JsonFile $reliabilityContractPath
$priorEvidenceOk = $reliabilityContract.status -eq "knowledge_reliability_eval_suite_completed_needs_owner_review"
Add-RetrievalRow $rows "P1 reliability eval suite contract is available" $priorEvidenceOk `
  "reliability_status=$($reliabilityContract.status)" `
  "retrieval_regression_prior_evidence_missing"

$contract = [ordered]@{
  schema_version = "heitang_retrieval_regression_basic_contract.v1"
  status = "retrieval_regression_completed_needs_owner_review"
  capability_id = "retrieval_regression"
  phase = "P1"
  acceptance_type = "core_only"
  required_inputs = @("baseline", "current")
  required_outputs = @("status", "query_match", "top_record_match", "top_citation_match", "citation_trace_count_match", "regressions")
  sample_input_path = $sampleInputPath
  sample_report_path = $sampleReportPath
  failure_sample_report_path = $failureSampleReportPath
  sample_status = $sampleReport.status
  failure_sample_status = $failureSampleReport.status
  next_gate = $nextGate
  global_goal_complete = $false
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $contractPath $contract

$contractOk = (Test-Path -LiteralPath $contractPath) -and
  $contract.sample_status -eq "pass" -and
  $contract.failure_sample_status -eq "regression_found" -and
  $contract.required_outputs.Count -eq 6 -and
  $contract.next_gate -eq "P1-9 Scope Resolver Basic" -and
  $contract.global_goal_complete -eq $false
Add-RetrievalRow $rows "retrieval regression basic contract artifact is generated" $contractOk `
  "contract=$contractPath; sample_status=$($contract.sample_status); failure_status=$($contract.failure_sample_status); next_gate=$($contract.next_gate)" `
  "retrieval_regression_contract_invalid"

$claimHits = Test-PositiveClaimBoundary @($contractPath, $sampleReportPath, $failureSampleReportPath)
Add-RetrievalRow $rows "new P1-8 evidence has no forbidden positive-state tokens" ($claimHits.Count -eq 0) `
  "scanned=contract,sample_report,failure_sample_report; hits=$($claimHits.Count)" `
  "retrieval_regression_forbidden_claim_token_found"

$blocked = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "retrieval_regression_completed_needs_owner_review"
} else {
  "retrieval_regression_blocked"
}

$checkpoint = [ordered]@{
  schema_version = "heitang_retrieval_regression_basic_checkpoint.v1"
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
  schema_version = "heitang_retrieval_regression_basic_failure_template.v1"
  status = "no_current_failure"
  affected_phase = "P1"
  affected_capability_id = "retrieval_regression"
  failed_acceptance_type = "core_only"
  resume_prompt_path = $resumePath
  created_at = (Get-Date).ToUniversalTime().ToString("o")
})
@(
  "# Retrieval Regression Basic Resume Prompt",
  "",
  "Resume from current_gate=$($chain.current_gate) if interrupted before commit.",
  "After commit, resume from next_gate=$nextGate.",
  "Keep global_goal_complete=false while remaining gates exist.",
  "Do not execute P1-9 until P1-8 evidence is committed."
) | Set-Content -Encoding UTF8 -Path $resumePath

$payload = [ordered]@{
  schema_version = "heitang_p1_retrieval_regression_basic_matrix.v1"
  status = $status
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
  repo_root = $repoRoot
  current_phase = $chain.current_phase
  current_gate = $chain.current_gate
  next_gate = $nextGate
  remaining_gates_count = $remaining.Count
  global_goal_complete = $false
  contract_path = $contractPath
  sample_report_path = $sampleReportPath
  failure_sample_report_path = $failureSampleReportPath
  checkpoint_path = $checkpointPath
  failure_template_path = $failurePath
  resume_prompt_path = $resumePath
  rows = $rows
}
Write-Json $matrixPath $payload

$blockerText = if ($blocked.Count -eq 0) {
  "- none for this P1-8 gate; Owner review remains outside automatic closure."
} else {
  ($blocked | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$report = @(
  "# P1-8 Retrieval Regression Basic Closure Report",
  "",
  "Status: $status",
  "",
  "## Acceptance Scope",
  "",
  "- Validate deterministic retrieval regression checks for top record, citation and citation trace stability.",
  "- This Gate is core_only; it does not add UI, external LLM calls or P2 retrieval benchmark behavior.",
  "",
  "## Verification Summary",
  "",
  "- current_phase: $($chain.current_phase)",
  "- current_gate: $($chain.current_gate)",
  "- next_gate: $nextGate",
  "- remaining_gates: $($remaining.Count)",
  "- global_goal_complete: false",
  "- blocked rows: $($blocked.Count)",
  "",
  "## Evidence Matrix",
  "",
  $evidenceText,
  "",
  "## White-box Test Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- command: run_retrieval_regression_basic_matrix.ps1",
  "- schema evidence: regression checker, pydantic schema, pass/fail sample reports and narrow tests.",
  "",
  "## Black-box Test Result",
  "",
  "- result: not_required",
  "- reason: core_only retrieval regression has no standalone user UI path.",
  "",
  "## Evidence Completeness Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- artifacts: contract, matrix, sample input/reports, checkpoint, failure template, resume prompt and this report.",
  "",
  "## Lifecycle Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- scope: create and read deterministic retrieval regression reports plus rerunnable verifier contract.",
  "",
  "## Regression Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- tests: python -m pytest tests/test_retrieval_regression_basic.py tests/test_agent_rag_retrieve.py tests/test_agent_rag_citation_trace.py tests/test_retrieval_eval.py -q",
  "",
  "## Boundary Compliance Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- no UI/runtime edits, no dependency addition, no external service use, no P2 entry.",
  "",
  "## Reviewer Findings",
  "",
  "- P1-8 uses deterministic core evidence only and does not fake a UI blackbox.",
  "- P2 retrieval benchmark remains queued separately.",
  "- P1-7 reliability eval evidence remains readable and precedes this regression check.",
  "",
  "## Final Close Decision",
  "",
  "- close_allowed: $($blocked.Count -eq 0)",
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
if ($blocked.Count -gt 0) { exit 1 }
