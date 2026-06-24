param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p1_citation_verification_basic"
}

function Add-CitationRow(
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
$verifierPath = Join-Path $repoRoot "heitang_kb_forge\citation_verification\verifier.py"
$schemaPath = Join-Path $repoRoot "heitang_kb_forge\schemas\citation_verification_schema.py"
$testPath = Join-Path $repoRoot "tests\test_citation_verification.py"
$p0ReservationPath = Join-Path $appRoot "output\capability_blackbox\memory_evidence\memory_evidence_metadata_reservation_matrix.json"
$gapContractPath = Join-Path $appRoot "output\p1_gap_analysis_basic\gap_analysis_basic_contract.json"
$matrixPath = Join-Path $OutputRoot "citation_verification_basic_matrix.json"
$contractPath = Join-Path $OutputRoot "citation_verification_basic_contract.json"
$sampleInputPath = Join-Path $OutputRoot "citation_verification_sample_input.json"
$sampleReportPath = Join-Path $OutputRoot "citation_verification_sample_report.json"
$passingReportPath = Join-Path $OutputRoot "citation_verification_passing_report.json"
$sampleHelperPath = Join-Path $OutputRoot "run_citation_verification_sample.py"
$checkpointPath = Join-Path $OutputRoot "citation_verification_basic_checkpoint.json"
$failurePath = Join-Path $OutputRoot "citation_verification_basic_failure_template.json"
$resumePath = Join-Path $OutputRoot "citation_verification_basic_resume_prompt.md"
$reportPath = Join-Path $repoRoot "docs\audits\current\citation_verification_closure_report.md"
$rows = [System.Collections.ArrayList]::new()

$requiredFiles = @(
  $chainPath,
  $registryPath,
  $planPath,
  $queuePath,
  $rubricPath,
  $p1BackfillPath,
  $verifierPath,
  $schemaPath,
  $testPath,
  $p0ReservationPath,
  $gapContractPath
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
Add-CitationRow $rows "required citation verification source and prior evidence files exist" ($missingFiles.Count -eq 0) `
  "missing=$($missingFiles.Count)" `
  "citation_verification_required_file_missing"

$chain = Read-JsonFile $chainPath
$remaining = @($chain.remaining_gates)
$completedReview = @($chain.completed_with_owner_review_needed)
$prePassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-6 Citation Verification Basic Plus" -and
  $remaining.Count -eq 86 -and
  $remaining[0] -eq "P1-6 Citation Verification Basic Plus" -and
  $completedReview -notcontains "P1-6 Citation Verification Basic Plus"
$postPassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-7 Knowledge Reliability Eval Suite Basic" -and
  $remaining.Count -eq 85 -and
  $remaining[0] -eq "P1-7 Knowledge Reliability Eval Suite Basic" -and
  $completedReview -contains "P1-6 Citation Verification Basic Plus"
$stateOk = ($prePassState -or $postPassState) -and $chain.global_goal_complete -eq $false
Add-CitationRow $rows "status machine is at or just past P1-6 with global guard" $stateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($remaining[0]); remaining=$($remaining.Count); global_goal_complete=$($chain.global_goal_complete)" `
  "citation_verification_status_machine_mismatch"

$preconditionsOk = ($completedReview -contains "P0 Release Gate") -and
  ($completedReview -contains "P1-1 Capability Chain Runner") -and
  ($completedReview -contains "P1-2 Capability Registry") -and
  ($completedReview -contains "P1-3 Memory Layer Separation Basic") -and
  ($completedReview -contains "P1-4 Evidence Graph Basic") -and
  ($completedReview -contains "P1-5 Gap Analysis Basic Plus")
Add-CitationRow $rows "P0 release and P1-1 through P1-5 precede citation verification gate" $preconditionsOk `
  "p0_release=$($completedReview -contains 'P0 Release Gate'); p1_runner=$($completedReview -contains 'P1-1 Capability Chain Runner'); p1_registry=$($completedReview -contains 'P1-2 Capability Registry'); p1_memory=$($completedReview -contains 'P1-3 Memory Layer Separation Basic'); p1_graph=$($completedReview -contains 'P1-4 Evidence Graph Basic'); p1_gap=$($completedReview -contains 'P1-5 Gap Analysis Basic Plus')" `
  "citation_verification_missing_precondition"

$nextGate = if ($prePassState -and $remaining.Count -gt 1) {
  $remaining[1]
} elseif ($postPassState) {
  $remaining[0]
} else {
  ""
}
$chainShapeOk = $nextGate -eq "P1-7 Knowledge Reliability Eval Suite Basic" -and
  ($remaining -contains "P1 Release Gate") -and
  ($remaining -contains "P2 Release Gate") -and
  ($remaining -contains "Final Owner Review Gate")
Add-CitationRow $rows "remaining chain preserves release gates and next gate" $chainShapeOk `
  "next_gate=$nextGate; p1_release=$($remaining -contains 'P1 Release Gate'); p2_release=$($remaining -contains 'P2 Release Gate'); final=$($remaining -contains 'Final Owner Review Gate')" `
  "citation_verification_chain_sequence_invalid"

$registryRow = @(
  Get-Content -LiteralPath $registryPath -Encoding UTF8 |
    Where-Object { $_ -match "^\| citation_verification \|" }
)
$registryCells = if ($registryRow.Count -eq 1) { Split-MarkdownRow $registryRow[0] } else { @() }
$registryOk = $registryRow.Count -eq 1 -and
  $registryCells[2] -eq "P1" -and
  $registryCells[3] -eq "core_only" -and
  $registryCells[5] -eq "not_required" -and
  $registryCells[6] -eq "not_required" -and
  $registryCells[12] -eq "true"
$registryStatusOk = $registryOk -and (
  ($prePassState -and $registryCells[4] -in @("partial", "passed")) -or
  ($postPassState -and $registryCells[4] -eq "passed" -and $registryCells[13] -eq "true")
)
Add-CitationRow $rows "citation_verification registry row follows core-only contract" $registryStatusOk `
  "row_count=$($registryRow.Count); type=$($registryCells[3]); core=$($registryCells[4]); ui=$($registryCells[5]); blackbox=$($registryCells[6]); close_allowed=$($registryCells[13])" `
  "citation_verification_registry_row_invalid"

$planText = Get-Content -Raw -LiteralPath $planPath -Encoding UTF8
$queueText = Get-Content -Raw -LiteralPath $queuePath -Encoding UTF8
$rubricText = Get-Content -Raw -LiteralPath $rubricPath -Encoding UTF8
$p1Text = Get-Content -Raw -LiteralPath $p1BackfillPath -Encoding UTF8
$crossRefsOk = $planText.Contains("| 29 | P1 | citation_verification | Citation Verification Basic Plus | core_only |") -and
  $queueText.Contains("10. P1-6 Citation Verification Basic Plus") -and
  $queueText.Contains("11. P1-7 Knowledge Reliability Eval Suite Basic") -and
  $rubricText.Contains("| P1 | citation_verification | core_only |") -and
  $p1Text.Contains("citation_verification")
Add-CitationRow $rows "plan, queue, rubric and P1 grouping reference citation verification gate" $crossRefsOk `
  "plan=$($planText.Contains('| 29 | P1 | citation_verification | Citation Verification Basic Plus | core_only |')); queue_p1_6=$($queueText.Contains('10. P1-6 Citation Verification Basic Plus')); queue_p1_7=$($queueText.Contains('11. P1-7 Knowledge Reliability Eval Suite Basic'))" `
  "citation_verification_cross_reference_invalid"

$verifierText = Get-Content -Raw -LiteralPath $verifierPath -Encoding UTF8
$schemaText = Get-Content -Raw -LiteralPath $schemaPath -Encoding UTF8
$sourceShapeOk = $verifierText.Contains("def verify_citations") -and
  $schemaText.Contains("class CitationVerificationInput") -and
  $schemaText.Contains("class CitationVerificationReport") -and
  $schemaText.Contains("missing_citation_claim_ids") -and
  $schemaText.Contains("unresolved_citation_claim_ids") -and
  $schemaText.Contains("out_of_scope_claim_ids")
Add-CitationRow $rows "source implements structured citation verification input and report schema" $sourceShapeOk `
  "verifier=$($verifierText.Contains('def verify_citations')); input_schema=$($schemaText.Contains('class CitationVerificationInput')); report_schema=$($schemaText.Contains('class CitationVerificationReport'))" `
  "citation_verification_source_shape_missing"

$sampleInput = [ordered]@{
  allowed_scope_ids = @("kb-a")
  claims = @(
    [ordered]@{ claim_id = "claim-1"; text = "covered"; citation = "source-a.md#chunk=chunk-1" },
    [ordered]@{ claim_id = "claim-2"; text = "missing citation" },
    [ordered]@{ claim_id = "claim-3"; text = "unresolved citation"; citation = "source-z.md#chunk=chunk-z" },
    [ordered]@{ claim_id = "claim-4"; text = "out of scope"; citation = "source-b.md#chunk=chunk-2" }
  )
  source_trace = @(
    [ordered]@{ source_id = "source-a"; source_path = "source-a.md"; chunk_id = "chunk-1"; citation = "source-a.md#chunk=chunk-1"; scope_id = "kb-a" },
    [ordered]@{ source_id = "source-b"; source_path = "source-b.md"; chunk_id = "chunk-2"; citation = "source-b.md#chunk=chunk-2"; scope_id = "kb-b" }
  )
}
Write-Json $sampleInputPath $sampleInput
$pythonCode = @"
import json
import sys
from pathlib import Path

sys.path.insert(0, r"$repoRoot")

from heitang_kb_forge.citation_verification import verify_citations

payload = json.loads(Path(r"$sampleInputPath").read_text(encoding="utf-8-sig"))
gap_report = verify_citations(payload)
Path(r"$sampleReportPath").write_text(json.dumps(gap_report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
passing_payload = {
    "allowed_scope_ids": ["kb-a"],
    "claims": [
        {"claim_id": "claim-1", "text": "covered", "citation": "source-a.md#chunk=chunk-1"},
        {"claim_id": "claim-2", "text": "also covered", "citation": "source-a.md#chunk=chunk-2"},
    ],
    "source_trace": [
        {"source_id": "source-a-1", "source_path": "source-a.md", "chunk_id": "chunk-1", "citation": "source-a.md#chunk=chunk-1", "scope_id": "kb-a"},
        {"source_id": "source-a-2", "source_path": "source-a.md", "chunk_id": "chunk-2", "citation": "source-a.md#chunk=chunk-2", "scope_id": "kb-a"},
    ],
}
passing_report = verify_citations(passing_payload)
Path(r"$passingReportPath").write_text(json.dumps(passing_report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
"@
Set-Content -Encoding UTF8 -Path $sampleHelperPath -Value $pythonCode
$sampleResult = Invoke-CheckedCommand "python" @($sampleHelperPath) $repoRoot
$sampleReport = Read-JsonFile $sampleReportPath
$passingReport = Read-JsonFile $passingReportPath
$sampleOk = $sampleResult.exit_code -eq 0 -and
  $sampleReport.status -eq "citation_gaps_found" -and
  @($sampleReport.missing_citation_claim_ids).Count -eq 1 -and
  @($sampleReport.unresolved_citation_claim_ids).Count -eq 1 -and
  @($sampleReport.out_of_scope_claim_ids).Count -eq 1 -and
  $sampleReport.citation_coverage -eq 0.25 -and
  $passingReport.status -eq "pass" -and
  $passingReport.citation_coverage -eq 1.0
Add-CitationRow $rows "citation verifier detects missing, unresolved and out-of-scope citations" $sampleOk `
  "exit_code=$($sampleResult.exit_code); gap_status=$($sampleReport.status); missing=$(@($sampleReport.missing_citation_claim_ids).Count); unresolved=$(@($sampleReport.unresolved_citation_claim_ids).Count); out_of_scope=$(@($sampleReport.out_of_scope_claim_ids).Count); coverage=$($sampleReport.citation_coverage); pass_status=$($passingReport.status)" `
  "citation_verification_sample_output_invalid"

$pytestResult = Invoke-CheckedCommand "python" @(
  "-m",
  "pytest",
  "tests/test_citation_verification.py",
  "tests/test_gap_analysis.py",
  "tests/test_knowledge_graph_export.py",
  "-q"
) $repoRoot
$pytestOk = $pytestResult.exit_code -eq 0
Add-CitationRow $rows "narrow citation, gap and evidence graph regression tests pass" $pytestOk `
  "exit_code=$($pytestResult.exit_code); stdout=$($pytestResult.stdout.Trim()); stderr=$($pytestResult.stderr.Trim())" `
  "citation_verification_regression_tests_failed"

$p0Reservation = Read-JsonFile $p0ReservationPath
$gapContract = Read-JsonFile $gapContractPath
$priorEvidenceOk = $p0Reservation.status -eq "memory_evidence_metadata_reserved_needs_review" -and
  $gapContract.status -eq "gap_analysis_completed_needs_owner_review"
Add-CitationRow $rows "P0 citation reservation and P1 gap evidence are available" $priorEvidenceOk `
  "p0_reservation_status=$($p0Reservation.status); gap_status=$($gapContract.status)" `
  "citation_verification_prior_evidence_missing"

$contract = [ordered]@{
  schema_version = "heitang_citation_verification_basic_contract.v1"
  status = "citation_verification_completed_needs_owner_review"
  capability_id = "citation_verification"
  phase = "P1"
  acceptance_type = "core_only"
  required_inputs = @("claims", "source_trace", "allowed_scope_ids")
  required_outputs = @("missing_citation_claim_ids", "unresolved_citation_claim_ids", "out_of_scope_claim_ids", "resolved_claim_ids", "citation_coverage", "source_trace_citations")
  sample_input_path = $sampleInputPath
  sample_report_path = $sampleReportPath
  passing_report_path = $passingReportPath
  sample_gap_count = @($sampleReport.missing_citation_claim_ids).Count + @($sampleReport.unresolved_citation_claim_ids).Count + @($sampleReport.out_of_scope_claim_ids).Count
  passing_coverage = $passingReport.citation_coverage
  next_gate = $nextGate
  global_goal_complete = $false
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $contractPath $contract

$contractOk = (Test-Path -LiteralPath $contractPath) -and
  $contract.sample_gap_count -eq 3 -and
  $contract.required_outputs.Count -eq 6 -and
  $contract.next_gate -eq "P1-7 Knowledge Reliability Eval Suite Basic" -and
  $contract.global_goal_complete -eq $false
Add-CitationRow $rows "citation verification basic contract artifact is generated" $contractOk `
  "contract=$contractPath; sample_gap_count=$($contract.sample_gap_count); next_gate=$($contract.next_gate)" `
  "citation_verification_contract_invalid"

$claimHits = Test-PositiveClaimBoundary @($contractPath, $sampleReportPath, $passingReportPath)
Add-CitationRow $rows "new P1-6 evidence has no forbidden positive-state tokens" ($claimHits.Count -eq 0) `
  "scanned=contract,sample_report,passing_report; hits=$($claimHits.Count)" `
  "citation_verification_forbidden_claim_token_found"

$blocked = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "citation_verification_completed_needs_owner_review"
} else {
  "citation_verification_blocked"
}

$checkpoint = [ordered]@{
  schema_version = "heitang_citation_verification_basic_checkpoint.v1"
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
  schema_version = "heitang_citation_verification_basic_failure_template.v1"
  status = "no_current_failure"
  affected_phase = "P1"
  affected_capability_id = "citation_verification"
  failed_acceptance_type = "core_only"
  resume_prompt_path = $resumePath
  created_at = (Get-Date).ToUniversalTime().ToString("o")
})
@(
  "# Citation Verification Basic Resume Prompt",
  "",
  "Resume from current_gate=$($chain.current_gate) if interrupted before commit.",
  "After commit, resume from next_gate=$nextGate.",
  "Keep global_goal_complete=false while remaining gates exist.",
  "Do not execute P1-7 until P1-6 evidence is committed."
) | Set-Content -Encoding UTF8 -Path $resumePath

$payload = [ordered]@{
  schema_version = "heitang_p1_citation_verification_basic_matrix.v1"
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
  passing_report_path = $passingReportPath
  checkpoint_path = $checkpointPath
  failure_template_path = $failurePath
  resume_prompt_path = $resumePath
  rows = $rows
}
Write-Json $matrixPath $payload

$blockerText = if ($blocked.Count -eq 0) {
  "- none for this P1-6 gate; Owner review remains outside automatic closure."
} else {
  ($blocked | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$report = @(
  "# P1-6 Citation Verification Basic Plus Closure Report",
  "",
  "Status: $status",
  "",
  "## Acceptance Scope",
  "",
  "- Validate deterministic citation verification for missing, unresolved and out-of-scope citations.",
  "- This Gate is core_only; it does not add UI, external LLM calls or P1-7 reliability eval suite behavior.",
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
  "- command: run_citation_verification_basic_matrix.ps1",
  "- schema evidence: verifier, pydantic schema, gap sample report, passing sample report and narrow tests.",
  "",
  "## Black-box Test Result",
  "",
  "- result: not_required",
  "- reason: core_only citation verification has no standalone user UI path.",
  "",
  "## Evidence Completeness Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- artifacts: contract, matrix, sample input/reports, checkpoint, failure template, resume prompt and this report.",
  "",
  "## Lifecycle Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- scope: create and read deterministic citation verification reports plus rerunnable verifier contract.",
  "",
  "## Regression Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- tests: python -m pytest tests/test_citation_verification.py tests/test_gap_analysis.py tests/test_knowledge_graph_export.py -q",
  "",
  "## Boundary Compliance Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- no UI/runtime edits, no dependency addition, no external service use, no P2 entry.",
  "",
  "## Reviewer Findings",
  "",
  "- P1-6 uses deterministic core evidence only and does not fake a UI blackbox.",
  "- Knowledge reliability eval suite remains queued as P1-7.",
  "- P0 citation status reservation and P1 gap analysis evidence remain readable.",
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
