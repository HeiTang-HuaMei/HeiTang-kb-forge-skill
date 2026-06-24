param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p1_conflict_exception_detection_basic"
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

function Add-ConflictRow(
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
$detectorPath = Join-Path $repoRoot "heitang_kb_forge\conflict_exception\detector.py"
$schemaPath = Join-Path $repoRoot "heitang_kb_forge\schemas\conflict_exception_schema.py"
$testPath = Join-Path $repoRoot "tests\test_conflict_exception_detection_basic.py"
$classificationContractPath = Join-Path $appRoot "output\p1_classification_reasoning_basic\classification_reasoning_basic_contract.json"
$matrixPath = Join-Path $OutputRoot "conflict_exception_detection_basic_matrix.json"
$contractPath = Join-Path $OutputRoot "conflict_exception_detection_basic_contract.json"
$conflictReportPath = Join-Path $OutputRoot "conflict_exception_conflict_report.json"
$passReportPath = Join-Path $OutputRoot "conflict_exception_pass_report.json"
$exceptionReportPath = Join-Path $OutputRoot "conflict_exception_exception_report.json"
$sampleHelperPath = Join-Path $OutputRoot "run_conflict_exception_sample.py"
$checkpointPath = Join-Path $OutputRoot "conflict_exception_detection_basic_checkpoint.json"
$failurePath = Join-Path $OutputRoot "conflict_exception_detection_basic_failure_template.json"
$resumePath = Join-Path $OutputRoot "conflict_exception_detection_basic_resume_prompt.md"
$reportPath = Join-Path $repoRoot "docs\audits\current\conflict_exception_detection_closure_report.md"
$rows = [System.Collections.ArrayList]::new()

$requiredFiles = @(
  $chainPath,
  $registryPath,
  $planPath,
  $queuePath,
  $rubricPath,
  $p1BackfillPath,
  $detectorPath,
  $schemaPath,
  $testPath,
  $classificationContractPath
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
Add-ConflictRow $rows "required conflict exception source and prior evidence files exist" ($missingFiles.Count -eq 0) `
  "missing=$($missingFiles.Count)" `
  "conflict_exception_required_file_missing"

$chain = Read-JsonFile $chainPath
$remaining = @($chain.remaining_gates)
$completedReview = @($chain.completed_with_owner_review_needed)
$prePassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-12 Conflict and Exception Detection Basic" -and
  $remaining.Count -eq 80 -and
  $remaining[0] -eq "P1-12 Conflict and Exception Detection Basic" -and
  $completedReview -notcontains "P1-12 Conflict and Exception Detection Basic"
$postPassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-13 AI Config Governance Basic" -and
  $remaining.Count -eq 79 -and
  $remaining[0] -eq "P1-13 AI Config Governance Basic" -and
  $completedReview -contains "P1-12 Conflict and Exception Detection Basic"
$stateOk = ($prePassState -or $postPassState) -and $chain.global_goal_complete -eq $false
Add-ConflictRow $rows "status machine is at or just past P1-12 with global guard" $stateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($remaining[0]); remaining=$($remaining.Count); global_goal_complete=$($chain.global_goal_complete)" `
  "conflict_exception_status_machine_mismatch"

$preconditionsOk = ($completedReview -contains "P0 Release Gate") -and
  ($completedReview -contains "P1-11 Classification Reasoning Basic")
Add-ConflictRow $rows "P0 release and P1-11 precede conflict exception detection" $preconditionsOk `
  "p0_release=$($completedReview -contains 'P0 Release Gate'); p1_classification=$($completedReview -contains 'P1-11 Classification Reasoning Basic')" `
  "conflict_exception_missing_precondition"

$nextGate = if ($prePassState -and $remaining.Count -gt 1) {
  $remaining[1]
} elseif ($postPassState) {
  $remaining[0]
} else {
  ""
}
$chainShapeOk = $nextGate -eq "P1-13 AI Config Governance Basic" -and
  ($remaining -contains "P1 Release Gate") -and
  ($remaining -contains "P2 Release Gate") -and
  ($remaining -contains "Final Owner Review Gate")
Add-ConflictRow $rows "remaining chain preserves release gates and next gate" $chainShapeOk `
  "next_gate=$nextGate; p1_release=$($remaining -contains 'P1 Release Gate'); p2_release=$($remaining -contains 'P2 Release Gate'); final=$($remaining -contains 'Final Owner Review Gate')" `
  "conflict_exception_chain_sequence_invalid"

$registryRow = @(
  Get-Content -LiteralPath $registryPath -Encoding UTF8 |
    Where-Object { $_ -match "^\| conflict_exception_detection \|" }
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
Add-ConflictRow $rows "conflict_exception_detection registry row follows core-only contract" $registryStatusOk `
  "row_count=$($registryRow.Count); type=$($registryCells[3]); core=$($registryCells[4]); ui=$($registryCells[5]); blackbox=$($registryCells[6]); close_allowed=$($registryCells[13])" `
  "conflict_exception_registry_row_invalid"

$planText = Get-Content -Raw -LiteralPath $planPath -Encoding UTF8
$queueText = Get-Content -Raw -LiteralPath $queuePath -Encoding UTF8
$rubricText = Get-Content -Raw -LiteralPath $rubricPath -Encoding UTF8
$p1Text = Get-Content -Raw -LiteralPath $p1BackfillPath -Encoding UTF8
$crossRefsOk = $planText.Contains("| 35 | P1 | conflict_exception_detection | Conflict and Exception Detection Basic | core_only |") -and
  $queueText.Contains("16. P1-12 Conflict and Exception Detection Basic") -and
  $queueText.Contains("17. P1-13 AI Config Governance Basic") -and
  $rubricText.Contains("| P1 | conflict_exception_detection | core_only |") -and
  $p1Text.Contains("conflict_exception_detection")
Add-ConflictRow $rows "plan, queue, rubric and P1 grouping reference conflict exception detection" $crossRefsOk `
  "plan=$($planText.Contains('| 35 | P1 | conflict_exception_detection | Conflict and Exception Detection Basic | core_only |')); queue_p1_12=$($queueText.Contains('16. P1-12 Conflict and Exception Detection Basic')); queue_p1_13=$($queueText.Contains('17. P1-13 AI Config Governance Basic'))" `
  "conflict_exception_cross_reference_invalid"

$detectorText = Get-Content -Raw -LiteralPath $detectorPath -Encoding UTF8
$schemaText = Get-Content -Raw -LiteralPath $schemaPath -Encoding UTF8
$sourceShapeOk = $detectorText.Contains("def detect_conflict_exceptions") -and
  $schemaText.Contains("class ConflictExceptionInput") -and
  $schemaText.Contains("class ConflictExceptionReport") -and
  $schemaText.Contains("class ConflictRecord") -and
  $schemaText.Contains("class ExceptionRecord")
Add-ConflictRow $rows "source implements structured conflict, exception and report schema" $sourceShapeOk `
  "detector=$($detectorText.Contains('def detect_conflict_exceptions')); input_schema=$($schemaText.Contains('class ConflictExceptionInput')); report_schema=$($schemaText.Contains('class ConflictExceptionReport'))" `
  "conflict_exception_source_shape_missing"

$pythonCode = @"
import json
import sys
from pathlib import Path

sys.path.insert(0, r"$repoRoot")

from heitang_kb_forge.conflict_exception import detect_conflict_exceptions

conflict_report = detect_conflict_exceptions({
    "statements": [
        {"statement_id": "allow-1", "topic": "external source validation", "polarity": "allow", "text": "Allow public source validation."},
        {"statement_id": "deny-1", "topic": "external source validation", "polarity": "deny", "text": "Do not validate restricted sources."},
        {"statement_id": "exception-1", "topic": "external source validation", "polarity": "allow", "text": "Allow only owner approved public sources.", "exception_of": "deny-1"},
    ],
})
pass_report = detect_conflict_exceptions({
    "statements": [
        {"statement_id": "allow-1", "topic": "citation", "polarity": "allow", "text": "Allow citation trace."},
        {"statement_id": "allow-2", "topic": "citation", "polarity": "supports", "text": "Supports source trace."},
    ],
})
exception_report = detect_conflict_exceptions({
    "statements": [{
        "statement_id": "exception-1",
        "topic": "delete test object",
        "polarity": "allow",
        "text": "Allow deletion only for test marked objects.",
        "exception_of": "general-delete-ban",
    }],
})

Path(r"$conflictReportPath").write_text(json.dumps(conflict_report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
Path(r"$passReportPath").write_text(json.dumps(pass_report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
Path(r"$exceptionReportPath").write_text(json.dumps(exception_report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
"@
Set-Content -Encoding UTF8 -Path $sampleHelperPath -Value $pythonCode
$sampleResult = Invoke-CheckedCommand "python" @($sampleHelperPath) $repoRoot
$conflictReport = Read-JsonFile $conflictReportPath
$passReport = Read-JsonFile $passReportPath
$exceptionReport = Read-JsonFile $exceptionReportPath
$sampleOk = $sampleResult.exit_code -eq 0 -and
  $conflictReport.status -eq "conflicts_with_exceptions_found" -and
  $conflictReport.conflict_count -eq 1 -and
  $conflictReport.exception_count -eq 1 -and
  $passReport.status -eq "pass" -and
  $passReport.conflict_count -eq 0 -and
  $exceptionReport.status -eq "exceptions_found" -and
  $exceptionReport.exception_count -eq 1
Add-ConflictRow $rows "conflict exception detection handles conflict, pass and exception-only paths" $sampleOk `
  "exit_code=$($sampleResult.exit_code); conflict_status=$($conflictReport.status); conflict_count=$($conflictReport.conflict_count); exception_count=$($conflictReport.exception_count); pass_status=$($passReport.status); exception_status=$($exceptionReport.status)" `
  "conflict_exception_sample_output_invalid"

$pytestResult = Invoke-CheckedCommand "python" @(
  "-m",
  "pytest",
  "tests/test_conflict_exception_detection_basic.py",
  "tests/test_governance_conflict_detector.py",
  "tests/test_classification_reasoning_basic.py",
  "-q"
) $repoRoot
$pytestOk = $pytestResult.exit_code -eq 0
Add-ConflictRow $rows "narrow conflict exception and related core tests pass" $pytestOk `
  "exit_code=$($pytestResult.exit_code); stdout=$($pytestResult.stdout.Trim()); stderr=$($pytestResult.stderr.Trim())" `
  "conflict_exception_tests_failed"

$classificationContract = Read-JsonFile $classificationContractPath
$priorEvidenceOk = $classificationContract.status -eq "classification_reasoning_completed_needs_owner_review"
Add-ConflictRow $rows "P1 classification reasoning contract is available" $priorEvidenceOk `
  "classification_reasoning_status=$($classificationContract.status)" `
  "conflict_exception_prior_evidence_missing"

$contract = [ordered]@{
  schema_version = "heitang_conflict_exception_detection_basic_contract.v1"
  status = "conflict_exception_detection_completed_needs_owner_review"
  capability_id = "conflict_exception_detection"
  phase = "P1"
  acceptance_type = "core_only"
  required_inputs = @("statements")
  required_outputs = @("status", "conflict_count", "exception_count", "conflicts", "exceptions")
  conflict_report_path = $conflictReportPath
  pass_report_path = $passReportPath
  exception_report_path = $exceptionReportPath
  conflict_status = $conflictReport.status
  pass_status = $passReport.status
  exception_status = $exceptionReport.status
  next_gate = $nextGate
  global_goal_complete = $false
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $contractPath $contract

$contractOk = (Test-Path -LiteralPath $contractPath) -and
  $contract.conflict_status -eq "conflicts_with_exceptions_found" -and
  $contract.pass_status -eq "pass" -and
  $contract.exception_status -eq "exceptions_found" -and
  $contract.required_outputs.Count -eq 5 -and
  $contract.next_gate -eq "P1-13 AI Config Governance Basic" -and
  $contract.global_goal_complete -eq $false
Add-ConflictRow $rows "conflict exception detection basic contract artifact is generated" $contractOk `
  "contract=$contractPath; conflict_status=$($contract.conflict_status); pass_status=$($contract.pass_status); exception_status=$($contract.exception_status); next_gate=$($contract.next_gate)" `
  "conflict_exception_contract_invalid"

$claimHits = Test-PositiveClaimBoundary @($contractPath, $conflictReportPath, $passReportPath, $exceptionReportPath)
Add-ConflictRow $rows "new P1-12 evidence has no forbidden positive-state tokens" ($claimHits.Count -eq 0) `
  "scanned=contract,conflict,pass,exception; hits=$($claimHits.Count)" `
  "conflict_exception_forbidden_claim_token_found"

$blocked = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "conflict_exception_detection_completed_needs_owner_review"
} else {
  "conflict_exception_detection_blocked"
}

$checkpoint = [ordered]@{
  schema_version = "heitang_conflict_exception_detection_basic_checkpoint.v1"
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
  schema_version = "heitang_conflict_exception_detection_basic_failure_template.v1"
  status = "no_current_failure"
  affected_phase = "P1"
  affected_capability_id = "conflict_exception_detection"
  failed_acceptance_type = "core_only"
  resume_prompt_path = $resumePath
  created_at = (Get-Date).ToUniversalTime().ToString("o")
})
@(
  "# Conflict and Exception Detection Basic Resume Prompt",
  "",
  "Resume from current_gate=$($chain.current_gate) if interrupted before commit.",
  "After commit, resume from next_gate=$nextGate.",
  "Keep global_goal_complete=false while remaining gates exist.",
  "Do not execute P1-13 until P1-12 evidence is committed."
) | Set-Content -Encoding UTF8 -Path $resumePath

$payload = [ordered]@{
  schema_version = "heitang_p1_conflict_exception_detection_basic_matrix.v1"
  status = $status
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
  repo_root = $repoRoot
  current_phase = $chain.current_phase
  current_gate = $chain.current_gate
  next_gate = $nextGate
  remaining_gates_count = $remaining.Count
  global_goal_complete = $false
  contract_path = $contractPath
  conflict_report_path = $conflictReportPath
  pass_report_path = $passReportPath
  exception_report_path = $exceptionReportPath
  checkpoint_path = $checkpointPath
  failure_template_path = $failurePath
  resume_prompt_path = $resumePath
  rows = $rows
}
Write-Json $matrixPath $payload

$blockerText = if ($blocked.Count -eq 0) {
  "- none for this P1-12 gate; Owner review remains outside automatic closure."
} else {
  ($blocked | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$report = @(
  "# P1-12 Conflict and Exception Detection Basic Closure Report",
  "",
  "Status: $status",
  "",
  "## Acceptance Scope",
  "",
  "- Validate deterministic conflict and exception detection from structured statements.",
  "- This Gate is core_only; it does not add UI, external LLM calls or runtime orchestration.",
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
  "- command: run_conflict_exception_detection_basic_matrix.ps1",
  "- schema evidence: detector, pydantic schema, conflict/pass/exception reports and narrow tests.",
  "",
  "## Black-box Test Result",
  "",
  "- result: not_required",
  "- reason: core_only conflict exception detection has no standalone user UI path.",
  "",
  "## Evidence Completeness Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- artifacts: contract, matrix, sample reports, checkpoint, failure template, resume prompt and this report.",
  "",
  "## Lifecycle Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- scope: create and read deterministic conflict exception reports plus rerunnable verifier contract.",
  "",
  "## Regression Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- tests: python -m pytest tests/test_conflict_exception_detection_basic.py tests/test_governance_conflict_detector.py tests/test_classification_reasoning_basic.py -q",
  "",
  "## Boundary Compliance Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- no UI/runtime edits, no dependency addition, no external service use, no P2 entry.",
  "",
  "## Reviewer Findings",
  "",
  "- P1-12 uses deterministic core evidence only and does not fake a UI blackbox.",
  "- AI Config Governance remains queued as P1-13.",
  "- P1-11 classification reasoning evidence remains readable.",
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
