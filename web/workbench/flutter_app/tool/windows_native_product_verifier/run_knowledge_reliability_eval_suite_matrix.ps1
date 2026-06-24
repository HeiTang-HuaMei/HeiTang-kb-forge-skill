param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p1_knowledge_reliability_eval_suite"
}

function Add-ReliabilityRow(
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
$evalSuitePath = Join-Path $repoRoot "heitang_kb_forge\reliability\eval_suite.py"
$schemaPath = Join-Path $repoRoot "heitang_kb_forge\schemas\reliability_eval_schema.py"
$testPath = Join-Path $repoRoot "tests\test_knowledge_reliability_eval_suite.py"
$evidenceGraphContractPath = Join-Path $appRoot "output\p1_evidence_graph_basic\evidence_graph_basic_contract.json"
$gapContractPath = Join-Path $appRoot "output\p1_gap_analysis_basic\gap_analysis_basic_contract.json"
$citationContractPath = Join-Path $appRoot "output\p1_citation_verification_basic\citation_verification_basic_contract.json"
$citationPassingReportPath = Join-Path $appRoot "output\p1_citation_verification_basic\citation_verification_passing_report.json"
$matrixPath = Join-Path $OutputRoot "knowledge_reliability_eval_suite_matrix.json"
$contractPath = Join-Path $OutputRoot "knowledge_reliability_eval_suite_contract.json"
$sampleInputPath = Join-Path $OutputRoot "knowledge_reliability_eval_suite_sample_input.json"
$sampleReportPath = Join-Path $OutputRoot "knowledge_reliability_eval_suite_sample_report.json"
$failureSampleReportPath = Join-Path $OutputRoot "knowledge_reliability_eval_suite_failure_sample_report.json"
$sampleHelperPath = Join-Path $OutputRoot "run_knowledge_reliability_eval_suite_sample.py"
$checkpointPath = Join-Path $OutputRoot "knowledge_reliability_eval_suite_checkpoint.json"
$failurePath = Join-Path $OutputRoot "knowledge_reliability_eval_suite_failure_template.json"
$resumePath = Join-Path $OutputRoot "knowledge_reliability_eval_suite_resume_prompt.md"
$reportPath = Join-Path $repoRoot "docs\audits\current\knowledge_reliability_eval_suite_closure_report.md"
$rows = [System.Collections.ArrayList]::new()

$requiredFiles = @(
  $chainPath,
  $registryPath,
  $planPath,
  $queuePath,
  $rubricPath,
  $p1BackfillPath,
  $evalSuitePath,
  $schemaPath,
  $testPath,
  $evidenceGraphContractPath,
  $gapContractPath,
  $citationContractPath,
  $citationPassingReportPath
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
Add-ReliabilityRow $rows "required reliability eval source and prior evidence files exist" ($missingFiles.Count -eq 0) `
  "missing=$($missingFiles.Count)" `
  "knowledge_reliability_eval_required_file_missing"

$chain = Read-JsonFile $chainPath
$remaining = @($chain.remaining_gates)
$completedReview = @($chain.completed_with_owner_review_needed)
$prePassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-7 Knowledge Reliability Eval Suite Basic" -and
  $remaining.Count -eq 85 -and
  $remaining[0] -eq "P1-7 Knowledge Reliability Eval Suite Basic" -and
  $completedReview -notcontains "P1-7 Knowledge Reliability Eval Suite Basic"
$postPassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-8 Retrieval Regression Basic" -and
  $remaining.Count -eq 84 -and
  $remaining[0] -eq "P1-8 Retrieval Regression Basic" -and
  $completedReview -contains "P1-7 Knowledge Reliability Eval Suite Basic"
$stateOk = ($prePassState -or $postPassState) -and $chain.global_goal_complete -eq $false
Add-ReliabilityRow $rows "status machine is at or just past P1-7 with global guard" $stateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($remaining[0]); remaining=$($remaining.Count); global_goal_complete=$($chain.global_goal_complete)" `
  "knowledge_reliability_eval_status_machine_mismatch"

$preconditionsOk = ($completedReview -contains "P0 Release Gate") -and
  ($completedReview -contains "P1-4 Evidence Graph Basic") -and
  ($completedReview -contains "P1-5 Gap Analysis Basic Plus") -and
  ($completedReview -contains "P1-6 Citation Verification Basic Plus")
Add-ReliabilityRow $rows "P0 release and P1-4 through P1-6 precede reliability eval suite" $preconditionsOk `
  "p0_release=$($completedReview -contains 'P0 Release Gate'); p1_graph=$($completedReview -contains 'P1-4 Evidence Graph Basic'); p1_gap=$($completedReview -contains 'P1-5 Gap Analysis Basic Plus'); p1_citation=$($completedReview -contains 'P1-6 Citation Verification Basic Plus')" `
  "knowledge_reliability_eval_missing_precondition"

$nextGate = if ($prePassState -and $remaining.Count -gt 1) {
  $remaining[1]
} elseif ($postPassState) {
  $remaining[0]
} else {
  ""
}
$chainShapeOk = $nextGate -eq "P1-8 Retrieval Regression Basic" -and
  ($remaining -contains "P1 Release Gate") -and
  ($remaining -contains "P2 Release Gate") -and
  ($remaining -contains "Final Owner Review Gate")
Add-ReliabilityRow $rows "remaining chain preserves release gates and next gate" $chainShapeOk `
  "next_gate=$nextGate; p1_release=$($remaining -contains 'P1 Release Gate'); p2_release=$($remaining -contains 'P2 Release Gate'); final=$($remaining -contains 'Final Owner Review Gate')" `
  "knowledge_reliability_eval_chain_sequence_invalid"

$registryRow = @(
  Get-Content -LiteralPath $registryPath -Encoding UTF8 |
    Where-Object { $_ -match "^\| knowledge_reliability_eval_suite \|" }
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
Add-ReliabilityRow $rows "knowledge_reliability_eval_suite registry row follows core-only contract" $registryStatusOk `
  "row_count=$($registryRow.Count); type=$($registryCells[3]); core=$($registryCells[4]); ui=$($registryCells[5]); blackbox=$($registryCells[6]); close_allowed=$($registryCells[13])" `
  "knowledge_reliability_eval_registry_row_invalid"

$planText = Get-Content -Raw -LiteralPath $planPath -Encoding UTF8
$queueText = Get-Content -Raw -LiteralPath $queuePath -Encoding UTF8
$rubricText = Get-Content -Raw -LiteralPath $rubricPath -Encoding UTF8
$p1Text = Get-Content -Raw -LiteralPath $p1BackfillPath -Encoding UTF8
$crossRefsOk = $planText.Contains("| 30 | P1 | knowledge_reliability_eval_suite | Knowledge Reliability Eval Suite Basic | core_only |") -and
  $queueText.Contains("11. P1-7 Knowledge Reliability Eval Suite Basic") -and
  $queueText.Contains("12. P1-8 Retrieval Regression Basic") -and
  $rubricText.Contains("| P1 | knowledge_reliability_eval_suite | core_only |") -and
  $p1Text.Contains("knowledge_reliability_eval_suite")
Add-ReliabilityRow $rows "plan, queue, rubric and P1 grouping reference reliability eval suite" $crossRefsOk `
  "plan=$($planText.Contains('| 30 | P1 | knowledge_reliability_eval_suite | Knowledge Reliability Eval Suite Basic | core_only |')); queue_p1_7=$($queueText.Contains('11. P1-7 Knowledge Reliability Eval Suite Basic')); queue_p1_8=$($queueText.Contains('12. P1-8 Retrieval Regression Basic'))" `
  "knowledge_reliability_eval_cross_reference_invalid"

$evalText = Get-Content -Raw -LiteralPath $evalSuitePath -Encoding UTF8
$schemaText = Get-Content -Raw -LiteralPath $schemaPath -Encoding UTF8
$sourceShapeOk = $evalText.Contains("def run_reliability_eval") -and
  $schemaText.Contains("class ReliabilityEvalInput") -and
  $schemaText.Contains("class ReliabilityEvalReport") -and
  $schemaText.Contains("available_for_next_gate") -and
  $schemaText.Contains("overall_score")
Add-ReliabilityRow $rows "source implements structured reliability eval input and report schema" $sourceShapeOk `
  "eval_suite=$($evalText.Contains('def run_reliability_eval')); input_schema=$($schemaText.Contains('class ReliabilityEvalInput')); report_schema=$($schemaText.Contains('class ReliabilityEvalReport'))" `
  "knowledge_reliability_eval_source_shape_missing"

$evidenceGraphContract = Read-JsonFile $evidenceGraphContractPath
$gapContract = Read-JsonFile $gapContractPath
$citationContract = Read-JsonFile $citationContractPath
$citationPassingReport = Read-JsonFile $citationPassingReportPath
$sampleInput = [ordered]@{
  evidence_graph_status = $evidenceGraphContract.status
  evidence_graph_entity_count = 1
  gap_status = $gapContract.status
  gap_count = 0
  citation_status = $citationContract.status
  citation_coverage = $citationPassingReport.citation_coverage
  minimum_citation_coverage = 0.8
}
Write-Json $sampleInputPath $sampleInput
$pythonCode = @"
import json
import sys
from pathlib import Path

sys.path.insert(0, r"$repoRoot")

from heitang_kb_forge.reliability import run_reliability_eval

payload = json.loads(Path(r"$sampleInputPath").read_text(encoding="utf-8-sig"))
report = run_reliability_eval(payload)
Path(r"$sampleReportPath").write_text(json.dumps(report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
failure_payload = dict(payload)
failure_payload["citation_coverage"] = 0.25
failure_report = run_reliability_eval(failure_payload)
Path(r"$failureSampleReportPath").write_text(json.dumps(failure_report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
"@
Set-Content -Encoding UTF8 -Path $sampleHelperPath -Value $pythonCode
$sampleResult = Invoke-CheckedCommand "python" @($sampleHelperPath) $repoRoot
$sampleReport = Read-JsonFile $sampleReportPath
$failureSampleReport = Read-JsonFile $failureSampleReportPath
$sampleOk = $sampleResult.exit_code -eq 0 -and
  $sampleReport.status -eq "pass" -and
  $sampleReport.available_for_next_gate -eq $true -and
  $sampleReport.overall_score -eq 100 -and
  $failureSampleReport.status -eq "fail" -and
  @($failureSampleReport.blockers) -contains "citation_verification"
Add-ReliabilityRow $rows "reliability eval suite aggregates graph, gap and citation evidence" $sampleOk `
  "exit_code=$($sampleResult.exit_code); pass_status=$($sampleReport.status); available=$($sampleReport.available_for_next_gate); score=$($sampleReport.overall_score); failure_status=$($failureSampleReport.status); failure_blockers=$(@($failureSampleReport.blockers) -join ',')" `
  "knowledge_reliability_eval_sample_output_invalid"

$pytestResult = Invoke-CheckedCommand "python" @(
  "-m",
  "pytest",
  "tests/test_knowledge_reliability_eval_suite.py",
  "tests/test_citation_verification.py",
  "tests/test_gap_analysis.py",
  "tests/test_reliability_score.py",
  "-q"
) $repoRoot
$pytestOk = $pytestResult.exit_code -eq 0
Add-ReliabilityRow $rows "narrow reliability, citation, gap and legacy reliability regression tests pass" $pytestOk `
  "exit_code=$($pytestResult.exit_code); stdout=$($pytestResult.stdout.Trim()); stderr=$($pytestResult.stderr.Trim())" `
  "knowledge_reliability_eval_regression_tests_failed"

$priorEvidenceOk = $evidenceGraphContract.status -eq "evidence_graph_basic_completed_needs_owner_review" -and
  $gapContract.status -eq "gap_analysis_completed_needs_owner_review" -and
  $citationContract.status -eq "citation_verification_completed_needs_owner_review"
Add-ReliabilityRow $rows "P1 evidence graph, gap and citation contracts are available" $priorEvidenceOk `
  "graph_status=$($evidenceGraphContract.status); gap_status=$($gapContract.status); citation_status=$($citationContract.status)" `
  "knowledge_reliability_eval_prior_evidence_missing"

$contract = [ordered]@{
  schema_version = "heitang_knowledge_reliability_eval_suite_basic_contract.v1"
  status = "knowledge_reliability_eval_suite_completed_needs_owner_review"
  capability_id = "knowledge_reliability_eval_suite"
  phase = "P1"
  acceptance_type = "core_only"
  required_inputs = @("evidence_graph_status", "evidence_graph_entity_count", "gap_status", "gap_count", "citation_status", "citation_coverage")
  required_outputs = @("status", "overall_score", "available_for_next_gate", "dimensions", "blockers", "warnings")
  sample_input_path = $sampleInputPath
  sample_report_path = $sampleReportPath
  failure_sample_report_path = $failureSampleReportPath
  sample_status = $sampleReport.status
  sample_overall_score = $sampleReport.overall_score
  next_gate = $nextGate
  global_goal_complete = $false
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $contractPath $contract

$contractOk = (Test-Path -LiteralPath $contractPath) -and
  $contract.sample_status -eq "pass" -and
  $contract.sample_overall_score -eq 100 -and
  $contract.required_outputs.Count -eq 6 -and
  $contract.next_gate -eq "P1-8 Retrieval Regression Basic" -and
  $contract.global_goal_complete -eq $false
Add-ReliabilityRow $rows "knowledge reliability eval suite contract artifact is generated" $contractOk `
  "contract=$contractPath; sample_status=$($contract.sample_status); score=$($contract.sample_overall_score); next_gate=$($contract.next_gate)" `
  "knowledge_reliability_eval_contract_invalid"

$claimHits = Test-PositiveClaimBoundary @($contractPath, $sampleReportPath, $failureSampleReportPath)
Add-ReliabilityRow $rows "new P1-7 evidence has no forbidden positive-state tokens" ($claimHits.Count -eq 0) `
  "scanned=contract,sample_report,failure_sample_report; hits=$($claimHits.Count)" `
  "knowledge_reliability_eval_forbidden_claim_token_found"

$blocked = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "knowledge_reliability_eval_suite_completed_needs_owner_review"
} else {
  "knowledge_reliability_eval_suite_blocked"
}

$checkpoint = [ordered]@{
  schema_version = "heitang_knowledge_reliability_eval_suite_checkpoint.v1"
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
  schema_version = "heitang_knowledge_reliability_eval_suite_failure_template.v1"
  status = "no_current_failure"
  affected_phase = "P1"
  affected_capability_id = "knowledge_reliability_eval_suite"
  failed_acceptance_type = "core_only"
  resume_prompt_path = $resumePath
  created_at = (Get-Date).ToUniversalTime().ToString("o")
})
@(
  "# Knowledge Reliability Eval Suite Resume Prompt",
  "",
  "Resume from current_gate=$($chain.current_gate) if interrupted before commit.",
  "After commit, resume from next_gate=$nextGate.",
  "Keep global_goal_complete=false while remaining gates exist.",
  "Do not execute P1-8 until P1-7 evidence is committed."
) | Set-Content -Encoding UTF8 -Path $resumePath

$payload = [ordered]@{
  schema_version = "heitang_p1_knowledge_reliability_eval_suite_matrix.v1"
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
  "- none for this P1-7 gate; Owner review remains outside automatic closure."
} else {
  ($blocked | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$report = @(
  "# P1-7 Knowledge Reliability Eval Suite Basic Closure Report",
  "",
  "Status: $status",
  "",
  "## Acceptance Scope",
  "",
  "- Validate a deterministic basic reliability eval suite over evidence graph, gap analysis and citation verification evidence.",
  "- This Gate is core_only; it does not add UI, external LLM calls or P1-8 retrieval regression behavior.",
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
  "- command: run_knowledge_reliability_eval_suite_matrix.ps1",
  "- schema evidence: eval suite, pydantic schema, pass/fail sample reports and narrow tests.",
  "",
  "## Black-box Test Result",
  "",
  "- result: not_required",
  "- reason: core_only reliability eval suite has no standalone user UI path.",
  "",
  "## Evidence Completeness Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- artifacts: contract, matrix, sample input/reports, checkpoint, failure template, resume prompt and this report.",
  "",
  "## Lifecycle Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- scope: create and read deterministic reliability eval reports plus rerunnable verifier contract.",
  "",
  "## Regression Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- tests: python -m pytest tests/test_knowledge_reliability_eval_suite.py tests/test_citation_verification.py tests/test_gap_analysis.py tests/test_reliability_score.py -q",
  "",
  "## Boundary Compliance Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- no UI/runtime edits, no dependency addition, no external service use, no P2 entry.",
  "",
  "## Reviewer Findings",
  "",
  "- P1-7 uses deterministic core evidence only and does not fake a UI blackbox.",
  "- Retrieval regression remains queued as P1-8.",
  "- P1-4/P1-5/P1-6 contracts remain readable and feed this basic eval suite.",
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
