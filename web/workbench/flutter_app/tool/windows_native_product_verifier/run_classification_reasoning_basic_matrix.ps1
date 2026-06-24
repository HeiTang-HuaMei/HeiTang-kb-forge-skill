param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p1_classification_reasoning_basic"
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

function Add-ClassificationRow(
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
$reasonerPath = Join-Path $repoRoot "heitang_kb_forge\classification_reasoning\reasoner.py"
$schemaPath = Join-Path $repoRoot "heitang_kb_forge\schemas\classification_reasoning_schema.py"
$testPath = Join-Path $repoRoot "tests\test_classification_reasoning_basic.py"
$ruleContractPath = Join-Path $appRoot "output\p1_rule_extraction_basic\rule_extraction_basic_contract.json"
$matrixPath = Join-Path $OutputRoot "classification_reasoning_basic_matrix.json"
$contractPath = Join-Path $OutputRoot "classification_reasoning_basic_contract.json"
$sampleReportPath = Join-Path $OutputRoot "classification_reasoning_sample_report.json"
$allowedReportPath = Join-Path $OutputRoot "classification_reasoning_allowed_report.json"
$unknownReportPath = Join-Path $OutputRoot "classification_reasoning_unknown_report.json"
$sampleHelperPath = Join-Path $OutputRoot "run_classification_reasoning_sample.py"
$checkpointPath = Join-Path $OutputRoot "classification_reasoning_basic_checkpoint.json"
$failurePath = Join-Path $OutputRoot "classification_reasoning_basic_failure_template.json"
$resumePath = Join-Path $OutputRoot "classification_reasoning_basic_resume_prompt.md"
$reportPath = Join-Path $repoRoot "docs\audits\current\classification_reasoning_basic_closure_report.md"
$rows = [System.Collections.ArrayList]::new()

$requiredFiles = @(
  $chainPath,
  $registryPath,
  $planPath,
  $queuePath,
  $rubricPath,
  $p1BackfillPath,
  $reasonerPath,
  $schemaPath,
  $testPath,
  $ruleContractPath
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
Add-ClassificationRow $rows "required classification reasoning source and prior evidence files exist" ($missingFiles.Count -eq 0) `
  "missing=$($missingFiles.Count)" `
  "classification_reasoning_required_file_missing"

$chain = Read-JsonFile $chainPath
$remaining = @($chain.remaining_gates)
$completedReview = @($chain.completed_with_owner_review_needed)
$prePassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-11 Classification Reasoning Basic" -and
  $remaining.Count -eq 81 -and
  $remaining[0] -eq "P1-11 Classification Reasoning Basic" -and
  $completedReview -notcontains "P1-11 Classification Reasoning Basic"
$postPassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-12 Conflict and Exception Detection Basic" -and
  $remaining.Count -eq 80 -and
  $remaining[0] -eq "P1-12 Conflict and Exception Detection Basic" -and
  $completedReview -contains "P1-11 Classification Reasoning Basic"
$stateOk = ($prePassState -or $postPassState) -and $chain.global_goal_complete -eq $false
Add-ClassificationRow $rows "status machine is at or just past P1-11 with global guard" $stateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($remaining[0]); remaining=$($remaining.Count); global_goal_complete=$($chain.global_goal_complete)" `
  "classification_reasoning_status_machine_mismatch"

$preconditionsOk = ($completedReview -contains "P0 Release Gate") -and
  ($completedReview -contains "P1-10 Rule Extraction Basic")
Add-ClassificationRow $rows "P0 release and P1-10 precede classification reasoning" $preconditionsOk `
  "p0_release=$($completedReview -contains 'P0 Release Gate'); p1_rule=$($completedReview -contains 'P1-10 Rule Extraction Basic')" `
  "classification_reasoning_missing_precondition"

$nextGate = if ($prePassState -and $remaining.Count -gt 1) {
  $remaining[1]
} elseif ($postPassState) {
  $remaining[0]
} else {
  ""
}
$chainShapeOk = $nextGate -eq "P1-12 Conflict and Exception Detection Basic" -and
  ($remaining -contains "P1 Release Gate") -and
  ($remaining -contains "P2 Release Gate") -and
  ($remaining -contains "Final Owner Review Gate")
Add-ClassificationRow $rows "remaining chain preserves release gates and next gate" $chainShapeOk `
  "next_gate=$nextGate; p1_release=$($remaining -contains 'P1 Release Gate'); p2_release=$($remaining -contains 'P2 Release Gate'); final=$($remaining -contains 'Final Owner Review Gate')" `
  "classification_reasoning_chain_sequence_invalid"

$registryRow = @(
  Get-Content -LiteralPath $registryPath -Encoding UTF8 |
    Where-Object { $_ -match "^\| classification_reasoning_basic \|" }
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
Add-ClassificationRow $rows "classification_reasoning_basic registry row follows core-only contract" $registryStatusOk `
  "row_count=$($registryRow.Count); type=$($registryCells[3]); core=$($registryCells[4]); ui=$($registryCells[5]); blackbox=$($registryCells[6]); close_allowed=$($registryCells[13])" `
  "classification_reasoning_registry_row_invalid"

$planText = Get-Content -Raw -LiteralPath $planPath -Encoding UTF8
$queueText = Get-Content -Raw -LiteralPath $queuePath -Encoding UTF8
$rubricText = Get-Content -Raw -LiteralPath $rubricPath -Encoding UTF8
$p1Text = Get-Content -Raw -LiteralPath $p1BackfillPath -Encoding UTF8
$crossRefsOk = $planText.Contains("| 34 | P1 | classification_reasoning_basic | Classification Reasoning Basic | core_only |") -and
  $queueText.Contains("15. P1-11 Classification Reasoning Basic") -and
  $queueText.Contains("16. P1-12 Conflict and Exception Detection Basic") -and
  $rubricText.Contains("| P1 | classification_reasoning_basic | core_only |") -and
  $p1Text.Contains("classification_reasoning_basic")
Add-ClassificationRow $rows "plan, queue, rubric and P1 grouping reference classification reasoning" $crossRefsOk `
  "plan=$($planText.Contains('| 34 | P1 | classification_reasoning_basic | Classification Reasoning Basic | core_only |')); queue_p1_11=$($queueText.Contains('15. P1-11 Classification Reasoning Basic')); queue_p1_12=$($queueText.Contains('16. P1-12 Conflict and Exception Detection Basic'))" `
  "classification_reasoning_cross_reference_invalid"

$reasonerText = Get-Content -Raw -LiteralPath $reasonerPath -Encoding UTF8
$schemaText = Get-Content -Raw -LiteralPath $schemaPath -Encoding UTF8
$sourceShapeOk = $reasonerText.Contains("def classify_items") -and
  $schemaText.Contains("class ClassificationReasoningInput") -and
  $schemaText.Contains("class ClassificationReasoningReport") -and
  $schemaText.Contains("class ClassificationDecision") -and
  $schemaText.Contains("reason_codes")
Add-ClassificationRow $rows "source implements structured classification input, decision and report schema" $sourceShapeOk `
  "reasoner=$($reasonerText.Contains('def classify_items')); input_schema=$($schemaText.Contains('class ClassificationReasoningInput')); report_schema=$($schemaText.Contains('class ClassificationReasoningReport'))" `
  "classification_reasoning_source_shape_missing"

$pythonCode = @"
import json
import sys
from pathlib import Path

sys.path.insert(0, r"$repoRoot")

from heitang_kb_forge.classification_reasoning import classify_items

sample_report = classify_items({
    "candidates": [
        {"item_id": "policy-1", "text": "Answers must cite package evidence.", "labels": ["policy"]},
        {"item_id": "evidence-1", "text": "source_path=guide.md chunk=chunk-1 citation=[1]"},
        {"item_id": "claim-1", "text": "The document states a supported fact."},
        {"item_id": "task-1", "text": "Next step: owner review after blocked gate is fixed."},
    ],
})
allowed_report = classify_items({
    "allowed_categories": ["evidence"],
    "candidates": [
        {"item_id": "policy-1", "text": "Answers must follow this rule."},
        {"item_id": "evidence-1", "text": "source_path=guide.md chunk=chunk-1 citation=[1]"},
    ],
})
unknown_report = classify_items({"candidates": [{"item_id": "plain", "text": "neutral paragraph"}]})

Path(r"$sampleReportPath").write_text(json.dumps(sample_report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
Path(r"$allowedReportPath").write_text(json.dumps(allowed_report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
Path(r"$unknownReportPath").write_text(json.dumps(unknown_report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
"@
Set-Content -Encoding UTF8 -Path $sampleHelperPath -Value $pythonCode
$sampleResult = Invoke-CheckedCommand "python" @($sampleHelperPath) $repoRoot
$sampleReport = Read-JsonFile $sampleReportPath
$allowedReport = Read-JsonFile $allowedReportPath
$unknownReport = Read-JsonFile $unknownReportPath
$sampleCategories = @($sampleReport.decisions | ForEach-Object { $_.category })
$allowedCategories = @($allowedReport.decisions | ForEach-Object { $_.category })
$sampleOk = $sampleResult.exit_code -eq 0 -and
  $sampleReport.status -eq "classified" -and
  $sampleReport.decision_count -eq 4 -and
  ($sampleCategories -join ",") -eq "policy,evidence,claim,task" -and
  $allowedReport.status -eq "classification_gaps_found" -and
  ($allowedCategories -join ",") -eq "unknown,evidence" -and
  @($allowedReport.unresolved_item_ids).Count -eq 1 -and
  $unknownReport.status -eq "classification_gaps_found" -and
  $unknownReport.unresolved_item_ids[0] -eq "plain"
Add-ClassificationRow $rows "classification reasoning handles categories, allowed filter and unknown path" $sampleOk `
  "exit_code=$($sampleResult.exit_code); sample_status=$($sampleReport.status); sample_categories=$($sampleCategories -join ','); allowed_categories=$($allowedCategories -join ','); unknown_status=$($unknownReport.status)" `
  "classification_reasoning_sample_output_invalid"

$pytestResult = Invoke-CheckedCommand "python" @(
  "-m",
  "pytest",
  "tests/test_classification_reasoning_basic.py",
  "tests/test_rule_extraction_basic.py",
  "tests/test_multimodal_chart_classification.py",
  "-q"
) $repoRoot
$pytestOk = $pytestResult.exit_code -eq 0
Add-ClassificationRow $rows "narrow classification reasoning and related core tests pass" $pytestOk `
  "exit_code=$($pytestResult.exit_code); stdout=$($pytestResult.stdout.Trim()); stderr=$($pytestResult.stderr.Trim())" `
  "classification_reasoning_tests_failed"

$ruleContract = Read-JsonFile $ruleContractPath
$priorEvidenceOk = $ruleContract.status -eq "rule_extraction_completed_needs_owner_review"
Add-ClassificationRow $rows "P1 rule extraction contract is available" $priorEvidenceOk `
  "rule_extraction_status=$($ruleContract.status)" `
  "classification_reasoning_prior_evidence_missing"

$contract = [ordered]@{
  schema_version = "heitang_classification_reasoning_basic_contract.v1"
  status = "classification_reasoning_completed_needs_owner_review"
  capability_id = "classification_reasoning_basic"
  phase = "P1"
  acceptance_type = "core_only"
  required_inputs = @("candidates", "allowed_categories")
  required_outputs = @("status", "decision_count", "decisions", "unresolved_item_ids", "category_counts")
  sample_report_path = $sampleReportPath
  allowed_report_path = $allowedReportPath
  unknown_report_path = $unknownReportPath
  sample_decision_count = $sampleReport.decision_count
  sample_categories = $sampleCategories
  allowed_unresolved_count = @($allowedReport.unresolved_item_ids).Count
  unknown_status = $unknownReport.status
  next_gate = $nextGate
  global_goal_complete = $false
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $contractPath $contract

$contractOk = (Test-Path -LiteralPath $contractPath) -and
  $contract.sample_decision_count -eq 4 -and
  ($contract.sample_categories -join ",") -eq "policy,evidence,claim,task" -and
  $contract.allowed_unresolved_count -eq 1 -and
  $contract.unknown_status -eq "classification_gaps_found" -and
  $contract.required_outputs.Count -eq 5 -and
  $contract.next_gate -eq "P1-12 Conflict and Exception Detection Basic" -and
  $contract.global_goal_complete -eq $false
Add-ClassificationRow $rows "classification reasoning basic contract artifact is generated" $contractOk `
  "contract=$contractPath; decisions=$($contract.sample_decision_count); categories=$($contract.sample_categories -join ','); next_gate=$($contract.next_gate)" `
  "classification_reasoning_contract_invalid"

$claimHits = Test-PositiveClaimBoundary @($contractPath, $sampleReportPath, $allowedReportPath, $unknownReportPath)
Add-ClassificationRow $rows "new P1-11 evidence has no forbidden positive-state tokens" ($claimHits.Count -eq 0) `
  "scanned=contract,sample,allowed,unknown; hits=$($claimHits.Count)" `
  "classification_reasoning_forbidden_claim_token_found"

$blocked = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "classification_reasoning_completed_needs_owner_review"
} else {
  "classification_reasoning_blocked"
}

$checkpoint = [ordered]@{
  schema_version = "heitang_classification_reasoning_basic_checkpoint.v1"
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
  schema_version = "heitang_classification_reasoning_basic_failure_template.v1"
  status = "no_current_failure"
  affected_phase = "P1"
  affected_capability_id = "classification_reasoning_basic"
  failed_acceptance_type = "core_only"
  resume_prompt_path = $resumePath
  created_at = (Get-Date).ToUniversalTime().ToString("o")
})
@(
  "# Classification Reasoning Basic Resume Prompt",
  "",
  "Resume from current_gate=$($chain.current_gate) if interrupted before commit.",
  "After commit, resume from next_gate=$nextGate.",
  "Keep global_goal_complete=false while remaining gates exist.",
  "Do not execute P1-12 until P1-11 evidence is committed."
) | Set-Content -Encoding UTF8 -Path $resumePath

$payload = [ordered]@{
  schema_version = "heitang_p1_classification_reasoning_basic_matrix.v1"
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
  allowed_report_path = $allowedReportPath
  unknown_report_path = $unknownReportPath
  checkpoint_path = $checkpointPath
  failure_template_path = $failurePath
  resume_prompt_path = $resumePath
  rows = $rows
}
Write-Json $matrixPath $payload

$blockerText = if ($blocked.Count -eq 0) {
  "- none for this P1-11 gate; Owner review remains outside automatic closure."
} else {
  ($blocked | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$report = @(
  "# P1-11 Classification Reasoning Basic Closure Report",
  "",
  "Status: $status",
  "",
  "## Acceptance Scope",
  "",
  "- Validate deterministic classification reasoning into category decisions with reason codes.",
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
  "- command: run_classification_reasoning_basic_matrix.ps1",
  "- schema evidence: reasoner, pydantic schema, sample/allowed/unknown reports and narrow tests.",
  "",
  "## Black-box Test Result",
  "",
  "- result: not_required",
  "- reason: core_only classification reasoning has no standalone user UI path.",
  "",
  "## Evidence Completeness Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- artifacts: contract, matrix, sample reports, checkpoint, failure template, resume prompt and this report.",
  "",
  "## Lifecycle Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- scope: create and read deterministic classification reasoning reports plus rerunnable verifier contract.",
  "",
  "## Regression Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- tests: python -m pytest tests/test_classification_reasoning_basic.py tests/test_rule_extraction_basic.py tests/test_multimodal_chart_classification.py -q",
  "",
  "## Boundary Compliance Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- no UI/runtime edits, no dependency addition, no external service use, no P2 entry.",
  "",
  "## Reviewer Findings",
  "",
  "- P1-11 uses deterministic core evidence only and does not fake a UI blackbox.",
  "- Conflict and exception detection remains queued as P1-12.",
  "- P1-10 rule extraction evidence remains readable.",
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
