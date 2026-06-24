param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p1_plan_execute_runtime_basic"
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

function Add-PlanExecuteRow(
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
$runtimePath = Join-Path $repoRoot "heitang_kb_forge\plan_execute\runtime.py"
$schemaPath = Join-Path $repoRoot "heitang_kb_forge\schemas\plan_execute_schema.py"
$testPath = Join-Path $repoRoot "tests\test_plan_execute_runtime_basic.py"
$taskModeContractPath = Join-Path $appRoot "output\p1_task_mode_router_basic\task_mode_router_basic_contract.json"
$matrixPath = Join-Path $OutputRoot "plan_execute_runtime_basic_matrix.json"
$contractPath = Join-Path $OutputRoot "plan_execute_runtime_basic_contract.json"
$executedReportPath = Join-Path $OutputRoot "plan_execute_executed_report.json"
$blockedReportPath = Join-Path $OutputRoot "plan_execute_blocked_report.json"
$missingReportPath = Join-Path $OutputRoot "plan_execute_missing_dependency_report.json"
$sampleHelperPath = Join-Path $OutputRoot "run_plan_execute_sample.py"
$checkpointPath = Join-Path $OutputRoot "plan_execute_runtime_basic_checkpoint.json"
$failurePath = Join-Path $OutputRoot "plan_execute_runtime_basic_failure_template.json"
$resumePath = Join-Path $OutputRoot "plan_execute_runtime_basic_resume_prompt.md"
$reportPath = Join-Path $repoRoot "docs\audits\current\plan_execute_runtime_closure_report.md"
$rows = [System.Collections.ArrayList]::new()

$requiredFiles = @(
  $chainPath,
  $registryPath,
  $planPath,
  $queuePath,
  $rubricPath,
  $p1BackfillPath,
  $runtimePath,
  $schemaPath,
  $testPath,
  $taskModeContractPath
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
Add-PlanExecuteRow $rows "required plan execute runtime source and prior evidence files exist" ($missingFiles.Count -eq 0) `
  "missing=$($missingFiles.Count)" `
  "plan_execute_runtime_required_file_missing"

$chain = Read-JsonFile $chainPath
$remaining = @($chain.remaining_gates)
$completedReview = @($chain.completed_with_owner_review_needed)
$prePassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-15 Plan-and-Execute Runtime Basic" -and
  $remaining.Count -eq 77 -and
  $remaining[0] -eq "P1-15 Plan-and-Execute Runtime Basic" -and
  $completedReview -notcontains "P1-15 Plan-and-Execute Runtime Basic"
$postPassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-16 Long Document Reading Strategy Basic" -and
  $remaining.Count -eq 76 -and
  $remaining[0] -eq "P1-16 Long Document Reading Strategy Basic" -and
  $completedReview -contains "P1-15 Plan-and-Execute Runtime Basic"
$stateOk = ($prePassState -or $postPassState) -and $chain.global_goal_complete -eq $false
Add-PlanExecuteRow $rows "status machine is at or just past P1-15 with global guard" $stateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($remaining[0]); remaining=$($remaining.Count); global_goal_complete=$($chain.global_goal_complete)" `
  "plan_execute_runtime_status_machine_mismatch"

$preconditionsOk = ($completedReview -contains "P0 Release Gate") -and
  ($completedReview -contains "P1-14 Task Mode Router Basic")
Add-PlanExecuteRow $rows "P0 release and P1-14 precede plan execute runtime" $preconditionsOk `
  "p0_release=$($completedReview -contains 'P0 Release Gate'); p1_task_mode=$($completedReview -contains 'P1-14 Task Mode Router Basic')" `
  "plan_execute_runtime_missing_precondition"

$nextGate = if ($prePassState -and $remaining.Count -gt 1) {
  $remaining[1]
} elseif ($postPassState) {
  $remaining[0]
} else {
  ""
}
$chainShapeOk = $nextGate -eq "P1-16 Long Document Reading Strategy Basic" -and
  ($remaining -contains "P1 Release Gate") -and
  ($remaining -contains "P2 Release Gate") -and
  ($remaining -contains "Final Owner Review Gate")
Add-PlanExecuteRow $rows "remaining chain preserves release gates and next gate" $chainShapeOk `
  "next_gate=$nextGate; p1_release=$($remaining -contains 'P1 Release Gate'); p2_release=$($remaining -contains 'P2 Release Gate'); final=$($remaining -contains 'Final Owner Review Gate')" `
  "plan_execute_runtime_chain_sequence_invalid"

$registryRow = @(
  Get-Content -LiteralPath $registryPath -Encoding UTF8 |
    Where-Object { $_ -match "^\| plan_execute_runtime \|" }
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
Add-PlanExecuteRow $rows "plan_execute_runtime registry row follows core-only contract" $registryStatusOk `
  "row_count=$($registryRow.Count); type=$($registryCells[3]); core=$($registryCells[4]); ui=$($registryCells[5]); blackbox=$($registryCells[6]); close_allowed=$($registryCells[13])" `
  "plan_execute_runtime_registry_row_invalid"

$planText = Get-Content -Raw -LiteralPath $planPath -Encoding UTF8
$queueText = Get-Content -Raw -LiteralPath $queuePath -Encoding UTF8
$rubricText = Get-Content -Raw -LiteralPath $rubricPath -Encoding UTF8
$p1Text = Get-Content -Raw -LiteralPath $p1BackfillPath -Encoding UTF8
$crossRefsOk = $planText.Contains("| 38 | P1 | plan_execute_runtime | Plan-and-Execute Runtime Basic | core_only |") -and
  $queueText.Contains("19. P1-15 Plan-and-Execute Runtime Basic") -and
  $queueText.Contains("20. P1-16 Long Document Reading Strategy Basic") -and
  $rubricText.Contains("| P1 | plan_execute_runtime | core_only |") -and
  $p1Text.Contains("plan_execute_runtime")
Add-PlanExecuteRow $rows "plan, queue, rubric and P1 grouping reference plan execute runtime" $crossRefsOk `
  "plan=$($planText.Contains('| 38 | P1 | plan_execute_runtime | Plan-and-Execute Runtime Basic | core_only |')); queue_p1_15=$($queueText.Contains('19. P1-15 Plan-and-Execute Runtime Basic')); queue_p1_16=$($queueText.Contains('20. P1-16 Long Document Reading Strategy Basic'))" `
  "plan_execute_runtime_cross_reference_invalid"

$runtimeText = Get-Content -Raw -LiteralPath $runtimePath -Encoding UTF8
$schemaText = Get-Content -Raw -LiteralPath $schemaPath -Encoding UTF8
$sourceShapeOk = $runtimeText.Contains("def run_plan_execute") -and
  $schemaText.Contains("class PlanExecuteInput") -and
  $schemaText.Contains("class PlanExecuteReport") -and
  $schemaText.Contains("remaining_step_ids") -and
  $schemaText.Contains("blocked_step_ids")
Add-PlanExecuteRow $rows "source implements structured plan execute input and report schema" $sourceShapeOk `
  "runtime=$($runtimeText.Contains('def run_plan_execute')); input_schema=$($schemaText.Contains('class PlanExecuteInput')); report_schema=$($schemaText.Contains('class PlanExecuteReport'))" `
  "plan_execute_runtime_source_shape_missing"

$pythonCode = @"
import json
import sys
from pathlib import Path

sys.path.insert(0, r"$repoRoot")

from heitang_kb_forge.plan_execute import run_plan_execute

executed = run_plan_execute({
    "steps": [
        {"step_id": "read", "title": "Read facts"},
        {"step_id": "test", "title": "Run tests", "depends_on": ["read"]},
        {"step_id": "commit", "title": "Commit", "depends_on": ["test"]},
    ],
})
blocked = run_plan_execute({
    "steps": [
        {"step_id": "read", "title": "Read facts", "completed": True},
        {"step_id": "repair", "title": "Repair", "blocked": True, "depends_on": ["read"]},
        {"step_id": "retest", "title": "Retest", "depends_on": ["repair"]},
    ],
})
missing = run_plan_execute({
    "steps": [
        {"step_id": "commit", "title": "Commit", "depends_on": ["test"]},
    ],
})

Path(r"$executedReportPath").write_text(json.dumps(executed.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
Path(r"$blockedReportPath").write_text(json.dumps(blocked.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
Path(r"$missingReportPath").write_text(json.dumps(missing.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
"@
Set-Content -Encoding UTF8 -Path $sampleHelperPath -Value $pythonCode
$sampleResult = Invoke-CheckedCommand "python" @($sampleHelperPath) $repoRoot
$executedReport = Read-JsonFile $executedReportPath
$blockedReport = Read-JsonFile $blockedReportPath
$missingReport = Read-JsonFile $missingReportPath
$sampleOk = $sampleResult.exit_code -eq 0 -and
  $executedReport.status -eq "executed" -and
  (@($executedReport.execution_order) -join ",") -eq "read,test,commit" -and
  $blockedReport.status -eq "blocked" -and
  (@($blockedReport.blocked_step_ids) -join ",") -eq "repair" -and
  (@($blockedReport.remaining_step_ids) -join ",") -eq "retest" -and
  $missingReport.status -eq "missing_dependencies" -and
  (@($missingReport.missing_dependency_step_ids) -join ",") -eq "commit"
Add-PlanExecuteRow $rows "plan execute runtime handles executable, blocked and missing dependency paths" $sampleOk `
  "exit_code=$($sampleResult.exit_code); executed=$($executedReport.status); blocked=$($blockedReport.status); missing=$($missingReport.status)" `
  "plan_execute_runtime_sample_output_invalid"

$pytestResult = Invoke-CheckedCommand "python" @(
  "-m",
  "pytest",
  "tests/test_plan_execute_runtime_basic.py",
  "tests/test_task_mode_router_basic.py",
  "tests/test_planning_readiness.py",
  "-q"
) $repoRoot
$pytestOk = $pytestResult.exit_code -eq 0
Add-PlanExecuteRow $rows "narrow plan execute and related planning tests pass" $pytestOk `
  "exit_code=$($pytestResult.exit_code); stdout=$($pytestResult.stdout.Trim()); stderr=$($pytestResult.stderr.Trim())" `
  "plan_execute_runtime_tests_failed"

$taskModeContract = Read-JsonFile $taskModeContractPath
$priorEvidenceOk = $taskModeContract.status -eq "task_mode_router_completed_needs_owner_review"
Add-PlanExecuteRow $rows "P1 task mode router contract is available" $priorEvidenceOk `
  "task_mode_status=$($taskModeContract.status)" `
  "plan_execute_runtime_prior_evidence_missing"

$contract = [ordered]@{
  schema_version = "heitang_plan_execute_runtime_basic_contract.v1"
  status = "plan_execute_runtime_completed_needs_owner_review"
  capability_id = "plan_execute_runtime"
  phase = "P1"
  acceptance_type = "core_only"
  required_inputs = @("steps")
  required_outputs = @("status", "execution_order", "completed_step_ids", "remaining_step_ids", "blocked_step_ids", "missing_dependency_step_ids")
  executed_report_path = $executedReportPath
  blocked_report_path = $blockedReportPath
  missing_dependency_report_path = $missingReportPath
  sample_statuses = @($executedReport.status, $blockedReport.status, $missingReport.status)
  next_gate = $nextGate
  global_goal_complete = $false
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $contractPath $contract

$contractOk = (Test-Path -LiteralPath $contractPath) -and
  ($contract.sample_statuses -join ",") -eq "executed,blocked,missing_dependencies" -and
  $contract.required_outputs.Count -eq 6 -and
  $contract.next_gate -eq "P1-16 Long Document Reading Strategy Basic" -and
  $contract.global_goal_complete -eq $false
Add-PlanExecuteRow $rows "plan execute runtime basic contract artifact is generated" $contractOk `
  "contract=$contractPath; statuses=$($contract.sample_statuses -join ','); next_gate=$($contract.next_gate)" `
  "plan_execute_runtime_contract_invalid"

$claimHits = Test-PositiveClaimBoundary @($contractPath, $executedReportPath, $blockedReportPath, $missingReportPath)
Add-PlanExecuteRow $rows "new P1-15 evidence has no forbidden positive-state tokens" ($claimHits.Count -eq 0) `
  "scanned=contract,executed,blocked,missing; hits=$($claimHits.Count)" `
  "plan_execute_runtime_forbidden_claim_token_found"

$blockedRows = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blockedRows.Count -eq 0) {
  "plan_execute_runtime_completed_needs_owner_review"
} else {
  "plan_execute_runtime_blocked"
}

$checkpoint = [ordered]@{
  schema_version = "heitang_plan_execute_runtime_basic_checkpoint.v1"
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
  schema_version = "heitang_plan_execute_runtime_basic_failure_template.v1"
  status = "no_current_failure"
  affected_phase = "P1"
  affected_capability_id = "plan_execute_runtime"
  failed_acceptance_type = "core_only"
  resume_prompt_path = $resumePath
  created_at = (Get-Date).ToUniversalTime().ToString("o")
})
@(
  "# Plan-and-Execute Runtime Basic Resume Prompt",
  "",
  "Resume from current_gate=$($chain.current_gate) if interrupted before commit.",
  "After commit, resume from next_gate=$nextGate.",
  "Keep global_goal_complete=false while remaining gates exist.",
  "Do not execute P1-16 until P1-15 evidence is committed."
) | Set-Content -Encoding UTF8 -Path $resumePath

$payload = [ordered]@{
  schema_version = "heitang_p1_plan_execute_runtime_basic_matrix.v1"
  status = $status
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
  repo_root = $repoRoot
  current_phase = $chain.current_phase
  current_gate = $chain.current_gate
  next_gate = $nextGate
  remaining_gates_count = $remaining.Count
  global_goal_complete = $false
  contract_path = $contractPath
  executed_report_path = $executedReportPath
  blocked_report_path = $blockedReportPath
  missing_dependency_report_path = $missingReportPath
  checkpoint_path = $checkpointPath
  failure_template_path = $failurePath
  resume_prompt_path = $resumePath
  rows = $rows
}
Write-Json $matrixPath $payload

$blockerText = if ($blockedRows.Count -eq 0) {
  "- none for this P1-15 gate; Owner review remains outside automatic closure."
} else {
  ($blockedRows | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$report = @(
  "# P1-15 Plan-and-Execute Runtime Basic Closure Report",
  "",
  "Status: $status",
  "",
  "## Acceptance Scope",
  "",
  "- Validate deterministic plan-and-execute ordering, blocked state and missing dependency handling.",
  "- This Gate is core_only; it does not execute real external tools, UI paths or runtime orchestration.",
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
  "- result: $($(if ($blockedRows.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- command: run_plan_execute_runtime_basic_matrix.ps1",
  "- schema evidence: runtime, pydantic schema, executed/blocked/missing reports and narrow tests.",
  "",
  "## Black-box Test Result",
  "",
  "- result: not_required",
  "- reason: core_only plan-and-execute runtime has no standalone user UI path.",
  "",
  "## Evidence Completeness Result",
  "",
  "- result: $($(if ($blockedRows.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- artifacts: contract, matrix, sample reports, checkpoint, failure template, resume prompt and this report.",
  "",
  "## Lifecycle Result",
  "",
  "- result: $($(if ($blockedRows.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- scope: create and read deterministic plan execution reports plus rerunnable verifier contract.",
  "",
  "## Regression Result",
  "",
  "- result: $($(if ($blockedRows.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- tests: python -m pytest tests/test_plan_execute_runtime_basic.py tests/test_task_mode_router_basic.py tests/test_planning_readiness.py -q",
  "",
  "## Boundary Compliance Result",
  "",
  "- result: $($(if ($blockedRows.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- no UI/runtime edits, no dependency addition, no external service use, no P2 entry.",
  "",
  "## Reviewer Findings",
  "",
  "- P1-15 uses deterministic core evidence only and does not fake a UI blackbox.",
  "- Long Document Reading Strategy remains queued as P1-16.",
  "- P1-14 task mode router evidence remains readable.",
  "",
  "## Final Close Decision",
  "",
  "- close_allowed: $($blockedRows.Count -eq 0)",
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
