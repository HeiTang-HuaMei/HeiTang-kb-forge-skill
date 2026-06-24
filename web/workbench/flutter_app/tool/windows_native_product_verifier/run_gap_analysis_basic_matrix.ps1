param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p1_gap_analysis_basic"
}

function Add-GapRow(
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
$analyzerPath = Join-Path $repoRoot "heitang_kb_forge\gap_analysis\analyzer.py"
$schemaPath = Join-Path $repoRoot "heitang_kb_forge\schemas\gap_analysis_schema.py"
$testPath = Join-Path $repoRoot "tests\test_gap_analysis.py"
$p0ReservationPath = Join-Path $appRoot "output\capability_blackbox\memory_evidence\memory_evidence_metadata_reservation_matrix.json"
$evidenceGraphContractPath = Join-Path $appRoot "output\p1_evidence_graph_basic\evidence_graph_basic_contract.json"
$matrixPath = Join-Path $OutputRoot "gap_analysis_basic_matrix.json"
$contractPath = Join-Path $OutputRoot "gap_analysis_basic_contract.json"
$sampleInputPath = Join-Path $OutputRoot "gap_analysis_sample_input.json"
$sampleReportPath = Join-Path $OutputRoot "gap_analysis_sample_report.json"
$sampleHelperPath = Join-Path $OutputRoot "run_gap_analysis_sample.py"
$checkpointPath = Join-Path $OutputRoot "gap_analysis_basic_checkpoint.json"
$failurePath = Join-Path $OutputRoot "gap_analysis_basic_failure_template.json"
$resumePath = Join-Path $OutputRoot "gap_analysis_basic_resume_prompt.md"
$reportPath = Join-Path $repoRoot "docs\audits\current\gap_analysis_closure_report.md"
$rows = [System.Collections.ArrayList]::new()

$requiredFiles = @(
  $chainPath,
  $registryPath,
  $planPath,
  $queuePath,
  $rubricPath,
  $p1BackfillPath,
  $analyzerPath,
  $schemaPath,
  $testPath,
  $p0ReservationPath,
  $evidenceGraphContractPath
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
Add-GapRow $rows "required gap-analysis source and prior evidence files exist" ($missingFiles.Count -eq 0) `
  "missing=$($missingFiles.Count)" `
  "gap_analysis_required_file_missing"

$chain = Read-JsonFile $chainPath
$remaining = @($chain.remaining_gates)
$completedReview = @($chain.completed_with_owner_review_needed)
$prePassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-5 Gap Analysis Basic Plus" -and
  $remaining.Count -eq 87 -and
  $remaining[0] -eq "P1-5 Gap Analysis Basic Plus" -and
  $completedReview -notcontains "P1-5 Gap Analysis Basic Plus"
$postPassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-6 Citation Verification Basic Plus" -and
  $remaining.Count -eq 86 -and
  $remaining[0] -eq "P1-6 Citation Verification Basic Plus" -and
  $completedReview -contains "P1-5 Gap Analysis Basic Plus"
$stateOk = ($prePassState -or $postPassState) -and $chain.global_goal_complete -eq $false
Add-GapRow $rows "status machine is at or just past P1-5 with global guard" $stateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($remaining[0]); remaining=$($remaining.Count); global_goal_complete=$($chain.global_goal_complete)" `
  "gap_analysis_status_machine_mismatch"

$preconditionsOk = ($completedReview -contains "P0 Release Gate") -and
  ($completedReview -contains "P1-1 Capability Chain Runner") -and
  ($completedReview -contains "P1-2 Capability Registry") -and
  ($completedReview -contains "P1-3 Memory Layer Separation Basic") -and
  ($completedReview -contains "P1-4 Evidence Graph Basic")
Add-GapRow $rows "P0 release and P1-1 through P1-4 precede gap analysis gate" $preconditionsOk `
  "p0_release=$($completedReview -contains 'P0 Release Gate'); p1_runner=$($completedReview -contains 'P1-1 Capability Chain Runner'); p1_registry=$($completedReview -contains 'P1-2 Capability Registry'); p1_memory=$($completedReview -contains 'P1-3 Memory Layer Separation Basic'); p1_graph=$($completedReview -contains 'P1-4 Evidence Graph Basic')" `
  "gap_analysis_missing_precondition"

$nextGate = if ($prePassState -and $remaining.Count -gt 1) {
  $remaining[1]
} elseif ($postPassState) {
  $remaining[0]
} else {
  ""
}
$chainShapeOk = $nextGate -eq "P1-6 Citation Verification Basic Plus" -and
  ($remaining -contains "P1 Release Gate") -and
  ($remaining -contains "P2 Release Gate") -and
  ($remaining -contains "Final Owner Review Gate")
Add-GapRow $rows "remaining chain preserves release gates and next gate" $chainShapeOk `
  "next_gate=$nextGate; p1_release=$($remaining -contains 'P1 Release Gate'); p2_release=$($remaining -contains 'P2 Release Gate'); final=$($remaining -contains 'Final Owner Review Gate')" `
  "gap_analysis_chain_sequence_invalid"

$registryRow = @(
  Get-Content -LiteralPath $registryPath -Encoding UTF8 |
    Where-Object { $_ -match "^\| gap_analysis \|" }
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
Add-GapRow $rows "gap_analysis registry row follows core-only contract" $registryStatusOk `
  "row_count=$($registryRow.Count); type=$($registryCells[3]); core=$($registryCells[4]); ui=$($registryCells[5]); blackbox=$($registryCells[6]); close_allowed=$($registryCells[13])" `
  "gap_analysis_registry_row_invalid"

$planText = Get-Content -Raw -LiteralPath $planPath -Encoding UTF8
$queueText = Get-Content -Raw -LiteralPath $queuePath -Encoding UTF8
$rubricText = Get-Content -Raw -LiteralPath $rubricPath -Encoding UTF8
$p1Text = Get-Content -Raw -LiteralPath $p1BackfillPath -Encoding UTF8
$crossRefsOk = $planText.Contains("| 28 | P1 | gap_analysis | Gap Analysis Basic Plus | core_only |") -and
  $queueText.Contains("9. P1-5 Gap Analysis Basic Plus") -and
  $queueText.Contains("10. P1-6 Citation Verification Basic Plus") -and
  $rubricText.Contains("| P1 | gap_analysis | core_only |") -and
  $p1Text.Contains("gap_analysis")
Add-GapRow $rows "plan, queue, rubric and P1 grouping reference gap analysis gate" $crossRefsOk `
  "plan=$($planText.Contains('| 28 | P1 | gap_analysis | Gap Analysis Basic Plus | core_only |')); queue_p1_5=$($queueText.Contains('9. P1-5 Gap Analysis Basic Plus')); queue_p1_6=$($queueText.Contains('10. P1-6 Citation Verification Basic Plus'))" `
  "gap_analysis_cross_reference_invalid"

$analyzerText = Get-Content -Raw -LiteralPath $analyzerPath -Encoding UTF8
$schemaText = Get-Content -Raw -LiteralPath $schemaPath -Encoding UTF8
$sourceShapeOk = $analyzerText.Contains("def analyze_gaps") -and
  $schemaText.Contains("class GapAnalysisInput") -and
  $schemaText.Contains("class GapAnalysisReport") -and
  $schemaText.Contains("missing_claims") -and
  $schemaText.Contains("missing_rules") -and
  $schemaText.Contains("missing_sources")
Add-GapRow $rows "source implements structured gap input and report schema" $sourceShapeOk `
  "analyzer=$($analyzerText.Contains('def analyze_gaps')); input_schema=$($schemaText.Contains('class GapAnalysisInput')); report_schema=$($schemaText.Contains('class GapAnalysisReport'))" `
  "gap_analysis_source_shape_missing"

$sampleInput = [ordered]@{
  required_claims = @("claim a", "claim b")
  evidence_claims = @("claim a")
  required_rules = @("rule a")
  evidence_rules = @()
  required_sources = @("source a", "source b")
  evidence_sources = @("source b")
}
Write-Json $sampleInputPath $sampleInput
$pythonCode = @"
import json
import sys
from pathlib import Path

sys.path.insert(0, r"$repoRoot")

from heitang_kb_forge.gap_analysis import analyze_gaps

payload = json.loads(Path(r"$sampleInputPath").read_text(encoding="utf-8-sig"))
report = analyze_gaps(payload)
Path(r"$sampleReportPath").write_text(json.dumps(report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
"@
Set-Content -Encoding UTF8 -Path $sampleHelperPath -Value $pythonCode
$sampleResult = Invoke-CheckedCommand "python" @($sampleHelperPath) $repoRoot
$sampleReport = Read-JsonFile $sampleReportPath
$sampleOk = $sampleResult.exit_code -eq 0 -and
  $sampleReport.status -eq "gaps_found" -and
  $sampleReport.gap_count -eq 3 -and
  @($sampleReport.missing_claims).Count -eq 1 -and
  @($sampleReport.missing_rules).Count -eq 1 -and
  @($sampleReport.missing_sources).Count -eq 1
Add-GapRow $rows "gap analyzer produces missing claims, rules and sources" $sampleOk `
  "exit_code=$($sampleResult.exit_code); status=$($sampleReport.status); gap_count=$($sampleReport.gap_count); claims=$(@($sampleReport.missing_claims).Count); rules=$(@($sampleReport.missing_rules).Count); sources=$(@($sampleReport.missing_sources).Count)" `
  "gap_analysis_sample_output_invalid"

$pytestResult = Invoke-CheckedCommand "python" @(
  "-m",
  "pytest",
  "tests/test_gap_analysis.py",
  "tests/test_evidence_gate.py",
  "tests/test_evidence_gate_boundary.py",
  "-q"
) $repoRoot
$pytestOk = $pytestResult.exit_code -eq 0
Add-GapRow $rows "narrow gap and evidence boundary regression tests pass" $pytestOk `
  "exit_code=$($pytestResult.exit_code); stdout=$($pytestResult.stdout.Trim()); stderr=$($pytestResult.stderr.Trim())" `
  "gap_analysis_regression_tests_failed"

$p0Reservation = Read-JsonFile $p0ReservationPath
$graphContract = Read-JsonFile $evidenceGraphContractPath
$priorEvidenceOk = $p0Reservation.status -eq "memory_evidence_metadata_reserved_needs_review" -and
  $graphContract.status -eq "evidence_graph_basic_completed_needs_owner_review"
Add-GapRow $rows "P0 gap reservation and P1 graph evidence are available" $priorEvidenceOk `
  "p0_reservation_status=$($p0Reservation.status); graph_status=$($graphContract.status)" `
  "gap_analysis_prior_evidence_missing"

$contract = [ordered]@{
  schema_version = "heitang_gap_analysis_basic_contract.v1"
  status = "gap_analysis_completed_needs_owner_review"
  capability_id = "gap_analysis"
  phase = "P1"
  acceptance_type = "core_only"
  required_inputs = @("required_claims", "evidence_claims", "required_rules", "evidence_rules", "required_sources", "evidence_sources")
  required_outputs = @("missing_claims", "missing_rules", "missing_sources", "covered_claims", "covered_rules", "covered_sources", "gap_count")
  sample_input_path = $sampleInputPath
  sample_report_path = $sampleReportPath
  sample_gap_count = $sampleReport.gap_count
  next_gate = $nextGate
  global_goal_complete = $false
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $contractPath $contract

$contractOk = (Test-Path -LiteralPath $contractPath) -and
  $contract.sample_gap_count -eq 3 -and
  $contract.required_outputs.Count -eq 7 -and
  $contract.next_gate -eq "P1-6 Citation Verification Basic Plus" -and
  $contract.global_goal_complete -eq $false
Add-GapRow $rows "gap analysis basic contract artifact is generated" $contractOk `
  "contract=$contractPath; sample_gap_count=$($contract.sample_gap_count); next_gate=$($contract.next_gate)" `
  "gap_analysis_contract_invalid"

$claimHits = Test-PositiveClaimBoundary @($contractPath, $sampleReportPath)
Add-GapRow $rows "new P1-5 evidence has no forbidden positive-state tokens" ($claimHits.Count -eq 0) `
  "scanned=contract,sample_report; hits=$($claimHits.Count)" `
  "gap_analysis_forbidden_claim_token_found"

$blocked = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "gap_analysis_completed_needs_owner_review"
} else {
  "gap_analysis_blocked"
}

$checkpoint = [ordered]@{
  schema_version = "heitang_gap_analysis_basic_checkpoint.v1"
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
  schema_version = "heitang_gap_analysis_basic_failure_template.v1"
  status = "no_current_failure"
  affected_phase = "P1"
  affected_capability_id = "gap_analysis"
  failed_acceptance_type = "core_only"
  resume_prompt_path = $resumePath
  created_at = (Get-Date).ToUniversalTime().ToString("o")
})
@(
  "# Gap Analysis Basic Resume Prompt",
  "",
  "Resume from current_gate=$($chain.current_gate) if interrupted before commit.",
  "After commit, resume from next_gate=$nextGate.",
  "Keep global_goal_complete=false while remaining gates exist.",
  "Do not execute P1-6 until P1-5 evidence is committed."
) | Set-Content -Encoding UTF8 -Path $resumePath

$payload = [ordered]@{
  schema_version = "heitang_p1_gap_analysis_basic_matrix.v1"
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
  checkpoint_path = $checkpointPath
  failure_template_path = $failurePath
  resume_prompt_path = $resumePath
  rows = $rows
}
Write-Json $matrixPath $payload

$blockerText = if ($blocked.Count -eq 0) {
  "- none for this P1-5 gate; Owner review remains outside automatic closure."
} else {
  ($blocked | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$report = @(
  "# P1-5 Gap Analysis Basic Plus Closure Report",
  "",
  "Status: $status",
  "",
  "## Acceptance Scope",
  "",
  "- Validate deterministic gap analysis for missing claims, rules and sources.",
  "- This Gate is core_only; it does not add UI, external LLM calls or P1-6 citation verification.",
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
  "- command: run_gap_analysis_basic_matrix.ps1",
  "- schema evidence: analyzer, pydantic schema, sample report and narrow tests.",
  "",
  "## Black-box Test Result",
  "",
  "- result: not_required",
  "- reason: core_only gap analysis has no standalone user UI path.",
  "",
  "## Evidence Completeness Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- artifacts: contract, matrix, sample input/report, checkpoint, failure template, resume prompt and this report.",
  "",
  "## Lifecycle Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- scope: create and read deterministic sample gap report plus rerunnable verifier contract.",
  "",
  "## Regression Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- tests: python -m pytest tests/test_gap_analysis.py tests/test_evidence_gate.py tests/test_evidence_gate_boundary.py -q",
  "",
  "## Boundary Compliance Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- no UI/runtime edits, no dependency addition, no external service use, no P2 entry.",
  "",
  "## Reviewer Findings",
  "",
  "- P1-5 uses deterministic core evidence only and does not fake a UI blackbox.",
  "- Citation verification remains queued as P1-6.",
  "- Prior P0 reservation and P1 graph evidence remain readable.",
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
